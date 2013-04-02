function resetTrialInfo(obj,event,trialInfo)
% This is a callback function that just sets two property values back to
% their initial values for iteration / flag checking.
    trialInfo.flight_stopped = 0;
    trialInfo.time_elapsed = 0;
end