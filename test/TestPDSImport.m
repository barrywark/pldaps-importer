classdef TestPDSImport < TestPldapsBase
    
    properties
        pdsFile
        plxFile
        epochGroup
        trialFunctionName
        timezone
    end
    
    methods
        function self = TestPDSImport(name)
            self = self@TestPldapsBase(name);
            
            import ovation.*;
           
            % N.B. these value should match those in runtestsuite
            self.pdsFile = 'fixtures/pat120811a_decision2_16.PDS';
            self.plxFile = 'fixtures/pat120811a_decision2_1600matlabfriendlyPLX.mat';
            self.trialFunctionName = 'pat120811a_decision2_16';
            self.timezone = 'America/New_York';
            
            
            % Import the plx file
            %ImportPladpsPlx(self.epochGroup,...
            %   self.plxFile);
        end
        
        function setUp(self)
           setUp@TestPldapsBase(self);
           
           %TODO remove for real testing
           itr = self.context.query('EpochGroup', 'true');
           self.epochGroup = itr.next();
           assertFalse(itr.hasNext());
        end
        
        % EpochGroup
        %  - should have correct trial function name as group label
        %  - should have PDS start time
        %  - should have original plx file attached as Resource
        %  - should have PLX exp file attached as Resource
        % For each Epoch
        %  - should have trial function name as protocol ID
        %  - should have parameters from c1, PDS
        %  - should have duration equal to eye tracker data duration (last sample of eye tracker data gives duration)
        %  - should have sequential unique identifier with prev/next 
        %  - should have next/pre if next/prev epochs were recorded, respectively
        %  - should have approparite stimuli and responses
        % For each stimulus
        %  - should have correct plugin ID (TBD)
        %  - should have event times (+ other?) stimulus parameters
        % For each response
        %  - ??
        % These are for plx import
        %  - should have spike times t0 < ts <= end_trial
        %  - should have same number of wave forms
        
        function testEpochsShouldHaveNextPrevLinksWhenConsecutive(self)
            import java.util.HashSet
            trialNumbers = HashSet();
            epochs = self.epochGroup.getEpochs();
            for n=1:length(epochs)
                trialNums = epochs(n).getProperty('trialNumber');
                trialNum = trialNums(1);
                trialNumbers.add(trialNum); %contains all the trial numbers for the epochs
            end
            for n=1:length(epochs)
                current = epochs(n);
                currentNums = current.getProperty('trialNumber');
                currentNum = currentNums(1);
                
                next = current.getNextEpoch();
                if ~ isempty(next)
                    nextNumbers = next.getProperty('trialNumber');
                    nextNumber = nextNumbers(1);
                    assert(nextNumber == currentNum + 1)
                else
                    assert( ~trialNumbers.contains(currentNum +1));
                end
            end
        end
        
        function testShouldUseTrialFunctionNameAsEpochProtocolID(self)
            epochs = self.epochGroup.getEpochs();
            for n=1:length(epochs)
                assertTrue(epochs(n).getProtocolID().equals(java.lang.String(self.trialFunctionName)));
            end
        end
        
        function testShouldUseTrialFunctionNameAsEpochGroupLabel(self)
            
            assertTrue(self.epochGroup.getLabel().equals(java.lang.String(self.trialFunctionName)));
            
        end
        
        function testShouldAttachPDSAsResource(self)
            [~, pdsName, ext] = fileparts(self.pdsFile);
            assertTrue( ~isempty(self.epochGroup.getResource([pdsName ext])));
        end
        
        function testEpochShouldHaveProperties(self)
             epochs = self.epochGroup.getEpochs();
            for n=1:length(epochs)
                props = epochs(n).getProperties().keySet();
                assertTrue(props.contains('datapixxtime'));
                assertTrue(props.contains('uniqueNumber'));
                assertTrue(props.contains('uniqueNumberString'));
                assertTrue(props.contains('trialNumber'));
                assertTrue(props.contains('goodTrial'));
                assertTrue(props.contains('coherence'));
                assertTrue(props.contains('chooseRF'));
                assertTrue(props.contains('timeOfChoice'));
                assertTrue(props.contains('timeOfReward'));
                assertTrue(props.contains('timeBrokeFixation'));
                assertTrue(props.contains('correct'));
                                
            end
        end
        
         function testEpochShouldHaveResponses(self)
             epochs = self.epochGroup.getEpochs();
            for n=1:length(epochs)
                %todo getResponse and stimulus stuff
                assertTrue(false);
                                
            end
        end
                
        function testEpochGroupShouldHavePDSStartTime(self)
            import ovation.*;
            fileStruct = load(self.pdsFile, '-mat');
            pds = fileStruct.PDS;
            
            idx = find(pds.unique_number(:,1) ~= -1);
            unum = pds.unique_number(idx(1),:);
            first_duration = pds.eyepos{idx(1)}(end,3);
            
            endTime = datetime(unum(1), unum(2), unum(3), unum(4), unum(5), unum(6), 0, self.timezone);
            startTime = endTime.minusMillis(first_duration * 1000);
            
            assertTrue(self.epochGroup.getStartTime().equals(startTime));
            
        end
        
        function testEpochGroupShouldHavePDSEndTime(self)
                        import ovation.*;
            fileStruct = load(self.pdsFile, '-mat');
            pds = fileStruct.PDS;
            
            idx = find(pds.unique_number(:,1) ~= -1);
            unum = pds.unique_number(idx(end),:);
            
            endTime = datetime(unum(1), unum(2), unum(3), unum(4), unum(5), unum(6), 0, self.timezone);
            
            assertTrue(self.epochGroup.getEndTime().equals(endTime));
        end
    end
end