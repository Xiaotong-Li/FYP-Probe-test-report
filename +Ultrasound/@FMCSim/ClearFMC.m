function obj=ClearFMC(obj)
% ClearFMC    *no parameters
% fills the existing FMC with zeros, keeping its size.
%
% example:
% sim.ClearFMC;
%
% See also Ultrasound.FMCSim
%
% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012

obj.FMC=zeros(size(obj.FMC)); % dimensions verified, time-samples first
end