function Snorm = emoz_read_norming(datapath, normfilepath)
% Read the norming scores from the rating study done independently of the
% eye-tracking study. Auditive stimuli are rated from 1 to 5 (poorly
% identify emotion to well identified emotion)
% !! very specific to the norming file (cf. ligne 58)
%____
%-CREx 20151220
% ANR RAPP C. Petrone http://www.lpl-aix.fr/~petrone/projectf.html
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/emoz

pdat = [fileparts(datapath), filesep]; 

% Only T0 files needed (critical time which correspond to the noun
% prononziation will be read on the crit_time file) 
list = dir(datapath);

% Initialize some variables by opening the first file only
% Open the file
fid = fopen([pdat, list(1).name]); 

% Read the data 
% Get the header line
hdr = fgetl(fid);

% Number of AOI columns
Naoi = length(strfind(hdr, 'AOI'));
faoii = repmat('%f ', 1, Naoi);
faoi = faoii;
fcol = ['%s %s %f %f %f %f %s ', repmat('%f ', 1, 12), faoi];

Cdat = textscan(fid, fcol,  'Delimiter', '\t', 'EmptyValue', NaN); 
% Return 1 x 271 cell 

% Close the file
fclose(fid);

% Search unique media names (excluded 'NaN' and training media)
Cmed = Cdat{2};

umed = unique(Cmed);
iok = zeros(length(umed), 1);
for im = 1 : length(umed)
    if ~strcmp(umed{im}, 'NaN') && isempty(strfind(umed{im}, 'train'))
        iok(im) = im;
    end
end
umedf = umed(iok>0);

Nmed = length(umedf);
cmed = char(umedf);
spk = upper(cmed(:,1));
medstim = cell(Nmed, 1);
for j = 1 : Nmed
    mednam = umedf{j};
    numed = str2double(mednam(isstrprop(mednam, 'digit')));
    % In norming media names, 57 isn't missing... remove 1 after 58
    if numed >= 58 
        numed = numed - 1; 
    end
    medstim{j} = ['S', num2str(numed), spk(j)];
end

% Load critical times to construct time vector (time locking analysis)
fid = fopen(normfilepath);
A = textscan(fid, '%s%s%s%d%s%s%s%d', 'delimiter','\t', 'headerlines', 1);
fclose(fid);
% [1]Stimulus [2]Speaker [3]Type(audio) [4]Repetition [5]Emotion	
% [6]Scale	[7]Participant	[8]Score

normnames = cell(length(A{1}), 1);
for i = 1 : length(A{1})
    normnames{i} = [A{1}{i} A{2}{i}];
end
   
% Mean score value per media
unormstim = unique(normnames);
Nusn = length(unormstim);
nb = zeros(Nusn, 1);
scorenorm = zeros(Nusn, 1);

for i = 1 : Nusn
    imed = strcmp(unormstim{i}, normnames);
    scorenorm(i) = mean(A{8}(imed));
    nb(i) = sum(imed);
end
% unique(nb)=13 => OK, always 13 participants per media
% Associated this mean score with umedf media names
scoremed = zeros(Nmed, 1);
for i = 1 : Nmed
    scoremed(i) = scorenorm(strcmp(medstim{i}, unormstim));
end
Snorm = [];
Snorm.mednames = umedf;
Snorm.scoremed = scoremed;