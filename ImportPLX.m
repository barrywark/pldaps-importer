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
    %
    %      expFile: Path to a spike sorter .exp file with parameters for
    %      the spike sorting in plxFile.
    
    nargchk(3, 5, nargin); %#ok<NCHKI>
    if(nargin < 5)
        ntrials = [];
    else
        ntrials = varargin{1};
    end
    
    import ovation.*
    
    plxStruct = load('-mat', plxFile);
    plx = plxStruct.plx;
    
    expModificationDate = org.joda.time.DateTime(...
        java.io.File(expFile).lastModified());
    drSuffix = [num2str(expModificationDate.getYear()) '-' ...
        num2str(expModificationDate.getMonthOfYear()) '-'...
        num2str(expModificationDate.getDayOfMonth())];
    
    
    %TODO: derivationParameters
    derivationParameters = struct2map(...
        convertNumericDataInStruct(...
        loadPLXExpFile(expFile)));
    
    disp('Importing PLX data...');
    idx = find(plx.unique_number(:,1) > 0);
    if(~isempty(ntrials))
        idx = idx(1:ntrials);
    end
    uniqueNumberCache = [];
    epIdx = 0;
    nIdx = length(idx);
    for i = 1:length(idx)
        if(mod(i,5) == 0)
            disp(['    Epoch ' num2str(i) ' of ' num2str(nIdx)]);
        end
        
        
        [epoch,uniqueNumberCache,epIdx] = findEpochByUniqueNumber(epochGroup,...
            plx.unique_number(idx(i),:),...
            uniqueNumberCache,...
            epIdx+1);
        
        if(isempty(epoch))
            warning('ovation:import:plx:unique_number',...
                'PLX data appears to contain a unique number not present in the epoch group');
            continue;
        end
        
        if(~isempty(plx.spike_times{idx(i)}))
            spike_times = plx.spike_times{idx(i)};
            [maxChannels,maxUnits] = size(spike_times);
            
            % First channel (row) is unsorted
            for c = 2:maxChannels
                % First unit (column) is unsorted
                for u = 2:maxUnits
                    
                    if(isempty(spike_times{c,u}))
                        continue;
                    end
                    
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
                        NumericData(spike_times{c,u}'),...
                        's',... %times in seconds
                        derivationParameters,...
                        {'time from epoch start'}...
                        );
                end
            end
        end
        
        if(~isempty(plx.spike_waveforms{idx(i)}))
            spike_waveforms = plx.spike_waveforms{idx(i)};
            
            [maxChannels,maxUnits] = size(spike_waveforms);
            
            % First channel (row) is unsorted
            for c = 2:maxChannels
                % First unit (column) is unsorted
                for u = 2:maxUnits
                    
                    if(isempty(spike_waveforms{c,u}))
                        continue;
                    end
                    
                    derivedResponseName = ['spikeWaveforms_channel_'...
                        num2str(c-1) '_unit_' num2str(u-1)];
                    
                    waveformData = spike_waveforms{c,u};
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
    end
    
    disp('Attaching .plx file...');
    epochGroup.addResource('com.plexon.plx', plxRawFile);
    
    disp('Attaching .exp file...');
    epochGroup.addResource('com.plexon.exp', expFile);
end