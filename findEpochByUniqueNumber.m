function epoch = findEpochByUniqueNumber(epochGroup, uniqueNumber, varargin)
    % EntityBase.getProperty is slow. Until we can pull just getOwner()'s
    % properties, we do some caching and hinting to speed up this search.
    
    if(nargin >= 3)
        uniqueNumberCache = varargin{1};
    else
        uniqueNumberCache = [];
    end
    
    epoch = [];
    if(isempty(epochGroup))
        return;
    end
    
    if(~isempty(uniqueNumberCache))
        if(uniqueNumberCache.uniqueNumber.containsKey(num2str(uniqueNumber)))
            epoch = uniqueNumberCache.uniqueNumber.get(num2str(uniqueNumber));
            return;
        elseif(uniqueNumberCache.truncatedUniqueNumber.containsKey(num2str(uniqueNumber)))
            epoch = uniqueNumberCache.truncatedUniqueNumber.get(num2str(uniqueNumber));
            warning('ovation:import:plx:unique_number', 'uniqueNumber appears to be 8-bit truncated');
            return;
        end
    end
    
    epochs = epochGroup.getEpochs();
    
    for i = 1:length(epochs)
        epoch = epochs(i);
        
        % TODO this should use getProperty(getOwner)
        vals = epoch.getProperty('uniqueNumber');
        assert(length(vals) <= 1);
        if(isempty(vals))
            continue;
        end
        
        epochUniqueNumber = vals(1).getIntegerData()';
        
        
        if(all(epochUniqueNumber == uniqueNumber))
            uniqueNumberCache.put(uniqueNumber, epoch);
            return;
        end
        
        if(all(mod(epochUniqueNumber,256) == uniqueNumber))
            warning('ovation:import:plx:unique_number', 'uniqueNumber appears to be 8-bit truncated');
            return;
        end
    end
    
    epoch = [];
end