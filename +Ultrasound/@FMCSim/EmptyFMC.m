function obj=EmptyFMC(obj)
% EmptyFMC               *no parameters
% Empties the FMC, sets its contents to empty.
%
% example:
% sim.EmptyFMC(TxRxList,1e-6,60e-6)
% See also Ultrasound.FMCSim

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012
obj.FMC=zeros(0,size(obj.FMC,2),'single');

end