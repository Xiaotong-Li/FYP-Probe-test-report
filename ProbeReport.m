function ProbeReport(varargin)
%% prepare input and output names
if nargin==0 % if function called with no arguments    
    % load prode data
    if ~exist('LastFileName','var')
        LastFileName='d:\My Cubby\0000\2014-12-__ tmp\probe test results\2014-12-04 Imasonic 5MHz Matrix 11606 A101\RawProbeData.mat';
        fprintf('setting source file name to default : %s\n',LastFileName);
    else
        
    end
    % set report name
    if ~exist('ProbeName','var')
        ProbeName = '2014-12-04 Imasonic 5MHz Matrix 11606 A101';
        fprintf('setting probe name to default: %s\n',ProbeName);
    end
    fprintf('loading the file from variable LastFileName - %s\n',LastFileName);
elseif nargin==2
    % get LastFileName and ProbeName from arguments
    LastFileName=varargin{1};
    ProbeName=varargin{2};
else
    error('0 or 2 arguments needed');
end

%% define constants
SelectedElementIdx=32;
HistogramBins=7;
% highPassFilter settings
PassBand=100e3;
StopBand=70e3;

%% load source data
load(LastFileName);
    
%% clear older report if exists
reportFilename = fullfile(pwd,[ProbeName '.doc']);
if exist(reportFilename,'file')
     try % try closing old word instance
           hdlActiveX = actxGetRunningServer('Word.Application');
           try 
            docu=hdlActiveX.Application.ActiveDocument; docu.Close(0);
           catch E1
           end
           invoke(hdlActiveX, 'Quit');
       catch E
       end
    fprintf('deleting old report...\n');
    delete(reportFilename);
end

%% create new report
fprintf('opening new report...\n');
wr = wordreport(reportFilename);
wr.setstyle('Heading 1');
wr.addtext(['Probe test report: ' ProbeName ],[1 1]); % line break before and after text


wr.setstyle('Heading 1');
wr.addtext('Contents', [1 1]); %  line break before and after text
wr.createtoc(1, 3);

%% overview section
fprintf('adding overview...\n');
wr.setstyle('Heading 2');
wr.addtext('Source data overview', [1 1]);
figure(1); clf;
imagesc(DataIn); ylabel('time[us]'); xlabel('element index[-]');
title('Source data overview');
colormap wave;
wr.addfigure(); close(1);
%% Begin data filtering
% find a slice of time where the first reflection from the glass block is
% expected
[tmp, tCutIdx] = min(abs(usi.FMCTimeBase-15e-6)); % time 0
[tmp, t1idx]= min(abs(usi.FMCTimeBase-16e-6)); % time 1
[tmp, t2idx]= min(abs(usi.FMCTimeBase-22e-6)); % time 2
%% reset all data before tCut to zero
DataIn(1:tCutIdx,:)=0;
%% scale the data from input units to volts per volt
DataIn=DataIn.*(1/usi.DynarayVoltage).*(10.^(-usi.DynarayGain/20)).*(1/2^16);

%% remove DC offset
DataIn=DataIn-repmat(mean(DataIn),size(DataIn,1),1);
%% Apply filter

HighPassFilter=MakeHighPassFilter(StopBand,PassBand,usi.FMCSamplingRate);
DataInHP=filter(HighPassFilter,DataIn);
DataInHilbert=abs(hilbert(DataInHP));


%% demo hilbert transform
DoHilbertDemo=0;
if DoHilbertDemo
eidx=17;
figure(1); clf;

hp1=plot(usi.FMCTimeBase(t1idx:t2idx)*1e6,DataInHP(t1idx:t2idx,eidx),'b');
set(hp1,'linewidth',4);
hold on;
hp2=plot(usi.FMCTimeBase(t1idx:t2idx)*1e6,DataInHilbert(t1idx:t2idx,eidx),'r');
set(hp2,'linewidth',4);
grid on;

xlabel('time[us]'); ylabel('waveform[V/V]')
legend('waveform','envelope');
figure(2); clf;
freq_expand=64; % expand factor
    fps=abs(fft(DataInHP(t1idx:t2idx,eidx),length(DataInHP(t1idx:t2idx,eidx))*freq_expand));
    % wrong: fbase=linspace(0,1/1000,length(DataInHP(t1idx:t2idx,p))*freq_expand); % where does 1/1000 constant come from?? it should be usi.FMCSamplingRate !!
    fbase=linspace(0,usi.FMCSamplingRate,length(DataInHP(t1idx:t2idx,eidx))*freq_expand); % where does 1/1000 constant come from?? it should be usi.FMCSamplingRate !!
    fpshalf=fps(1:floor(end/2)); fbasehalf=fbase(1:floor(end/2));
    fpshalf=20*log10(fpshalf); fpshalf=fpshalf-max(fpshalf);
plot(fbasehalf,fpshalf); ylim([-40 0]); grid on; hold on;
plot([min(fbasehalf) max(fbasehalf)],[1 1]*-3); 
end
%% 
figure(1); clf;

subplot(2,1,1);
plot(usi.FMCTimeBase*1e6,DataInHP(:,:)); xlabel('time[us]'); ylabel('response[V/V]');
grid on;
title('all elements');

subplot(2,1,2);

plot(usi.FMCTimeBase(t1idx:t2idx)*1e6,DataInHP(t1idx:t2idx,SelectedElementIdx)); xlabel('time[us]'); ylabel('response[V/V]');
grid on;
title(sprintf('single element, %d',SelectedElementIdx));
wr.addfigure(); close(1);
wr.setstyle('Normal');
wr.addtext('Note: The excitation pulse has been blanked for purpose of response analysis. ', [1 1]);
wr.addtext(sprintf('Note: Signal treated with high-pass filter at %0.0f kHz',PassBand/1e3), [0 1]);
%% data analysis
% record the strengh of received signals
fprintf('adding pulse-echo strength analysis...\n');
for p=1:128
    [amplitude(p),i(p)] = max(DataInHP(t1idx:t2idx,p)); % record the strength
    % Xiaotong's version:
    gain=20*log10(DataInHP(t1idx:t2idx,p)/amplitude(p)); % ??? wrong!!! the DataInHP contains positive AND negative values, so you cannot take log10 of it!
    t1_idx=find(gain>-3,1,'first'); t1=usi.FMCTimeBase(t1_idx);
    t2_idx=find(gain>-3,1,'last'); t2=usi.FMCTimeBase(t2_idx);
    tmax(p) = usi.FMCTimeBase(i(p));
    time_length(p)=t2-t1; % record the correspond time
    % Jurek's version of the above line:
    PulseEchoResponse=20*log10(abs(DataInHilbert(t1idx:t2idx,p)));  % note the abs()
    PulseEchoResponse=PulseEchoResponse-max(PulseEchoResponse); 
    t1_idx=find(PulseEchoResponse>-3,1,'first'); t1=usi.FMCTimeBase(t1_idx);
    t2_idx=find(PulseEchoResponse>-3,1,'last'); t2=usi.FMCTimeBase(t2_idx);
    [value_max, tIdx_max]=max(abs(DataInHilbert(t1idx:t2idx,p))); % take max and it's location from envelope, not the raw waveform
    tmax(p)= usi.FMCTimeBase(tIdx_max);   
    time_length(p)=t2-t1; % record the pulse length
   
    
    freq_expand=64; % expand factor
    fps=abs(fft(DataInHP(t1idx:t2idx,p),length(DataInHP(t1idx:t2idx,p))*freq_expand));
    % wrong: fbase=linspace(0,1/1000,length(DataInHP(t1idx:t2idx,p))*freq_expand); % where does 1/1000 constant come from?? it should be usi.FMCSamplingRate !!
    fbase=linspace(0,usi.FMCSamplingRate,length(DataInHP(t1idx:t2idx,p))*freq_expand); % where does 1/1000 constant come from?? it should be usi.FMCSamplingRate !!
    fpshalf=fps(1:floor(end/2)); fbasehalf=fbase(1:floor(end/2));
    fpshalf=20*log10(fpshalf); fpshalf=fpshalf-max(fpshalf);
    
    f1_idx=find(fpshalf>-3,1,'first'); f1=fbasehalf(f1_idx);
    f2_idx=find(fpshalf>-3,1,'last'); f2=fbasehalf(f2_idx);
    [tmp fmax_idx]=max(fpshalf); fcenter=(f1+f2)/2;
    prb_bandwidth(p)=(f2-f1)/fcenter;
end

% calculate average value of strength
aplave = mean(amplitude);
% sort strength difference in ascending order
[a,m] = sort(abs(amplitude-aplave));

% calculate average value of response time
tave = mean(tmax);
% sort response time difference in ascending order
[t,n] = sort(abs(tmax-tave));

% calculate average value of time length
tlave = mean(time_length);
%sort time length difference inascending orde
[tl,o] = sort(abs(time_length-tlave));



wr.setstyle('Heading 1');
wr.addtext('Analysis',[1 1]);

% setup figure 2 represents the strength
% 10 of the worst elements are marked as *
wr.setstyle('Heading 2');
wr.addtext('Per-element strength Deviation',[0 1]);

figure(2),stem(amplitude), hold on,
plot(1:0.05:128,aplave,'r'), hold on,
plot(m(119:128),amplitude(m(119:128)),'r*');
axis([0 128 0.2e-06 2e-06]), xlabel('Nth element'),ylabel('Amplitude'),
grid on;
title('Strength analysis');
wr.addfigure(); close(2);

figure(3),hist(amplitude,HistogramBins);
title('Strength deviation'); xlabel('pulse-echo strength[V/V]'); ylabel('occurence count[-]');
grid on;
wr.addfigure(); close(3);
wr.addpagebreak();

%%setup figure 4 represents the response time
% 10 of the worst elements are marked as *
wr.setstyle('Heading 2');
wr.addtext('Peak Time Deviation',[0 1]);

figure(4), stem(tmax), hold on,
plot(1:0.05:128,tave,'r'), hold on,
plot(n(119:128),tmax(n(119:128)),'r*');
title('peak time analysis');
axis([0 128 6e-06 8e-06]); xlabel('Nth element'),ylabel('Time[s]'),
grid on;
wr.addfigure(); close(4);

figure(5),hist(tmax,HistogramBins);
xlabel('Time[s]'); ylabel('occurences');
title('peak time deviation');
grid on;
wr.addfigure(); close(5);
wr.addpagebreak();

%% setup figure 6 represents the time length
% 10 of the worst elements are marked as *
fprintf('adding pulse-echo length analysis...\n');
wr.setstyle('Heading 2');
wr.addtext('Pulse Length Deviation',[0 1]);
figure(6), stem(time_length), hold on,
plot(o(119:128),time_length(o(119:128)),'r*');
title('rx pulse length');
axis([0 128 0 2.5e-06]); xlabel('Nth element'),ylabel('Pulse Length[s]'),
grid on;
wr.addfigure(); close(6);

figure(7),hist(time_length,HistogramBins);
xlabel('Pulse length[s]'); ylabel('occurences');
title('Pulse length deviation');
grid on;
wr.addfigure(); close(7);
wr.addpagebreak();

%setup figure 6 represents the time length
% 10 of the worst elements are marked as *
wr.setstyle('Heading 2');
wr.addtext('Bandwidth analysis',[0 1]);
figure(8), stem(prb_bandwidth*100);
title('Bandwidth deviation');
xlabel('Nth element'),ylabel('Bandwidth [%]'),
grid on;
wr.addfigure(); close(8);

figure(9),hist(prb_bandwidth*100,HistogramBins);
title('Bandwidth deviation');
grid on;
wr.addfigure(); close(9);
wr.addpagebreak();
%% add table
fprintf('adding worst elements table\n');
wr.setstyle('Heading 1');
wr.addtext('Worst Performing Elements',[1 1]);
wr.setstyle('Normal');
wr.addtext('Table sorted by worst first',[1 1]);
dataCell = { ...
    'Amplitude Element NO. ', num2str(m(119:128)); ...
    'Time response Element NO.', num2str(n(119:128)); ...
    'Time length Element NO.', num2str(o(119:128))};
[nbRows, nbCols] = size(dataCell);
wr.addtable(nbRows, nbCols, dataCell, [1 1]);
%% page setup
fprintf('finalizing...');
wr.addpagenumbers('wdAlignPageNumberRight');
wr.updatetoc();
%---
wr.close();
%---
open(reportFilename);
fprintf('done.\n');
