% solves series of scenes and composes 3D image
function obj=RenderImage3D(obj,verbose)
if nargin<2
    verbose=true;
end

obj.cuTFM_align_pixels;

% original image_x0 store - the obj.image_x0 will have to be cycled
backup_x0=obj.image_x0;
backup_nx=obj.image_nx;
obj.image_nx=1;
% reserve memory for result
obj.image=zeros(obj.image_nz,obj.image_ny,backup_nx,'single');

if verbose, 
%    fprintf('slice ---'); 
    tstart=now; 
    slicespermessage=2;
end

% enable/disable debugging
%a=obj.cuTFMv4007(int32(23),int32(0),int32(0));

obj.cuTFMv4007(int32(19)); % make sure the scene settings are uploaded
obj.cuTFMv4007(int32(20)); % this uploads FMC

for x_idx=1:backup_nx
    xx=(x_idx-1)*obj.image_dx+backup_x0;
    obj.image_x0=xx; % temporary measure to make cueTFM happy
    % solve scene for this x-slice
    obj.cuTFMv4007(int32(19)); % make sure the scene settings are uploaded
    [~, ~, CoeffBuffer NaNFlag]=obj.cuTFMv4007(int32(26)); % call coeff generator
    obj.coeffs=CoeffBuffer(:); % reshape and store
    obj.cuTFMv4007(int32(25)); % upload coeffs to GPU    
    obj.cuTFMv4007(int32(21)); % render image
    xslice=obj.cuTFMv4007(int32(22));% download image
    
    obj.image(:,:,x_idx)=xslice;
    
        if verbose
        if mod(x_idx,slicespermessage)==0
        elapsedtime=(now-tstart)*24*3600; timeperslice=elapsedtime/x_idx; timeleft=(backup_nx-x_idx)*timeperslice;
        %fprintf('\b\b\b%03d',x_idx); 
        obj.SetMessage(sprintf('3D TFM: slice %d of %d; %0.1f s left',x_idx,backup_nx,timeleft)); 
        slicespermessage=ceil(2/timeperslice);
        end
        end
    
end

obj.image_x0=backup_x0;
obj.image_nx=backup_nx;
if verbose, %fprintf(' done.\n');
    obj.SetMessage('3D TFM: done'); 
end
end