% function cuTFM_align_pixels(obj)
% aligns size of the output image to the requirements of the cuTFM kernel
function obj=cuTFM_align_pixels(obj)
align_x=obj.gpuSettings.align_x;
align_y=obj.gpuSettings.align_y*8; % up to 8 GPUs

obj.image_ny=align_y*ceil(obj.image_ny/align_y);
obj.image_nz=align_x*ceil(obj.image_nz/align_x);

end
