function [result,message,metadata] = display_experiment_metadata(protocol_folder)
    
    result = 1;
    message = 'Metadata OK';
    
    try
        % Will it load?
        cf = cd;
        cd(protocol_folder)
        eval('experiment_metadata');
        cd(cf);
    catch ME
        disp(ME)
        result = 0;
        metadata = 'null';
        message = ['Problem loading metadata: ' ME.message];
        return
    end
    
    [~,protocol_name]       = fileparts(protocol_folder);
    metadata.Protocol       =  protocol_name;
    metadata.ExperimentName = [metadata.Protocol '-' metadata.Line '-' metadata.DateTime]; 

    disp(metadata)
    
    choice = input('Correct metadata? [Y]/n: ','s');
    
    switch choice
        case {'n','N'}
            message = 'Metadata Rejected';
        otherwise
            message = 'Metadata Accepted';
    end
    
end