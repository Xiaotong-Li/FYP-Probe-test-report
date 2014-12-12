function obj=CreateHalfMatrixAscanList(obj,t0,t1)
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
local_txrxlist=zeros(2,((NElements^2)/2+NElements/2)); % create empty HMC list
indexer=1;
for tx=1:NElements
    for rx=1:tx
        local_txrxlist(:,indexer)=[tx rx]-1;
        indexer=indexer+1;
    end
end
obj.CreateTxRxList(local_txrxlist,t0,t1);
end