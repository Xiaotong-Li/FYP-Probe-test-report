% function coeffOffsetVector(yline,ProbeElementNumber)
% returns a vector of indices pointing to the coeffs table, for a given
% line and tx/rx number
% use with care
function out=coeffOffsetVector(obj,yline,tx)
    coeffOffset=@(yline,tx)((yline-1)*obj.ProbeElementCount*obj.coeffsize+(tx-1)*obj.coeffsize+1); 
    out=(coeffOffset(yline,tx):(coeffOffset(yline,tx)+(obj.coeffsize-1)));
end