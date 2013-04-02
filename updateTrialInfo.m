function updateTrialInfo(obj,event,trialInfo,monitor_channel)
% This is a callback function for the timer that will update some
% properties of trialInfo based on data from a DAQ. To avoid updating the
% properties, pass something other than the DAQ's handle to the function
% (i.e. monitor_channel = 0;)
% The trialInfo properties can then be checked in the other function to see
% if this callback updated them or not.
    if isobject(monitor_channel)
        start(monitor_channel);
        freq = mean(getdata(monitor_channel));
        if freq > 1;
            trialInfo.flight_stopped = 0;
        else
            trialInfo.flight_stopped = 1;
        end
        stop(monitor_channel);
    end
    trialInfo.time_elapsed = trialInfo.time_elapsed + datenum(event.Data.time(end));
end