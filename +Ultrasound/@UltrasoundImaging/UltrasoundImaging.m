classdef UltrasoundImaging < handle 
% UltrasoundImaging object
% see https://github.com/jerzydziewierz/ultrasound2/wiki/cuTFM-TOC for
% documentation
% note: only the most important methods and properties are listed below
%
% UltrasoundImaging properties:
%   refractionVariant - 
%   parametricInterface - note that this is not supported in some C/CUDA accelearted codes
%   medium1_velocity - velocity of sound in the medium where probe is
%   medium2_velocity - velocity of sound in the medium below the interface, if refractionVariant is not `NoRefraction`
% UltrasoundImaging methods:
%   SolveScene - Prepares for imaging using stored settings
%   RenderImage - Renders TFM image using stored settings

% Jerzy Dziewierz, University of Strathclyde
% copyright 2009-2012

    
    properties %(SetAccess = protected )
                              
        refractionVariant = Ultrasound.RefractionVariant.Undefined; % I Love You!
        constrainedFlag = Ultrasound.ConstrainedFlag.NotConstrained;
        parametricInterface = @(SurfaceXY)(0.*SurfaceXY(1,:)+0.*SurfaceXY(2,:));
        % medium
        
        medium1_velocity = 1450;
        medium2_velocity = 2850;
        % probe
        ProbeElementLocations=[];      
        ProbeDirectivityCosLimit=0; 
        % data
        FMC = [];
        unfiltered_FMC = [];
        
        FMCSamplingRate = 100e6;
        TxRxList = [];
        
        % image
        
        image_x0 = 0;
        image_y0 = -32e-3;
        image_z0 = -10e-3;
        image_nx = 1;
        image_ny = 160;
        image_nz = 80;
        image_dx = 2e-3;
        image_dy = 2e-3;
        image_dz = -2e-3;
        
        image = [];
        SASACI_images = [];
        SASACI = [];
        SASACI_corr = [];
        filter_init = 0;
        % GPU Settings
        gpuSettings;
        filter;
        SurfaceParameters=zeros(15,1,'single');
    end

    properties (SetAccess = private, GetAccess = private)
      FMCTimeStartInternal = 0;  
    end    
    properties (Dependent = true)
        FMCTimeStart
        FMCTimeEnd
        FMCTimeBase
    end
    properties (Dependent = true, SetAccess = private)
        
        ProbeElementCount;
        image_xcoordinates;
        image_ycoordinates;
        image_zcoordinates;
        image_depth;
              
    end
    
    properties (Dependent = true, Hidden=true)
        InterfaceID;  
    end
    
    properties (Hidden)
        coeffs
        InfoFigure
        InfoString
        coeffsize=5; 
        LastCoeffSetMD5
        fitorder_stats
        fiterror_stats
        pattern_spread=10e-3;
        pattern_npoints=3;
    end
    methods
        % constructor
        function obj = UltrasoundImaging(obj,varargin)
            
            global UltraSoundImaging_Initialised
            if isempty(UltraSoundImaging_Initialised)
                UltraSoundImaging_Initialised = 1;
            else
                if UltraSoundImaging_Initialised==1
                    fprintf('\n');
                    fprintf('warning: cannot create two instances of this class nor re-start the class\n');
                    fprintf('use the previously declared class or delete this one first\n');
                    error('cannot do that');
                end
            end                
            
            % default values

            % load default probe
            in=load('+Ultrasound\@UltrasoundImaging\probe');
            obj.ProbeElementLocations=in.probe.element_pos';
            
            % prepare GPU settings
            obj.gpuSettings.align_x=128;
            obj.gpuSettings.align_y=1;
            
            % prepare figure
            screensize=get(0,'ScreenSize');
            obj.InfoFigure=figure(24335);
            set(obj.InfoFigure,'Position',[screensize(3)-400 32 400 40]);
            set(obj.InfoFigure,'MenuBar','none','Name','Ultrasound Imaging','NumberTitle','off');
            set(obj.InfoFigure,'Visible','on','WindowStyle','normal');                       
            
            warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
            fjFrame=get(obj.InfoFigure,'JavaFrame');
            fjFrame.fHG1Client.getWindow.setAlwaysOnTop(true);         
            
            obj.InfoString=uicontrol('parent',obj.InfoFigure,'position',[0 0 400 40],'style','pushbutton');
            set(obj.InfoString,'string','no message');
            figure(1);
        end
        
        % destructor
        function delete(obj)
            try
            delete(obj.InfoFigure);            
            clear mex
            catch E % failed - typically will fail if called from eg. remoteParallelFunction
            end
            global UltraSoundImaging_Initialised
            UltraSoundImaging_Initialised=[];            
        end
        
        % 
        
        % dynamic properties
        function FMCTimeBase=get.FMCTimeBase(obj)
            FMCLength=size(obj.FMC,1);
            dt=1./obj.FMCSamplingRate;               
            FMCTimeBase=linspace(obj.FMCTimeStart,obj.FMCTimeEnd,FMCLength);
        end
        
        function FMCTimeEnd=get.FMCTimeEnd(obj)
            FMCLength=size(obj.FMC,1);
            dt=1./obj.FMCSamplingRate;           
            FMCTimeEnd=obj.FMCTimeStart+dt*FMCLength;
        end                
        
        function InterfaceID=get.InterfaceID(obj)
            InterfaceID=single(obj.refractionVariant);
%             if (obj.refractionVariant==Ultrasound.RefractionVariant.NoRefraction)
%                 InterfaceID=0;
%             elseif (obj.refractionVariant==Ultrasound.RefractionVariant.PlanarInterfaceZ)                
%                 InterfaceID=1;
%             elseif (obj.refractionVariant==Ultrasound.RefractionVariant.CylinderX)
%                 InterfaceID=2;
%             elseif (obj.refractionVariant==Ultrasound.RefractionVariant.SinX)
%                 InterfaceID=3;
%             elseif (obj.refractionVariant==Ultrasound.RefractionVariant.Poly5)
%                 InterfaceID=4;
%             elseif (obj.refractionVariant==Ultrasound.RefractionVariant.AilidhDualPoly5)
%                 InterfaceID=7;
%             else
%                 InterfaceID=-1;
%             end
        end
                
        function image_xcoordinates=get.image_xcoordinates(obj)
            image_xcoordinates=obj.image_x0:obj.image_dx:(obj.image_x0+(double(obj.image_nx)-1)*obj.image_dx);
        end
        function image_ycoordinates=get.image_ycoordinates(obj)
            image_ycoordinates=obj.image_y0:obj.image_dy:(obj.image_y0+(double(obj.image_ny)-1)*obj.image_dy);
        end
        function image_zcoordinates=get.image_zcoordinates(obj)
            image_zcoordinates=obj.image_z0:obj.image_dz:(obj.image_z0+(double(obj.image_nz)-1)*obj.image_dz);
        end        
        function image_depth=get.image_depth(obj)
            image_depth=-obj.image_zcoordinates;
        end
        
        function set.ProbeElementLocations(obj,ProbeElementLocations)
            if size(ProbeElementLocations,1)~=3
                error('ProbeElementLocations must be a 3*n double matrix')
            end
            obj.ProbeElementLocations=single(ProbeElementLocations); % data type conversion needed for compatibility with cuTFM kernel
        end
        
        function set.TxRxList(obj,newTxRxList)
            if size(newTxRxList,1)~=2
                error('TxRxList must be of size 2*N')
            end
            obj.TxRxList=uint8(newTxRxList);
        end
        
        function ProbeElementCount=get.ProbeElementCount(obj)
            ProbeElementCount=size(obj.ProbeElementLocations,2);
        end
        
        function set.refractionVariant(obj,NewVariant)
            % here i can validate that remaining parameters allow switching
            % the algo variant.
            obj.refractionVariant=NewVariant;
            if NewVariant==Ultrasound.RefractionVariant.PlanarInterfaceZ
                obj.parametricInterface=@(SurfaceXY)(0);
            end
            if NewVariant==Ultrasound.RefractionVariant.SinX                
                obj.parametricInterface=str2func(sprintf('@(SurfaceXY)(%e+%e*sin(2*pi*%e*SurfaceXY(2,:)))',obj.SurfaceParameters(3),obj.SurfaceParameters(1),obj.SurfaceParameters(2)));
            end
            if NewVariant==Ultrasound.RefractionVariant.Poly5
                obj.parametricInterface=str2func(sprintf('@(SurfaceXY)(polyval([%e %e %e %e %e],SurfaceXY(2,:)))',obj.SurfaceParameters(1),obj.SurfaceParameters(2),obj.SurfaceParameters(3),obj.SurfaceParameters(4),obj.SurfaceParameters(5)));
            end
            if NewVariant==Ultrasound.RefractionVariant.CylinderX
                obj.constrainedFlag = Ultrasound.ConstrainedFlag.ConstrainedY;
            end
            
        end
        
        function set.SurfaceParameters(obj,Params)
            if length(Params) < 15
                Params=[Params(:); zeros(15-length(Params(:)),1)];
                obj.SurfaceParameters(1:length(Params)) = single(Params);
            else
                error('Maximum of 15 parameters allowed');
            end
        end
        
%         function set.FMCTimeStart(obj,NewValue)
%         % this is a placeholder so that this can be overriden with a subclass    
%             obj.FMCTimeStart=NewValue;
%         end       
         function SetFMCTimeStart(obj,NewValue)
               obj.FMCTimeStartInternal=NewValue;
         end
       
        function out=get.FMCTimeStart(obj)
            out=obj.FMCTimeStartInternal;
        end
    end
    methods (Access=protected)

    end
              
end
        
        