% function t=PropagationTime3Points(3x1 double point1,3x1 double point2,2x1 double SurfaceXY,function surface,double speed1,double speed2)
% returns propagation time betwen point1, trough point [surfaceXY surface(surfaceXY)]
% to point2, using speed1 and speed2. 

function [ t ] = PropagationTime3Points(point1,point2,SurfaceXY,surface,speed1,speed2)

z = surface(surfaceXY);

path1 = sqrt((surfaceXY(1)-point1(1))^2 + (surfaceXY(2)-point1(2))^2 + (z-point1(3))^2);
path2 = sqrt((surfaceXY(1)-point2(1))^2 + (surfaceXY(2)-point2(2))^2 + (z-point2(3))^2);

t = path1/speed1 + path2/speed2;

end
