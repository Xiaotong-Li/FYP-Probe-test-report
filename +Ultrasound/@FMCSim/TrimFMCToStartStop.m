
function obj=TrimFMCToStartStop(obj,time1,time2)
% TrimFMCToStartStop(time1,time2)
% trims or extends the FMC matrix as needed by time1 and time2
% 
% example:
% sim.TrimFMCToStartStop(5e-6,20e-6)
% 
% See also Ultrasound.FMCSim

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012

% figure out old indices
oldtime1=obj.FMCTimeStart; oldtime2=obj.FMCTimeEnd; nt=(oldtime2-oldtime1)*obj.FMCSamplingRate;
% check for error
if (time2<time1)||(time2<oldtime1)||(time1>oldtime2)
    error('cannot have negative time span')
end
if size(obj.FMC,2)<1
    % need to initialize fmc?
    error('No ascans in FMC? fill the TxRxList first')
end
% figure out what changes
if time1~=oldtime1
    if time1>oldtime1 % trim front
        % find best trim idx
        oldTimeBase=obj.FMCTimeBase;
        [~, trimidx]=min(abs(time1-obj.FMCTimeBase));
        obj.FMC=obj.FMC(trimidx:end,:);
        %obj.FMCTimeBase=obj.FMCTimeBase(trimidx:end);
        obj.SetFMCTimeStart(oldTimeBase(trimidx));
        oldtime1=time1;
    elseif time1<oldtime1 % extend front
        % fix new time to nearest sample
        timediff=oldtime1-time1;
        ndiff=floor(timediff*obj.FMCSamplingRate);
        time1b=oldtime1-ndiff/obj.FMCSamplingRate;
        newFMC=zeros((ndiff+size(obj.FMC,1)),size(obj.FMC,2));
        newFMC((ndiff+1):end,:)=obj.FMC;
        % save new values
        obj.FMC=newFMC;
        obj.SetFMCTimeStart(time1b);
        oldtime1=time1b; % in case if time2 also changes
    end
end
if time2~=oldtime2
    if time2>oldtime2 % extend back
        timediff=time2-oldtime2;
        ndiff=ceil(timediff*obj.FMCSamplingRate);
        time2b=oldtime2+ndiff/obj.FMCSamplingRate;
        newTBase=linspace(oldtime1,time2b,ndiff+length(obj.FMCTimeBase));
        newFMC=zeros(length(newTBase),size(obj.FMC,2));
        newFMC(1:end-ndiff,:)=obj.FMC;
        % save new values
        obj.FMC=newFMC;
        %obj.FMCTimeBase=newTBase;
        %obj.FMCTimeEnd=time2b;
    elseif time2<oldtime2 % trim back
        [~, trimidx]=min(abs(time2-obj.FMCTimeBase));
        obj.FMC=obj.FMC(1:trimidx,:);
        %obj.FMCTimeBase=obj.FMCTimeBase(1:trimidx);
        %obj.FMCTimeEnd=obj.FMCTimeBase(end);
    end
end
end