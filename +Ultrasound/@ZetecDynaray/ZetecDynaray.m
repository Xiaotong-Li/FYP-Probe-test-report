% Ultrasound.ZetecDynaray object to help to controll the dynaray
% functions:
% help
% DynarayInit
% MakeOnlineChannel
% DynarayRefreshBuffers
% GetOnlineData
classdef ZetecDynaray< Ultrasound.FMCSim;
   properties
       DynarayVoltage=40; % [V]
       DynarayPulsetime=160e-9; % [s]
       DynarayGain=45; % [dB];
       DynarayAveraging = int32(0); % [times] Note that Ultravision appears to have bug that stops me from being able to delete a channel with averaging enabled. This breaks the following code.
       DynarayReccurence=int32(6000); % [Hz]
       %DynarayDigitizingFrequency = 50e6; %int32(50); % [MHz]. supported: 25,50,100MHz only.
       DynarayDoRectification = int32(0); % 0=none, 1=bipolar
       DynarayChannelNamePrefix = 'FMC Part' ; % any string, must be rather short
       DynaraySoftAverages=1;   
       batch_size=256;
   end
   properties (Hidden)
       uv
       dl
   end
   methods
       function help(obj)
           help Ultrasound.ZetecDynaray
       end
       function obj=DynarayInit(obj)
           try    
                NET.addAssembly('e:\Jurek\gitrepo\Dynaray_link\components\Matlab side\UltraVisionMatlabClientComponent\bin\Debug\UltraVisionMatlabClientComponent.exe');
                UltraVisionRC=UltraVisionMatlabClientComponent.Form1;
                UltraVisionRC.InitRC;
            catch E
        
           end
        obj.uv=UltraVisionRC.RCMarshall;
        obj.uv.RCInitDataManager;
        if obj.uv.GetPing
            fprintf('Connection initiated OK\n\n');
        else
            error('connection error :-(')
        end
       end
       % alias function
       function obj=DynarayMakeOnlineChannel(obj,local_TxRxList)
           if nargin==1
               local_TxRxList=obj.TxRxList(:);
           end
           obj=MakeOnlineChannel(obj,local_TxRxList);
       end
       
       function obj=MakeOnlineChannel(obj,local_TxRxList)
           fprintf('setting up Dynaray . . .');
            %tic;
            if nargin==2
                txrxlist=int32(local_TxRxList(:));
            else
                txrxlist=int32(obj.TxRxList(:));
            end
            DigitizingFrequency=(obj.FMCSamplingRate)/1e6;
            if (DigitizingFrequency~=25)&&(DigitizingFrequency~=50)&&(DigitizingFrequency~=100)                
                error('Your current sampling rate is %0.0f MHz; only 25,50 or 100MHz sampling rate supported by Dynaray',DigitizingFrequency);
            end
            time1=uint32(obj.FMCTimeStart*1e6);
            range=uint32(obj.FMCTimeEnd*1e6)-uint32(obj.FMCTimeStart*1e6);
            resultChannelDel=obj.uv.RCDeleteOnlineUltrasoundChannel;
            if ~resultChannelDel
                warning('channel not deleted');
            end 
            if obj.DynarayGain>79
                error('DynarayGain is too high - UltraVision crashes if set >79');
            end
            resultChannelCreate=obj.uv.RCCreateOnlineUltrasoundChannel(txrxlist, obj.DynarayVoltage, obj.DynarayPulsetime, obj.DynarayGain,...            
                time1, range, int32(obj.DynarayAveraging ),int32(obj.DynarayReccurence),...
                DigitizingFrequency,int32(obj.DynarayDoRectification),obj.DynarayChannelNamePrefix);    
            if ~resultChannelCreate
                warning('channel not created');
            end
            %tDynaray=toc;
              [dl bl]=obj.UVSortBeams;
              obj.dl=dl;
              obj.uv.RCSetReadDataList(dl);
              obj.uv.RCPrepareLastBufferReaders; 
            fprintf('done\n');
       end
       function obj=DynarayRefreshBuffers(obj)
              [dl bl]=obj.UVSortBeams;
              obj.dl=dl;
              obj.uv.RCSetReadDataList(dl);
              obj.uv.RCPrepareLastBufferReaders;
       end
       function obj=DynarayGetTxRxData(obj)
           % split into batches
           batch_size=obj.batch_size;
           fulllist=obj.TxRxList;
           splits=ceil(length(fulllist)/batch_size);
           FMC=[];
           tstart_acq=obj.now_in_seconds;
           for batch_idx=1:splits
               fprintf('batch %d of %d ...',batch_idx,splits)
               batch_start_idx=(1+(batch_idx-1)*batch_size);
               batch_indices=batch_start_idx:(min(batch_start_idx+batch_size-1,length(fulllist)));
               local_TxRxList=fulllist(:,batch_indices);
               obj.MakeOnlineChannel(local_TxRxList);
               tmp=obj.DynarayGetOnlineData;
               if isempty(FMC)
                   FMC=zeros(size(tmp,1),length(fulllist),'single');
               end
               FMC(:,batch_indices)=tmp;
               time_elapsed=obj.now_in_seconds-tstart_acq;
               time_per_batch=time_elapsed./(batch_idx);
               total_time=splits*time_per_batch;
               time_finish=tstart_acq+total_time;
               time_remaining=time_finish-obj.now_in_seconds;
               fprintf('%0.1f mins remaining\n',time_remaining/60);               
           end
           obj.TxRxList=fulllist;
           obj.FMC=single(FMC);
       end
       function indata=DynarayGetOnlineData(obj)
          % prepare SoftAvg buffer
          ascanlength=int32(obj.uv.RCGetCurrentAscanLength); 
           SoftAveragedIn=zeros(size(ascanlength*length(obj.dl),1),'double');
          % begin acquiring data
          fprintf(' ---');
          for avg_index=1:obj.DynaraySoftAverages
           ascanlength=int32(obj.uv.RCGetCurrentAscanLength); 
           if ascanlength<0
               % try RefreshBuffers
               obj.DynarayRefreshBuffers; pause(0.3);
               ascanlength=int32(obj.uv.RCGetCurrentAscanLength); 
               if ascanlength<0
                    error('no data returned from Dynaray')
               end
           end
           in=int32(obj.uv.RCReadOnlineAscanData(false)); 
           SoftAveragedIn=SoftAveragedIn+double(in);
           fprintf('\b\b\b%03d',avg_index);
%            if mod(avg_index,8)==0 
%             fprintf('.');             
% %            indata=reshape(SoftAveragedIn,ascanlength,length(dl));
% %             subplot(2,1,1);
% %             imagesc(indata'); drawnow;  
% %             subplot(2,1,2); plot(indata(:,5))
%             end; % put a dot on the screen        
        drawnow;
          end
          fprintf('\b\b\b');
          SoftAveragedIn=SoftAveragedIn./obj.DynaraySoftAverages;
          indata=reshape(SoftAveragedIn,ascanlength,length(obj.dl));
          obj.FMC=single(indata);
       end
       
       function q=DynarayReadOfflineAscanDataSizesPerBeam(obj,beamIdx)
           % reads the offline data size: 
           % [AscanLength, ScanCount,IndexCount]
           q=int32(obj.uv.RCReadOfflineAscanDataSizesPerBeam(int32(beamIdx)));
       end
       
       function q=DynarayReadOfflineAscanData(obj,beamIdx,scanIdx,indexIdx)
           % reads single offline A-scan
           q=obj.uv.RCReadOfflineAscanDataPerBeamScanIndex(int32(beamIdx),scanIdx,int32(indexIdx));
       end
       
       function q=DynarayReadOfflineAllAscans(obj,beamIdx)
           if nargin<2
               error('Usage: .DynarayReadOfflineAllAscans(beamIdx)');
           end
           qsize=obj.DynarayReadOfflineAscanDataSizesPerBeam(beamIdx);
           if qsize(1)==0
               q=NaN;
           else
            q=int32(obj.uv.RCReadOfflineAscanDataPerBeam(int32(beamIdx)));
            q=reshape(q,qsize);
           end
       end
       function q=CreateLinearProbe(obj,ElementCount,ElementPitch)
           y_coords=(0:(ElementCount-1))*ElementPitch;
           % note: do not center the elements
           %y_coords=y_coords-mean(y_coords);
           obj.ProbeElementLocations=[zeros(size(y_coords)); y_coords; zeros(size(y_coords))];
       end

   end
   methods (Access=protected)
              % picks up data names from UltraVision and returns a indexing vector which
% can be used to order the data according to beam number. This is much
% faster done in Matlab, that's why it is here.
       function [datalist beamlist]=UVSortBeams(obj,Channel)
           if nargin==1
               Channel=1;
           end
           datanames=char(obj.uv.RCGetDataNames);
           % get data names into cells
           dnlist=[];
           dataidx=-1;
           datalist=[];
           beamlist=[];
           while ~isempty(datanames)
               dataidx=dataidx+1;
               [dn, datanames]=strtok(datanames,'*');
               [acquisition_str,dn]=strtok(dn,'/');
               [channel_str,dn]=strtok(dn,'/');
               [beam_str,dn]=strtok(dn,'/');
               [ascan_str,dn]=strtok(dn,'/');
               
               % only accept data from channel 1 and ascan 0
               if ~strcmp(channel_str,sprintf('channel@%d',Channel))
                   continue
               end
               if ~strcmp(ascan_str,'ascan@0')
                   continue
               end
               % pick up beam number
               [tmp beam_nr_str]=strtok(beam_str,'@');
               beamnumber=str2num(beam_nr_str(2:end));
               datalist=[datalist dataidx];
               beamlist=[beamlist beamnumber];
           end
           % sort the beamlist
           [beamlist sorting_idx]=sort(beamlist);
           % and reorder datalist accordingly
           datalist=datalist(sorting_idx);
           datalist=int32(datalist);                      
       end
   end
end