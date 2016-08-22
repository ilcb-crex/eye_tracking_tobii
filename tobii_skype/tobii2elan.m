function tobii2elan(tsvpath, elanpath)
% Write an Elan file of fixations from the Tobii exported file.
%
% Tobii fixation file contains at least these data columns:
% RecordingTimestamp, FixationIndex and GazeEventDuration
% as well as all the columns of AOI hits.
%
% To be read by Elan, the fixations are formatted as annotations.
% The annotation file will contain the columns: Tier, BeginTime, EndTime and 
% Annotation.
% Each row represents one fixation in the AOI that is defined by the Tier 
% name. The total duration of the fixation appears as the annotated text, 
% in milliseconds.
%
% -- Input parameters:
%  - tsvpath: path of the tsv file (Tobii exported data of fixation)
%    Ex.: C:/data/tobii_export/project_P02.tsv
%
%  - elanpath: path of the directory where to save Elan's files
%    Ex.: C:/data/elan_import
%
% Files will be saved in csv inside elanpath directory. 
% Ex.: C:/data/elan_import/project_P02_importElan.csv
%
% Require the specific function: read_tobiifile
%
%-CREx 20160314 
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/tobii_skype


% Read data file (special function, see below)
[Cdat, hnames] = read_tobiifile(tsvpath);

Sdat = find_dat(Cdat, hnames);
Sdat.dt = [0 ; diff(Sdat.timest)];

[iaoi, Naoi] = find_aoicol(hnames);
aoinames = hnames(iaoi);

aoitab = cell2mat(Cdat(iaoi));
Sfix = [];

% Process each AOI columns independently
for ia = 1 : Naoi
    faoi = aoinames{ia};
    fixaoi = aoitab(:,ia);
    % When 1 => fixation inside !
    % Find all fixations
    ifix = find(fixaoi==1);
    fixid = Sdat.fixind(ifix);
    dt = Sdat.dt(ifix);
    % Find all unique fixid
    [ufix, iuid]  = unique(fixid);
    tbeg = Sdat.timest(ifix(iuid));
    tbeg_str = datestr(tbeg/86400/1000, 'HH:MM:SS.FFF');
    
    % Duration of each fixation (cropped if AOI location is changing)
    Nfix = length(ufix);
    dur = zeros(Nfix, 1);
    for k = 1 : Nfix
        dur(k) = sum(dt(fixid == ufix(k)));
    end
    tend = tbeg + dur;
    tend_str = datestr(tend/86400/1000, 'HH:MM:SS.FFF');
    
    % t_beg fix
    Sfix.(faoi).tbeg_str = tbeg_str;
    Sfix.(faoi).tend_str = tend_str;
    Sfix.(faoi).dur = dur;
end

% Write Elan file for import
[~, nam] = fileparts(tsvpath);
elanfile = fullfile(elanpath, [nam,'_importElan.csv']);

fid = fopen(elanfile, 'w');
hdr = ['Tier\t', 'BeginTime\t', 'EndTime\t', 'Annotation\n'];
colform = '%s\t%s\t%s\t%d\n';

fprintf(fid, hdr);
for ia = 1 : Naoi
    faoi = aoinames{ia};
    Nfix = length(Sfix.(faoi).dur);
    for k = 1 : Nfix
        fprintf(fid, colform, faoi,...
            Sfix.(faoi).tbeg_str(k,:), Sfix.(faoi).tend_str(k,:),...
            Sfix.(faoi).dur(k));
    end
end
fclose(fid);    

% Find the required data in the Tobii export file
% = RecordingTimestamp, FixationIndex and GazeEventDuration
function Sdat = find_dat(Cdat, hnames)
colnames = {'RecordingTimestamp'
            'FixationIndex'
            'GazeEventDuration'};
% fieldnames of the structure holding required data (Sdat)
fdat = {'timest'
        'fixind'
        'evdur'};
    
Sdat = [];
for j = 1 : length(colnames)
    icol = find(strcmp(hnames, colnames{j})==1);
    if ~isempty(icol)
        Sdat.(fdat{j}) = Cdat{icol};
    else
        fprintf('!!! %s column not found', colnames{j})
    end
end

% Find AOI column indices iaoi (and total number Naoi)
function [iaoi, Naoi] = find_aoicol(hnames)
    chdr = char(hnames);
    chdr = cellstr(chdr(:, 1:3));
    iaoi = find(strcmpi(chdr, 'aoi')==1);
    if ~isempty(iaoi)
        Naoi = length(iaoi);
    else
        Naoi = [];
    end