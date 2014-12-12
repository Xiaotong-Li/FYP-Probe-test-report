function FilterFMCgpu(obj,Fc1,Fc2)

if(isempty(obj.unfiltered_FMC))
    obj.unfiltered_FMC = obj.FMC;
end
if(size(obj.unfiltered_FMC)~=size(obj.FMC))
    obj.unfiltered_FMC = obj.FMC;
end

Fs = obj.FMCSamplingRate;

N     = 101;      % Order
obj.SetFMCTimeStart(obj.FMCTimeStart + (N/(2*Fs)));

flag  = 'scale';  % Sampling Flag
Alpha = 2.5;      % Window Parameter
% Create the window vector for the design algorithm.
win = gausswin(N+1, Alpha);

% Calculate the coefficients using the FIR1 function.
b  = fir1(N, [Fc1 Fc2]/(Fs/2), 'bandpass', win, flag);
b = dfilt.dffir(b);

% We need to split this into parts so that the GPU does not run out of
% memory
n_parts = 8;
per_part = size(obj.FMC,2) / n_parts;
for part = 1:n_parts
gpu_data = gpuArray(obj.unfiltered_FMC(:,(part-1)*per_part+1:part*per_part));
y=flipud(filter(b.Numerator,1,flipud(filter(b.Numerator,1,gpu_data))));
obj.FMC(:,(part-1)*per_part+1:part*per_part) = gather(y);
end
    
    
    