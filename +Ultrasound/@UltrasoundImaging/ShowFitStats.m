function obj=ShowFitStats(obj)
fitorder_stats=obj.fitorder_stats;
fprintf('coeffsize: %d\n',obj.coeffsize);
fprintf('peak error: %e\n',max(obj.fiterror_stats(:)));
fprintf('fitorder=1: %d cases\n',sum(fitorder_stats(:)==0));
    fprintf('fitorder=2: %d cases\n',sum(fitorder_stats(:)==1));
    fprintf('fitorder=3: %d cases\n',sum(fitorder_stats(:)==2));
    fprintf('fitorder=4: %d cases\n',sum(fitorder_stats(:)==3));
    fprintf('fitorder=5: %d cases\n',sum(fitorder_stats(:)==4));
    fprintf('fitorder=6: %d cases\n',sum(fitorder_stats(:)==5));
    fprintf('fitorder=7: %d cases\n',sum(fitorder_stats(:)==6));
    fprintf('fitorder=8: %d cases\n',sum(fitorder_stats(:)==7));
    fprintf('fitorder=9: %d cases\n',sum(fitorder_stats(:)==8));
    fprintf('fitorder=10: %d cases\n',sum(fitorder_stats(:)==9));
    fprintf('fitorder=11: %d cases\n',sum(fitorder_stats(:)==10));
    fprintf('fitorder=12: %d cases\n',sum(fitorder_stats(:)==11));
    fprintf('fitorder=13: %d cases\n',sum(fitorder_stats(:)==12));
    fprintf('fitorder=14: %d cases\n',sum(fitorder_stats(:)==13));
    fprintf('fitorder=15: %d cases\n',sum(fitorder_stats(:)==14));
    fprintf('fitorder=16: %d cases\n',sum(fitorder_stats(:)==15));
    fprintf('fitorder=error: %d cases\n',sum(fitorder_stats(:)==99));
end