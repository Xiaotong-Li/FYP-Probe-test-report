        
                        function SetFMCTimeStart(obj,NewValue)
% !WARNING: THERE ARE SYNTAX PROBLEMS IN HAVING THIS TO UPDATE THE
% SUPERCLASS AND do trimming at the same time. So i resign from trimming capability here        
% instead, a separate method SetFMCTimeStartAndTrim is provided
% obj.TrimFMCToStartStop(NewValue,obj.FMCTimeEnd);
% THIS METHOD DOES NOT TRIM THE FMC
% apparently there is a problem having a set.* method that would write the
% superclass variable AND execute subclass method on single entry.. . . 
            obj.SetFMCTimeStart@Ultrasound.UltrasoundImaging(NewValue);
            
                        end