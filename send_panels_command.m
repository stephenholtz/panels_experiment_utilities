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
        pause(.03)
        Panel_com('set_mode',cond_struct.Mode);
        pause(.03)
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

    else
        Panel_com('set_pattern_id',cond_struct.PatternID);
        pause(.03)
        Panel_com('set_position',cond_struct.InitialPosition);
        pause(.03)
        Panel_com('set_mode',cond_struct.Mode);
        pause(.03)

        % Deal with values over 127.
        if abs(cond_struct.Gains(1))>127
            [cond_struct.Gains(1),cond_struct.Gains(2)] = get_valid_gain_bias_vals(cond_struct.Gains(1));
        end
        if abs(cond_struct.Gains(3))>127
            [cond_struct.Gains(3),cond_struct.Gains(4)] = get_valid_gain_bias_vals(cond_struct.Gains(3));
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
    end
    
    Panel_com('set_ao',[3,cond_struct.Voltage*(32767/10)]);
    
    time = cond_struct.Duration;
    voltage = cond_struct.Voltage;
    
end

function [gain,bias] = get_valid_gain_bias_vals(fps)
    % ugly function to fix the gain and bias values...
    ideal_fps = abs(fps);

    range_gain = 0:127;
    range_bias = 0:127;

    found = false; %#ok<*NASGU>
    while true
        for gain = range_gain
            for bias = range_bias
                if(gain + 2.5*bias) == ideal_fps
                    found = true;
                    gain = gain*sign(fps); %#ok<*FXSET>
                    bias = bias*sign(fps);
                    return
                end
            end
        end
    end

    if ~found %#ok<UNRCH>
        error('Specified gain cannot be acheived!') 
    end

end
