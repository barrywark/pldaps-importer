function [plx] = plx2mat(plxname)
% combine script 
% PLDAPS script that incorporates Plexon "PLX" files and PLDAPS "PDS" files


if ~exist('plxname', 'var')

    [PLXfile PLXpathname] = uigetfile('PlexonData/*.PLX','Load Plexon PLX File');
    plxname = [PLXpathname PLXfile];
end

[plx.tscounts, plx.wfcounts, plx.evcounts] = plx_info(plxname,1);
temp = find(plx.evcounts);
[plx.unit,plx.channel] = find(plx.wfcounts);


for i = 1:10
    [~, plx.ts{i}, plx.sv{i}] = plx_event_ts(plxname, temp(i));
end

%%% strobed words 
[plx.number, plx.timestamps, plx.strobed_values] = plx_event_ts(plxname, 257);          

% get start and end times for each trial
plx.start_times = plx.ts{8};  % start times 
%end_times = temp_timestamps(:,1);   % end times (first strobed word)


plx.end_index = find(plx.strobed_values == mod(2011,256));
plx.end_times = plx.timestamps(plx.end_index);

%%% get timestamps & waveforms
for i = 1:length(plx.end_times) % for all start value time stamps 
    temp = find(plx.start_times < plx.end_times(i)); % find  the start time directly before the end time


    % [~, plx.wave_timestamps] = plx_ts(plxname, plx.channel(j)-1, plx.unit(j)-1);
    %%% event timestamps

    if ~isempty(temp)
        temp_start_time = plx.start_times(temp(end));
        %fprintf(['trial length: \t \f' num2str(plx.end_times(i)-temp_start_time) '\r'])
        plx.unique_number(i,:) = plx.strobed_values(plx.end_index(i):plx.end_index(i)+5)';

        % add fp1 info
        temp = plx.ts{2}(plx.ts{2} > temp_start_time & plx.ts{2} < plx.end_times(i)) - temp_start_time;
        plx.fp1on(i) = temp(1);
        plx.fp1entered(i) = temp(2);
        plx.fp1off(i) = temp(3);

        % add fp2 info
        temp = plx.ts{3}(plx.ts{3} > temp_start_time & plx.ts{3} < plx.end_times(i)) - temp_start_time;
        plx.fp2off(i) = temp(1);


        % add dots info
        temp = plx.ts{4}(plx.ts{4} > temp_start_time & plx.ts{4} < plx.end_times(i)) - temp_start_time;
        plx.dotson(i) = temp(1);
        plx.dotsoff(i) = temp(2);


        %add choice/reward info
        temp = plx.ts{5}(plx.ts{5} > temp_start_time & plx.ts{5} < plx.end_times(i)) - temp_start_time;
        plx.timechoice(i) = temp(1);
        plx.timereward(i) = temp(2);

        %add target info
        temp = plx.ts{6}(plx.ts{6} > temp_start_time & plx.ts{6} < plx.end_times(i)) - temp_start_time;
        plx.targon(i) = temp(1);
        
        % add spikes & waveforms
        for j = 1:length(plx.channel) % for all channels
           [~, plx.npw, plx.wave_timestamps, plx.spike_waves] = plx_waves_v(plxname, plx.channel(j)-1, plx.unit(j)-1);
           plx.spike_times{i}{plx.channel(j)-1, plx.unit(j)} = plx.wave_timestamps(plx.wave_timestamps > temp_start_time & plx.wave_timestamps < plx.end_times(i)+1)-temp_start_time;
        end
    end
end


