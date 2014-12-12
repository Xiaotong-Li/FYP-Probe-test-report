function obj=SaveToFile(obj,filename)
% saves the state of the object file. Calculated properties are also saved
% so that the file can be read outside this software package. reader can
% decide which fields to load.
frame.ProbeDirectivityCosLimit=obj.ProbeDirectivityCosLimit;
%frame.FMCTimeBase=obj.FMCTimeBase;
%frame.FMCTimeEnd=obj.FMCTimeEnd;
%frame.algorithm=obj.algorithm;
frame.refractionVariant=obj.refractionVariant;
frame.parametricInterface=obj.parametricInterface;
frame.medium1_velocity=obj.medium1_velocity;
frame.medium2_velocity=obj.medium2_velocity;
frame.ProbeElementLocations=obj.ProbeElementLocations;
frame.FMC=obj.FMC;
frame.FMCSamplingRate=obj.FMCSamplingRate;
frame.TxRxList=obj.TxRxList;
frame.image_x0=obj.image_x0;
frame.image_y0=obj.image_y0;
frame.image_z0=obj.image_z0;
frame.image_nx=obj.image_nx;
frame.image_ny=obj.image_ny;
frame.image_nz=obj.image_nz;
frame.image_dx=obj.image_dx;
frame.image_dy=obj.image_dy;
frame.image_dz=obj.image_dz;
frame.image=obj.image;
frame.FMCTimeStart=obj.FMCTimeStart;
frame.ProbeElementCount=obj.ProbeElementCount; 
frame.image_xcoordinates=obj.image_xcoordinates;
frame.image_ycoordinates=obj.image_ycoordinates;
frame.image_zcoordinates=obj.image_zcoordinates;
frame.image_depth=obj.image_depth;
frame.coeffs=obj.coeffs;
frame.coeffsize=obj.coeffsize;
frame.LastCoeffSetMD5=obj.LastCoeffSetMD5;

save(filename,'frame');
end