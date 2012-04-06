classdef TestPLXImport < TestPldapsBase
    
    properties
        plx
        drNameSuffix
        epochGroup
    end
    
    methods
        function self = TestPLXImport(name)
            self = self@TestPldapsBase(name);
            
            import ovation.*;

            
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
        
        % The PLX import should
        %  - import spike data to existing Epochs
        %    - with spike times t0 <= ts < end_trial
        %    - the same number of wave forms as spike times
        
        function testShouldAppendPLXFile(self)
            self.assertFileResource(self.epochGroup, self.plxRawFile);
        end
        
        function testShouldAppendEXPFile(self)
            self.assertFileResource(self.epochGroup, self.plxExpFile);
        end
        
        function assertFileResource(~, target, name)
            [~,name,ext]=fileparts(name);
            name = [name ext];
            names = target.getResourceNames();
            found = false;
            for i = 1:length(names)
                if(names(i).equals(name))
                    found = true;
                end
            end
            
            assertTrue(found);
        end
        
        function testFindEpochGivesNullForNullEpochGroup(~)
            assertTrue(isempty(findEpochByUniqueNumber([], [1,2])));
        end
        
        function testGivesEmptyForNoMatchingEpochByUniqueNumber(self)
            assertTrue(isempty(findEpochByUniqueNumber(self.epochGroup, [1,2,3,4,5,6])));
        end
        
        function testFindsMatchingEpochFromUniqueNumber(self)
            
            for i = 1:size(self.plx.unique_number, 1)
                unum = self.plx.unique_number(i,:);
                
                epoch = findEpochByUniqueNumber(self.epochGroup, unum);
                if(isempty(epoch))
                    continue;
                end
                epochUnum = epoch.getOwnerProperty('uniqueNumber').getIntegerData()';
                assertTrue(all(mod(epochUnum, 256) == unum));
            end
        end
        
        function testShouldAssignSpikeTimesToSpanningEpoch(self)
           % Spikes in plx.wave_ts should be assigned to the Epoch in which they occurred
        
           [maxChannels,maxUnits] = size(self.plx.wave_ts);
           
           epochs = self.epochGroup.getEpochs(); %sorted in time
           epoch = epochs(1);
           durationTotalSeconds = 0;
           while(~isempty(epoch))
               for c = 2:maxChannels % Row 1 is unsorted
                   for u = 2:maxUnits % Col 1 in unsorted
                       spikeTimes = self.plx.wave_ts{c,u};
                       
                       epochSpikeTimes = spikeTimes(spikeTimes > durationTotalSeconds & ...
                           spikeTimes < (durationTotalSeconds + epoch.getDuration()));
                       
                       % assume there's only one DR
                       drName = ['spikeTimes_channel_' num2str(c-1)...
                           '_unit_' num2str(u-1) ...
                           self.drNameSuffix '-1'];
                       
                       derivedResponses = epoch.getDerivedResponses(drName);
                       for d = 1:length(derivedResponses)
                           dr = derivedResponses(d);
                           actualSpikeTimes = dr.getFloatingPointData();
                           assertElementsAlmostEqual(actualSpikeTimes, epochSpikeTimes,...
                               'absolute',...
                               1e-9); %nanosecond precision
                           assertTrue(min(actualSpikeTimes) >= 0);
                           assertTrue(max(actualSpikeTimes) < epoch.getDuration());
                       end
                   end
               end
               
               durationTotalSeconds = durationTotalSeconds + epoch.getDuration();
               epoch = epoch.getNextEpoch();
           end
               
        end
        
        
        function testShouldHaveSpikeWaveformsForEachUnit(self)
            % Spikes in plx.wave_ts should be assigned to the Epoch in which they occurred
        
           [maxChannels,maxUnits] = size(self.plx.wave_ts);
           
           epochs = self.epochGroup.getEpochs(); %sorted in time
           epoch = epochs(1);
           durationTotalSeconds = 0;
           while(~isempty(epoch))
               for c = 2:maxChannels % Row 1 is unsorted
                   for u = 2:maxUnits % Col 1 in unsorted
                       spikeTimes = self.plx.wave_ts{c,u};
                       
                       spike_idx = spikeTimes > durationTotalSeconds & ...
                           spikeTimes < (durationTotalSeconds + epoch.getDuration());
                       
                       % assume there's only one DR
                       drName = ['spikeWaveforms_channel_' num2str(c-1)...
                           '_unit_' num2str(u-1) ...
                           self.drNameSuffix '-1'];
                       
                       derivedResponses = epoch.getDerivedResponses(drName);
                       for d = 1:length(derivedResponses)
                           dr = derivedResponses(d);
                           
                           waveforms = reshape(dr.getFloatingPointData(), dr.getShape()');
                           
                           % Should have same number of waveforms as spike
                           % times
                           assertEqual(length(spike_idx), size(waveforms, 1));
                       end
                   end
               end
               
               durationTotalSeconds = durationTotalSeconds + epoch.getDuration();
               epoch = epoch.getNextEpoch();
           end
        end
        
    end
end