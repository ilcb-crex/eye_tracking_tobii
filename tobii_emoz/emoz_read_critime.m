function Scrit = emoz_read_critime(critpath)
% Read critical times from file designed by critpath path
% The file is expected to be formatted with 6 columns:
% [1] media name (avi fideo file name)
% [2] critical time in seconds = beginning of the sentence
% [3] critical time in seconds = end of the noun
% [4] critical time in seconds = end of the verb
% [5] critical time in seconds = end of the sentence
% [6] sentence (string)
%
% Only the first 5 columns are kept and stored in Scrit structure with
% field mednam, tbeg, tnoun, tverb and tend
%
%____
%-CREx 20151220
% ANR RAPP C. Petrone http://www.lpl-aix.fr/~petrone/projectf.html
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/emoz

fid = fopen(critpath);
A = textscan(fid, '%s%f%f%f%f%s', 'delimiter','\t', 'headerlines', 1);
fclose(fid);

Scrit = [];
Scrit.mednam = A{1};
Scrit.tbeg = A{2};
Scrit.tnoun = A{3};
Scrit.tverb = A{4};
Scrit.tend = A{5};