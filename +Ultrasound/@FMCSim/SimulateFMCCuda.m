function obj=SimulateFMCCuda(obj)
% SimulateFMC    *No arguments
% executes the FMC simulation process
% uses CUDA implementation
%
% Stored settings apply
%
% example:
% sim.SimulateFMC
%
% See also Ultrasound.FMCSim, Ultrasound.FMCSim.SimulateFMC_GPU

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012

obj.cuTFMv4007(int32(19)); % upload settings
obj.cuTFMv4007(int32(30)); % make FMC
obj.FMC=obj.cuTFMv4007(int32(29)); % download to object

end % object SimulateFMC