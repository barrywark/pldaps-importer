function exp = loadPLXExpFile(expFilePath)
    % Written by Kyler Eastman
    
    exp = [];
    
    if(~exist(expFilePath, 'file'))
        error(['Cannot find exp file at ' expFilePath]);
    end
    
    [fid,msg] = fopen(expFilePath, 'r');
    if(fid == -1)
        error(msg);
    end
    
    line = fgetl(fid);
    while line ~=-1
        if line(1) ~= ';'
            try 
                eval(['exp.' line ';']);
            catch
                equals = find(line=='=');
                eval(['exp.' line(1:equals) '''' line(equals+1:end) ''';']);
            end
        end
        line = fgetl(fid);
    end
end