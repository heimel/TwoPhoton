function im = tppreview(record, selFrames, firstFrames, channel,opt, mode, verbose)
%  TPPREVIEW - Preview twophoton image data
%
%    IM = TPPREVIEW(RECORD, SELFRAMES, FIRSTFRAMES,CHANNEL, OPT, MODE, VERBOSE)
%
%  Read a few frames to create a preview image.  DIRNAME is the
%  directory name to be opened, and NUMFRAMES is the number of
%  frames to read.  If FIRSTFRAMES is 1, then the first SELFRAMES
%  frames will be read; If FIRSTFRAMES is 0, the frames will be taken
%  randomly from those available. If FIRSTFRAMES > 1 then start at
%  FIRSTFRAMES (i.e. skip FIRSTFRAMES-1 frames at start)
%
%  CHANNEL is the channel to be read.  If it is empty, then
%  all channels will be read and third dimension of im will
%  correspond to channel.  For example, im(:,:,1) would be
%  preview image from channel 1.
%
%  If MODE is 1 (default) than frames are averaged. If MODE is 2 then a
%  maximum projection is used. For MODE is 3 an maximum projection across
%  the X-axis is taken, for MODE 4 the same through the Y-axis
%
%  2008, Steve Van Hooser
%  2010-2017, Alexander Heimel
%

if nargin<7 || isempty(verbose) 
    verbose = true;
end
if nargin<6
    mode = []; 
end
if nargin<5 
    opt = []; 
end
if nargin<4 
    channel = [];
end
if nargin<3 || isempty(firstFrames)
    firstFrames = 1;
end
if nargin<2 || isempty(selFrames)
    selFrames = 100;
end

fname = tpfilename(record);
if ~exist(fname,'file')
    errormsg(['File ' fname ' does not exist.']);
    im = [];
    return
end

inf = tpreadconfig(record);

if isfield(inf,'third_axis_name') && ~isempty(inf.third_axis_name) && lower(inf.third_axis_name(1))=='z'
    zstack = true;
else
    zstack = false;
end

if isempty(mode)
    if zstack
        mode = 2; % maximum projection
    else
        mode = 1; % average
    end
end

if isempty(channel)
    channel = 1:inf.NumberOfChannels;
end

total_nFrames=inf.NumberOfFrames;
numFrames = round(min(max(selFrames), total_nFrames));
if length(selFrames) == 2
    first = round(max(min(selFrames),1));
else
    first = 1;
end

if firstFrames == 0
    N = randperm(total_nFrames);
        frame_selection = sort(N(1:numFrames));
elseif firstFrames == 1
        frame_selection = first:numFrames;
else % skip some
    frame_selection = firstFrames:(firstFrames+numFrames);
end


warning('ON','TPREADFRAME:MEM');

switch mode
    case {1,2} % average or max through Z/T axis
        im = zeros( inf.Height,inf.Width,inf.NumberOfChannels);
        for c=channel
            if ~isempty(opt) && strcmp(opt, 'tryagain')
                im(:,:,c) = tpreadframe(record,c,frame_selection,opt,verbose,'tryagain',mode);
                opt = [];
            else
                im(:,:,c) = tpreadframe(record,c,frame_selection,opt,verbose,[],mode);
            end
        end
    case {3,4} % maximum projection through X or Y axis, respectively
        % takes memory
        im4d = zeros( inf.Height,inf.Width,total_nFrames,inf.NumberOfChannels);
        for c=channel
            for f = 1:total_nFrames
                im4d(:,:,f,c) = double( tpreadframe(record,c,f,opt,verbose) );
            end
        end
        im(:,:,c) = max(im4d(:,:,:,c),[],mode-2);
end

