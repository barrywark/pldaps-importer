function [times, idx] = generateStartAndEndTimes(macTimes, eyepos, timezone)
    if (size(macTimes, 2) ~= 6) %throw error
        
    end
    import ovation.*
    
    idx = find(macTimes(:,1) ~= -1);
    times = cell(1, length(idx));
    for n=1:length(idx)
        macTime = macTimes(idx(n),:);
        times{n}.endtime = datetime(macTime(1),...
            macTime(2),...
            macTime(3),...
            macTime(4),...
            macTime(5),...
            macTime(6),...
            0,...
            timezone);
        
        duration = eyepos{idx(n)}(end,3);
        
        times{n}.starttime = times{n}.endtime.minusMillis(duration*1000);
    end
    
end