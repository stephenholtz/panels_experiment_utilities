function updateTrialInfo(obj,event,trialInfo,monitoring_daq,monitor_hw_ind,monitor_threshold_val)
% This is a callback function for the timer that will update some
% properties of trialInfo based on data from a DAQ. To avoid updating the
% properties, pass something other than the DAQ's handle to the function
% (i.e. monitoring_daq = 0;)
% The trialInfo properties can then be checked in the other function to see
% if this callback updated them or not.
    if isobject(monitoring_daq)
        peeked_data = peekdata(monitoring_daq,10);
        freq = median(peeked_data(:,monitor_hw_ind));
        if freq < monitor_threshold_val;
            trialInfo.flight_stopped = 1;
        else
            trialInfo.flight_stopped = 0;
        end
    end
    trialInfo.time_elapsed = trialInfo.time_elapsed + datenum(event.Data.time(end));
end