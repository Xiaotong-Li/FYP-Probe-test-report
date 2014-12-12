% this function calls the coeff generator

function obj=SolveScene(obj)
obj.cuTFM_align_pixels;
obj.cuTFMv4007(int32(19)); % make sure the scene settings are uploaded 
[ZVector TBuffer CoeffBuffer NaNFlag]=obj.cuTFMv4007(int32(26)); % call coeff generator
% save zTim_reviewImgData ZVector TBuffer CoeffBuffer
obj.coeffs=CoeffBuffer(:); % reshape and store
obj.cuTFMv4007(int32(25)); % upload coeffs to GPU
end


