function plx = plx2mat(plxname)

if ~exist('plxname', 'var')

    [PLXfile PLXpathname] = uigetfile('PlexonData/*.PLX','Load Plexon PLX File');
    plxname = [PLXpathname PLXfile];
end

[plx.tscounts, plx.wfcounts, plx.evcounts] = plx_info(plxname,1);
[plx.unit,plx.channel] = find(plx.wfcounts);

% find channels with event counts on them
ch_counts = find(plx.evcounts~=0);
            
for ii = 1:length(ch_counts)
    [~, plx.ts{ii}, plx.sv{ii}] = plx_event_ts(plxname, ch_counts(ii));
end

%%% strobed words 
[plx.number, plx.timestamps, plx.strobed_values] = plx_event_ts(plxname, 257);          

%% get start and end times for each trial
% we allign to the timestamps for bit 7 of the datapixx
% bit 7 should only be used for trial start
plx.start_times = plx.ts{7};  % start times
plx.end_index   = find(plx.strobed_values == mod(2012,256));
plx.end_times   = plx.timestamps(plx.end_index);


%% Main Trial Loop
disp('Finding unique numbers')        
for ii = 1:length(plx.end_times)
    % display progress
    if mod(ii,50)==0
        disp([num2str(ii) ' of ' num2str(length(plx.end_times)) ' trials'])
    end
    
    % keep track of unique number that is stobed on each trial
    plx.unique_number(ii,:) = plx.strobed_values(plx.end_index(ii):plx.end_index(ii)+5)';
            
end
disp('Done!')
disp('Extracting spike data...')
for ch = 1:length(plx.channel)
    for un = 1:length(plx.unit)
            [~,plx.npw{plx.channel(ch),plx.unit(un)}, plx.wave_ts{plx.channel(ch),plx.unit(un)}, ...
                plx.spike_waves{plx.channel(ch),plx.unit(un)}] = plx_waves_v(plxname, plx.channel(ch)-1, plx.unit(un)-1);
    end
end
disp('Done!')


disp(['Saving plx.mat file: ' plxname(1:end-3) 'mat']);
save([plxname(1:end-3) 'mat'], 'plx')
        
    
    
