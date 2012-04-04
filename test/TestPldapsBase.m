classdef TestPldapsBase < TestCase
    
    properties
        context
        connection_file
        username
        password
    end
    
    properties(Constant)
        
        pdsFile = 'fixtures/jlyTest040212tmpSaccadeMapping1102.PDS';
        plxFile = 'fixtures/jlyTest040212tmpSaccadeMapping1103.MAT';
        plxRawFile = 'fixtures/jlyTest040212tmpSaccadeMapping1103.plx';
        plxExpFile = 'fixtures/jlyTest040212tmpdots1109.exp';
        timezone = org.joda.time.DateTimeZone.forID('US/Central');
    end
    
    methods
        function self = TestPldapsBase(name)
            self = self@TestCase(name);
            
            import ovation.*;
            
            % N.B. these values should match those in runtestsuite
            self.connection_file = 'ovation/matlab_fd.connection';
            self.username = 'TestUser';
            self.password = 'password';
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
