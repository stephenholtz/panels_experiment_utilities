function updateTrialInfo(obj,event,trialInfo,monitoring_daq,samples_to_monitor,monitor_hw_ind,monitor_threshold_val,l_wba_hw_ind,r_wba_hw_ind)
% This is a callback function for the timer that will update some
% properties of trialInfo based on data from a DAQ. To avoid updating the
% properties, pass something other than the DAQ's handle to the function
% (i.e. monitoring_daq = 0;)
% The trialInfo properties can then be checked in the other function to see
% if this callback updated them or not.
    if isobject(monitoring_daq)
        peeked_data = peekdata(monitoring_daq,samples_to_monitor);
        trialInfo.lmr_wba = peeked_data(:,l_wba_hw_ind) - peeked_data(:,r_wba_hw_ind);
        freq = median(peeked_data(:,monitor_hw_ind));
        if freq < monitor_threshold_val;
            trialInfo.flight_stopped = 1;
        else
            trialInfo.flight_stopped = 0;
        end
    end
    trialInfo.time_elapsed = trialInfo.time_elapsed + datenum(event.Data.time(end));
end