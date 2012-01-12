function epoch = findEpochByUniqueNumber(epochGroup, uniqueNumber)
   
    if(isempty(epochGroup))
        epoch = [];
        return;
    end
    
    epochs = epochGroup.getEpochs();
    for i = 1:length(epochs)
       epoch = epochs(i);
       
       % TODO this should use getProperty(
       vals = epoch.getProperty('uniqueNumber');
       assert(length(vals) <= 1);
       if(isempty(vals))
           epoch = [];
           return;
       end
       
       epochUniqueNumber = vals(1).getIntegerData()';
       
       if(all(epochUniqueNumber == uniqueNumber))
           return;
       end
       
       if(all(mod(epochUniqueNumber,256) == uniqueNumber))
           warning('ovation:import:plx:unique_number', 'uniqueNumber appears to be 8-bit truncated');
           return;
       end
    end
    
    epoch = [];
end