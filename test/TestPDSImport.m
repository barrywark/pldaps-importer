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
            import org.joda.time.*;
           
            % N.B. these value should match those in runtestsuite
            self.pdsFile = 'fixtures/ovationtest032712revcodots1440.PDS';
            self.plxFile = 'fixtures/fixtures/ovationtest032712revcodots1440.mat';
            self.trialFunctionName = 'ovationtest032712revcodots1440';
            self.timezone = DateTimeZone.forID('US/Central');
            
            
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
        %  - should have PDS start time (min unique number)
        %  - should have PDS start time + last datapixxendtime seconds
        %  - should have original plx file attached as Resource
        %  - should have PLX exp file attached as Resource
        % For each Epoch
        %  - should have trial function name as protocol ID
        %  - should have protocol parameters from dv, PDS
        %  - should have start and end time defined by datapixx
        %  - should have sequential time with prev/next 
        %  - should have next/pre
        %    - intertrial Epochs should interpolate
        %  - should have approparite stimuli and responses
        % For each stimulus
        %  x should have correct plugin ID (TBD)
        %  x should have event times (+ other?) stimulus parameters
        % For each response
        %  - should have numeric data from PDS

        
        function testEpochsShouldHaveNextPrevLinks(self)
            
            epochs = self.epochGroup.getEpochs();
            
            for i = 1:length(epochs)
                prev = epochs(i).getPreviousEpoch();
                assert(~isempty(prev));
                if(strfind(epochs(i).getProtocolID(), 'intertrial'))
                    assertFalse(strfind(prev.getProtocolID(),'intertrial'));
                    assertFalse(isempty(prev.getOwnerProperty('trialNumber')));
                else
                    assertTrue(strfind(prev.getProtocolID(),'intertrial'));
                end
                
            end
        end
        
        function testEpochShouldHaveDVParameters(self)
            import ovation.*;
            fileStruct = load(self.pdsFile, '-mat');
            dv = fileStruct.dv;
            
            % Convert DV paired cells to a struct
            dv.bits = cell2struct(dv.bits(:,2)',...
                num2cell(strcat('bit_', num2str(cell2mat(dv.bits(:,1)))), 2)',...
                2);
            
            dvMap = ovation.struct2map(dv);
            epochsItr = self.epochGroup.getEpochsIterable().iterator();
            while(epochsItr.hasNext())
                epoch = epochsItr.next();
                keyItr = dvMap.keySet().iterator();
                while(keyItr.hasNext())
                    key = keyItr.next();
                    if(isempty(dvMap.get(key)))
                        continue;
                    end
                    if(isjava(dvMap.get(key)))
                        assertJavaEqual(dvMap.get(key),...
                            epoch.getProtocolParameter(key));
                    else
                        assertEqual(dvMap.get(key),...
                            epoch.getProtocolParameter(key));
                    end
                end
            end
        end
        
        function testEpochShouldHavePDSProtocolParameters(self)
            import ovation.*;
            fileStruct = load(self.pdsFile, '-mat');
            pds = fileStruct.PDS;
            
            
            epochsItr = self.epochGroup.getEpochsIterable().iterator();
            i = 1;
            while(epochsItr.hasNext())
                epoch = epochsItr.next();
                assertEqual(pds.targ1XY(i),...
                    epoch.getProtocolParameter('target1_XY_deg_visual_angle'));
                assertEqual(pds.targ2XY(i),...
                    epoch.getProtocolParameter('target2_XY_deg_visual_angle'));
                assertEqual(pds.coherence(i),...
                    epoch.getProtocolParameter('coherence'));
                if(isfield(pds, 'fp2XY'))
                    assertEqual(pds.fp2XY(i),...
                        epoch.getProtocolParameter('fp2_XY_deg_visual_angle'));
                end
                assertEqual(pds.inRF(i),...
                    epoch.getProtocolParameter('inReceptiveField'));
            end
        end
        
        function testEpochsShouldBeSequentialInTime(self)
            epochs = self.epochGroup.getEpochs();
            
            for i = 2:length(epochs)
                assertJavaEqual(epochs(i).getPreviousEpoch(),...
                    epochs(i-1));
            end
        end
               
        function testEpochStartAndEndTimeShouldBeDeterminedByDataPixxTime(self)
            import ovation.*;
            fileStruct = load(self.pdsFile, '-mat');
            pds = fileStruct.PDS;
            
            epochs = self.epochGroup.getEpochs();
            
            j = 1;
            for i = 1:length(epochs)
                epoch = epochs(i);
                if(strcmp(char(epoch.getProtocolID()), 'intertrial'))
                    assertJavaEqual(epoch.getStartTime(),...
                        self.epochGroup.getStartTime.plusMillis(1000*pds.datapixxstoptime(j)));
                    assertJavaEqual(epoch.getEndTime(),...
                        self.epochGroup.getStartTime.plusMillis(1000*pds.datapixxstarttime(j+1)));
                else
                    assertJavaEqual(epoch.getStartTime(),...
                        self.epochGroup.getStartTime.plusMillis(1000*pds.datapixxstarttime(j)));
                    assertJavaEqual(epoch.getEndTime(),...
                        self.epochGroup.getStartTime.plusMillis(1000*pds.datapixxstoptime(j)));
                    j = j+1;
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
        
        function testShouldAttachPDSAsEpochGroupResource(self)
            [~, pdsName, ext] = fileparts(self.pdsFile);
            assertTrue( ~isempty(self.epochGroup.getResource([pdsName ext])));
        end
        
        function testEpochShouldHaveProperties(self)
             epochs = self.epochGroup.getEpochs();
            for n=1:length(epochs)
                props = epochs(n).getOwnerProperties().keySet();
                assertTrue(props.contains('dataPixxStart_seconds'));
                assertTrue(props.contains('dataPixxStop_seconds'));
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
        
        function testEpochShouldHaveResponseDataFromPDS(self)
            fileStruct = load(self.pdsFile, '-mat');
            pds = fileStruct.PDS;
            
            experiment = self.epochGroup.getExperiment();
            
            devices.eye_tracker = experiment.externalDevice('Eye Trac 6000', 'ASL');
            devices.eye_tracker_timer = experiment.externalDevice('Windows', 'Microsoft');
            
            epochs = self.epochGroup.getEpochs();
            for n=1:length(epochs)
                epoch = epochs(n);
                assertFalse(isempty(epoch.getResponse(devices.eye_tracker.getName())));
                
                r = epoch.getResponse(devices.eye_tracker.getName());
                rData = reshape(r.getFloatingPointData(),...
                    r.getShape()');
                
                assertElementsAlmostEqual(pds.eyepos{n}(:,1:2), rData);
                
                assertFalse(isempty(epoch.getResponse(devices.eye_tracker_timer.getName())));    
                r = epoch.getResponse(devices.eye_tracker_timer.getName());
                rData = r.getFloatingPointData();
                assertElementsAlmostEqual(pds.eyepos{n}(:,3), rData);
            end
        end
        
        function testEpochStimuliShouldHavePluginIDAndParameters(self)
            experiment = self.epochGroup.getExperiment();
            trialFunction = self.epochGroup.getLabel();
            pluginID = ['edu.utexas.huk.pladapus.' char(trialFunction)];
            
            fileStruct = load(self.pdsFile, '-mat');
            dv = fileStruct.dv;
            
            % Convert DV paired cells to a struct
            dv.bits = cell2struct(dv.bits(:,2)',...
                num2cell(strcat('bit_', num2str(cell2mat(dv.bits(:,1)))), 2)',...
                2);
            
            dvMap = ovation.struct2map(dv);
            
            devices.psychToolbox = experiment.externalDevice('PsychToolbox', 'Huk lab');

            epochs = self.epochGroup.getEpochs();
            for n=1:length(epochs)
                epoch = epochs(n);
                assertFalse(isempty(epoch.getStimulus(devices.psychToolbox.getName())));
                
            end
            
            epochsItr = self.epochGroup.getEpochsIterable().iterator();
            while(epochsItr.hasNext())
                epoch = epochsItr.next();
                s = epoch.getStimulus(devices.psychToolbox.getName());
                assertFalse(isempty(s));
                
                assertTrue(strcmp(pluginID, char(s.getPluginID())));
                
                keyItr = dvMap.keySet().iterator();
                while(keyItr.hasNext())
                    key = keyItr.next();
                    if(isempty(dvMap.get(key)))
                        continue;
                    end
                    if(isjava(dvMap.get(key)))
                        assertJavaEqual(dvMap.get(key),...
                            s.getStimulusParameter(key));
                        assertJavaEqual(dvMap.get(key),...
                            s.getDeviceParameters.get(key));
                    else
                        assertEqual(dvMap.get(key),...
                            s.getStimulusParameter(key));
                        assertEqual(dvMap.get(key),...
                            s.getDeviceParameters.get(key));
                    end
                end
            end
            
            
        end
                
        function testEpochGroupShouldHavePDSStartTime(self)
            import ovation.*;
            fileStruct = load(self.pdsFile, '-mat');
            pds = fileStruct.PDS;
            
            idx = find(pds.datapixxstarttime == min(pds.datapixxstarttime));
            unum = pds.unique_number(idx(1),:);
            
            startTime = datetime(unum(1), unum(2), unum(3), unum(4), unum(5), unum(6), 0, self.timezone.getID());
            
            
            assertJavaEqual(self.epochGroup.getStartTime(),...
                startTime);
            
        end
        
        function testEpochGroupShouldHavePDSEndTime(self)
            import ovation.*;
            
            fileStruct = load(self.pdsFile, '-mat');
            pds = fileStruct.PDS;
            
            totalDurationSeconds = max(pds.datapixxstoptime) - min(pds.datapixxstarttime);
            
            assertJavaEqual(self.epochGroup.getEndTime(),...
                self.epochGroup.getStartTime().plusMillis(1000*totalDurationSeconds));
        end
    end
end