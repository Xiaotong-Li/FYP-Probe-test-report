function obj=CreateTxRxList(obj,txrxlist,t0,t1)
% function CreateTxRxList(txrxlist,t0,t1)
% populates TxRxList with a supplied list, and creates empty
% FMC spanning from t0 to t1
% txrxlist must be a N*2 matrix
%
% example:
% TxRxList=[1 1; 1 2; 2 1];
% sim.CreateTxRxList(TxRxList,1e-6,60e-6)
% See also Ultrasound.FMCSim

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012

obj.TxRxList=txrxlist;
nt=round((t1-t0)*obj.FMCSamplingRate);
obj.FMC=zeros(nt,size(obj.TxRxList,2),'single');
obj.SetFMCTimeStart(t0); % that's in subclass

end