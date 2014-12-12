function RenderSASACI_image(obj)
original_FMC = obj.FMC;
FMC2 = reshape(original_FMC,size(original_FMC,1),obj.ProbeElementCount,obj.ProbeElementCount);
TFM_output = zeros(obj.ProbeElementCount,obj.image_ny,obj.image_nz);

for tx_idx = 0:obj.ProbeElementCount-1
    TxRxList = [ones(1,obj.ProbeElementCount)*tx_idx; 0:(obj.ProbeElementCount-1)];
    obj.TxRxList = uint8(TxRxList);
    obj.SolveScene;
    obj.FMC = single(squeeze(FMC2(:,:,tx_idx+1)));
    obj.RenderImage;
    TFM_output(tx_idx+1,:,:) = obj.image';
end
obj.SASACI_images = TFM_output;
TxRxList = [];
for tx=0:obj.ProbeElementCount-1
    for rx=0:obj.ProbeElementCount-1
        TxRxList = [TxRxList; tx rx];
    end
end
obj.TxRxList = uint8(TxRxList)';
obj.FMC = original_FMC;
end
