function FilterFMC(obj,Fc1,Fc2)

if(isempty(obj.unfiltered_FMC))
    obj.unfiltered_FMC = obj.FMC;
end


Fs = obj.FMCSamplingRate;
N   = 2;
h  = fdesign.bandpass('N,F3dB1,F3dB2', N, Fc1, Fc2, Fs);
obj.filter = design(h, 'butter');


% for t = 1:obj.ProbeElementCount
%     clc;
%     fprintf('Processing tx %03d of %03d\n',t,obj.ProbeElementCount);
%     sstart = (t-1)*obj.ProbeElementCount+1;
%     send = sstart + (obj.ProbeElementCount-1);
%     subset = obj.unfiltered_FMC(:,sstart:send);
%     subset=single(flipud(filter(obj.filter,flipud(filter(obj.filter,subset)))));
%     obj.FMC(:,sstart:send) = subset;
% end

for t= 1:size(obj.FMC,2)
%     clc;
%     fprintf('Processing tx %03d of %03d\n',t,size(obj.FMC,2));
    subset=single(flipud(filter(obj.filter,flipud(filter(obj.filter,obj.unfiltered_FMC(:,t))))));
    obj.FMC(:,t) = subset;
end
%     

    
% for t= 1:size(obj.FMC,2)
% 
%     obj.FMC=single(flipud(filter(obj.filter,flipud(filter(obj.filter,obj.unfiltered_FMC)))));
% 
% end

    
    
    