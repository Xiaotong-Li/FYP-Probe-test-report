% function [time loc]=RefractedRayTime(obj,pt1,pt2) 

function [time loc]=RefractedRayTime(obj,pt1,pt2) 
% check if the point is surely below interface
if pt2(3)>obj.parametricInterface(pt2([1 2]))
    % if not, calculate direct ray time
    time_direct=sqrt(sum((pt2-pt1).^2))./obj.medium1_velocity;
    loc=pt1; time=time_direct;
else
% find refracted ray time
 costfunction=@(X)(sqrt(sum(([X; obj.parametricInterface(X)]-pt1).^2))./obj.medium1_velocity+sqrt(sum(([X; obj.parametricInterface(X)]-pt2).^2))./obj.medium2_velocity);
 % Chose a sensible first guess. Make sure it is within constraints
 
 X0=(pt1+pt2)/2;
 
 % try pattern search
 pattern_spread=obj.pattern_spread;
 pattern_points=linspace(-pattern_spread*obj.pattern_npoints/2,pattern_spread*obj.pattern_npoints/2,obj.pattern_npoints);
 bestTimeR = inf; bestLocR=X0([1 2]);
 for pattern_idx=pattern_points
      localX=X0; localX(2)=localX(2)+ pattern_idx; % chose differnt y-points
      
       % If the object is subject to contsraints, ensure that the guesses
       % are within these. 
       
       if(obj.constrainedFlag == Ultrasound.ConstrainedFlag.ConstrainedX)
           if localX(1) < obj.SurfaceParameters(1)
               localX(1) = obj.SurfaceParameters(1);
           elseif localX(1) > obj.SurfaceParameters(2)
               localX(1) = obj.SurfaceParameters(2);
           end
       end
       
       if(obj.constrainedFlag == Ultrasound.ConstrainedFlag.ConstrainedY)
           if localX(2) < obj.SurfaceParameters(1)
               localX(2) = obj.SurfaceParameters(1);
           elseif localX(2) > obj.SurfaceParameters(2)
               localX(2) = obj.SurfaceParameters(2);
           end
       end
       % The above code should deal with the problem of having imaginary
       % times due to the costfunction not solving
       
     [timeR locR]=obj.minSearch(costfunction,localX([1 2]));
     if ~isreal(timeR)
         timeR=NaN;
     end
     if timeR< bestTimeR
          bestTimeR=timeR;
          bestLocR=locR;
     end
 end
 tmp=obj.parametricInterface(bestLocR); if ~isreal(tmp) tmp=NaN; end;
bestLocR=[bestLocR; tmp];
if numel(bestLocR)<3
    error('aa');
end
loc=bestLocR; 
time=timeR;
 

end