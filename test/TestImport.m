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
            
            project = self.context.insertProject('TestImportMapping',...
                'TestImportMapping',...
                org.joda.time.DateTime());
            
            expt = project.insertExperiment('TestImportMapping',...
                org.joda.time.DateTime());
            
            self.pdsFile = 'fixtures/pat120811a_decision2_16.PDS';
            trialFunctionName = 'trial_function_name';
            epochGroup = ImportPladpsPDS(expt,...
                self.pdsFile,...
                trialFunctionName,...
                timezone);
            
            
            assert(epochGroup.getLabel().equals(java.lang.String(trialFunctionName)));
            
            % EpochGroup
            %  - should have PDS start time
            %  - should have next/prev links for all epochs in group
            % For each Epoch
            %  - should have parameters from c1, PDS
            %  - should have duration equal to eye tracker
            %  - should have sequential unique identifier with prev/next
            %  - should have next/pre
            
            self.plxFile = 'fixtures/pat120811a_decision2_1600matlabfriendlyPLX.mat';
            ImportPladpsPlx(epochGroup,...
                self.plxFile);
            
            % These are for plx import
            %  - should have spike times t0 < ts <= end_trial
            %  - should have same number of wave forms
        end
    end
end