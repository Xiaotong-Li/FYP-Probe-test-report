function spotsize=CalculateSpotSize2D(obj,db_treshold)
if nargin<2
    db_treshold=-6;
end
spotsize=2*sqrt(sum(obj.image(:)>db_treshold)*obj.image_dy*abs(obj.image_dz))/sqrt(pi);

%fprintf('diameter: %0.1f mm; ',spotdiameter*1e3);
%spotsizes(frame)=spotdiameter;