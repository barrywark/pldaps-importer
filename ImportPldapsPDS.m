function epochGroup = ImportPldapsPDS(experiment,...
                                      animal,...
                                      pdsfile,...
                                      timezone,...
                                      ntrials)
    % Import PL-DA-PS PDS structural data into an Ovation Experiment
    %
    %    epochGroup = ImportPladpsPDS(experiment, animal, pdsfile, timezone)
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
    if(nargin < 5)
        ntrials = [];
    end
    
    
    %validate(); -makes sure the properties have the right length, etc
    pdsFileStruct = load('-mat', pdsfile);
    pds = pdsFileStruct.PDS;
    displayVariables = pdsFileStruct.dv;
    
    [~, trialFunction, ~] = fileparts(pdsfile);
    
    
    % External devices
    devices.psychToolbox = experiment.externalDevice('PsychToolbox', 'Huk lab');
    devices.psychToolbox.addProperty('psychtoolbox version', '3.0.8');
    devices.psychToolbox.addProperty('matlab version', 'R2009a 32bit');
    devices.datapixx = experiment.externalDevice('DataPixx', 'VPixx Technologies');
    devices.monitor = experiment.externalDevice('Monitor LH 1080p', 'LG');
    devices.monitor.addProperty('resolution', NumericData([1920, 1080]));
    devices.eye_tracker = experiment.externalDevice('Eye Trac 6000', 'ASL');
    devices.eye_tracker_timer = experiment.externalDevice('Windows', 'Microsoft');
    
    % generate the start and end times for each epoch, from the unique_number and
    % timezone
    
    firstEpochIdx = pds.datapixxstarttime == min(pds.datapixxstarttime);
    firstEpochStart = uniqueNumberToDateTime(pds.unique_number(firstEpochIdx,:),...
        timezone.getID());
    
    firstEpochDatapixxStart = pds.datapixxstarttime(firstEpochIdx);
    
    lastEpochIdx = pds.datapixxstoptime == max(pds.datapixxstoptime);
    lastEpochDatapixxEnd = pds.datapixxstoptime(lastEpochIdx);
    lastEpochEnd = firstEpochStart.plusMillis(...
        1000 * (lastEpochDatapixxEnd - firstEpochDatapixxStart)...
        );
    
    
    %% Insert one epochGroup per PDS file
    epochGroup = experiment.insertEpochGroup(animal,...
        trialFunction, ...
        firstEpochStart,...
        lastEpochEnd);
    
    % Convert DV paired cells to a struct
    displayVariables.bits = cell2struct(displayVariables.bits(:,2)',...
        num2cell(strcat('bit_', num2str(cell2mat(displayVariables.bits(:,1)))), 2)',...
        2);
    
    insertEpochs(epochGroup,...
        trialFunction,...
        pds,...
        repmat(displayVariables,length(pds.unique_number),1),...
        devices,...
        ntrials); %TODO dv should be a struct array, but we're faking it
    
end

function insertEpochs(epochGroup, protocolID, pds, parameters, devices, ntrials)
    import ovation.*;
    
    if(isempty(ntrials))
        ntrials = length(pds);
    end
    
    disp('Importing Epochs...');
    previousEpoch = [];
    for n=1:ntrials
        if(mod(n,5) == 0)
            disp(['    ' num2str(n) ' of ' num2str(ntrials) '...']);
        end
        
        
        dataPixxStart = pds.datapixxstarttime(n);
        dataPixxEnd = pds.datapixxstoptime(n);
        
        %TODO check inter-trial interval
        
        protocol_parameters = parameters(n);
        protocol_parameters.target1_XY_deg_visual_angle = pds.targ1XY(n);
        protocol_parameters.target2_XY_deg_visual_angle = pds.targ2XY(n);
        protocol_parameters.coherence = pds.coherence(n);
        if(isfield(pds, 'fp2XY'))
            protocol_parameters.fp2_XY_deg_visual_angle = pds.fp2XY(n);
        end
        protocol_parameters.inReceptiveField = pds.inRF(n);
        
        
        
        epoch = epochGroup.insertEpoch(epochGroup.getStartTime().plusMillis(dataPixxStart * 1000),...
            epochGroup.getStartTime().plusMillis(dataPixxEnd * 1000),...
            protocolID,...
            struct2map(protocol_parameters));
        
        epoch.addProperty('dataPixxStart_seconds', pds.datapixxstarttime(n));
        epoch.addProperty('dataPixxStop_seconds', pds.datapixxstoptime(n));
        epoch.addProperty('uniqueNumber', NumericData(int32(pds.unique_number(n,:))));
        epoch.addProperty('uniqueNumberString', num2str(pds.unique_number(n,:)));
        epoch.addProperty('trialNumber', pds.trialnumber(n));
        epoch.addProperty('goodTrial', pds.goodtrial(n));
        
        % These are more like DerivedResponses...
        epoch.addProperty('coherence', pds.coherence(n)); % TODO Is this a protocol parameter?
        epoch.addProperty('chooseRF', pds.chooseRF(n));
        epoch.addProperty('timeOfChoice', pds.timechoice(n));
        epoch.addProperty('timeOfReward', pds.timereward(n));
        epoch.addProperty('timeBrokeFixation', pds.timebrokefix(n));
        epoch.addProperty('correct', pds.correct(n));
        
        previousEpoch = setPreviousEpoch(epoch, previousEpoch);
        
        addResponseAndStimulus(epoch, protocolID, pds.eyepos{n}, parameters(n), devices, n);       
        
        if(isnan(pds.fp1off(n)))
            fp1offTime = epoch.getEndTime();
        else
            fp1offTime = epoch.getStartTime().plusSeconds(pds.fp1off(n));
        end
        
        epoch.addTimelineAnnotation('fixation point 1 on',...
            'fixationPoint1',...
            epoch.getStartTime().plusSeconds(pds.fp1on(n)),...
            fp1offTime);
        epoch.addTimelineAnnotation('fixation point 1 entered',...
            'fixationPoint1',...
            epoch.getStartTime().plusSeconds(pds.fp1entered(n)));
        
        if(pds.timebrokefix(n) > 0)
            epoch.addTimelineAnnotation('time broke fixation',...
                'fixation',...
                epoch.getStartTime().plusSeconds(pds.timebrokefix(n)));
        end
        
        
        epoch.addTimelineAnnotation('fixation point 2 off',...
            'fixationPoint2',...
            epoch.getStartTime().plusSeconds(pds.fp2off(n)));
        if(pds.targoff(n) > 0)
            epoch.addTimelineAnnotation('target on',...
                'target',...
                epoch.getStartTime().plusSeconds(pds.targon(n)),...
                epoch.getStartTime().plusSeconds(pds.targoff(n)));
        else
            
            epoch.addTimelineAnnotation('target on',...
                'target',...
                epoch.getStartTime().plusSeconds(pds.targon(n)));
        end
        epoch.addTimelineAnnotation('dots on',...
            'dots',...
            epoch.getStartTime().plusSeconds(pds.dotson(n)),...
            epoch.getStartTime().plusSeconds(pds.dotsoff(n)));
        epoch.addTimelineAnnotation('time of choice',...
            'choice',...
            epoch.getStartTime().plusSeconds(pds.timechoice(n)));
        epoch.addTimelineAnnotation('time of reward',...
            'reward',...
            epoch.getStartTime().plusSeconds(pds.timereward(n)));
        
    end
end

function previousEpoch = setPreviousEpoch(epoch, previousEpoch)
    if (~ isempty(previousEpoch) )
        if (previousEpoch.getMyProperty('trialNumber') +1) == epoch.getMyProperty('trialNumber')
            epoch.setPreviousEpoch(previousEpoch);
        end
    end
    
    previousEpoch = epoch;
    
end

function addResponseAndStimulus(epoch, trialFunction, eye_position_data, dv, devices, epochNumber)
    import ovation.*;
    
    
    stimulusDeviceParams = struct2map(dv); % TODO divide the c1 file into device parameters
    stimulusParameters = struct2map(dv); % and stimulus parameters
    
    dimensionLabels{1} = 'time';
    dimensionLabels{2} = 'X-Y';
    
    samplingRateUnits{1} = 'Hz';
    samplingRateUnits{2} = 'N/A';
    
	% eye_position_data(:,3) are sample times in seconds. We estimate a
	% single sample rate for eye position data by taking the reciprocal of
	% the median inter-sample difference.
    sampling_rate = 1 / median(diff(eye_position_data(:,3)));
    
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
        'edu.utexas.huk.eye_position'); %TODO should be numeric data UTI
    
    data = NumericData(eye_position_data(:,3));
    epoch.insertResponse(devices.eye_tracker_timer,...
        [],...
        data,...
        's',...
        'time',...
        1,...
        'N/A',...
        'edu.utexas.huk.eye_position_sample_time'); % TODO should be numeric data UTI?
    
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
