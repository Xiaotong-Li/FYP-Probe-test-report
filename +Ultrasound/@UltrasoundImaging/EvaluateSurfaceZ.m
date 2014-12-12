% this function calls the coeff generator

function [obj, ZVector]=EvaluateSurfaceZ(obj,XYVector)
obj.cuTFMv4007(int32(19)); % make sure the scene settings are uploaded 
[ZVector]=obj.cuTFMv4007(int32(31),single(XYVector)); % call coeff generator
end


