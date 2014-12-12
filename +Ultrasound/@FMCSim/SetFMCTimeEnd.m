function SetFMCTimeEnd(obj,NewValue)
% SetFMCTimeEnd(NewTimeEnd)
% trims and updates the FMC with new finish time. FMC is resized as needed.
% 
% example: 
% sim.SetFMCTimeEnd(50e-6)
%
% See also Ultrasound.FMCSim

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012

obj.TrimFMCToStartStop(obj.FMCTimeStart,NewValue);
end