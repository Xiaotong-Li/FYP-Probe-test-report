function time=DirectRayTime(obj,pt1,pt2)
    time=sqrt(sum((pt1-pt2).^2))./obj.medium1_velocity;
end