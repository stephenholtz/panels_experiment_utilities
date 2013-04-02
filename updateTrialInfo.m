function updateTrialInfo(obj,event,trialInfo,monitor_channel)
    if isobject(monitor_channel)
        start(monitor_channel);
        freq = mean(getdata(monitor_channel));
        disp(freq)
        if freq > 1;
            trialInfo.flight_stopped = 0;
        else
            trialInfo.flight_stopped = 1;
        end
        stop(monitor_channel);
    end
    trialInfo.time_elapsed = trialInfo.time_elapsed + datenum(event.Data.time(end));
end