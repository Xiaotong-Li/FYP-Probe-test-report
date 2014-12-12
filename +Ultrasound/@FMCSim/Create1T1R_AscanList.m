function obj=Create1T1R_AscanList(obj,t0,t1)
% CreateHalfMatrixAscanList(t0,t1)
% creates fresh TxRxList and initializes FMC Buffer
% tstart, tfinish - time span of the FMC
%
% Stored  settings apply
% example:
% sim.CreateHalfMatrixAscanList(1e-6,80e-6);
% See also Ultrasound.FMCSim

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012

NElements=size(obj.ProbeElementLocations,2);
local_txrxlist=[0:(NElements-1); 0:(NElements-1)];
obj.CreateTxRxList(local_txrxlist,t0,t1);
end