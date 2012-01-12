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
                eval(['exp.' strrep(line, '.', '_') ';']);
            catch
                equals = find(line=='=');
                eval(['exp.' strrep(line(1:equals), '.', '_')...
                    '''' line(equals+1:end) ''';']);
            end
        end
        line = fgetl(fid);
    end
end