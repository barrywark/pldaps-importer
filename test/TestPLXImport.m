classdef TestPLXImport < TestPldapsBase
    
    properties
        pdsFile
        plxFile
        epochGroup
        trialFunctionName
        timezone
        plx
        drNameSuffix
    end
    
    methods
        function self = TestPLXImport(name)
            self = self@TestPldapsBase(name);
            
            import ovation.*;
            
            % N.B. these value should match those in runtestsuite
            self.pdsFile = 'fixtures/pat120811a_decision2_16.PDS';
            self.plxFile = 'fixtures/pat120811a_decision2_1600matlabfriendlyPLX.mat';
            self.trialFunctionName = 'trial_function_name';
            self.timezone = 'America/New_York';
            
            expModificationDate = org.joda.time.DateTime(java.io.File(self.plxFile).lastModified());
            self.drNameSuffix = [num2str(expModificationDate.getYear()) '-' ...
                num2str(expModificationDate.getMonthOfYear()) '-'...
                num2str(expModificationDate.getDayOfMonth())];
            
            
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
            
            plxStruct = load(self.plxFile);
            self.plx = plxStruct.plx;
        end
        
        % These are for plx import
        %  - should have spike times t0 < ts <= end_trial
        %  - should have same number of wave forms
        
        
        function testFindEpochGivesNullForNullEpochGroup(~)
            assertTrue(isempty(findEpochByUniqueNumber([], [1,2])));
        end
        
        function testGivesEmptyForNoMatchingEpochByUniqueNumber(self)
            assertTrue(isempty(findEpochByUniqueNumber(self.epochGroup, [1,2,3,4,5,6])));
        end
        
        function testFindsMatchingEpochFromUniqueNumber(self)
            
            idx = find(self.plx.unique_number(:,1) ~= 0);
            
            unum = self.plx.unique_number(idx(1),:);
            
            epoch = findEpochByUniqueNumber(self.epochGroup, unum);
            assertFalse(isempty(epoch));
            epochUnum = epoch.getMyProperty('uniqueNumber').getIntegerData()';
            assertTrue(all(mod(epochUnum, 256) == unum));
        end
        
        function testShouldHaveSpikeTimesForEachUnit(self)
            epochs = self.epochGroup.getEpochsUnsorted();
            for i = 1:length(epochs)
                epoch = epochs(i);
                epochUniqueNumber = epoch.getMyProperty('uniqueNumber').getIntegerData()';
                plxUniqueNumber = mod(epochUniqueNumber, 256); % Yikes!
                
                plxIdx = self.plxIdxForUniqueNumber(plxUniqueNumber);
                
                if(isempty(plxIdx) || isempty(self.plx.spike_times{plxIdx}))
                    continue;
                end
                
                [maxChannels,maxUnits] = size(self.plx.spike_times{plxIdx});
                for c = 2:maxChannels % row 1 is unsorted
                    for u = 2:maxUnits % col 1 is unsorted
                        if(~isempty(self.plx.spike_times{plxIdx}{c,u}))
                            
                            % assume there's only DR
                            drName = ['spikeTimes_channel_' num2str(c-1)...
                                '_unit_' num2str(u-1) ...
                                self.drNameSuffix '-1'];
                            
                            dr = epoch.getMyDerivedResponse(drName);
                            if(~isempty(dr))
                                times = dr.getDoubleData();
                                assertTrue(all(diff(self.plx.spike_times{plxIdx}{c,u}, times) < 0.001));
                            end
                        end
                    end
                end
            end
        end
        
        function testDerivedResponsesHaveDerivationParamters(self)
            assertFalse(true);
        end
        
        function testShouldHaveSpikeWaveformsForEachUnit(self)
            epochs = self.epochGroup.getEpochsUnsorted();
            for i = 1:length(epochs)
                epoch = epochs(i);
                epochUniqueNumber = epoch.getMyProperty('uniqueNumber').getIntegerData()';
                plxUniqueNumber = mod(epochUniqueNumber, 256); % Yikes!
                
                plxIdx = self.plxIdxForUniqueNumber(plxUniqueNumber);
                
                if(isempty(plxIdx) || isempty(self.plx.spike_waveforms{plxIdx}))
                    continue;
                end
                
                [maxChannels,maxUnits] = size(self.plx.spike_waveforms{plxIdx});
                for c = 2:maxChannels % row 1 is unsorted
                    for u = 2:maxUnits % col 1 is unsorted
                        if(~isempty(self.plx.spike_waveforms{plxIdx}{c,u}))
                            
                            % Assume there's only one DR
                            drName = ['spikeWaveforms_channel_' num2str(c-1)...
                                '_unit_' num2str(u-1) ...
                                self.drNameSuffix '-1'];
                            
                            dr = epoch.getMyDerivedResponse(drName);
                            if(~isempty(dr))
                                waveForms = reshape(dr.getDoubleData(), dr.getShape());
                                assertTrue(all(diff(self.plx.spike_waveforms{plxIdx}{c,u}, waveForms) < 0.001));
                            end
                        end
                    end
                end
            end
        end
        
        function idx = plxIdxForUniqueNumber(self, unum)
            for i = 1:length(self.plx.unique_number)
                if(all(unum == self.plx.unique_number(i,:)))
                    idx = i;
                    return;
                end
            end
            
            idx = [];
        end
        
        function testSpikeTimeShouldBeInEpochTimeRange(self)
            
        end
        
        function testShouldHaveSameNumberOfSpikesAndWaveForms(self)
            
        end
    end
end