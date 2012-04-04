function ImportPLX(epochGroup, plxFile, plxRawFile, expFile, varargin)
    % Import Plexon data into an existing PL-DA-PS PDS EpochGroup
    %
    %    ImportPLX(epochGroup, plxFile, plxRawFile, expFile)
    %
    %      epochGroup: ovation.EpochGroup containing Epochs matching Plexon
    %      data.
    %
    %      plxFile: Path to a Matlab .mat file produced by plx2mat from a Plexon .plx
    %      file.
    %
    %      plxRawFile: Path to .plx file from wich plxFile was generated.
    
    nargchk(4, 6, nargin); %#ok<NCHKI>
    if(nargin < 6)
        ntrials = [];
    else
        ntrials = varargin{1};
    end
    
    import ovation.*
    
    plxStruct = load('-mat', plxFile);
    plx = plxStruct.plx;
    
    expModificationDate = org.joda.time.DateTime(...
        java.io.File(plxRawFile).lastModified());
    drSuffix = [num2str(expModificationDate.getYear()) '-' ...
        num2str(expModificationDate.getMonthOfYear()) '-'...
        num2str(expModificationDate.getDayOfMonth())];
    
    lines = ovation.util.read_lines(expFile);
    expTxt = lines{1};
    for i = 2:length(lines)
        expTxt = sprintf('%s\n%s', expTxt, lines{i});
    end
    derivationParameters.expFileContents = expTxt;
    
    derivationParameters = struct2map(derivationParameters);
    
    disp('Calculating PLX-PDS unique number mapping...');
    epochCache.uniqueNumber = java.util.HashMap();
    epochCache.truncatedUniqueNumber = java.util.HashMap();
    epochs = epochGroup.getEpochsUnsorted();
    for i = 1:length(epochs)
        if(mod(i,5) == 0)
            disp(['    Epoch ' num2str(i) ' of ' num2str(length(epochs))]);
        end
        
        epoch = epochs(i);
        epochUniqueNumber = epoch.getOwnerProperty('uniqueNumber');
        if(~isempty(epochUniqueNumber))
            epochUniqueNumber = epochUniqueNumber.getIntegerData()';
        end
        
        epochCache.uniqueNumber.put(num2str(epochUniqueNumber), epoch);
        epochCache.truncatedUniqueNumber.put(num2str(mod(epochUniqueNumber,256)),...
            epoch);
    end
    
    disp('Importing PLX data...');
    
    % NB: Currently ignoring spikes before first epoch start
    end_times = plx.ts{7}(2:2:end);
    start_times = plx.ts{7}(1:2:end);
    if(numel(end_times) ~= numel(start_times))
        error('ovation:import:plx:epoch_boundary',...
            'Bit 7 events do not form Epoch boundary pairs');
    end
    if(abs(numel(end_times) - numel(plx.strobe_times)) > 1)
        error('ovation:import:plx:epoch_boundary',...
            'End-trial and strobe_time events are not paired');
    end
    
    [maxChannels,maxUnits] = size(plx.wave_ts);
    
    for i = 1:length(plx.strobe_times)
        if(mod(i,5) == 0)
            disp(['    Epoch ' num2str(i) ' of ' num2str(length(idx))]);
        end
        
        % Find epoch
        epoch = findEpochByUniqueNumber(epochGroup,...
            plx.unique_number(idx(i),:),...
            epochCache);
        if(isempty(epoch))
            error('ovation:import:plx:unique_number',...
                'Unable to align PLX data: PLX data contains a unique number not present in the epoch group');
        end
        
        % Epoch spikes are strobe_time to end_time
        
        % Add Epoch spike times and waveforms
        start_time = plx.strobe_times(i); % Or use start_times
        end_time = end_times(i);
        insertSpikeDerivedResponses(epoch, plx, start_time, end_time);
        
        % Add bit events to Epoch
        % TODO
        
        % Inter-epoch spikes are end_time to next strobe_time (if present)
        % else end
        if(~isempty(epoch.nextEpoch())) 
            next = epoch.nextEpoch();
            if(next.getProtocolID().contains('intertrial'))
                if(i == length(plx.strobe_times)) % Or use start_times
                    inter_trial_end = [];
                else
                    inter_trial_end = plx.strobe_times(i+1);
                end
                
                insertSpikeDerivedResponses(next, plx, end_time, inter_trial_end);
            end
        end
        
        
        % Add bit events to inter-trial Epoch
        %TODO
        
    end
    

    %% OLD
%         % Add spike times DerivedResponse
%         if(~isempty(plx.spike_times{idx(i)}))
%             spike_times = plx.spike_times{idx(i)}; % We need to find spike times relative to expt start
%             [maxChannels,maxUnits] = size(spike_times);
%             
%             % First channel (row) is unsorted
%             for c = 2:maxChannels
%                 % First unit (column) is unsorted
%                 for u = 2:maxUnits
%                     
%                     if(isempty(spike_times{c,u}))
%                         continue;
%                     end
%                     
%                     derivedResponseName = ['spikeTimes_channel_' ...
%                         num2str(c-1) '_unit_' num2str(u-1)];
%                     
%                     j = 1;
%                     drNameCandidate = [derivedResponseName '-' ...
%                         drSuffix '-' num2str(j)];
%                     while(~isempty(epoch.getMyDerivedResponse(drNameCandidate)))
%                         j = j+1;
%                         drNameCandidate = [derivedResponseName '-'...
%                             drSuffix '-' num2str(j)];
%                     end
%                     
%                     derivedResponseName = drNameCandidate;
%                     
%                     epoch.insertDerivedResponse(derivedResponseName,...
%                         NumericData(spike_times{c,u}'),...
%                         's',... %times in seconds
%                         derivationParameters,...
%                         {'time from epoch start'}...
%                         );
%                 end
%             end
%         end
%         
%         % Add spike waveforms DerivedResponse
%         if(~isempty(plx.spike_waveforms{idx(i)}))
%             spike_waveforms = plx.spike_waveforms{idx(i)};
%             
%             [maxChannels,maxUnits] = size(spike_waveforms);
%             
%             % First channel (row) is unsorted
%             for c = 2:maxChannels
%                 % First unit (column) is unsorted
%                 for u = 2:maxUnits
%                     
%                     if(isempty(spike_waveforms{c,u}))
%                         continue;
%                     end
%                     
%                     derivedResponseName = ['spikeWaveforms_channel_'...
%                         num2str(c-1) '_unit_' num2str(u-1)];
%                     
%                     waveformData = spike_waveforms{c,u};
%                     data = NumericData(reshape(waveformData, 1, ...
%                         numel(waveformData)),...
%                         size(waveformData));
%                     
%                     j = 1;
%                     drNameCandidate = [derivedResponseName '-' ...
%                         drSuffix '-' num2str(j)];
%                     while(~isempty(epoch.getMyDerivedResponse(drNameCandidate)))
%                         j = j+1;
%                         drNameCandidate = [derivedResponseName '-'...
%                             drSuffix '-' num2str(j)];
%                     end
%                     
%                     derivedResponseName = drNameCandidate;
%                     
%                     epoch.insertDerivedResponse(derivedResponseName,...
%                         data,...
%                         'mV',... % TODO confirm units
%                         derivationParameters,...
%                         {'spikes','waveform'}... % TODO dimension labels?
%                         );
%                 end
%             end
%         end
%         
%         % Add event TimelineAnnotations
%         
%         %t = toc(tstart);
%         %disp(['      ' num2str(t) ' seconds']);
%     end
    
    disp('Attaching .plx file...');
    epochGroup.addResource('com.plexon.plx', plxRawFile);
    
    disp('Attaching .exp file...');
    epochGroup.addResource('com.plexon.exp', expFile);
end

function insertSpikeDerivedResponses(epoch, plx, start_time, end_time)
    
    % First channel (row) is unsorted
    for c = 2:maxChannels
        % First unit (column) is unsorted
        for u = 2:maxUnits
            if(isempty(plx.wave_ts{c,u}))
                continue;
            end
            
            % Find spikes in this Epoch
            if(isempty(end_time))
                spke_idx = wave_ts{c,u} >= start_time;
            else 
                spike_idx = plx.wave_ts{c,u} >= start_time && plx.wave_ts{c,u} < end_time;
            end
            
            % Calculate relative spike times
            spike_times = plx.wave_ts{c,u}(spke_idx) - plx.wave_ts{c,u}(spike_idx(1));
            
            
            % Insert spike times
            derivedResponseName = ['spikeTimes_channel_' ...
                num2str(c-1) '_unit_' num2str(u-1)];
            
            j = 1;
            drNameCandidate = [derivedResponseName '-' ...
                drSuffix '-' num2str(j)];
            while(~isempty(epoch.getMyDerivedResponse(drNameCandidate)))
                j = j+1;
                drNameCandidate = [derivedResponseName '-'...
                    drSuffix '-' num2str(j)];
            end
            
            derivedResponseName = drNameCandidate;
            
            epoch.insertDerivedResponse(derivedResponseName,...
                NumericData(spike_times'),...
                's',... %times in seconds
                derivationParameters,...
                {'time from epoch start'}...
                );
            
            
            % Insert spike wave forms
            derivedResponseName = ['spikeWaveforms_channel_'...
                num2str(c-1) '_unit_' num2str(u-1)];
            
            waveformData = plx.spike_waves{c,u}(spike_idx,:);
            data = NumericData(reshape(waveformData, 1, ...
                numel(waveformData)),...
                size(waveformData));
            
            j = 1;
            drNameCandidate = [derivedResponseName '-' ...
                drSuffix '-' num2str(j)];
            while(~isempty(epoch.getMyDerivedResponse(drNameCandidate)))
                j = j+1;
                drNameCandidate = [derivedResponseName '-'...
                    drSuffix '-' num2str(j)];
            end
            
            derivedResponseName = drNameCandidate;
            
            epoch.insertDerivedResponse(derivedResponseName,...
                data,...
                'mV',... % TODO confirm units
                derivationParameters,...
                {'spikes','waveform'}... % TODO dimension labels?
                );
            
        end
    end
end