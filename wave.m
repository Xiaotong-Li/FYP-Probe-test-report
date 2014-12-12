% wave colormap. goes from blue, trough white to red
% usage: colormap wave
%
% by Jerzy Dziewierz, CUE 2010
function out=wave
out=[ 
    linspace(0.3,0.99,127) linspace(0.99,1,128);
    linspace(0.0,0.99,127) linspace(0.99,0.0,128);
    linspace(1,0.99,127) linspace(0.99,0.3,128)]';