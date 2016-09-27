% Specific program to process fixation data from tobii_emoz project
%
% This project concerns study of prosodic clues that would allow to detect early 
% the emotional state of the speaker.
%
% The experimental design includes video stimuli (fixed image with
% associated sound). Each image is subdivided in 2 images (x_midscreen = 513 in px).
% This batch allows the whole processing from the data extaction to the
% mean proportion curves computation.
%____
%-CREx 20151220
% ANR RAPP C. Petrone http://www.lpl-aix.fr/~petrone/projectf.html
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/emoz

% INPUT PARAMETERS ---------------

%-- Data file paths
%- Main path
datapath = 'C:\Users\zielinski\_Docs_\OnTheRoad\EyeTracking\Tobii_Emozione\data\';
%- Path of all required data file
% fixpath : Tobii expoted file (.tsv) with AOIs columns
% critpath : files of critical times (times of interest per media)
% normpath : path of file with norming study results (rate per condition)
% freqpth : file with frequency characteristics of auditive stimuli
datopt = [];
datopt.fixpath = [datapath, 'export_tobii', filesep, 'Emo*T0*P*.tsv'];
datopt.critpath = [datapath, 'critical_times.txt'];
datopt.normpath = [datapath, 'norming_auditive.txt'];
datopt.freqpath = [datapath, 'speech_f0_slope.txt'];


%-- Threshold of norming scales to select media
% Media with norming value inside the threshold interval will be defined as
% "good media" (confidence in emotion determination), those outside
% threshold interval will be defined as "bad media"
thrnorm = [];
thrnorm.fear = [0 1.5];
thrnorm.anger = [4.5 5];
thrnorm.sadness = [0 1.5];
thrnorm.happiness = [4.5 5];
thrnorm.neutral = [0 1.5];
thrnorm.incredulity = [4.5 5];

% GO ------------------------------

%-- Extract data from raw files and define data structure
Sdat = emoz_timeanalysis_extract(datopt);

%-- Compute logit

%- Prepare data
% Reassign data => common perfect time vector (fsamlp = 60 Hz)
% Same for all media and subjects
Sdat = emoz_timeanalysis_prepare(Sdat);

%- Compute the mean fixation for each realigned versions
Sta = emoz_timeanalysis_compute(Sdat, thrnorm);

%- Built the composite curve
Spatchw = emoz_timeanalysis_patchwork(Sta);

%- Save all these big structures
save Stimeanalysis_emoz Sdat Sta Spatchw

%-- Figures
% Add fieldname assertion (= "neutral") for the figure legend
Spatchw.assertion = Spatchw.neutral;

figopt = [];
% Pairs of condition to put on each graphic
figopt.supcond = {'assertion', 'incredulity' ; 'anger','fear' ; 'happiness', 'sadness'}; 
figopt.xlimits = [0 2600]; % in ms
emoz_timeanalysis_patchwork_fig(Spatchw, figopt)

% Figures for paper : 
% - refined title (only "Man speaker" or "Female speaker")
% - manually dragging of the legend before the autosave

emoz_timeanalysis_paper_fig(Spatchw, figopt)


