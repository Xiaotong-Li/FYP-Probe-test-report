function SetFMCTimeStartAndTrim(obj,NewValue)
% SetFMCTimeStartAndTrim(NewTime)
% trims and updates the FMC size with new start time. FMC is resized as needed
% 
% example: sim.SetFMCTimeStartAndTrim(50e-6)
% See also Ultrasound.FMCSim

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012
obj.TrimFMCToStartStop(NewValue,obj.FMCTimeEnd);
end