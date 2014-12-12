% function [fval X] = minSearch( function costFunction,2x1 double starting_x0, bool verbose) 
% uses simplex method to minimise cost function
% note that only 2-dimensional search is supported
% if you need other dimensionality, use Matlab's fminsearch instead

% History of this file:
% This is ripped of matlab's fminsearch function. The original however is rather slow, 
% so Jurek has hand-optimised it for 1D search, it became a LOT faster.
% Then Tim has extended it to 2D search and translated to C.
% eventually, it found it's way into this package, where Jurek given it
% furher tuning and refactoring. 
% the intention for the future is to refactor again to group conditional
% branches - so that it can be executed on GPU-like processors more
% effectively.

% minSearch4: phase 4.

function [fval X] = minSearch4(obj,costFunction,x,verbose) 
if nargin<4
    verbose=false;
end
tolf = 200e-12;
tolx= 1e-7;
simplexInitSize=1e-3;
maxloop=1e5;
loopcount=0;

% initial guess becomes first vertex of the simplex

vx1=x(1);
vy1=x(2); %v(:,1) = xin;
fv1=costFunction([vx1; vy1]); %fv(1) = costFunction(xin);
if verbose
    fprintf('IterValue:\n%1.9f\n',fv1);
end

% 2nd and 3rd vertex - simply add simplexInitSize to 1st or 2nd coordinate of a 2D point to make 3 points of the simplex

vx2=vx1+simplexInitSize; vy2=vy1;
fv2=costFunction([vx2; vy2]); 

if verbose
    fprintf('IterValue:\n%1.9f\n',fv2);
end

vx3=vx1; vy3=vy1+simplexInitSize;
fv3=costFunction([vx3; vy3]); % f = costFunction(x);
if verbose
    fprintf('IterValue:\n%1.9f\n',fv3);
end

% end simplex setup
% sort the simplex from smallest fv to largest, move V with fv.
[fv1 fv2 fv3 vx1 vy1 vx2 vy2 vx3 vy3]=sortJur(fv1,fv2,fv3,vx1,vy1,vx2,vy2,vx3,vy3);

%OPState* : decision made
%OPState*_NV new vertex
%OPState*_CostFunction 
%OPState*_IF decision
% S16: Check exit condition
while ((abs(fv2 - fv1) > tolf)||(abs(vx1-vx2)>tolx)||(abs(vy1-vy2)>tolx)&&loopcount<maxloop)
    loopcount=loopcount+1;
    
    % checks on accuracy of fval only - if abs(fv2-fv1)<tolerance => success.
    
    %OPState1
    %OPState1_NV
    
    % middle point made of 1st and 2nd vertex
    xbar1 = (vx1 + vx2)/2; % Average
    xbar2 = (vy1 + vy2)/2;
    
    % 1st guess for better point
    xr1 = 2*xbar1 - vx3;  % v(:,end) is simply [vx3  vy3], so xr must be [xr1 xr2]
    xr2 = 2*xbar2 - vy3;
    %OPState1_CostFunction
    fxr = costFunction([xr1; xr2]);
    if verbose
        fprintf('IterValue:\n%1.9f\n',fxr);
    end
    
    % if guess 1 is better than best point    
    %OPState1_IF
    if fxr < fv1 % Calculate the expansion point
        %OPState2
        %OPState2_NV
        xe1 = 3*xbar1 - 2*vx3;
        xe2 = 3*xbar2 - 2*vy3;
        %OPState2_CostFunction
        fxe = costFunction([xe1; xe2]);
        if verbose
            fprintf('IterValue:\n%1.9f\n',fxe);
        end
        %OPState2_IF
        if fxe < fxr
            %OPState3
            %OPState3_NV
            vx3 = xe1;
            vy3 = xe2;
            fv3 = fxe;
            %OPState3: NoCostFunction, NoIfs, gotostate=?
            %END OPState3
        else
            %OPState4
            %OPState4_NV
            vx3 = xr1;
            vy3 = xr2;
            fv3 = fxr;
            %OPState4: NoCostFunction, NoIfs, gotostate=?
        end %END OPState4
    else % if average is not better than best point
        %OPState5
        %OPState5_IF
        if fxr < fv2 % but still better than second-best point
            %OPState6
            %OPState6_NV
            vx3 = xr1;
            vy3 = xr2;
            fv3 = fxr;
            %OPState6: NoCostFunction, NoIfs, gotostate=? 
        else %and if it is not better than first two but better than worst current point
            %OPState7
            %OPState7_IF 8,11
            if fxr < fv3
                %OPState8
                %OPState8_NV
                xc1 = 1.5*xbar1 - 0.5*vx3;
                xc2 = 1.5*xbar2 - 0.5*vy3;
                %OPState8_CostFunction
                fxc = costFunction([xc1; xc2]);
                if verbose
                    fprintf('IterValue:\n%1.9f\n',fxc);
                end
                %OPState8_IF
                if fxc <= fxr %if this new point is better, save it
                    %OPState9
                    %OPState9_NV
                    vx3 = xc1;
                    vy3 = xc2;
                    fv3 = fxc;
                    how = 0; 
                    %END OPState9: NoCostFunction, NoIfs, gotostate=? 
                else % if not, try something else
                    %OPState10
                    how = 1;
                    %END OPState9: NoCalc, NoCostFunction, NoIfs,gotostate=? 
                    % can collapse this state in OPState8_IF                    
                end
                %END OPState8. gotostates=9,10
            else % the 'average' point is not better than any of the existing points
                %OPState11
                % Perform an inside contraction   
                %OPState11_NV
                xcc1 = 0.5*xbar1 + 0.5*vx3;
                xcc2 = 0.5*xbar2 + 0.5*vy3;
                %OPState11_CostFunction
                fxcc = costFunction([xcc1; xcc2]);
                if verbose
                    fprintf('IterValue:\n%1.9f\n',fxcc);
                end
                %OPState11_IF : 12,13
                if fxcc < fv3 % now, if the contracted point is better than the last worst point, save it
                    %OPState12
                    %OPState12_NV
                    vx3 = xcc1;
                    vy3 = xcc2;
                    fv3 = fxcc;
                    how = 0;
                    %END OPState12:  NoCostFunction, NoIfs,gotostate=? 
                else
                    %OPState13
                    how = 1; % the contracted point is not better than last worst - try something else
                    %END OPState13: NoCalc, NoCostFunction, NoIfs,gotostate=? 
                end
            end %END %OPState78: gotostates: 8,11
            
            if how % Shrink - try this if everything else failed. Replace two worst poins.
                %OPState14A , NV                     
                vx2 = vx1 + 0.5*(vx2 - vx1);
                vy2 = vy1 + 0.5*(vy2 - vy1);
                fv2 = costFunction([vx2; vy2]); % OPState14A: CF
                if verbose
                    fprintf('IterValue:\n%1.9f\n',fv2);
                end
                %OPState14B
                vx3 = vx1 + 0.5*(vx3 - vx1);
                vy3 = vy1 + 0.5*(vy3 - vy1);
                fv3 = costFunction([vx3; vy3]);
                if verbose
                    fprintf('IterValue:\n%1.9f\n',fv3);
                end
                
            end
        end %END OPState5. Gotostates=6,7
    end
    %END OPState1_IF. Gotostates=15,2
    
    % OPState: 15
    % sort so that we have best point in the top    
    %OPState1: Sorting
    [fv1 fv2 fv3 vx1 vy1 vx2 vy2 vx3 vy3]=sortJur(fv1,fv2,fv3,vx1,vy1,vx2,vy2,vx3,vy3);
    %OPState1: Check Exit condition
end
fval = fv1;
% some visualisation procedures may need the X too
X=[vx1; vy1]; 
if verbose
    fprintf('\nminsearch:\n%f, %f\n',vx1,vy1);
end
end

% Jurek's version of the sort function
% make sure to inline and pass params by reference - they use virtually no extra registers
function [a1 a2 a3 b1 b2 b3]=swapJur(a1,a2,a3,b1,b2,b3)
if a1>b1
    tmp=b1; b1=a1; a1=tmp;
    tmp=b2; b2=a2; a2=tmp;
    tmp=b3; b3=a3; a3=tmp;
end
end

function [fv1 fv2 fv3 vx1 vy1 vx2 vy2 vx3 vy3]=sortJur(fv1,fv2,fv3,vx1,vy1,vx2,vy2,vx3,vy3)
% this is a variant of a shake sort, but with only 1.5 pass needed since
% the length of the sorted array is known in advance
% swap procedure: 2-3, 1-2, 2-3. this is enough.
% the advantage here is that only 1 tmp register is used
[fv2 vx2 vy2 fv3 vx3 vy3]=swapJur(fv2,vx2,vy2,fv3,vx3,vy3);
[fv1 vx1 vy1 fv2 vx2 vy2]=swapJur(fv1,vx1,vy1,fv2,vx2,vy2);
[fv2 vx2 vy2 fv3 vx3 vy3]=swapJur(fv2,vx2,vy2,fv3,vx3,vy3);
end
