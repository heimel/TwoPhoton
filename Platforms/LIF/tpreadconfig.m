function params=tpreadconfig( records )
%TPREADCONFIG read twophoton experiment config file
%
% PARAMS. =
%  params.number_of_frames = total number of frames
%  params.lines_per_frame = lines per frame
%  params.pixels_per_line = number of pixels per line
%  params.frame_period = frame period, in s
%  params.frame_period__us = frame period, in us
%  params.scanline_period = scanline period in s
%  params.scanline_period__us = scanline period in us
%  params.dwell_time = pixel dwell time
%  params.dwell_time__us = pixel dwell time, in us
%  params.frame_timestamp = list of all frame timestamps
%  params.frame_timestamp__us = id, in us
%
% LIF version
%
% 2011, Alexander Heimel
%

%javaaddpath(which('tpreadconfig'))

params = [];
for i = 1:length(records)
    params = [params tpreadconfig_single( records(i) )];
end

function params = tpreadconfig_single( record )
persistent per_record per_params

if ~isempty(per_record)
    strip_record = rmfields(record,{'ROIs','measures'});
    if strip_record==per_record
        params = per_params;
        return
    end
end


fname = tpfilename(record);

if ~exist(fname,'file')
    warning('TPREADCONFIG:FileNotExists',['TPREADCONFIG: ' fname ' does not exist.']);
    params = [];
    return
end

[inf,imagenames] = lifinfo(fname,record.slice,1,tpscratchfilename(record,[],'lifinfo') );

if iscell(inf)
    %inf = inf{1}; % only take first=last? session
    logmsg('Multiple images in lif file. Select image name and add in slice field. Check Matlab command window for possibilities.');
    disp(imagenames);
    logmsg('Defaulting to first image.');
    inf = inf{1};
    inf.Series = 1;
end

params = inf; 

params.lines_per_frame = inf.Height;
params.pixels_per_line = inf.Width;
params.number_of_frames = inf.NumberOfFrames;

if isfield(inf,'third_axis_name') && strcmp(inf.third_axis_name,'t')
    params.scanline_period = inf.ParsedImageDescription.SecondsPerScanLine; % scanline period in s
    params.scanline_period__us = params.scanline_period *1e6; %scanline period in us
    params.dwell_time = params.scanline_period / params.pixels_per_line; % pixel dwell time in us
    params.dwell_time__us =  params.dwell_time*1e6;
else
    if isfield(params,'third_axis_name') && strcmpi(params.third_axis_name,'t')
        warning('TPREADCONFIG:NO_SECONDSPERSCANLINE','TPREADCONFIG:NO_SECONDSPERSCANLINE: No SecondsPerScanLine in multitiff image description. Choosing arbitrary scanline time');
        warning('off','TPREADCONFIG:NO_SECONDSPERSCANLINE')
    end
    params.scanline_period = 0; % making frame period 0
    %1/params.lines_per_frame; % making frame period 1
    params.scanline_period__us = params.scanline_period *1e6; %
    params.bidirectional = 0;
    params.dwell_time = params.scanline_period / params.pixels_per_line; % pixel dwell time in us
    params.dwell_time__us =  params.dwell_time*1e6;
end

if ~isfield( inf, 'frame_period')
    params.frame_period = 1; % arbitrarily set to 1
end
params.frame_period__us = params.frame_period * 1e6; % frame period in us

if ~isfield( inf, 'frame_timestamp')
    params.frame_timestamp = (0:(inf.NumberOfFrames-1))*params.frame_period;
end
params.frame_timestamp__us = params.frame_timestamp * 1E6; % list of all frame timestamps in s

per_params = params;
per_record = rmfields(record,{'ROIs','measures'});
