function p = polyfit_quick(~,x,y,n)
%POLYFIT Fit polynomial to data.
%  same as Matlab's polyfit, but with no bad conditioning check (the data
%  is always well conditioned).

% Construct Vandermonde matrix.
V(:,n+1) = ones(length(x),1,class(x));
for j = n:-1:1
   V(:,j) = x.*V(:,j+1);
end

% Solve least squares problem.
[Q,R] = qr(V,0);
%ws = warning('off','all'); 
p = R\(Q'*y);    % Same as p = V\y;
%warning(ws);
p = p.';          % Polynomial coefficients are row vectors by convention.

end
