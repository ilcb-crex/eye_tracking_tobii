% Batch processing script to convert Tobii's exported data files in Elan's
% annotation files.
% The tobii2elan function is launched to convert all the Tobii's files that
% are stored in a directory.
% tobii2elan's function require the read_tobiifile function.
% All theses functions are available in the GitHub repository.
%
%-CREx 20160314 
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/tobii_skype
% 
%--- ! Parameters to set directely inside this batch file:
%
% - Path of the main directory that contains the Tobii's tsv files 
%   directory
%   Ex. : pdir = 'C:/data/tobii'
%
% - Name of the directory containing Tobii's file in the main directory
%   Ex.: tobiidir = 'data_tobii_export'
%   (tsv files will be searched inside C:/data/tobii/data_tobii_export)
%
% - Name of the directory where Elan's files will be saved. It will be 
%  created inside the main directory.
%   Ex.: elandir = 'data_elan_import' (=> Elan file will be saved in
%   C:/data/tobii/data_elan_import)
%---

% ----- PARAMETERS 
pdir = 'C:/data/tobii';

% Name of the directory that contains Tobii's tsv files (inside the main
% directory).
tobiidir = 'data_tobii_export';

% Name of the directory that will be created to store Elan's files
elandir = 'data_elan_import';

% ----- END


% List of all tsv files in Tobii file directory
tobfiles = dir([pdir, filesep, tobiidir, filesep, '*.tsv']);

% Make directory to save Elan's files
elanpath = make_dir([pdir, filesep, elandir], 0);

% Format each Tobii's file in Elan's file
for i = 1 : length(tobfiles)
    tsvpath = [pdir, filesep, tobiidir, filesep, tobfiles(i).name];
    tobii2elan(tsvpath, elanpath)
end