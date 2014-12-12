function obj=SimulateFMC(obj)
% SimulateFMC    *No arguments
% executes the FMC simulation process
% uses MATLAB implementation
%
% Stored settings apply
%
% example:
% sim.SimulateFMC
%
% See also Ultrasound.FMCSim, Ultrasound.FMCSim.SimulateFMC_GPU

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012

set(obj.InfoString,'string','Checking consistency'); drawnow;
% first, add point-reflectors
% verify that ReflectorList and TargetSizes are consistend
if size(obj.ReflectorList,1)~=3
    error('ReflectorList must be xyz * N matrix')
end
if size(obj.ReflectorList,2)~=length(obj.ReflectorStrength)
    error('Each item in ReflectorList must have corresponding strength in ReflectorStrength matrix');
end

if length(obj.ProbeProtoSignal)<1
    error('ProbeProtoSignal is empty - load a signal')
end

if size(obj.TxRxList,2)~=size(obj.FMC,2)
    error('TxRxList not consistent with FMC size - Re-initialize both')
end

% precalculate some constants
FMC_t0_idx=-obj.FMCTimeStart*obj.FMCSamplingRate;
ProbeProtoSignalOffset_tidx=-obj.ProbeProtoSignalOffset.*obj.FMCSamplingRate;
total_signal_offset=FMC_t0_idx+ProbeProtoSignalOffset_tidx;
FMC_last_idx=size(obj.FMC,1)-length(obj.ProbeProtoSignal);
ProbeProtoSignal_length=length(obj.ProbeProtoSignal)-1;

% rotate the ProtoSignal to column format
obj.ProbeProtoSignal=obj.ProbeProtoSignal(:);

% for each line in the TxRxList
for TxRxIdx=1:length(obj.TxRxList)
    if mod(TxRxIdx,32)==0
        set(obj.InfoString,'string',sprintf('TxRx %d of %d',TxRxIdx,length(obj.TxRxList))); drawnow;
    end
    % for each reflector
    for ReflectorIdx=1:size(obj.ReflectorList,2)
        % get Tx element coordinates
        tx_idx=obj.TxRxList(1,TxRxIdx)+1; % matlab convention
        tx_x=obj.ProbeElementLocations(1,tx_idx);
        tx_y=obj.ProbeElementLocations(2,tx_idx);
        tx_z=obj.ProbeElementLocations(3,tx_idx);
        
        % calculate rx DirCos
        % note that DirCos does not take refraction into account
        % note that it is always assumed that the elements have axis going
        % in Z-negative direction
        
        tx_dx=obj.ReflectorList(1,ReflectorIdx)-tx_x;
        tx_dy=obj.ReflectorList(2,ReflectorIdx)-tx_y;
        tx_dz=obj.ReflectorList(3,ReflectorIdx)-tx_z;
        distance_tx=sqrt(tx_dx*tx_dx+tx_dy*tx_dy+tx_dz*tx_dz);
        tx_dircos=abs(tx_dz)/distance_tx; % this is formula for cosine of angle
        
        % get Rx element coordinates
        rx_idx=obj.TxRxList(2,TxRxIdx)+1;
        rx_x=obj.ProbeElementLocations(1,rx_idx);
        rx_y=obj.ProbeElementLocations(2,rx_idx);
        rx_z=obj.ProbeElementLocations(3,rx_idx);
        % calculate rx DirCos
        
        rx_dx=obj.ReflectorList(1,ReflectorIdx)-rx_x;
        rx_dy=obj.ReflectorList(2,ReflectorIdx)-rx_y;
        rx_dz=obj.ReflectorList(3,ReflectorIdx)-rx_z;
        distance_rx=sqrt(rx_dx*rx_dx+rx_dy*rx_dy+rx_dz*rx_dz);
        rx_dircos=abs(rx_dz)/distance_rx; % this is formula for cosine of angle
        % calculate amplitude modifier
        amplitudeModifier=10.^(obj.ReflectorStrength(ReflectorIdx)./20)*tx_dircos.^obj.ProbeDirectivityCosPower*rx_dircos.^obj.ProbeDirectivityCosPower;
        
        % calculate travel time, take refraction into account
        if (obj.refractionVariant==Ultrasound.RefractionVariant.ParametricInterface)||(obj.refractionVariant==Ultrasound.RefractionVariant.PlanarInterfaceZ)||(obj.refractionVariant==Ultrasound.RefractionVariant.SinX)
            % note that all of the above assume that the
            % obj.parametricInterface is correctly set.
            time1=obj.RefractedRayTime(obj.ProbeElementLocations(:,tx_idx),obj.ReflectorList(:,ReflectorIdx));
            time2=obj.RefractedRayTime(obj.ProbeElementLocations(:,rx_idx),obj.ReflectorList(:,ReflectorIdx));
        elseif obj.refractionVariant==Ultrasound.RefractionVariant.NoRefraction
            time1=obj.DirectRayTime(obj.ProbeElementLocations(:,tx_idx),obj.ReflectorList(:,ReflectorIdx));
            time2=obj.DirectRayTime(obj.ReflectorList(:,ReflectorIdx),obj.ProbeElementLocations(:,rx_idx));
        else
            error('unimplemented RefractionVariant');
        end
        % total time from transmission to reception
        totaltime_tidx=round((time1+time2)*obj.FMCSamplingRate+total_signal_offset);
        % imprint the proto signal in the FMC
        if (totaltime_tidx>0)&&(totaltime_tidx<FMC_last_idx) % if can fit in the FMC
            obj.FMC(totaltime_tidx:totaltime_tidx+ProbeProtoSignal_length,TxRxIdx)=...
                obj.FMC(totaltime_tidx:totaltime_tidx+ProbeProtoSignal_length,TxRxIdx)+obj.ProbeProtoSignal*amplitudeModifier;
        end
    end  % for each ReflectorList
end % end for TxRxIdx
obj.FMC=single(obj.FMC);
set(obj.InfoString,'string','FMCSim: Render FMC done'); drawnow;
end % object SimulateFMC