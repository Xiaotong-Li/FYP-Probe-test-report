% SetTFMImageSizeAroundPoint(point,boxsize,resolution)
function obj=SetTFMImageSizeAroundPoint(obj,point,boxsize,resolution,squeezeX,ZFactor)
if nargin<5
    squeezeX=false;
    ZFactor=1;
end
if nargin<6    
    ZFactor=1;
end

if ~squeezeX
obj.image_x0=point(1)-boxsize/2; 
else
    obj.image_x0=point(1);
end
obj.image_y0=point(2)-boxsize/2; 
obj.image_z0=min(0,point(3)+boxsize/5);
obj.image_dx=resolution; 
obj.image_dy=resolution; 
obj.image_dz=-resolution/ZFactor;
if ~squeezeX
obj.image_nx=round(((point(1)+boxsize/2)-obj.image_x0)/obj.image_dx);
else
    obj.image_nx=1;
end
obj.image_ny=round(((point(2)+boxsize/2)-obj.image_y0)/obj.image_dy);
obj.image_nz=round(((point(3)-boxsize/5)-obj.image_z0)/obj.image_dz);
obj.gpuSettings.align_x=128;
obj.gpuSettings.align_y=1;
obj.cuTFMv4007(int32(24),obj.gpuSettings.align_x,obj.gpuSettings.align_y);
obj.cuTFM_align_pixels;

if obj.image_nx==0
    obj.image_nx=1;
end
if nargin<9
    verbose=0;
end
if verbose
    fprintf('image size: %d x %d\n',obj.image_ny,obj.image_nz);
end
% make empty TFM image - less problems afterwards
if obj.image_nx==1
    obj.image=zeros(obj.image_ny,obj.image_nz,'single');
elseif obj.image_nx>1
    obj.image=zeros(obj.image_nx,obj.image_ny,obj.image_nz,'single');
else
    error('???');
end

end