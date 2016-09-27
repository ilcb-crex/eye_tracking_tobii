function Sdat = emoz_timeanalysis_extract(datopt)
% Extract, align & gather fixation data per conditions
% -- Read Tobii data file 
% -- Gather data together in a same structure Sdat
% -- Locked data depending on critical times (alignment process)
% -- Add norming results from the rating task
%
% datopt contains all the required path of the data files :
% datopt.fixpath : Tobii expoted file (.tsv) with AOIs columns
% datopt.critpath : files of critical times (times of interest per media)
% datopt.normpath : path of file with norming study results (rate per condition)
% datopt.freqpth : file with frequency characteristics of auditive stimuli
%
% Sdat is a very big structure that gather all the data per MEDIA and
% SUBJECT. See the attached document (emoz_methodo) for field details.
%
% Tobii data file (one *.tsv" file per subject)
% 271 columns
%(Excel / Copie du Header / Collage special / Transpose)
%
% [1] ParticipantName	P03 -- %s
% [2] MediaName	NaN ou file.avi -- %s
% [3] RecordingTimestamp	3 19 ... (ms) -- %d
% [4] GazePointIndex	1 2 3 4 ... -- %d
% [5] GazePointX (MCSpx)	NaN ... 746 -- %d
% [6] GazePointY (MCSpx)	NaN ... 383 -- %d
% [7] GazeEventType	NaN / Fixation / Unclassified -- %s
% [8] GazeEventDuration	NaN / 167 650 ... -- %d
% (same for each row that concerned the same
% event) 
% [9] FixationIndex	1 2 3 ... -- %d
%(same for each row of the same fixation event)
% [10] FixationPointX (MCSpx)	507 -- %d
% [11] FixationPointY (MCSpx)	447 -- %d
% [12] SaccadeIndex	always NaN -- %d
% [13] PupilLeft	2.80 -- %d
% [14] PupilRight	2.62 (we don't care...) -- %d
% [15] ValidityLeft	0 to 4 or NaN (if mouse event) -- %d
% [16] ValidityRight	0 to 4 -- %d
% [17] MouseEventIndex	1 2 3 ... -- %d
% [18] MouseEventX (MCSpx)	484 -- %d
% [19] MouseEventY (MCSpx)  391 -- %d
%
% AOI[Incor_stat]Hit  NaN or -1 / 0 / 1 -- %d
% AOI[Correct_stat]Hit NaN or -1 / 0 / 1 -- %d
% -1 : AOI inactive
% 0 : AOI active, fixation not located in the AOI
% 1 : AOI active and fixation point located inside
%
% Here we use AOI columns to find fixation indication
% It has required a preprocessing on Tobii Studio, involving definitions of
% each AOI for each media files (2  x 128 AOIs)
% The best would have been to look at fixation index when x- and
% y-coordinates where falling to the desired part of the screen
%
%- CREx 2015
% 

% Only T0 files needed (critical time which correspond to the noun
% prononziation will be read on the crit_time file) 

x_midscreen = 513; % in px to define AOI (click)

%--- Data list names
list = dir(datopt.fixpath);

C = struct2cell(list);
fnames = C(1,:);

%--- All data paths
pdat = [fileparts(datopt.fixpath), filesep];
allp = cellstr([ repmat(pdat, length(list), 1) char(fnames')]);

%--- Subject names
subj = cell(length(fnames),1);
% Data file name is of the kind : "Emozione_T0_P03.tsv"
% They have been rename after Tobii Studio export to include the real name
% of Tobii Participant (otherwise, it appends by default the rec string 
% : Emozione_T0_Rec 03.tsv

for i = 1 : length(fnames)
    sp = strsplit(fnames{i},'_');
    % Subject name (P**)
    subj{i} = sp{3}(1:3);
end
[usubj, ~, isubj] = unique(subj); % Only usefull if several Periods were extracted


% --- Initialize some variables by opening the first file only

% Read data file (special function, see below)
[Cdat, hdr] = read_tobiifile(allp{1});

% Search unique media names (excluded 'NaN' and training media)
% Special function (see below)
umedf = emoz_medianames(Cdat{2});
        
% Find speaker gender and emotion associated to each media 
% Special function (see below)
Smed = emoz_scan_mednames(umedf);
emot = Smed.emot;
spk = Smed.spk;


% Read and compute norming results
Snorm = emoz_read_norming(datopt.fixpath, datopt.normpath);
% Snorm : structure with fields : 
% mednames {126x1} : media names
% and scoremed [126x1] : norming result

% Read and associated speech frequency with media 
Sfreq = emoz_read_speechfreq(datopt.fixpath, datopt.freqpath);
      
% Load critical times to construct time vector (time locking analysis)
crit = emoz_read_critime(datopt.critpath);


% Alignment
falign = {'tbeg', 'tnoun', 'tverb', 'tend', 'tclick'};
 
% Strore all results in big data structure 
% Sdat.EMOT.SPEAKER.TALIGN with fields :
% subj, medianames, time, isfix, corclick, tsound, tnoun, tverb, tclick
% norming & freq
    
% Initialize structure of results by specific function (to lightening the
% code !!!)
Sdat = ini_struct(Smed, usubj, falign);

Nfile = length(allp);
Nmedia = length(umedf);
% Process each data file => each subject
% Store the results on Sprop super structure
for id = 1 : Nfile
    disp(['Compute file : ', allp{id}])

    if id > 1
        % id == 1 previously load to initialize things
        % Read data file (special function, see below)
        [Cdat, hdr] = read_tobiifile(allp{id});
    end
    
    % ! When adding the 2nd part of Emozion data, bug appears because of 
    % the presence of additional columns of AOI_Hit
    % (maybe missing in teh previous preprocessing of 1st part)
    hnames = format_hdr(hdr);
    aoinames = hnames(20:end);

    % Associated indices of subject
    IS = isubj(id);
    
    % Calculate the proportion of fixation duration 
    % for both AOIs for each media
    mednamdat = Cdat{2};
    aoitab = cell2mat(Cdat(20:end));
    % Timestamp for this subject
    timest = Cdat{3};
    
    dt = [ 0 ; diff(timest)];

    mousex = Cdat{18};
        
    for k = 1 : Nmedia
        
        smedia = umedf{k}; 
        semo = emot{k};
        sspk = spk{k};
        
        disp(['Compute media : ', smedia])
        
        % Indices of the rows associated with the media "smedia"
        imed = strcmp(mednamdat, smedia);
        
        % AOI fixation columns
        aoip = aoitab(imed,:);

        % Timestamps
        dtp = dt(imed);
        tsp = timest(imed);
        
        % Corresponding critical times in ms
        icritmed = strcmp(crit.mednam, smedia);
        tcrit = [crit.tbeg(icritmed) crit.tnoun(icritmed) crit.tverb(icritmed) crit.tend(icritmed)].*1000;
        
        % Mouse click abscisse 
        mousexp = mousex(imed);       
        imsx = find(isnan(mousexp)==0);
              
        % Find the columns associated with the AOIs
        % Find the first not-NaN value 
        [irowi, icoli] = find(isnan(aoip)==0, 1, 'first');
        % Find the last not-NaN row
        irowf = find(isnan(aoip(:, icoli))==0, 1, 'last');

        % AOIs columns implicated in the media 
        icolf = find(isnan(aoip(irowi, :))==0, 1, 'last');

        % So the not-NaN part of the media with defined AOIs 
        aoistate = aoip(irowi : irowf, icoli : icolf);

        % Name of the column
        colnames = aoinames(icoli : icolf);    

        % Corresponding time vector
        tm = tsp(irowi : irowf);
         
        % t0 = 0 s at the start of the media
        tm = tm - tm(1);
 
        % Check for the sample frequency : if 120 Hz, decimate the data
        if mean(dtp) < 10
            tm = tm(1:2:end);
            aoistate = aoistate(1:2:end, :);
        end
        
        % No answer = incorrect response !
        mcor = 0;
        if ~isempty(imsx)
           
            msx = mousexp(imsx);
            if msx < x_midscreen
                clickaoi = 'left';
            else
                clickaoi = 'right';
            end
            % Correct answer image side write on the media name ('ex.
            % female36-incr-right.avi')
            if ~isempty(strfind(smedia, clickaoi))
                mcor = 1;
            end
            tclick = tsp(imsx)-tsp(irowi);
            talign = [tcrit tclick];
        else
            talign = tcrit;
        end
        
        % Media file names as already stored when initialized big data
        % structure
        mednames = Sdat.(semo).(sspk).medianames;  
        
        IM = find(strcmp(mednames, smedia)==1);
        
        % Store correct answer indicator
        Sdat.(semo).(sspk).corclick(IM, IS) = mcor; 
        % Store norming values for each media
        inorm = strcmp(smedia, Snorm.mednames);
        Sdat.(semo).(sspk).norming(IM) = Snorm.scoremed(inorm);

        % Store speech parameters
        ifreq = strcmp(smedia, Sfreq.mednames);
        Sdat.(semo).(sspk).freq.t1(IM) = Sfreq.t1(ifreq);
        Sdat.(semo).(sspk).freq.t2(IM) = Sfreq.t2(ifreq);
        Sdat.(semo).(sspk).freq.slope(IM) = Sfreq.slope(ifreq);
        Sdat.(semo).(sspk).freq.time(IM) = Sfreq.time(ifreq);
        
        % Store time and fixation vectors depending on critical time alignment
        Na = length(talign);
            
        for ia = 1 : Na
            stal = falign{ia};

            tAL = talign(ia);
            % Find the sample associated with the critical time
            IC = find(tm >= tAL, 1, 'first');
            if ~isempty(IC)
                % Case when answer time is shorter than critical time !
                % (id = 10, k=110 = P12)

                % Substract this critical time
                tmc = tm - tm(IC); 

                % Only rows when all AOIs of the set are activated 
                iactiv = find(aoistate(:,1)~=-1 & isnan(aoistate(:,1))==0);
                
                aoiact = aoistate(iactiv, :);
                tmact = tmc(iactiv, :);
                for ic = 1 : length(colnames)
                    % Store fixation values of the Correct AOI only
                    if ~isempty(strfind(colnames{ic}, 'Cor'))
                        Sdat.(semo).(sspk).datalign.(stal).time{IM, IS} = tmact;
                        Sdat.(semo).(sspk).datalign.(stal).isfix{IM, IS} = aoiact(:, ic);
                    end  
                end
            end
          
            % Store click - reaction time
            if ~isempty(imsx)
                Sdat.(semo).(sspk).datalign.(stal).tclick(IM, IS) = tclick - tAL;
            end

            % Store critical time for each media
            Sdat.(semo).(sspk).datalign.(stal).tcrit.tbeg(IM) = tcrit(1) - tAL;
            Sdat.(semo).(sspk).datalign.(stal).tcrit.tnoun(IM) = tcrit(2) - tAL;
            Sdat.(semo).(sspk).datalign.(stal).tcrit.tverb(IM) = tcrit(3) - tAL;
            Sdat.(semo).(sspk).datalign.(stal).tcrit.tend(IM) = tcrit(4) - tAL;
           
        end
    end
end

%______
%
% Specific functions to process Tobii data from "Emozione" project

% --- Return the format string used by textscan to read Emozion data file
% Define the number of AOI columns from the hdr line
function fcol = format_scan(hdr)
% Number of AOI columns
Naoi = length(strfind(hdr, 'AOI'));
faoii = repmat('%f ', 1, Naoi);
faoi = faoii;
fcol = ['%s %s %f %f %f %f %s ', repmat('%f ', 1, 12), faoi];
% Choose %f for the integer numbers to keep NaN values (convert to "0" with
% %d format)

    
% --- Format the field names of the header string
function hnames = format_hdr(hdr)

% Retrieve names of the fields from the header line
% Remove space before bracket
hdr = strrep(hdr, ' (', '_');
% Remove brackets
hdr = strrep(hdr, ')', '');
% Rename AOI filed names
hdr = strrep(hdr, 'AOI[','AOI_');
hdr = strrep(hdr, ']Hit','');
% Remove unwanted characters at the begining
hdr = regexprep(hdr, '[^a-zA-Z_0-9\s]','');

% Remove last blank or tabulation
dd = double(hdr);
if dd(end)==9
    hdr = hdr(1:end-1);
end

% Split the string to extract field names
hnames = strsplit(hdr);


% --- Read tsv Tobii data file
function [Cdat, hdr] = read_tobiifile(fpath)

% Open the file
fid = fopen(fpath); 

% Get the header line
hdr = fgetl(fid);

% Format of the data to read in the file (conversion specifier string)
% Special function (see below) - number of format string depend on the
% number of AOI columns
fcol = format_scan(hdr);

% Get the data 
Cdat = textscan(fid, fcol,  'Delimiter', '\t', 'EmptyValue', NaN); 
% Return 1 x 271 cell 

% Close the file
fclose(fid);


% --- Return the cellstr of unique media file names
function  umednames = emoz_medianames(Cmed)

umed = unique(Cmed);
iok = zeros(length(umed), 1);
for im = 1 : length(umed)
    if ~strcmp(umed{im}, 'NaN') && isempty(strfind(umed{im}, 'train'))
        iok(im) = im;
    end
end
umednames = umed(iok>0);


% --- Find speaker gender and emotions names from the media file names
function Smed = emoz_scan_mednames(umednames)

% We can't do the method with strsplit because file names are not
% consistents...
speaker = cell(length(umednames), 1);
emotion = cell(length(umednames), 1);
comb = cell(length(umednames), 1);

audio = {'stat','incr','happ','sad', 'fear', 'anger'};
audiot = {'neutral','incredulity','happiness','sadness', 'fear', 'anger'};
for i = 1 : length(umednames)
    snam = umednames{i};
    if strcmpi(snam(1),'m')
        speaker{i} = 'man';
    else
        speaker{i} = 'woman';
    end
    for j = 1 : length(audio)
        if ~isempty(strfind(snam, audio{j}))
            emotion{i} = audiot{j};
            comb{i} = [speaker{i},'_',emotion{i}];
        end
    end
end   
Smed.mednames = umednames;
Smed.spk = speaker;
Smed.emot = emotion;
Smed.combnam = comb;


function Sdat = ini_struct(Smed, usubj, falign)

umedf = Smed.mednames;
uemot = unique(Smed.emot);
uspk = unique(Smed.spk);

Nemo = length(uemot);
Nspk = length(uspk);

Nsubj = length(usubj);

Nali = length(falign);

Sdat = struct;
for i = 1 : Nemo
    emoz = uemot{i};
    
    for j = 1 : Nspk
        sspk = uspk{j};
        
        % Find corresponding medias
        imed = strcmp(Smed.combnam, [sspk,'_', emoz]);
        
        % Number of media per condition (emotion)
        Nmed = sum(imed);
        
        Sres = [];
        Sres.subj = usubj;
        Sres.medianames = umedf(imed);               
 
        % 1 : click on correct AOI ; 0 : on bad AOI or no click at all
        Sres.corclick = zeros(Nmed, Nsubj);
        % Add norming results
        Sres.norming = zeros(Nmed, 1);

        % Add speech frequency analysis results
        Sres.freq = struct('t1', NaN(Nmed, 1),...
                            't2', NaN(Nmed, 1),...
                            'slope', NaN(Nmed, 1),...
                            'time', NaN(Nmed, 1));
        
        Sdat.(emoz).(sspk) = Sres;
        
        % Add data dependent on the critical time used for alignment
        for k = 1 : Nali
            stalig = falign{k};

            Sdata = [];
            % Only correct AOI are taken into account
            % = consistent with the speaker intonation
            
            % Time vectors won't be the same per subject (duration function
            % of reaction time + change of sampling frequency between the 
            % 1st and 2nd part of the experiment)
            Sdata.time = cell(Nmed, Nsubj);
            
            % 1 : Correct AOI is fixated, 0 : not fixated
            Sdata.isfix = cell(Nmed, Nsubj); 

            Sdata.tclick = zeros(Nmed, Nsubj);
            
            % Critical times per media 
            Sdata.tcrit.tbeg = zeros(Nmed, 1); % Begining of the sentence
            Sdata.tcrit.tnoun = zeros(Nmed, 1);  % End of the noun
            Sdata.tcrit.tverb = zeros(Nmed, 1);  % End of the verb
            Sdata.tcrit.tend = zeros(Nmed, 1); % End of the sentence
            
            % Big structure
            Sdat.(emoz).(sspk).datalign.(stalig) = Sdata;         
        end
    end
end