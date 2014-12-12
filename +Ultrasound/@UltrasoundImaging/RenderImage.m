function obj=RenderImage(obj,debugvalue)

% assume that scene settings and coeffs are uploaded already
obj.cuTFMv4007(int32(20)); % this uploads FMC
obj.cuTFMv4007(int32(21)); % render image
obj.image=obj.cuTFMv4007(int32(22));% download image

end