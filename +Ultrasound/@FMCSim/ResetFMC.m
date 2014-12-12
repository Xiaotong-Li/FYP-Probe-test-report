function obj=ResetFMC(obj)
% EmptyFMC               *no parameters
% Calls the FMC reset function in the cuTFM
%
% example:
% sim.EmptyFMC(TxRxList,1e-6,60e-6)
% See also Ultrasound.FMCSim

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012


% upload settings
%debugvar=obj.cuTFMv4007(23,1,1)
obj.cuTFMv4007(int32(19));
% reset FMC buffer
obj.cuTFMv4007(int32(28)); % method_ResetFMC
obj.FMC=obj.cuTFMv4007(int32(29)); %method_DownloadFMC
% there is an additional optional parameter to select which GPU to select
% do download the FMC from:
% obj.FMC=obj.cuTFMv4007(int32(29),1); % download from GPU 1
perfCounter=obj.cuTFMv4007(int32(17)); 
end