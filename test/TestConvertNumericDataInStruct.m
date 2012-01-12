classdef TestConvertNumericDataInStruct < TestCase
    methods
        function self = TestConvertNumericDataInStruct(name)
            self = self@TestCase(name);
        end
        
        function testShouldConvertVectors(self)
            import ovation.*;
            
            s.vec = [1,2,3];
            s.val = 3;
            
            expected.vec = NumericData(s.vec);
            expected.val = 3;
            
            actual = convertNumericDataInStruct(s);
            
            self.assertEqualStructs(expected, actual);
        end
        
        function testShouldConvertMatrices(self)
            import ovation.*;
            
            s.vec = [1,2,3;4,5,6];
            s.val = 3;
            
            expected.vec = NumericData(reshape(s.vec, 1, numel(s.vec)), size(s.vec));
            expected.val = 3;
            
            actual = convertNumericDataInStruct(s);
            
            self.assertEqualStructs(expected, actual);
        end
        
        function assertEqualStructs(self, s1, s2)
            fnames = fieldnames(s1);
            for i = 1:length(fnames)
                fname = fnames{i};
                if(isjava(s1.(fname)))
                    assert(all(s1.(fname).getDataBytes() == s2.(fname).getDataBytes()));
                    assert(all(s1.(fname).getShape() == s2.(fname).getShape()));
                else
                    assert(s1.(fname) == s2.(fname));
                end
            end
        end
    end
end