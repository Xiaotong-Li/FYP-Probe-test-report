% apply envelope detection, and conversion to dB scale to the image

function RelativeSensitivity=ApplyHilbertAbs(obj)
if size(size(obj.image),2)==2 % 2D image
    obj.image=abs(hilbert(obj.image));
    RelativeSensitivity=max(obj.image(:));
elseif size(size(obj.image),2)==3 
    for idx_x=1:size(obj.image,3)
        obj.image(:,:,idx_x)=abs(hilbert(squeeze(obj.image(:,:,idx_x))));        
    end
    RelativeSensitivity=max(obj.image(:));
else
    error('???');
end
    
