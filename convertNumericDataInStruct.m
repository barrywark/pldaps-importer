function s = convertNumericDataInStruct(inStruct)
% Convert arrays and matricies in inStruct to NumericData objects.

    import ovation.*;
    fnames = fieldnames(inStruct);
    for i = 1:length(fnames)
       if(isnumeric(inStruct.(fnames{i})) && numel(inStruct.(fnames{i})) > 1)
           data = inStruct.(fnames{i});
           
           if(isvector(data))
               s.(fnames{i}) = NumericData(data);
           else
               s.(fnames{i}) = NumericData(reshape(data, 1, numel(data)), size(data));
           end
       else
           s.(fnames{i}) = inStruct.(fnames{i});
       end
    end
end