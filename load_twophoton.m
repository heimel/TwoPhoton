%load_twophoton. Sets path for TwoPhoton analysis folders
%
% 2025, Alexander Heimel

twophoton_path = fileparts(mfilename("fullpath"));

% set default lab, can be overruled depending on host:
% alternatives 'Fitzpatrick','Levelt','Lohmann'
% is case-sensitive!
params.lab='Levelt';

switch params.lab
    case 'Lohmann'
        twophoton_microscope_type='Lohmann';
    case 'Levelt'
        twophoton_microscope_type='FluoView';
    case 'Fitzpatrick'
        twophoton_microscope_type='PrairieView';
end

addpath(twophoton_path, ...
    fullfile(twophoton_path, 'Reid_cell_finder' ),...
    fullfile(twophoton_path, 'Reid_cell_finder' , 'basic_findcell'),...
    fullfile(twophoton_path, 'Synchronization' , params.lab) ,...
    fullfile(twophoton_path, 'Laser' , params.lab),...
    fullfile(twophoton_path, 'Platforms', twophoton_microscope_type));

% addpath(twophoton_path, ...
%     genpath([path2invivotools filesep 'Scanbox_Yeti']),...   % Get Scanbox from Github
%     genpath([path2invivotools filesep 'NoRMCorre'])); % Get NoRMCorre from Github

load_scanbox;

if exist('java','file') && usejava('jvm')
    javaaddpath(fullfile(twophoton_path,'Reid_cell_finder/java'));
    % now check if ij.jar file is already in the javaclasspath
    % ij.jar is the ImageJ javaclass and used in Reid_cell_finder
    jvc=javaclasspath('-all');
    found_ij=strfind(jvc,'ij.jar');
    found_ij= (sum([found_ij{:}])>0);
    if ~found_ij
        javaaddpath(fullfile(twophoton_path,'Reid_cell_finder/ij/ij.jar'));
    end
end
