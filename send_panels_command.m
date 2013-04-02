function [time, voltage] = send_panels_command(cond_struct)
% Runs a condition based on the fields of the struct. Returns the
% time that it should be allowed to run (i.e. for a pause).
% For the most recent version of the panels, there is a fast mode
% that can load patterns to panels, check the field 'display_type'
% Also can use higher gain values.

    if isfield(cond_struct,'DisplayType') && sum(strcmpi(cond_struct.DisplayType,'panels'))

        Panel_com('load_pattern_2panels',cond_struct.PatternID);
        pause(.05) % Takes a bit of time to load the pattern
        Panel_com('set_position',cond_struct.InitialPosition);
        pause(.05) % For some reason this also takes some time
        Panel_com('set_mode',cond_struct.Mode);
        pause(.05)
        Panel_com('send_gain_bias',cond_struct.Gains);
        pause(.05)
        % For now leave this out, need to reconvene with Jin - 12/12
        %Panel_com('set_posfunc_id',cond_struct.PosFunctionY);
        %Panel_com('set_posfunc_id',cond_struct.PosFunctionX);
        %Panel_com('set_funcy_freq',cond_struct.FuncFreqY);
        %Panel_com('set_funcx_freq',cond_struct.FuncFreqX);
    else
        Panel_com('set_pattern_id',cond_struct.PatternID);
        pause(.03)
        Panel_com('set_position',cond_struct.InitialPosition);
        pause(.03)
        Panel_com('set_mode',cond_struct.Mode);
        pause(.03)

        % Deal with values over 127.
        if abs(cond_struct.Gains(1))>127
            [cond_struct.Gains(1),cond_struct.Gains(2)] = Exp.Utilities.get_valid_gain_bias_vals(cond_struct.Gains(1));
        end
        if abs(cond_struct.Gains(3))>127
            [cond_struct.Gains(3),cond_struct.Gains(4)] = Exp.Utilities.get_valid_gain_bias_vals(cond_struct.Gains(3));
        end

        Panel_com('send_gain_bias',cond_struct.Gains);
        pause(.03)
        Panel_com('set_funcy_freq',cond_struct.FuncFreqY);
        pause(.03)
        Panel_com('set_posfunc_id',cond_struct.PosFunctionY);
        pause(.03)
        Panel_com('set_funcx_freq',cond_struct.FuncFreqX);
        pause(.03)
        Panel_com('set_posfunc_id',cond_struct.PosFunctionX);
        pause(.03)

%        % Some new issues 12/12, need to meet with Jin
%         if cond_struct.PosFunctionY(2)
%             Panel_com('set_posfunc_id',cond_struct.PosFunctionY);
%             pause(.05)
%         end
% 
%         if cond_struct.PosFunctionX(2)
%             Panel_com('set_posfunc_id',cond_struct.PosFunctionX);
%             pause(.05)
%         end
% 
%         if cond_struct.PosFunctionY(2)
%             Panel_com('set_funcy_freq',cond_struct.FuncFreqY);
%             pause(.05)
%         end
% 
%         if cond_struct.PosFunctionX(2)
%             Panel_com('set_funcx_freq',cond_struct.FuncFreqX);
%             pause(.05)
%         end

    end
    
    Panel_com('set_ao',[3,cond_struct.Voltage*(32767/10)]);
%    Panel_com('set_ao',[4,0]); % trigger for precise timing of stim onset
    
    time = cond_struct.Duration;
    voltage = cond_struct.Voltage;
end