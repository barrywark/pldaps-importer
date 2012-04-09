classdef TestPldapsBase < TestCase
    
    properties
        context
    end
    
    properties(Constant)
        
        pdsFile = 'fixtures/jlyTest040212tmpdots1109.PDS';
        plxFile = 'fixtures/jlyTest040212tmpDots1103.mat';
        plxRawFile = 'fixtures/jlyTest040212tmpDots1103.plx';
        plxExpFile = 'fixtures/jlyTest040212tmpdots1109.exp';
        
%         pdsFile = 'fixtures/jlyTest040212tmpSaccadeMapping1102.PDS';
%         plxFile = 'fixtures/jlyTest040212tmpSaccadeMapping1103.mat';
%         plxRawFile = 'fixtures/jlyTest040212tmpSaccadeMapping1103.plx';
%         plxExpFile = 'fixtures/jlyTest040212tmpdots1109.exp';
        
        connection_file = 'ovation/matlab_fd.connection';
        username = 'TestUser';
        password = 'password';
        timezone = org.joda.time.DateTimeZone.forID('US/Central');
    end
    
    methods
        function self = TestPldapsBase(name)
            self = self@TestCase(name);
        end

        function setUp(self)
            import ovation.*;
            
            self.context = Ovation.connect(fullfile(pwd(), self.connection_file), self.username, self.password);
            
        end

        function tearDown(self)
            self.context.close();
        end

    end
end
