function spotsize=CalculateSpotSize3D(obj,db_treshold)
if nargin<2
    db_treshold=-6;
end
spotsize=2*nthroot(sum(obj.image(:)>db_treshold)*abs(obj.image_dx*obj.image_dy*obj.image_dz)*3,3)/(2*sqrt(pi));

%fprintf('diameter: %0.1f mm; ',spotdiameter*1e3);
%spotsizes(frame)=spotdiameter;