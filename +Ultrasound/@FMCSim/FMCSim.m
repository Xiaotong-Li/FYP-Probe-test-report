classdef FMCSim < Ultrasound.UltrasoundImaging
    % This class extends class Ultrasound.UltrasoundImaging with methods needed to simulate FMC    
    %
    % FMCSim Properties:
    %   ProbeDirectivityCosPower - parameter of probe's elements
    %   ProbeProtoSignal - prototype of signal received by the probe
    %   ProbeProtoSignalOffset - offset in the ProbeProtoSignal to the centre of the signal        
    %   ReflectorList - 3xN list of XYZ locations of the reflectors to imprint in the FMC
    %   ReflectorStrength - 1xN list of strength of the reflectors in decibels. Note - decibels! put '0' there as default
    % 
    % FMCSim Methods:
    %   ClearFMC - fills the existing FMC with zeros, keeping its size
    %   EmptyFMC - sets FMC contents to empty. 
    %   CreateFullMatrixAscanList - generates TxRx List of "Full Matrix Capture" type and initializes FMC buffer   
    %   CreateHalfMatrixAscanList - generates TxRx List of "Half Matrix Capture" type and initializes FMC buffer
    %   CreateTxRxList - assigns TxRxList with provided TxRxList and initializes FMC buffer  
    %   SimulateFMC - performs FMC simulation
    %   TrimFMCAuto - trims FMC buffer to minimal size
    %
    % example:
    % sim=Ultrasound.FMCSim;
    %
    % See also Ultrasound.UltrasoundImaging
        
    % Jerzy Dziewierz, University of Strathclyde
    % Copyright 2009-2012    
    properties        
        
        %  parameter of probe's elements
        %  See detailed documentation for explanation
        ProbeDirectivityCosPower = single(1);  
                
        % prototype of signal received by the probe
        % this is used by SimulateFMC and gets imprinted into the FMC at calculated times 
        ProbeProtoSignal = single([]); 
        
        % offset in the ProbeProtoSignal to the centre of the signal
        % points to the centre, or peak in the signal, adjusts the timing of the imprinted signal
        ProbeProtoSignalOffset = single(0); 
                                
        ReflectorList = single([]);
        ReflectorStrength = single([]);
        
        %%ReflectorSurface = @(X)(0); % not supported at this time
        % need more material properties
        medium2_velocityShear = 1070; % nylon
        medium1_density = 1000; % water
        medium2_density = 1780; % nylon
        
                
    end
    properties (SetAccess = private)
%         FMCTimeBase = [];
%         FMCTimeEnd = 0;         
    end
%     properties (SetAccess = private, GetAccess = private)
%         FMCTimeStartInternal = 0;
%     end
    
    methods (Access = protected)

    end
    
    methods  
        
        function obj=FMCSim(obj)            
           set(obj.InfoFigure,'Name','FMCSim')
           set(obj.InfoString,'string','FMCSim init');
           drawnow;
        end
        
              function set.ProbeProtoSignal(obj,NewProtoSignal)
            obj.ProbeProtoSignal=single(NewProtoSignal);
        end
        function set.ProbeProtoSignalOffset(obj,newProbeProtoSignalOffset)
            obj.ProbeProtoSignalOffset=single(newProbeProtoSignalOffset);
        end
        function set.ReflectorList(obj,newReflectorList)
            obj.ReflectorList=single(newReflectorList);
        end
        function set.ReflectorStrength(obj,newReflectorStrength)
            obj.ReflectorStrength=single(newReflectorStrength);
        end
        
                         
    end
end