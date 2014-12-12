classdef(Enumeration) RefractionVariant < int32
% RefractionVariant   Enumeration of refraction variants as supported by Ultrasound.* code
%
% example:
% sim.RefractionVariant=Ultrasound.RefractionVariant.NoRefraction
% sim.RefractionVariant=Ultrasound.RefractionVariant.PlanarInterfaceZ
%
% See also Ultrasound.FMCSim

% Jerzy Dziewierz, University of Strathclyde
% Copyright 2009-2012
    enumeration
        % unknown or unset interface type
        Undefined (-1)
        
        % known refraction types
        % note that this must correspond to refraction types defined in other parts of the code - in particular in the CoeffGen and FMCSim
        NoRefraction (0)
        PlanarInterfaceZ (1)
        CylinderX (2)     
        SinX (3)     
        Poly5 (4)
        AilidhDualPoly5 (7)
        ParametricInterface (99)
          
    end
end