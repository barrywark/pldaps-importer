function [epoch,uniqueNumberCache,idx] = findEpochByUniqueNumber(epochGroup, uniqueNumber, varargin)
   % EntityBase.getProperty is slow. Until we can pull just getOwner()'s
   % properties, we do some caching and hinting to speed up this search.
    
   if(nargin >= 3)
        uniqueNumberCache = varargin{1};
    else
        uniqueNumberCache = [];
    end
    
    if(nargin >= 4)
        idxHint = varargin{2};
    else
        idxHint = [];
    end
    
    idx = [];
    
    if(isempty(epochGroup))
        epoch = [];
        idx = [];
        return;
    end
    
    if(~isempty(uniqueNumberCache))
        if(uniqueNumberCache.containsKey(uniqueNumber))
            epoch = uniqueNumberCache.get(uniqueNumber);
            idx = idxHint;
            return;
        end
    else
        uniqueNumberCache = java.util.HashMap();
    end
    
    epochs = epochGroup.getEpochs();
    
    if(~isempty(idxHint) && idxHint <= length(epochs))
       epoch = epochs(idxHint); 
       
       % TODO this should use getProperty(getOwner)
       vals = epoch.getProperty('uniqueNumber');
       assert(length(vals) <= 1);
       if(~isempty(vals))
           epochUniqueNumber = vals(1).getIntegerData()';
           
           
           if(all(epochUniqueNumber == uniqueNumber))
               uniqueNumberCache.put(uniqueNumber, epoch);
               idx = idxHint;
               return;
           end
           
           if(all(mod(epochUniqueNumber,256) == uniqueNumber))
               warning('ovation:import:plx:unique_number', 'uniqueNumber appears to be 8-bit truncated');
               uniqueNumberCache.put(uniqueNumber, epoch);
               idx = idxHint;
               return;
           end
       end
    end
    
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
           idx = i;
           return;
       end
       
       if(all(mod(epochUniqueNumber,256) == uniqueNumber))
           warning('ovation:import:plx:unique_number', 'uniqueNumber appears to be 8-bit truncated');
           uniqueNumberCache.put(uniqueNumber, epoch);
           idx = i;
           return;
       end
    end
    
    epoch = [];
end