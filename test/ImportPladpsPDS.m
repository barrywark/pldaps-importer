function epochGroup = ImportPladpsPDS(experiment, animal, pdsfile, trialFunction, timezone)
    
    %validate(); -makes sure the properties have the right length, etc
    files = load('-mat', pdsfile);
    pds = files.PDS;
    c1 = files.c1;
    
    psychToolbox = experiment.insertExternalDevice('PsychToolbox', 'Huk lab');
    datapixx = experiment.insertExternalDevice('DataPixx', 'FIXME');% what to do here
    plexon = experiment.insertExternalDevice('Plexon', 'FIXME');
    eye_tracker = experiment.insertExternalDevice('FIXME', 'FIXME'); % TODO
    eye_tracker_timer = experiment.insertExternalDevice('FIXME2', 'FIXME2'); %TODO
    
    % generate the start and end times for each epoch, from the unique_number and
    % timezone
    d = pds.eyepos{1}';
    durations = d(3, :)';
    [times, idx] = GenerateStartAndEndTimes(int8(pds.unique_number), durations, timezone);
    
    %% Insert one epochGroup per PDS file
    epochGroup = experiment.insertEpochGroup(animal, pdsfile, times{1}.starttime, times{end}.endtime);
    epochs = insertEpochs(idx, epochGroup, trialFunction, times, repmat(c1,length(pds.unique_number),1)); %c1 should be a struct array, but we're faking it
        
    function insertEpochs(idx, epochGroup, protocolID, times, parameters)
        
        previousEpoch = [];
        for n=1:length(times)
            protocol_parameters = parameters(idx(n));
            protocol_parameters.target1_XY_deg_visual_angle = pds.targ1XY(idx(n));
            protocol_parameters.target2_XY_deg_visual_angle = pds.targ2XY(idx(n));
            protocol_parameters.coherence = pds.coherence(idx(n));
            protocol_parameters.fp2_XY_deg_visual_angle = pds.fp2XY(idx(n)); %is there an fp1XY and an fp2on?
            protocol_parameters.inReceptiveField = pds.inRF(idx(n));
                        
            epoch = epochGroup.insertEpoch(times{n}.starttime,...
                                           times{n}.endtime,...
                                           protocolID,...
                                           struct2map(protocol_parameters));
            
            epoch.addProperty('datapixxtime', pds.datapixxtime(idx(n))); % we may not need this
            epoch.addProperty('uniqueNumber', pds.unique_number(idx(n))); % maybe make an integer out of this array?
            epoch.addProperty('trialNumber', pds.trialnumber(idx(n)));
            epoch.addProperty('goodTrial', pds.goodtrial(idx(n))); % -1 for bad trials

            % These are more like DerivedResponses...
            epoch.addProperty('coherence', pds.coherence(idx(n)));
            epoch.addProperty('chooseRF', pds.chooseRF(idx(n))); % add additional information as to right/left?
            epoch.addProperty('timeOfChoice', pds.timechoice(idx(n)));
            epoch.addProperty('timeOfReward', pds.timereward(idx(n)));
            epoch.addProperty('timeBrokeFixation', pds.timebrokefix(idx(n)));
            epoch.addProperty('correct', pds.correct(idx(n))); % should be a tag
            
            previousEpoch = setPreviousEpoch(previousEpoch, n);
            
            addResponseAndStimulus(epoch, pds.eyepos{idx(n)});
            
            
            epoch.addTimelineAnnotation('fixation point 1 on',...
                                        'fixationPoint1',...
                                        epoch.getStartTime().plusSeconds(pds.fp1on(idx(n))),...
                                        epoch.getStartTime().plusSeconds(pds.fp1off(idx(n))));
            epoch.addTimelineAnnotation('fixation point 1 entered',...
                                        'fixation',...
                                        epoch.getStartTime().plusSeconds(pds.fp1entered(idx(n))),...
                                        epoch.getStartTime().plusSeconds(pds.timebrokefix(idx(n))));
            epoch.addTimelineAnnotation('fixation point 2 off',...
                                        'fixationPoint2',...
                                        epoch.getStartTime().plusSeconds(pds.fp2off(idx(n))));
            epoch.addTimelineAnnotation('target on',...
                                        'target',...
                                        epoch.getStartTime().plusSeconds(pds.targon(idx(n))),...
                                        epoch.getStartTime().plusSeconds(pds.targoff(idx(n))));
            epoch.addTimelineAnnotation('dots on',...
                                        'dots',... 
                                        epoch.getStartTime().plusSeconds(pds.dotson(idx(n))),...
                                        epoch.getStartTime().plusSeconds(pds.dotsoff(idx(n))));
            epoch.addTimelineAnnotation('time of choice',...
                                        'choice',...
                                        epoch.getStartTime().plusSeconds(pds.timechoice(idx(n))));
            epoch.addTimelineAnnotation('time of reward',...
                                        'reward',...
                                        epoch.getStartTime().plusSeconds(pds.timereward(idx(n))));
        end
    end

    function previousEpoch = setPreviousEpoch(previousEpoch, n)
        if (~ isempty(previousEpoch))
            epoch.setPrevious(previousEpoch);
        end
        if (n>1 && (pds.trialnumber(n-1) + 1) == pds.trialnumber(n))
            previousEpoch = epoch;
        else
            previousEpoch = [];
        end
    end
    
    function addResponseAndStimulus(epoch, eye_position_data)
        
        stimulusDeviceParams = struct2map(c1); % which of these are also stimulus params?
        responseDeviceParams = struct2map(c1); % which of these are also response params?
        
        dimensionLabels{1} = 'time';
        dimensionLabels{2} = 'X-Y';
        
        samplingRateUnits{1} = 'Hz';
        samplingRateUnits{2} = 'N/A';
        
        sampling_rate = (length(eye_position_data) -1)/(eye_position_data(3, end) - eye_position_data(3, 1));% how to do sampling rate calculation
        
        epoch.insertStimulus(psychToolbox,...
                            stimulusDeviceParams,...
                            ['edu.utexas.huk.pladapus.' trialFunction],...
                            trialFunctionParams,... 
                            'pixels',... 
                            dimensionLabels);
                        
        data = NumericData(reshape(eye_position_data(:,1:2),1, numel(eye_position_data(:,1:2))),...
                                    size(eye_position_data(:,1:2)));
        
        epoch.insertResponse(eye_tracker,...
                            responseDeviceParams,...
                            data,...
                            'pixels',... % what units are the eye 
                            dimensionLabels,...
                            [sampling_rate, 1],...
                            samplingRateUnits,...
                            'edu.utexas.huk.eye_position');
                        
        data = NumericData(eye_position_data(:,3));
        epoch.insertResponse(eye_tracker_timer,...
            responseDeviceParams,...
            data,...
            's',...
            'time',...
            1,...
            'N/A',...
            'edu.utexas.huk.eye_position_sample_time');
        
        % Ditto for columns 4,5, and 6
        % Units? Labels? ... 
        
    end
end