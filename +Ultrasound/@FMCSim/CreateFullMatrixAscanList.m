function obj=CreateFullMatrixAscanList(obj,t0,t1)
% CreateFullMatrixAscanList(tstart,tfinish)
%
% Creates TxRxList and initializes FMC buffer
% tstart, tfinish - time span of the FMC
%
% Stored settings apply
% example:
% sim.CreateFullMatrixAscanList(1e-6,80e-6);
% See also Ultrasound.FMCSim

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012
            
NElements=size(obj.ProbeElementLocations,2);
local_txrxlist=zeros(2,NElements.^2);
for tx=1:(NElements)
    for rx=1:(NElements)
        local_txrxlist(:,rx+NElements*(tx-1))=[tx rx]-1;
    end
end
obj.CreateTxRxList(local_txrxlist,t0,t1);
end