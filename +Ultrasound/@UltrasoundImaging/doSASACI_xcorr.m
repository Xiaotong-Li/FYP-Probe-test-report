function doSASACI_xcorr( obj, A, threshold, threshold_exp, type)

if (type == Ultrasound.SASACI_type.Alternating)
    image1 = squeeze(sum(obj.SASACI_images(1:2:obj.ProbeElementCount,:,:)));
    image2 = squeeze(sum(obj.SASACI_images(2:2:obj.ProbeElementCount,:,:)));
    corr_alternating = zeros(obj.image_ny,obj.image_nz);
    
    for yy=A+1:obj.image_ny - A
%         clc;
%         fprintf('Processing line %d of %d\n',yy,obj.image_ny-A);
        for zz=A+1:obj.image_nz - A
            corr_alternating(yy,zz) = xcorr_2D(A,yy,zz,image1,image2);
            if(corr_alternating(yy,zz) < threshold)
%                 corr_alternating(yy,zz) = corr_alternating(yy,zz)^threshold_exp; 
                corr_alternating(yy,zz) = corr_alternating(yy,zz)/threshold_exp; 

            end
        end
    end 
    obj.SASACI = corr_alternating' .* (image1+image2)';
    obj.SASACI_corr = corr_alternating';
end
if (type ==  Ultrasound.SASACI_type.Hanning)
    hanning_weights = hanning(obj.ProbeElementCount);
    image1 = squeeze(sum(obj.SASACI_images));
    han = obj.SASACI_images;
    for n = 1:size(han,1)
        han(n,:,:) = han(n,:,:) .* hanning_weights(n);
    end
    image2 = squeeze(sum(han));
    corr_hanning = zeros(obj.image_ny,obj.image_nz);
    
    for yy=A+1:obj.image_ny - A
        for zz=A+1:obj.image_nz - A
            corr_hanning(yy,zz) = xcorr_2D(A,xx,yy,image1,image2);
            if(corr_hanning(xx,yy) < threshold)
                corr_hanning(xx,yy) = corr_hanning(xx,yy)^threshold_exp; 
            end
        end
    end 
    obj.SASACI = corr_hanning;
end
    
function [ p ] = xcorr_2D(A, i, j , RX1, RX2)
sigma_1 = 0;
sigma_2 = 0;
sigma_3 = 0;
for kk=i-A:i+A
    for jj=j-A:j+A
        sigma_1 = sigma_1 + RX1(kk,jj)*RX2(kk,jj);
        sigma_2 = sigma_2 + RX1(kk,jj)^2;
        sigma_3 = sigma_3 + RX2(kk,jj)^2;
    end
end
p = sigma_1 / (sqrt(sigma_2) * sqrt(sigma_3));
return


