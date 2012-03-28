function ImportPLX(epochGroup, plxFile, plxRawFile, varargin)
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
		java.io.File(expFile).lastModified());
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
		% TODO this should use getProperty(getOwner)
		epochUniqueNumber = epoch.getOwnerProperty('uniqueNumber');
		if(~isempty(epochUniqueNumber))
			epochUniqueNumber = epochUniqueNumber.getIntegerData()';
		end
		
		epochCache.uniqueNumber.put(num2str(epochUniqueNumber), epoch);
		epochCache.truncatedUniqueNumber.put(num2str(mod(epochUniqueNumber,256)),...
			epoch);
	end
    
    disp('Importing PLX data...');
    idx = find(plx.unique_number(:,1) > 0);
    if(~isempty(ntrials))
        idx = idx(1:ntrials);
    end
    
    
    for i = 1:length(idx)
		%tstart = tic();
		if(mod(i,5) == 0)
			disp(['    Epoch ' num2str(i) ' of ' num2str(length(idx)]);
		end
		
		
		epoch = findEpochByUniqueNumber(epochGroup,...
			plx.unique_number(idx(i),:),...
			epochCache);
		
		if(isempty(epoch))
			warning('ovation:import:plx:unique_number',...
				'PLX data appears to contain a unique number not present in the epoch group');
			continue;
        end
		
        % Add spike times DerivedResponse
		if(~isempty(plx.spike_times{idx(i)}))
			spike_times = plx.spike_times{idx(i)}; % We need to find spike times relative to expt start
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
		
        % Add spike waveforms DerivedResponse
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
        
        % Add event TimelineAnnotations
		
		%t = toc(tstart);
		%disp(['      ' num2str(t) ' seconds']);
	end
	
	disp('Attaching .plx file...');
	epochGroup.addResource('com.plexon.plx', plxRawFile);
	
	disp('Attaching .exp file...');
	epochGroup.addResource('com.plexon.exp', expFile);
end