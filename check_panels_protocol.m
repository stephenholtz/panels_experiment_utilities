function [result,msg,protocol_conditions] = check_panels_protocol(protocol_folder)
% This function just loads in some conditions from a function that has them
% as its output and makes sure the minimum number of fields exist in each
% experimental condition. This avoids missed settings (i.e. position
% function number etc.,)

    result = 1;    
    msg = 'Protocol OK';

    [~,protocol_name] = fileparts(protocol_folder);
    run(fullfile(protocol_folder,[protocol_name '.m']));
    protocol_conditions = ans; %#ok<*NOANS>
    
    if isfield(protocol_conditions,'experiment') && isfield(protocol_conditions,'interspersal') && isfield(protocol_conditions,'initial_alignment')
    else
        result = 0;
        msg = 'Missing a top level field, should have: ''.experiment'', ''.interspersal'', ''.initial_alignment''';
        return
    end

    panel_com_fields        =  {'PatternID',...         % trial_metadata type value
                                'Gains',...             % trial_metadata type value
                                'Mode',...              % trial_metadata type value
                                'Duration',...          % trial_metadata type value
                                'InitialPosition',...   % trial_metadata type value
                                'FuncFreqX',...         % trial_metadata type value
                                'PosFunctionX',...      % trial_metadata type value
                                'FuncFreqY',...         % trial_metadata type value
                                'PosFunctionY',...      % trial_metadata type value
                                'Voltage',...           % trial_metadata type value
                                'PosFuncNameX',...      % trial_metadata type value
                                'PosFuncNameY',...      % trial_metadata type value
                                'PatternName'}; 
    
    for fields = panel_com_fields
        f = fields{1};
        
        for i = 1:numel(protocol_conditions.experiment)
            if ~isfield(protocol_conditions.experiment(i),f)
                result = 0;
                msg = ['Missing a panel command field: protocol_conditions.experiment(' num2str(i) ').' f];
                return
            end
        end
        
        for i = 1:numel(protocol_conditions.interspersal)
            if ~isfield(protocol_conditions.interspersal(i),f)
                result = 0;
                msg = ['Missing a panel command field: protocol_conditions.closed_loop(' num2str(i) ').' f];
                return                
            end
        end
        
        for i = 1:numel(protocol_conditions.initial_alignment)
            if ~isfield(protocol_conditions.initial_alignment(i),f)
                result = 0;
                msg = ['Missing a panel command field: protocol_conditions.initial_alignment(' num2str(i) ').' f];
                return                
            end
        end
        
    end

end