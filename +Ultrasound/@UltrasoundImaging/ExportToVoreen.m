% ExportToVoreen exports a 3D data of matrix to voreen into "RAW" data
% format with "DAT" metadata file
% Usage: 
%
% ExportToVoreen(OutputFileName,ClipRange)
% 
% OutputFileName - string, name of the file
% ClipRange - range of values to clip the data to. Any input format data is
% accepted (single, double etc.) but the data must be internally converted
% to uint8 before going to Voreen. Therefore scaling is needed and this
% parameter controlls the scaling. For example, ClipRange=[-40 0]; scales
% the data to include smooth transition between -40 to 0; values more than
% -40 are saturated to -40 and values over 0 are saturated to 0.
% 
% the recomended data style is blobs after hilbert transform, in
% logarithmic scale. Note that wave-like (alternating sign) data doesn't
% work well with voreen's coloring algorithm
%

% Author: Jerzy Dziewierz, CUE 2012
% version 1.0
% version history:
% 1.0 first release to git

function ExportToVoreen(obj,filename,range)

% Scale the data
if nargin<3
    range=[min(obj.image(:)) max(obj.image(:))];
end

slicethick=abs([obj.image_dz obj.image_dy obj.image_dx]);
slicethick=slicethick;
dat=min(max((obj.image-range(1)),0)./(range(2)-range(1)),1);
i=uint8(dat*255);


% i=permute(i,[1 2 3]); uncomment if need be to permute dimensions

% save the data to raw file
fid=fopen([filename '.raw'],'w+');
cnt=fwrite(fid,i,'uint8');
fclose(fid);
% write the metadata file
fid=fopen([filename '.dat'],'w+');
fprintf(fid,'ObjectFileName: %s.raw\n',filename);
fprintf(fid,'TaggedFileName: ---\n');
fprintf(fid,'Resolution:     %d %d %d\n',size(i,1),size(i,2),size(i,3));
fprintf(fid,'SliceThickness: %f %f %f\n',slicethick(1),slicethick(2),slicethick(3));
fprintf(fid,'Format:         UCHAR\n');
fprintf(fid,'NbrTags:        0\n');
fprintf(fid,'ObjectType:     TEXTURE_VOLUME_OBJECT\n');
fprintf(fid,'ObjectModel:    I\n');
fprintf(fid,'GridType:       EQUIDISTANT\n');
fprintf(fid,'Modality:       ultrasound\n');
fprintf(fid,'TimeStep:       0\n');
fprintf(fid,'Unit:           mm\n');
fclose(fid);

end