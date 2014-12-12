% this function prepares coefficients for the fast coeff method
% needs remaiining parameters to be set correctly in the first place
% this is implemented in matlab for now, faster mex method to come later
function obj=PrepareCoeffs(obj,refresh)
if nargin<2
    refresh=false;
end

    % check if the parameters are not stored in cache
    pel=sprintf('%e',obj.ProbeElementLocations(:));
    txrxliststring=sprintf('%e',obj.TxRxList(:));
    ParamsUniqueId=sprintf('%d%d%s_%e_%e_%s_%e_%s,%e%e%e%e%e%e%e%e%e',uint32(obj.refractionVariant),obj.coeffsize,func2str(obj.parametricInterface),obj.medium1_velocity,obj.medium2_velocity,pel,obj.FMCSamplingRate,txrxliststring,obj.image_x0,obj.image_y0,obj.image_z0,obj.image_nx,obj.image_ny,obj.image_nz,obj.image_dx,obj.image_dy,obj.image_dz);
    paramsMD5=obj.calcMD5(ParamsUniqueId);
if refresh==false
    if strcmp(obj.LastCoeffSetMD5,paramsMD5)
        % last coeffs are good - no need to make another set
        obj.SetMessage('.');
        return
    end
    if ~exist([pwd '\CoeffCache'],'dir')
        mkdir('CoeffCache')
    end
    % try to load from cache
    try
        in=load([pwd '\CoeffCache\' sprintf('cached_%s',paramsMD5)]);
        obj.coeffs=in.coefftable;
        obj.LastCoeffSetMD5=paramsMD5;
        obj.SetMessage('..');
        return
    catch E
        % failed, calculate from scratch
    end
end 
    
    %coeffsize=8; % let's go for that
    coefftable=NaN(obj.coeffsize*obj.ProbeElementCount*obj.image_ny,1,'single');
    coefftableparfor=reshape(coefftable,obj.coeffsize*obj.ProbeElementCount,obj.image_ny);    
    objcoeffsize=obj.coeffsize; objProbeElementCount=obj.ProbeElementCount;
    %coeffOffset=@(line,tx)((line-1)*obj.ProbeElementCount*coeffsize+(tx-1)*coeffsize+1); 
    %coeffOffsetVector=@(line,tx)(coeffOffset(line,tx):(coeffOffset(line,tx)+obj.coeffsize));
    % note: prepare more delayPoints and use them to estimate best fit
    % order
    if obj.coeffsize==5
        delaypointsCount=9+1; % 17 to use for fitting and 16 to use for checking
    else
        delaypointsCount=17+16; % 17 to use for fitting and 16 to use for checking
    end
    DelayPointZ=linspace(obj.image_z0,obj.image_z0+(double(obj.image_nz)-1)*obj.image_dz,delaypointsCount);
    DelayPointZ_tofit=DelayPointZ(1:2:end);
    DelayPointZ_tocheck=DelayPointZ(2:2:end-1);
    % use medium 1 only    
    
    obj.SetMessage('SolveEq: entering parallel loop, no feedback for a couple of minutes');
    % for each line, for each tx, prepare a coefficient set. This can be moved to mex.    
    fitorder_stats=zeros(objProbeElementCount,obj.image_ny);
    fiterror_stats=zeros(objProbeElementCount,obj.image_ny);
   
    parfor line=1:obj.image_ny        
         s=warning('off','all');
         fprintf('Line %d: started\n',line);
       % obj.SetMessage(sprintf('PrepareCoeffs: %d of %d lines',line,obj.image_ny));
        coeffline=NaN(objcoeffsize*objProbeElementCount,1);
        for tx=1:objProbeElementCount  % for each tx
            % find 17 times
            % prepare empty coeff table
            DelayPointT=NaN(size(DelayPointZ));
            for idx=1:length(DelayPointZ)
                % simple pitagoras
                %DelayPointT(idx)=sqrt((obj.ProbeElementLocations(tx,1)-obj.image_x0).^2+(obj.ProbeElementLocations(tx,2)-obj.image_ycoordinates(line)).^2+(obj.ProbeElementLocations(tx,3)-DelayPointZ(idx)).^2)/obj.medium1_velocity;
                if obj.refractionVariant==Ultrasound.RefractionVariant.NoRefraction
                    DelayPointT(idx)=DirectRayTime(obj,obj.ProbeElementLocations(:,tx),[obj.image_x0 obj.image_ycoordinates(line) DelayPointZ(idx)]');
                end
                
                if obj.refractionVariant==Ultrasound.RefractionVariant.ParametricInterface
                    %DelayPointT(idx)=RefractedRayTime(obj,obj.medium1_velocity,obj.medium2_velocity,obj.ProbeElementLocations(tx,:),[obj.image_x0 obj.image_ycoordinates(line) DelayPointZ(idx)],obj.parametricInterface);
                    DelayPointT(idx)=obj.RefractedRayTime(obj.ProbeElementLocations(:,tx),[obj.image_x0 obj.image_ycoordinates(line) DelayPointZ(idx)]');
                end
                
                if obj.refractionVariant==Ultrasound.RefractionVariant.PlanarInterfaceZ
                    error('simple planar interface not implemented');    
                end
                
            end
            % fit poly, check order
            DelayPointT_tofit=DelayPointT(1:2:end);
            DelayPointT_tocheck=DelayPointT(2:2:end-1);
            earlyquit=0;

            for fitorder=0:(obj.coeffsize-1)                
                p=polyfit(DelayPointZ_tofit,DelayPointT_tofit,fitorder); 
                pad=zeros(1,obj.coeffsize-fitorder-1);
                p=[pad p];
                DelayPointT_fitted=polyval(p,DelayPointZ_tocheck);
                fiterror=max(abs(DelayPointT_fitted-DelayPointT_tocheck));
                %plot(DelayPointZ_tocheck,DelayPointT_fitted,'rx',DelayPointZ_tocheck,DelayPointT_tocheck,'go')
                if fiterror<200e-12                    
                    fitorder_stats(tx,line)=fitorder;                    
                    fiterror_stats(tx,line)=fiterror;  
                    earlyquit=1;
                    break
                end
            end
             if earlyquit==0
                 fitorder_stats(tx,line)=99;                    
                 fiterror_stats(tx,line)=fiterror; 
             end
            % debug: to plot, say
            % plot(DelayPointZ,DelayPointT,obj.image_zcoordinates,polyval(p,obj.image_zcoordinates))
            % store coeffs            
            %coefftable(obj.coeffOffsetVector(line,tx))=p;         
            coeffline((objcoeffsize*(tx-1)+1):(objcoeffsize*(tx)))=p;
            fprintf('Line %d: Done TX: %d\n',line,tx);
        end
        coefftableparfor(:,line)=coeffline;
   %     warning(s);
        fprintf('Line %d: completed\n',line);
    end % for line     
    coefftable=single(reshape(coefftableparfor,obj.coeffsize*obj.ProbeElementCount*obj.image_ny,1));
    obj.coeffs=coefftable;
    obj.LastCoeffSetMD5=paramsMD5;
    save([pwd '\CoeffCache\' sprintf('cached_%s',paramsMD5)],'coefftable');
    obj.SetMessage('Precalculation complete'); drawnow;
    
    obj.fitorder_stats=fitorder_stats;
    obj.fiterror_stats=fiterror_stats; 
    if (sum(fitorder_stats(:)==99)>0)
        warning('Cannot find proper coeff set. Move image away from surface, reduce curvature complexity, or raise fitorder');
    end
end
