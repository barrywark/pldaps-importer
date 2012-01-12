classdef TestPladpsBase < TestCase
    properties
        context
        connection_file
    end
    
    methods
        function self = TestPladpsBase(name)
             self = self@TestCase(name);
        end

        function setUp(self)
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

            system('mkdir -p ovation');
            
            import ovation.*;
            
            self.connection_file = ovation.util.createLocalOvationDatabase('ovation', ...
                'matlab_fd',...
                'TestUser',...
                'password',...
                'license.txt',...
                'ovation-development');
            
            self.context = Ovation.connect(self.connection_file, 'TestUser', 'password');
            addpath .; %test dir
            addpath ..; %pladps_importer

        end

        function tearDown(self)
            self.context.close();
            ovation.util.deleteLocalOvationDatabase(self.connection_file, true);
            disp('Called tearDown');
        end

    end
end
