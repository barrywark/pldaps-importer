classdef TestPladpsBase < TestCase
    properties
        context
        connection_file
        username
        password
    end
    
    methods
        function self = TestPladpsBase(name)
            self = self@TestCase(name);
            
            if strcmp('', getenv('OVATION_LOCK_SERVER'))
                setenv('OVATION_LOCK_SERVER', '127.0.0.1');
            end
            
            if strcmp('',getenv('OVATION_ROOT'))
                setenv('OVATION_ROOT', '/opt/ovation');
            end
            
            if strcmp('',getenv('OBJY_ROOT'))
                setenv('OBJY_ROOT', '/opt/object/mac86_64');
            end
            
            if strcmp('', getenv('OBJY_FDID'))
                setenv('OBJY_FDID', '1005')
            end
            if strcmp('', getenv('JAVA_ARTIFACTS_DIR'))
                setenv('JAVA_ARTIFACTS_DIR', '../../java/Ovation/artifacts')
            end
            
            
            import ovation.*;
            
            self.connection_file = 'ovation/matlab_fd.connection';
            
            % Delete the test database if it exists
            if(exist(self.connection_file, 'file') ~= 0)
                ovation.util.deleteLocalOvationDatabase(self.connection_file, true);
            end
            
            
            
            % Create a test database
            system('mkdir -p ovation');
            self.username = 'TestUser';
            self.password = 'password';
            
            self.connection_file = ovation.util.createLocalOvationDatabase('ovation', ...
                'matlab_fd',...
                self.username,...
                self.password,...
                'license.txt',...
                'ovation-development');
            
        end

        function setUp(self)
            import ovation.*;
            
            self.context = Ovation.connect(self.connection_file, self.username, self.password);
            
        end

        function tearDown(self)
            self.context.close();
        end

    end
end
