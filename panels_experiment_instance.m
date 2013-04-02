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
        % Repeat conditions that are missed due to no flight, depends on
        % check_flight being on
        repeat_missed_conditions = 1;
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
        function instance = experiment_settings()
        end
    end

    methods
        function recording_channel = initialize_recording_channel(instance,experiment_dir)
            % The analog input device used as the data acquisition device
            recording_channel = analoginput('nidaq','Dev1');
            addchannel(recording_channel,0:6);            
            daq_file = fullfile(experiment_dir,'data.daq');
            set(recording_channel,'LoggingMode','Disk','LogFileName',daq_file,'SampleRate',instance.aquisition_sampling_rate);
            set(recording_channel,'SamplesPerTrigger',Inf);
        end
    end
    
    methods (Static)
        
        function flight_check_channel = initialize_flight_check_channel()
            % The analog input for flight checking
            flight_check_channel = analoginput('mcc',0);
            addchannel(flight_check_channel, 0);
            set(flight_check_channel,'TriggerType','Immediate','SamplesPerTrigger',1,'ManualTriggerHwOn','Start')
        end
        
        function startle_channel = initialize_startle_channel()
            % The digital output for the startle trigger
            startle_channel = digitalio('mcc',0);
            addline(startle_channel,0,'Out');
        end
        
        function startle_animal(startle_channel)
            start(startle_channel)
            putvalue(startle_channel,1)
            pause(.05)
            putvalue(startle_channel,0) 
            pause(.01)
            putvalue(startle_channel,1)
            pause(.075)
            putvalue(startle_channel,0)
            stop(startle_channel)
        end
        
    end
    
end