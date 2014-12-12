function spotsize=CalculateSpotSize(obj,treshold)
if nargin<2
    treshold=-6;
end
if length(size(obj.image))==3
    spotsize=obj.CalculateSpotSize3D(treshold);
else
    spotsize=obj.CalculateSpotSize2D(treshold);
end