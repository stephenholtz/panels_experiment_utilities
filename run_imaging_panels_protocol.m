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
    num_repetitions = 4;
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
    experiment_metadata.orig_exp_loc = fullfile(storage_directory,experiment_metadata.Protocol,[experiment_metadata.Line '_' experiment_metadata.Effector],experiment_metadata.DateTime);
    mkdir(experiment_metadata.orig_exp_loc);
    % save the metadata now, in case the experiment crashes...
    [result,message] = save_experiment_metadata_file(experiment_metadata.orig_exp_loc,experiment_metadata);
    handle_result(result,message);
    % Create DAQ Channels
    daqreset;
    % Add analogoutput for the water bath control signal
    S_AO=daq.createSession('ni');
    S_AO.addAnalogOutputChannel('Dev1',0,'Voltage');
    S_AO.outputSingleScan([2.0]);
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
    fprintf('Initial Alignment. Press any key to start experiment.\n')
    pause()
    Panel_com('stop')

    % Create a variable to count the missed conditions for an alert email.
    time_taken_hand = tic;
    % Loop through the conditions, randomizing and repeating when/if necessary
    for repetition = 1:num_repetitions

        rep_conditions_left = 1:numel(protocol_conditions.experiment);
        if randomize_conditions
            rep_conditions_left = rep_conditions_left(randperm(numel(rep_conditions_left)));
        end

        while ~isempty(rep_conditions_left)
            current_condition = rep_conditions_left(1);
            
            % Start with interspersal period
            send_panels_command(protocol_conditions.interspersal);
            S_DO.outputSingleScan(1);            
            Panel_com('start');
            disp('Interpsersed Condition'); 
            Panel_com('stop');

            % Display the experimental stimulus
            fprintf('Condition %d / %d; rep %d / %d\n',numel(protocol_conditions.experiment)-numel(rep_conditions_left)+1,numel(protocol_conditions.experiment),repetition,num_repetitions);
            send_panels_command(protocol_conditions.experiment(current_condition));
 
            % Send the trigger to start acquisition before starting the stimulus (the 'stimulus' duration should be longer than the acquisition period)
            S_DO.outputSingleScan(1);
            Panel_com('start');

            % Pause for the correct amount of time
            cond_tic = tic;
            elapsed = toc(cond_tic);
            while elapsed < protocol_conditions.experiment(current_condition).Duration;
                pause(.001);
                elapsed = toc(cond_tic);
            end
            S_DO.outputSingleScan(0);
            % Remove completed condition from the list
            rep_conditions_left = rep_conditions_left(2:end);
            Panel_com('stop');
        end
    end

%===End the experiment and clean up the hardware etc.,=====================
    % End with another interspersal stimulus 
    send_panels_command(protocol_conditions.interspersal);
    Panel_com('start');
    pause(protocol_conditions.interspersal.Duration);
    % Stop/Delete DAQ channels
    delete(S_DO); delete(S_AO);
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
