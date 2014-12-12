% VisualizeDelays(Probe_Element_Number)
% visualizes delay time calculated from a given probe element to all point
% s in the image.
% note that the viewer uses "Depth" instead of "Z" (coordinates inverted)


function out=VisualiseDelays(obj,txNumber)
if nargin<2
    txNumber=1;
end
vfh=figure(24336); clf;
set(vfh,'MenuBar','none','Name','TOF preview','NumberTitle','off');
img=zeros(obj.image_nz,obj.image_ny);
depth=-obj.image_zcoordinates; % !!! NOTE! When drawing, Z dimension is inverted (converted to DEPTH)
himg=imagesc(obj.image_ycoordinates,depth,img); hold on;

% prepare interface
surface_z=zeros(obj.image_ny,1);
for y_idx=1:obj.image_ny
    surface_z(y_idx)=obj.parametricInterface([obj.image_x0; obj.image_ycoordinates(y_idx)]);
end
plot(obj.image_ycoordinates,real(-surface_z),'k','linewidth',2);
plot(obj.ProbeElementLocations(2,:),-obj.ProbeElementLocations(3,:),'gx')
plot(obj.ProbeElementLocations(2,txNumber),-obj.ProbeElementLocations(3,txNumber),'ro')
axis image; 

% calculate delays based on the poly
for yline_idx=1:obj.image_ny
    coeffs=obj.coeffs(obj.coeffOffsetVector(yline_idx,txNumber));
    delayValues=polyval(coeffs,obj.image_zcoordinates);
    img(:,yline_idx)=delayValues;
    set(himg,'CData',img); drawnow;
end
colorbar;

ylims=get(gca,'YLim'); ylims=ylims+[-10e-3 10e-3]; set(gca,'YLim',ylims);
xlims=get(gca,'XLim'); xlims=xlims+[-10e-3 10e-3]; set(gca,'XLim',xlims);

global USIGlobals
USIGlobals.hDelayVisLine1=line('XData',[],'YData',[]);
USIGlobals.hDelayVisLine2=line('XData',[],'YData',[]);
USIGlobals.DelayVisualizationElementIdx=txNumber;
USIGlobals.DelayVisualizationElementCoords=obj.ProbeElementLocations(:,txNumber);
USIGlobals.hFigTitle=title('');
USIGlobals.hDelayVisAxes=gca;
visproxy=@(A,B)(VisualizeDelaysUpdateFn(obj));
set(gcf,'WindowButtonMotionFcn',visproxy);

title(sprintf('coeff-based time of flight \nfrom element %d to pixels in the image. Units: seconds',txNumber));
xlabel('y[m]'); ylabel('depth[m]');

end

function VisualizeDelaysUpdateFn(obj)
global USIGlobals
if(~isempty(USIGlobals))
 pt=get(USIGlobals.hDelayVisAxes,'CurrentPoint');
 pt1=USIGlobals.DelayVisualizationElementCoords;
 pt2=[obj.image_x0 pt(1) -pt(3)]; 
[time, pti]=obj.RefractedRayTime(pt1(:),pt2(:));
disp(time);
if ~isnan(pti(3))
 set(USIGlobals.hDelayVisLine1,'XData',[pt1(2) pti(2) pt2(2)],'YData',-[pt1(3) pti(3) pt2(3)]);
else
 set(USIGlobals.hDelayVisLine1,'XData',[pt1(2) pt1(2) pt1(2)],'YData',-[pt1(3) pt1(3) pt1(3)]);   
end
end
end
