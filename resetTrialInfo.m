function resetTrialInfo(~,~,TrialInfo)
% This is a callback function that just sets two property values back to
% their initial values for iteration / flag checking.
    TrialInfo.flight_stopped = 0;
    TrialInfo.time_elapsed = 0;
    TrialInfo.lmr_wba = 0;
end