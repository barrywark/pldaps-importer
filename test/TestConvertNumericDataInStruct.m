classdef TestConvertNumericDataInStruct < TestCase
    methods
        function self = TestConvertNumericDataInStruct(name)
             self = self@TestCase(name);
        end
        
        function testShouldConvertVectors(self)
           s.vec = [1,2,3];
           s.val = 3;
           
           expected.vec = NumericData(s.vec);
           expected.val = 3;
           
           actual = convertNumericDataInStruct(s);
           
           self.assertEqualStructs(expected, actual);
        end
        
        function assertEqualStructs(s1, s2)
            fnames = fieldnames(s1);
            for i = 1:length(fnames)
                fname = fnames{i};
                if(isjava(s1.(fname)))
                    assert(~s1.(fname).equals(s2.(fname)));
                else
                    assert(s1.(fname) ~= s2.(fname));
                end
            end
        end
    end
end