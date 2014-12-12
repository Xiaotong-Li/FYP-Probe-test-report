function bandwidth=CalculateBandwidth(obj,DoPlotFigure)
if nargin<2
    DoPlotFigure=0;
end
freq_expand=64; % expand factor
fps=abs(fft(obj.ProbeProtoSignal,length(obj.ProbeProtoSignal)*freq_expand));
fbase=linspace(0,obj.FMCSamplingRate,length(obj.ProbeProtoSignal)*freq_expand);
fpshalf=fps(1:floor(end/2)); fbasehalf=fbase(1:floor(end/2));
fpshalf=20*log10(fpshalf); fpshalf=fpshalf-max(fpshalf);

f1_idx=find(fpshalf>-3,1,'first'); f1=fbasehalf(f1_idx);
f2_idx=find(fpshalf>-3,1,'last'); f2=fbasehalf(f2_idx);
[tmp fmax_idx]=max(fpshalf); fcenter=(f1+f2)/2;
bandwidth=(f2-f1)/fcenter;
if DoPlotFigure>0
    figure(DoPlotFigure)
    subplot(2,1,2)
    plot(fbasehalf,fpshalf); ylim([-20 0]);
    fprintf('bandwidth: %0.1f %%; ',bandwidth*100);
end