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

function [fval X] = minSearch(obj,costFunction,x,verbose) 
if nargin<4
    verbose=false;
end
tolf = 200e-12;
tolx= 1e-7;
maxloop=1e5;
loopcount=0;
rho = 1; chi = 2; psi = 0.5; sigma = 0.5;


%v11=0; v12=0; v13=0;                           % These don't need to be
%v21=0; v22=0; v23=0; %v = zeros(n,n+1);        % initialised here. Kept
% for clarity though.
%fv1=0; fv2=0; fv3=0; %fv = zeros(1,n+1);
v11=x(1);
v21=x(2); %v(:,1) = xin;
fv1=costFunction([v11; v21]); %fv(1) = costFunction(xin);
if verbose
    fprintf('IterValue:\n%1.9f\n',fv1);
end
%note! for clarity about what we are talking about here, the V and FV
%vector could be also named (xz) and (t) vector, eg
% v_x1, v_x2,v_x3, v_z1,v_z2, v_z3; and
% f_t1, f_t2, f_t3;  the index points to a verex number in your simplex.
% the simplex happens to be a triangle lying on a costFunction y=f(x,z) in 3D
% space, and it's only the accuracy of T that we are interested in, so
% (expensive!) checks on xz accuracy are unneccesary!


% = = initial simplex setup - simply add usual_delta to 1st or 2nd coordinate of a 2D point to make 3 points of the simplex
usual_delta = 0.05;             % 5 percent deltas for non-zero terms
%!! NOTE: TTHIS IS TOO SMALL FOR APPLICATION IN SI SYSTEMS
zero_term_delta=3e-3; % 3mm difference
%zero_term_delta = 0.00025;      % Even smaller delta for zero elements of x

% NOTE! The below code produces not enough spread for initial simplex when
% initial y-coordinate is too small. Need to spread more, otherwise the
% simplex fails to iterate 
ForcedSpread=2e-3; %

%for j = [1 2]
% j=1:: !loop unrolling
y1=x(1); y2=x(2); %y = xin;
if y1~=0 %if y(j) ~= 0
    y1=(1+usual_delta)*y1; % y(j) = (1 + usual_delta)*y(j);
else % else
    y1=zero_term_delta; % y(j) = zero_term_delta;
end % end

if (abs(y1-x(1))<ForcedSpread)
    y1=x(1)+ForcedSpread;
end

v12=y1; v22=y2;% v(:,j+1) = y;
x1=y1; x2=y2;% x(:) = y;
fv2=costFunction([x1; x2]);% f = costFunction(x);
if verbose
    fprintf('IterValue:\n%1.9f\n',fv2);
end
%end% end for j=[1 2]; where j=1;
% loop unrolling: with j=2::
%y = xin;
y1 = v11; y2=v21; % y=xin;
if y2~=0
    y2=(1+usual_delta)*y2; % y(j) = (1 + usual_delta)*y(j);
else
    y2=zero_term_delta; %y(j) = zero_term_delta;
end
% NOTE! The above code produces not enough spread for initial simplex when
% initial y-coordinate is too small. Need to spread more, otherwise the
% simplex fails to iterate 

if (abs(y2-v21)<ForcedSpread)
    y2=v21+ForcedSpread;
end
v13=y1; v23=y2; %v(:,j+1) = y;
x1=y1; x2=y2;% x(:) = y;
fv3=costFunction([x1; x2]); % f = costFunction(x);
if verbose
    fprintf('IterValue:\n%1.9f\n',fv3);
end
% end simplex setup
% sort the simplex from smallest fv to largest, move V with fv.
[fv1 fv2 fv3 v11 v21 v12 v22 v13 v23]=sortJur(fv1,fv2,fv3,v11,v21,v12,v22,v13,v23);

% Note to Tim: I wanted to save you the burden of rediscovering the wheel.
% Still, the challenge for you is to refactor this code to minimise time
% spent in the conditional branches !

%OPState* : decision made
%OPState*_C calculations
%OPState*_CostFunction 
%OPState*_IF decision

while ((abs(fv2 - fv1) > tolf)||(abs(v11-v12)>tolx)||(abs(v21-v22)>tolx)&&loopcount<maxloop)
    loopcount=loopcount+1;
    % checks on accuracy of fval only - if abs(fv2-fv1)<tolerance => success.
    
    %OPState1
    %OPState1_C
    xbar1 = (v11 + v12)/2; % Average
    xbar2 = (v21 + v22)/2;
    xr1 = (1 + rho)*xbar1 - rho*v13;  % v(:,end) is simply [v13  v23], so xr must be [xr1 xr2]
    xr2 = (1 + rho)*xbar2 - rho*v23;
    %OPState1_CostFunction
    fxr = costFunction([xr1; xr2]);
    if verbose
        fprintf('IterValue:\n%1.9f\n',fxr);
    end
    
    % if 'average' is better than best point    
    %OPState1_IF
    if fxr < fv1 % Calculate the expansion point
        %OPState2
        %OPState2_C
        xe1 = (1 + rho*chi)*xbar1 - rho*chi*v13;
        xe2 = (1 + rho*chi)*xbar2 - rho*chi*v23;
        %OPState2_CostFunction
        fxe = costFunction([xe1; xe2]);
        if verbose
            fprintf('IterValue:\n%1.9f\n',fxe);
        end
        %OPState2_IF
        if fxe < fxr
            %OPState3
            %OPState3_C
            v13 = xe1;
            v23 = xe2;
            fv3 = fxe;
            %OPState3: NoCostFunction, NoIfs, gotostate=?
            %END OPState3
        else
            %OPState4
            %OPState4_C
            v13 = xr1;
            v23 = xr2;
            fv3 = fxr;
            %OPState4: NoCostFunction, NoIfs, gotostate=?
        end %END OPState4
    else % if average is not better than best point
        %OPState5
        %OPState5_IF
        if fxr < fv2 % but still better than second-best point
            %OPState6
            %OPState6C
            v13 = xr1;
            v23 = xr2;
            fv3 = fxr;
            %OPState6: NoCostFunction, NoIfs, gotostate=? 
        else %and if it is not better than first two but better than worst current point
            %OPState7
            %OPState7_IF 8,11
            if fxr < fv3
                %OPState8
                %OPState8_C
                xc1 = (1 + psi*rho)*xbar1 - psi*rho*v13;
                xc2 = (1 + psi*rho)*xbar2 - psi*rho*v23;
                %OPState8_CostFunction
                fxc = costFunction([xc1; xc2]);
                if verbose
                    fprintf('IterValue:\n%1.9f\n',fxc);
                end
                %OPState8_IF
                if fxc <= fxr %if this new point is better, save it
                    %OPState9
                    %OPState9_C
                    v13 = xc1;
                    v23 = xc2;
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
                %OPState11_C
                xcc1 = (1-psi)*xbar1 + psi*v13;
                xcc2 = (1-psi)*xbar2 + psi*v23;
                %OPState11_CostFunction
                fxcc = costFunction([xcc1; xcc2]);
                if verbose
                    fprintf('IterValue:\n%1.9f\n',fxcc);
                end
                %OPState11_IF : 12,13
                if fxcc < fv3 % now, if the contracted point is better than the last worst point, save it
                    %OPState12
                    %OPState12_C
                    v13 = xcc1;
                    v23 = xcc2;
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
                %OPState14A                
                v12 = v11 + sigma*(v12 - v11);
                v22 = v21 + sigma*(v22 - v21);
                fv2 = costFunction([v12; v22]);
                if verbose
                    fprintf('IterValue:\n%1.9f\n',fv2);
                end
                %OPState14B
                v13 = v11 + sigma*(v13 - v11);
                v23 = v21 + sigma*(v23 - v21);
                fv3 = costFunction([v13; v23]);
                if verbose
                    fprintf('IterValue:\n%1.9f\n',fv3);
                end
                
            end
        end %END OPState5. Gotostates=6,7
    end
    %END OPState1_IF. Gotostates=1,5
    % sort so that we have best point in the top
    %OPState1: Sorting
    [fv1 fv2 fv3 v11 v21 v12 v22 v13 v23]=sortJur(fv1,fv2,fv3,v11,v21,v12,v22,v13,v23);
    %OPState1: Check Exit condition
end
fval = fv1;
% some visualisation procedures may need the X too
X=[v11; v21]; 
if verbose
    fprintf('\nminsearch:\n%f, %f\n',v11,v21);
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

function [fv1 fv2 fv3 v11 v21 v12 v22 v13 v23]=sortJur(fv1,fv2,fv3,v11,v21,v12,v22,v13,v23)
% this is a variant of a shake sort, but with only 1.5 pass needed since
% the length of the sorted array is known in advance
% swap procedure: 2-3, 1-2, 2-3. this is enough.
% the advantage here is that only 1 tmp register is used
[fv2 v12 v22 fv3 v13 v23]=swapJur(fv2,v12,v22,fv3,v13,v23);
[fv1 v11 v21 fv2 v12 v22]=swapJur(fv1,v11,v21,fv2,v12,v22);
[fv2 v12 v22 fv3 v13 v23]=swapJur(fv2,v12,v22,fv3,v13,v23);
end
