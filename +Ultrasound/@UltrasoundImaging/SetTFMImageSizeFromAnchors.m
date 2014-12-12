% Sets the image from corners of the image.
% usage:
%
% SetTFMImageSizeFromAnchors(x0,x1,y0,y1,z0,z1,resolutionX,resolutionY,resolutionZ,verbose)
%

function obj=SetTFMImageSizeFromAnchors(obj,x0,x1,y0,y1,z0,z1,resolutionX,resolutionY,resolutionZ,verbose)
obj.image_x0=x0; 
obj.image_y0=y0; 
obj.image_z0=z0;
obj.image_dx=resolutionX; 
obj.image_dy=resolutionY; 
obj.image_dz=-resolutionZ;
obj.image_nx=round((x1-obj.image_x0)/obj.image_dx);
obj.image_ny=round((y1-obj.image_y0)/obj.image_dy);
obj.image_nz=round((z1-obj.image_z0)/obj.image_dz);
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