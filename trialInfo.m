classdef trialInfo < handle
    % This class is useful because its fields can be set by a callback
    % function, whereas with timers this is not possible using regular
    % variables.
    properties (SetAccess = public, GetAccess = public)
        time_elapsed = 0;
        flight_stopped = 0;
    end
end