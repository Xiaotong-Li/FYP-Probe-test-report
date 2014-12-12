% this assumes that the image is hilber-abs-log-normalized
function leakage=CalculateLeakage(obj,treshold)
%imagesc(img_nolog.*(fmcsim.image<db_treshold))
if nargin<2
    treshold=-6;
end
img_binary=obj.image>treshold;
%img_nolog=10.^(single(obj.image)/20);
img_nolog=obj.image; % assume linear scale image
energy_inside=sum(sum(sum(abs(img_nolog.*img_binary))));
energy_outside=sum(sum(sum(img_nolog)))-energy_inside;
energy_percent_outside=energy_outside./(energy_outside+energy_inside);
leakage=energy_percent_outside;
% energy_outsides(frame)=energy_percent_outside;
% fprintf('leakage: %0.1f %%; ',energy_percent_outside*100);