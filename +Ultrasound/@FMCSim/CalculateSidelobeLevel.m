function sidelobelevel=CalculateSidelobeLevel(obj,base_treshold)
%% estimate peak sidelobe
% idea: iteratively increase the treshold until there is more than 1 blob in the image
if nargin<2
   error('this is linear-scale code, need base_treshold');
end
sidelobelevel=-inf;
for side_treshold_db=-3:-0.1:-50
    if (1/4)*side_treshold_db==round((1/4)*side_treshold_db)        
        obj.SetMessage(sprintf('sidelobe: checking %0.1f',side_treshold_db))
    end
    side_treshold=base_treshold*10^(side_treshold_db/20);
    img_b2=obj.image>side_treshold;
    stats=regionprops(img_b2,'area');
    if length(stats)>1
        sidelobelevel=side_treshold_db;
        obj.SetMessage(sprintf('sidelobe: found at %0.1f',side_treshold_db))
        break;
    end
end