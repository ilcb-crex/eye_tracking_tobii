function Sfreq = emoz_read_speechfreq(datapath, freqpath)
% Read the data file from the frequency analysis [speech_f0_slope.txt]
% containing columns: 
% [1]Stimulus [2]Speaker [3]f0T1 [4]f0T2 [5]f0slope [6]f0time
% Integrate the data inside a structure with frequency and slope values per
% media
% Sfreq
% t1
% t2
% slope
% time
% mednames
%____
%-CREx 20151220
% ANR RAPP C. Petrone http://www.lpl-aix.fr/~petrone/projectf.html
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/emoz

pdat = [fileparts(datapath), filesep]; 

% Only T0 files needed (critical time which correspond to the noun
% prononziation will be read on the crit_time file) 
list = dir(datapath);

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
    cnumed = mednam(isstrprop(mednam, 'digit'));
    numed = str2double(cnumed);
    if numed >= 58 % Remove 57, add 1 after 57
        numed = numed - 1;
    end
    if numed < 10
        strnumed = ['0', num2str(numed)];
    else
        strnumed = num2str(numed);
    end       
    medstim{j} = ['S', strnumed, spk(j)];
end

% Read fundamental frequency file
% Stimulus Speaker	f0T1	f0T2	f0slope	f0time
fid = fopen(freqpath);
A = textscan(fid, '%s%s%f%f%f%f', 'delimiter','\t', 'headerlines', 1);
fclose(fid);

% [1]Stimulus [2]Speaker [3]f0T1 [4]f0T2 [5]f0slope [6]f0time
% Sfreq.f0T1 = 
% Sfreq.f0T2	f0slope	f0time

stimfreq = cell(length(A{1}), 1);
for i = 1 : length(A{1})
    stimfreq{i} = [A{1}{i} A{2}{i}(1)];
end
   
% Mean score value per media
Nsf = length(stimfreq);

Sfreq = [];
Sfreq.t1 = NaN(Nmed, 1);
Sfreq.t2 = NaN(Nmed, 1);
Sfreq.slope = NaN(Nmed, 1);
Sfreq.time = NaN(Nmed, 1);

% Associated with umedf media names
for i = 1 : Nsf
    imed = find(strcmp(stimfreq{i}, medstim)==1);
    Sfreq.t1(imed) = A{3}(i);
    Sfreq.t2(imed) = A{4}(i);
    Sfreq.slope(imed) = A{5}(i);
    Sfreq.time(imed) = A{6}(i);
end
Sfreq.mednames = umedf;    
