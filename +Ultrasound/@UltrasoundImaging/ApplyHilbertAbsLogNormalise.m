% apply envelope detection, and conversion to dB scale to the image

function obj=ApplyHilbertAbsLogNormalise(obj,verbose)
if size(size(obj.image),2)==2 % 2D image
    obj.image=20*log10(abs(hilbert(obj.image)));
    obj.image=obj.image-max(obj.image(:));
elseif size(size(obj.image),2)==3 
    for idx_x=1:size(obj.image,3)
        obj.image(:,:,idx_x)=20*log10(abs(hilbert(squeeze(obj.image(:,:,idx_x)))));        
    end
    obj.image=obj.image-max(obj.image(:));
else
    error('???');
end
    
