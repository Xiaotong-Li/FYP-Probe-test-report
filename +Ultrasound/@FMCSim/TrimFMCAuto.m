function obj=TrimFMCAuto(obj)
% TrimFMCAuto             *No arguments
% finds first and last non-zero item of the FMC and trims the FMC
% out of outer zeros.
% example: 
% sim.TrimFMCAuto
%
% See also Ultrasound.FMCSim

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012

FMCTotal=sum(obj.FMC,2);
t1=obj.FMCTimeBase(max(find(FMCTotal~=0,1,'first')-2,1));
t2=obj.FMCTimeBase(min(find(FMCTotal~=0,1,'last')+2,length(FMCTotal)));
obj.TrimFMCToStartStop(t1,t2);

end