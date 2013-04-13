classdef panels_experiment_instance
% This just houses a few properties and functions that could also have
% their own individual functions or script m files. All functions might be
% rolled into this eventually...

    properties (Constant)
        % Number of repetitions of the experiment
        num_repetitions = 3;
        % Randomize the experiment stimuli within each repetition
        ramdomize_conditions = 1;
        % Record the wing beats
        record_flight = 1;
        % Check if the fly is flying during the experiment
        check_flight = 1;
        % Startle the fly if it is not flying (function to do so below),
        % depends on check_flight being on
        startle_for_flight = 1;
        % Minimum wing beat frequency signal to trigger a failed stimulus
        wbf_cutoff = .8;
        wbf_hw_index = 3;
        % Repeat conditions that are missed due to no flight, depends on
        % check_flight being on
        repeat_missed_conditions = 1;
        % Channel number on the daq that has the volt encoded signal
        volt_encoding_hw_ind = 7;
        min_volt_encoded_signal = .09; % anything less than .09V is a closed loop stimulus
        % Which COM port the controller lives on (not currently used)
        panel_controller_serial_port = 'COM3';
        % The directory where all of the data is stored
        storage_directory = 'C:\tf_tmpfs\';
        % Recorded data sampling rate
        aquisition_sampling_rate = 1000;
    end
    
    methods
        % This function will return all of the settings and is used in
        % running the experimental protocols
        function instance = experiment_settings(~)
        end
    end
    
    methods
        function daq_handle = initialize_data_recording_daq(instance,experiment_dir)
            % The analog input device used as the data acquisition device
            daq_handle = analoginput('nidaq','Dev1');
            addchannel(daq_handle,0:6);            
            daq_file = fullfile(experiment_dir,'data.daq');
            set(daq_handle,'LoggingMode','Disk','LogFileName',daq_file,'SampleRate',instance.aquisition_sampling_rate);
            set(daq_handle,'SamplesPerTrigger',Inf);
        end
        
        function startle_channel = initialize_startle_channel(~)
            % The digital output for the startle trigger
            startle_channel = digitalio('nidaq','Dev1');
            addline(startle_channel,0,'Out');
        end
        
        function startle_animal(~,startle_channel)
            dur = .075;
            pause(dur)
            start(startle_channel)
            pause(dur)
            putvalue(startle_channel,1)
            pause(dur)
            putvalue(startle_channel,0)
            pause(dur)
            putvalue(startle_channel,1)
            pause(dur)
            putvalue(startle_channel,0)
            pause(dur)
            stop(startle_channel)
            pause(dur)
        end
    end
    
end