function run_panels_protocol(protocol_folder)
% This runs a protocol, which consists of a function that returns a set of
% conditions for the controller, a metadata file that has the experimental
% conditions for record keeping, and a folder that has a copy of what is on
% the SD card in the controller.

%===Do some checks, and hardware initialization============================
    
    % check the protocol for all the required parts...
    [result,message,protocol_conditions] = check_panels_protocol(protocol_folder);
    handle_result(result,message);
    % verify the experiment_metadata...
    [result,message,experiment_metadata] = display_experiment_metadata(protocol_folder);
    handle_result(result,message);
    % 'initialize' the experiment settings and hardware...
    exp_instance = panels_experiment_instance;
    experiment_metadata.exp_instance = exp_instance;
    experiment_metadata.protocol_conditions = protocol_conditions;
    
    % make a folder for the experiment + experiment_metadata + data.daq...
    experiment_metadata.orig_exp_loc = fullfile(exp_instance.storage_directory,experiment_metadata.Protocol,[experiment_metadata.Line '_' experiment_metadata.Effector],experiment_metadata.DateTime);
    mkdir(experiment_metadata.orig_exp_loc);
    % save the metadata now, in case the experiment crashes...
    [result,message] = save_experiment_metadata_file(experiment_metadata.orig_exp_loc,experiment_metadata);
    handle_result(result,message);
    % Create DAQ Channels if needed...
    if exp_instance.record_flight || exp_instance.startle_for_flight;   
        daqreset;
    end
    if exp_instance.record_flight;      
        recording_channel  = exp_instance.initialize_recording_channel(experiment_metadata.orig_exp_loc);
    end
    if exp_instance.startle_for_flight;
        startle_channel    = exp_instance.initialize_startle_channel;
    end
    % Make an empty variable for the timer callback function...
    if exp_instance.check_flight;        
        flight_check_channel = exp_instance.initialize_flight_check_channel; 
    else
        flight_check_channel = [];
    end
    disp('Hardware OK')
    
%===Start the experiment===================================================

    % Begin initial closed loop portion (add hard coded path of location
    % for panels code)
    addpath(genpath('C:\XmegaController_Matlab_V13')); 
    Panel_com('set_config_id',protocol_conditions.initial_alignment.PanelCfgNum);
    pause(5); % Setting the configuration takes a few seconds.
    send_panels_command(protocol_conditions.initial_alignment);
    Panel_com('start')
    fprintf('Initial Alignment. Press any key to start experiment.\n')
    pause()
    Panel_com('stop')
    
    % Start DAQ Channels
    if exp_instance.record_flight;  start(recording_channel);   end
    if exp_instance.check_flight;   start(flight_check_channel);end
    % Set up timer function stuff
    timer_fcn_period = .1;
    trial_info = trialInfo; 
    timer_hand = timer('BusyMode','queue','Period',timer_fcn_period,'ExecutionMode','FixedRate','StartFcn',{@resetTrialInfo},'TimerFcn',{@updateTrialInfo, trial_info, flight_check_channel});
    check_is_on = @(str)(strcmpi('on',str));
    % Create a variable to count the missed conditions for an alert email.
    missed_condition_counter = 0;
    time_taken_hand = tic;
    
    % Loop through the conditions, randomizing and repeating when/if necessary
    for repetition = 1:exp_instance.num_repetitions
        
        rep_conditions_left = 1:numel(protocol_conditions.experiment);
        if exp_instance.ramdomize_conditions
            rep_conditions_left = rep_conditions_left(randperm(numel(rep_conditions_left)));
        end
        
        for current_condition = rep_conditions_left
            
            % Start with closed loop portion
            num_periods = ceil(protocol_conditions.closed_loop.Duration/timer_fcn_period);
            set(timer_hand,'TasksToExecute',num_periods);
            
            send_panels_command(protocol_conditions.closed_loop);
            Panel_com('start'); % This order matters! Flies don't like being put on stimulus hold
            start(timer_hand);
            fprintf(' Interpsersed Condition | Duration: %d | PatternName: %s\n',protocol_conditions.closed_loop.Duration,protocol_conditions.closed_loop.PatternName{1})
            
            running = check_is_on(timer_hand.Running);
            no_flight = 0;
            while running || no_flight
                running = check_is_on(timer_hand.Running);
                if exp_instance.check_flight && trial_info.flight_stopped
                    no_flight = 1;
                    exp_instance.startle_animal(startle_channel);
                    stop(timer_hand)
                    set(timer_hand,'TasksToExecute',num_periods);
                    start(timer_hand);
                elseif exp_instance.check_flight && ~trial_info.flight_stopped
                    no_flight = 0;
                end
            end
            Panel_com('stop');
            
            % Display the experimental stimulus
            num_periods = ceil(protocol_conditions.experiment(current_condition).Duration/timer_fcn_period);
            set(timer_hand,'TasksToExecute',num_periods);
            
            send_panels_command(protocol_conditions.experiment(current_condition));
            Panel_com('start');
            start(timer_hand);
            [~,ind]=find(rep_conditions_left==current_condition);
            fprintf('[Rep %d/%d] | [Cond %d/%d] | Duration: %d | PatternName: %s... \n',repetition,exp_instance.num_repetitions,ind,numel(protocol_conditions.experiment),protocol_conditions.experiment(current_condition).Duration,protocol_conditions.experiment(current_condition).PatternName(1:20));
            
            running = check_is_on(timer_hand.Running);
            while running
                running = check_is_on(timer_hand.Running);
                if exp_instance.check_flight && trial_info.flight_stopped
                    stop(timer_hand)
                    running = 0;
                    disp('Flight stopped!')
                    
                    if exp_instance.startle_for_flight
                        exp_instance.startle_animal(startle_channel);
                    end
                    
                    if exp_instance.repeat_missed_conditions
                        missed_condition_counter = missed_condition_counter + 1;
                        rep_conditions_left = [rep_conditions_left current_condition]; %#ok<*AGROW>
                        rep_conditions_left = rep_conditions_left(randperm(numel(rep_conditions_left)));
                        if ~mod(missed_condition_counter,25)
                            [result,message] = send_alert_email('Experiment Failing!',{['Name: ' experiment_metadata.ExperimentName],['Arena: ' experiment_metadata.Arena],['Times Flight Stopped: ' num2str(missed_condition_counter)]});
                            handle_result(result,message);
                        end
                    end
                end
            end
            Panel_com('stop');
        end
    end
    
%===End the experiment and clean up the hardware etc.,=====================

    % End with another closed loop (not wing beat checked)
    send_panels_command(protocol_conditions.closed_loop);
    pause(protocol_conditions.closed_loop.Duration);
    % Delete the timer
    delete(timer_hand)
    % Stop/Delete DAQ channels
    if exp_instance.record_flight;      stop(recording_channel);    delete(recording_channel); end
    if exp_instance.check_flight;       stop(flight_check_channel); delete(flight_check_channel);end
    if exp_instance.startle_for_flight; delete(startle_channel);    end
    % update the experiment_metadata file as the experiment finishes
    experiment_metadata.time_taken = toc(time_taken_hand);
    [result,message] = save_experiment_metadata_file(experiment_metadata.orig_exp_loc,experiment_metadata);
    handle_result(result,message);
    % copy the SC_card_contents to the experimental folder
    [result,message] = copy_SD_card_contents_to_exp_dir(protocol_folder,experiment_metadata.orig_exp_loc);
    handle_result(result,message);
    % end the experiment, send an alert email
    [result,message] = send_alert_email('Experiment Complete!',{['Name: ' experiment_metadata.ExperimentName],['Arena: ' experiment_metadata.Arena],['Time: ' num2str(experiment_metadata.time_taken/60) ' mins.']});
    handle_result(result,message);
	
    function handle_result(result,message)
    % Saves a few lines of code.
        if ~result; error(message)
        else        disp(message)
        end
    end
end