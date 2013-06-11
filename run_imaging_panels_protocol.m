function run_imaging_panels_protocol(protocol_folder)
% This runs a protocol, which consists of a function that returns a set of
% conditions for the controller, a metadata file that has the experimental
% conditions for record keeping, and a folder that has a copy of what is on
% the SD card in the controller.
%
% This is slightly different than the tethered flight function, it has a 
% bit more signal sending / waiting 

%===Set values for the current experiment here=============================
    % Number of repetitions
    num_repetitions = 2;
    % Randomize conditions
    randomize_conditions = 1;
    % Storage location
    storage_directory = 'C:\imaging_tmpfs'; 

%===Do some checks, and hardware initialization============================
    % check the protocol for all the required parts...
    [result,message,protocol_conditions] = check_panels_protocol(protocol_folder);
    handle_result(result,message);
    % verify the experiment_metadata...
    [result,message,experiment_metadata] = display_experiment_metadata(protocol_folder);
    handle_result(result,message);
    experiment_metadata.protocol_conditions = protocol_conditions;
    % make a folder for the experiment + experiment_metadata + data.daq...
    experiment_metadata.orig_exp_loc = fullfile(storage_directory,experiment_metadata.Protocol,[experiment_metadata.Line '_' experiment_metadata.Indicator],experiment_metadata.DateTime);
    mkdir(experiment_metadata.orig_exp_loc);
    % save the metadata now, in case the experiment crashes...
    [result,message] = save_experiment_metadata_file(experiment_metadata.orig_exp_loc,experiment_metadata);
    handle_result(result,message);
    % Create DAQ Channels
    daqreset;
    % Add analogoutput for the water bath control signal
    S_AO_0=daq.createSession('ni');
    S_AO_0.addAnalogOutputChannel('Dev1',0,'Voltage');
    S_AO_0.outputSingleScan(2.0);
    % Add analogoutput for parsing out stimuli from the experiment 
    S_AO_1=daq.createSession('ni');
    S_AO_1.addAnalogOutputChannel('Dev1',1,'Voltage');
    S_AO_1.outputSingleScan(0);
     % Add digital out for triggering prairie view
    S_DO=daq.createSession('ni');
    S_DO.addDigitalChannel('Dev1','port0/line0','OutputOnly');
    S_DO.outputSingleScan(0);
    disp('Hardware ON')

%===Start the experiment===================================================
    % Begin initial closed loop portion (add hard coded path of location for panels code)
    addpath(genpath('C:\XmegaController_Matlab_V13')); 
    PControl; pause(5);
    Panel_com('set_config_id',protocol_conditions.initial_alignment.PanelCfgNum);
    pause(3); % Setting the configuration takes a few seconds.
    send_panels_command(protocol_conditions.initial_alignment);
    Panel_com('start')
    fprintf('Initial Alignment. Press any key to start experiment (send acquisition trigger).\n')
    pause()
    Panel_com('stop')

    % Store the order of the conditions in the metadata
    experiment_metadata.ordered_conditions = [];
    % Create a variable to count the missed conditions for an alert email.
    time_taken_hand = tic;
    % Loop through the conditions, randomizing and repeating when/if necessary
    % Send the trigger to start acquisition before starting the stimulus
    % (the total 'stimulus' duration should be shorter than the acquisition period 
    % as set in PView, i.e. set the T-series to acquire some arbitrarily large
    % number of frames for a much shorter time (and remind by email to stop) )
    S_DO.outputSingleScan(1);
    % Let the initial reaction to the laser turning on go away
    pause(20); 

    for repetition = 1:num_repetitions
        rep_conditions_left = 1:numel(protocol_conditions.experiment);
        if randomize_conditions
            rep_conditions_left = rep_conditions_left(randperm(numel(rep_conditions_left)));
        end
        experiment_metadata.ordered_conditions = [experiment_metadata.ordered_conditions rep_conditions_left]; %#ok<*AGROW>

        while ~isempty(rep_conditions_left)
            current_condition = rep_conditions_left(1);
            % Start with interspersal period
            send_panels_command(protocol_conditions.interspersal);
            % The pre-stimulus has a voltage of 2
            S_AO_1.outputSingleScan(2);
            Panel_com('start');
            fprintf('Interpsersed Condition: %d\n',protocol_conditions.interspersal.Duration); 
            pause(protocol_conditions.interspersal.Duration);
            Panel_com('stop');
            % A small gap where the output goes to zero
            S_AO_1.outputSingleScan(0); pause(.01);
            % Display the experimental stimulus
            fprintf('Condition %d / %d; rep %d / %d\n',numel(protocol_conditions.experiment)-numel(rep_conditions_left)+1,numel(protocol_conditions.experiment),repetition,num_repetitions);
            send_panels_command(protocol_conditions.experiment(current_condition));
            % The actual stimulus has a voltage of 4
            S_AO_1.outputSingleScan(4);
            Panel_com('start');

            % Pause for the correct amount of time
            cond_tic = tic;
            elapsed = toc(cond_tic);
            while elapsed < protocol_conditions.experiment(current_condition).Duration;
                pause(.001);
                elapsed = toc(cond_tic);
            end
            % Remove completed condition from the list
            rep_conditions_left = rep_conditions_left(2:end);
            Panel_com('stop');
            % A small gap where the output goes to zero
            S_AO_1.outputSingleScan(0); pause(.01);
         end
    end
    S_DO.outputSingleScan(0);

%===End the experiment and clean up the hardware etc.,=====================
    % End with another interspersal stimulus 
    send_panels_command(protocol_conditions.interspersal);
    Panel_com('start');
    pause(protocol_conditions.interspersal.Duration);
    Panel_com('stop');
    % Stop/Delete DAQ channels
    delete(S_DO); delete(S_AO_0); delete(S_AO_1);
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
