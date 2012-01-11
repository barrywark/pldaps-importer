classdef TestImport < TestPladps
    
    properties
        pdsFile
        plxFile
    end
    
    methods
        function self = TestImport(name)
             self = self@TestPladps(name);
        end
        
        function TestImportMapping(self)
            import ovation.*;
            
            self.pdsFile = 'fixtures/pat120811a_decision2_16.PDS';
            self.plxFile = 'fixtures/pat120811a_decision2_1600matlabfriendlyPLX.mat';
            
            project = self.context.insertProject('TestImportMapping',...
                'TestImportMapping',...
                datetime());
            
            expt = project.insertExperiment('TestImportMapping',...
                datetime());
            
            
            trialFunctionName = 'trial_function_name';
            epochGroup = ImportPladpsPDS(expt,...
                self.pdsFile,...
                trialFunctionName,...
                timezone);
            
            
            assert(epochGroup.getLabel().equals(java.lang.String(trialFunctionName)));
            
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
            
            
            ImportPladpsPlx(epochGroup,...
                self.plxFile);
            
            % These are for plx import
            %  - should have spike times t0 < ts <= end_trial
            %  - should have same number of wave forms
        end
    end
end