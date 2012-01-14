function epochGroup = ImportPladpsPDS(experiment,...
                                      animal,...
                                      pdsfile,...
                                      timezone,...
                                      ntrials)
    % Import PL-DA-PS PDS structural data into an Ovation Experiment
    %
    %    epochGroup = ImportPladpsPDS(context, experiment, animal, pdsfile, 
    %                                 trialFunction, timezone)
    %      context: context with which to find the experiment
    %
    %      experiment: ovation.Experiment or ovation.EpochGroup object. A
    %      new EpochGroup for this PDS data will be added to the given
    %      experiment.
    %
    %      animal: ovation.Source. The Source for the newly added
    %      EpochGroup.
    %
    %      pdsfile: path to .PDS file
    %
    %      timezone: name of the time zone (e.g. 'America/New_York') where
    %      the experiment was performed
    
    import ovation.*;
    
    nargchk(4, 5, nargin); %#ok<NCHKI>
    if(nargin < 4)
        ntrials = [];
    end
    
    
    %validate(); -makes sure the properties have the right length, etc
    pdsFileStruct = load('-mat', pdsfile);
    pds = pdsFileStruct.PDS;
    c1 = pdsFileStruct.c1;
    
    [~, trialFunction, ~] = fileparts(pdsfile);
    
    devices.psychToolbox = experiment.insertExternalDevice('PsychToolbox', 'Huk lab');
    devices.psychToolbox.addProperty('psychtoolbox version', '3.0.8');
    devices.psychToolbox.addProperty('matlab version', 'R2009a 32bit');
    devices.datapixx = experiment.insertExternalDevice('DataPixx', 'VPixx Technologies');
    devices.monitor = experiment.insertExternalDevice('Monitor LH 1080p', 'LG');
    devices.monitor.addProperty('resolution', NumericData([1920, 1080]));
    devices.eye_tracker = experiment.insertExternalDevice('Eye Trac 6000', 'ASL');
    devices.eye_tracker_timer = experiment.insertExternalDevice('Windows', 'Microsoft');
    
    % generate the start and end times for each epoch, from the unique_number and
    % timezone
    
    [times, idx] = generateStartAndEndTimes(pds.unique_number, pds.eyepos, timezone);
    
    %% Insert one epochGroup per PDS file
    epochGroup = experiment.insertEpochGroup(animal, trialFunction, times{1}.starttime, times{end}.endtime);
    insertEpochs(idx, epochGroup, trialFunction, pds, times, repmat(c1,length(pds.unique_number),1), devices, ntrials); %TODO c1 should be a struct array, but we're faking it
    
end

function insertEpochs(idx, epochGroup, protocolID, pds, times, parameters, devices, ntrials)
    import ovation.*;
    
    if(isempty(ntrials))
        ntrials = length(times);
    end
    
    disp('Importing Epochs...');
    previousEpoch = [];
    for n=1:ntrials
        if(mod(n,5) == 0)
            disp(['    ' num2str(n) ' of ' num2str(ntrials) '...']);
        end
        
        protocol_parameters = convertNumericDataInStruct(parameters(idx(n)));
        protocol_parameters.target1_XY_deg_visual_angle = pds.targ1XY(idx(n));
        protocol_parameters.target2_XY_deg_visual_angle = pds.targ2XY(idx(n));
        protocol_parameters.coherence = pds.coherence(idx(n));
        protocol_parameters.fp2_XY_deg_visual_angle = pds.fp2XY(idx(n));
        protocol_parameters.inReceptiveField = pds.inRF(idx(n));
        
        epoch = epochGroup.insertEpoch(times{n}.starttime,...
            times{n}.endtime,...
            protocolID,...
            struct2map(protocol_parameters));
        
        epoch.addProperty('datapixxtime', pds.datapixxtime(idx(n))); % we may not need this
        epoch.addProperty('uniqueNumber', NumericData(int32(pds.unique_number(idx(n),:))));
        epoch.addProperty('uniqueNumberString', num2str(pds.unique_number(idx(n),:)));
        epoch.addProperty('trialNumber', pds.trialnumber(idx(n)));
        epoch.addProperty('goodTrial', pds.goodtrial(idx(n)));
        
        % These are more like DerivedResponses...
        epoch.addProperty('coherence', pds.coherence(idx(n)));
        epoch.addProperty('chooseRF', pds.chooseRF(idx(n)));
        epoch.addProperty('timeOfChoice', pds.timechoice(idx(n)));
        epoch.addProperty('timeOfReward', pds.timereward(idx(n)));
        epoch.addProperty('timeBrokeFixation', pds.timebrokefix(idx(n)));
        epoch.addProperty('correct', pds.correct(idx(n))); 
        
        previousEpoch = setPreviousEpoch(epoch, previousEpoch, pds, n);
        
        addResponseAndStimulus(epoch, protocolID, pds.eyepos{idx(n)}, parameters(idx(n)), devices, n);       
        
        epoch.addTimelineAnnotation('fixation point 1 on',...
            'fixationPoint1',...
            epoch.getStartTime().plusSeconds(pds.fp1on(idx(n))),...
            epoch.getStartTime().plusSeconds(pds.fp1off(idx(n))));
        epoch.addTimelineAnnotation('fixation point 1 entered',...
            'fixationPoint1',...
            epoch.getStartTime().plusSeconds(pds.fp1entered(idx(n))));
        
        if(pds.timebrokefix(idx(n)) > 0)
            epoch.addTimelineAnnotation('time broke fixation',...
                'fixation',...
                epoch.getStartTime().plusSeconds(pds.timebrokefix(idx(n))));
        end
        epoch.addTimelineAnnotation('fixation point 2 off',...
            'fixationPoint2',...
            epoch.getStartTime().plusSeconds(pds.fp2off(idx(n))));
        if(pds.targoff(idx(n)) > 0)
            epoch.addTimelineAnnotation('target on',...
                'target',...
                epoch.getStartTime().plusSeconds(pds.targon(idx(n))),...
                epoch.getStartTime().plusSeconds(pds.targoff(idx(n))));
        else
            
            epoch.addTimelineAnnotation('target on',...
                'target',...
                epoch.getStartTime().plusSeconds(pds.targon(idx(n))));
        end
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

function previousEpoch = setPreviousEpoch(epoch, previousEpoch, pds, n)
    if (~ isempty(previousEpoch) )
        if (previousEpoch.getMyProperty('trialNumber') +1) == epoch.getMyProperty('trialNumber')
            epoch.setPreviousEpoch(previousEpoch);
        end
    end
    
    previousEpoch = epoch;
    
end

function addResponseAndStimulus(epoch, trialFunction, eye_position_data, c1, devices, epochNumber)
    import ovation.*;
    
    stimulusDeviceParams = struct2map(convertNumericDataInStruct(c1)); % divide the c1 file into device parameters
    stimulusParameters = struct2map(convertNumericDataInStruct(c1)); % and stimulus parameters
    
    dimensionLabels{1} = 'time';
    dimensionLabels{2} = 'X-Y';
    
    samplingRateUnits{1} = 'Hz';
    samplingRateUnits{2} = 'N/A';
    
    sampling_rate = (length(eye_position_data) -1)/(eye_position_data(end, 3) - eye_position_data(1, 3));
    
    epoch.insertStimulus(devices.psychToolbox,...
        stimulusDeviceParams,...
        ['edu.utexas.huk.pladapus.' trialFunction],...
        stimulusParameters,...
        'degrees of visual angle',... 
        []);
    
    data = NumericData(reshape(eye_position_data(:,1:2),1, numel(eye_position_data(:,1:2))),...
        size(eye_position_data(:,1:2)));
    
    epoch.insertResponse(devices.eye_tracker,...
        [],...
        data,...
        'degrees of visual angle',...
        dimensionLabels,...
        [sampling_rate, 1],...
        samplingRateUnits,...
        'edu.utexas.huk.eye_position');
    
    data = NumericData(eye_position_data(:,3));
    epoch.insertResponse(devices.eye_tracker_timer,...
        [],...
        data,...
        's',...
        'time',...
        1,...
        'N/A',...
        'edu.utexas.huk.eye_position_sample_time');
    
    data = NumericData(eye_position_data(:,4));
    derivationParameters = struct(); %TODO: add derivation parameters, if any
    epoch.insertDerivedResponse(['State measurements ' epochNumber],...
        data,...
        'N/A',...
        struct2map(derivationParameters),...
        'state');
            
    % Ditto for columns 5, and 6
    % Units? Labels? ...
    
end