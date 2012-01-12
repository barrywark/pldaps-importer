classdef TestPDSImport < TestPladpsBase
    
    properties
        pdsFile
        plxFile
        epochGroup
        trialFunctionName
        timezone
    end
    
    methods
        function self = TestPDSImport(name)
            self = self@TestPladpsBase(name);
            
            import ovation.*;
            
            % This is our tie to the fixture
            self.pdsFile = 'fixtures/pat120811a_decision2_16.PDS';
            self.plxFile = 'fixtures/pat120811a_decision2_1600matlabfriendlyPLX.mat';
            
            ctx = Ovation.connect(self.connection_file, self.username, self.password);
            project = ctx.insertProject('TestImportMapping',...
                'TestImportMapping',...
                datetime());
            
            expt = project.insertExperiment('TestImportMapping',...
                datetime());
            source = ctx.insertSource('animal');
            
            self.trialFunctionName = 'trial_function_name';
            self.timezone = 'America/New_York';
            
            
            
            % Import the PDS file
            self.epochGroup = ImportPladpsPDS(expt,...
                source,...
                self.pdsFile,...
                self.trialFunctionName,...
                self.timezone,...
                2); %TODO only import 2 trials for now
            
            
            % Import the plx file
            %ImportPladpsPlx(self.epochGroup,...
            %   self.plxFile);
        end
        
        function setUp(self)
           setUp@TestPladpsBase(self);
           
           %TODO remove for real testing
           itr = self.context.query('EpochGroup', 'true');
           self.epochGroup = itr.next();
        end
        
        % EpochGroup
        %  - should have trial function name as group label
        %  - should have PDS start time
        %  - should have next/prev links for all epochs in group
        %  - should have original plx file attached as Resource
        % For each Epoch
        %  - should have trial function name as protocol ID
        %  - should have parameters from c1, PDS
        %  - should have duration equal to eye tracker data duration (last sample of eye tracker data gives duration)
        %  - should have sequential unique identifier with prev/next
        %  - should have next/pre if next/prev epochs were recorded, respecitively
        %  - should have approparite stimuli and responses
        % For each stimulus
        %  - should have correct plugin ID (TBD)
        %  - should have event times (+ other?) stimulus parameters
        % For each response
        %  - ??
        % These are for plx import
        %  - should have spike times t0 < ts <= end_trial
        %  - should have same number of wave forms
        
        
        function testShouldUseTrialFunctionNameAsEpochGroupLabel(self)
            % Import should use trialFunctionName as inserted EpochGroup
            % label.
            
            assertTrue(self.epochGroup.getLabel().equals(java.lang.String(self.trialFunctionName)));
            
        end
        
        function testEpochGroupShouldHavePDSStartTime(self)
            import ovation.*;
            fileStruct = load(self.pdsFile, '-mat');
            pds = fileStruct.PDS;
            
            idx = find(pds.unique_number(:,1) ~= -1);
            unum = pds.unique_number(idx(1),:);
            first_duration = pds.eyepos{idx(1)}(end,3);
            
            endTime = datetime(unum(1), unum(2), unum(3), unum(4), unum(5), unum(6), 0, self.timezone);
            startTime = endTime.minusSeconds(first_duration);
            
            assertTrue(self.epochGroup.getStartTime().equals(startTime));
            
        end
    end
end