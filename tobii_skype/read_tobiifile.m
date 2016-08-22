function [Cdat, hnames] = read_tobiifile(tsvpath)
% Read the fixations data inside the Tobii's exported TSV file.
% 
% -- Input parameters
%  - tsvpath: path of the tsv file
%    Ex.: C:/data/tobii_export/project_P02.tsv
%
% -- Output
%   - Cdat: cell with all the data (one column per column of the tsv file)
%   - hnames: formatted names of the columns
% 
% Check the list that set the links between the column names of the Tobii 
% file and the data format in the tobii_allcolformat function inside this
% file.
% 
%
%-CREx 20160314 
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/tobii_skype

% --- Read tsv Tobii data file
% Open the file
fid = fopen(tsvpath); 

% Get the header line
hdr = fgetl(fid);

% Format hdr
hnames = format_hdr(hdr);

% Format of the data to read in the file (conversion specifier string)
% Special function (see below) - number of format string depend on the
% number of AOI columns
fcol = format_columns(hnames);

% Get the data 
Cdat = textscan(fid, fcol,  'Delimiter', '\t', 'EmptyValue', NaN); 
% Return 1 x 271 cell 

% Close the file
fclose(fid);


% --- Format the field names of the header string
function hnames = format_hdr(hdr)
    % Remove spaces and special characters from header string
    % Return cell of column names

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

% Find AOI column indices (and total number)
function [iaoi, Naoi] = find_aoicol(hnames)
    chdr = char(hnames);
    chdr = cellstr(chdr(:, 1:3));
    iaoi = find(strcmpi(chdr, 'aoi')==1);
    if ~isempty(iaoi)
        Naoi = length(iaoi);
    else
        Naoi = [];
    end
    
% --- Return the format string used by textscan to read data file
function fcol = format_columns(hnames)
    % Deduce the format string to read the file 
    % Regarding column names (that was pre-formatted using format_hdr
    % to remove special characters...)
    poscol = tobii_allcolformat;

    % Check for AOI columns first
    [iaoi, Naoi] = find_aoicol(hnames);
    if ~isempty(iaoi)
        fcolaoi = [' ',repmat('%f ', 1, Naoi)];
    else
        fcolaoi ='';
    end

    Ncol = length(hnames) - Naoi;
    fcolp = cell(Ncol, 1);
    for i = 1 : Ncol
        namcol = hnames{i};
        icol = find(strcmp(namcol, poscol(:,1))==1);
        if ~isempty(icol)
            fcolp(i) = poscol(icol, 2);
        end
    end
    % Concat all formats 
    fcol = [strjoint(fcolp, ' '), fcolaoi];

%--- Return all possible column names (preformatted)
function allcol = tobii_allcolformat
% Choose %f for the integer numbers to keep NaN values (convert to "0" with
% %d format)
allcol = { 'ExportDate', '%s'
    'StudioVersionRec', '%s'
    'StudioProjectName', '%s'
    'StudioTestName', '%s'
    'ParticipantName', '%s'
    'RecordingName', '%s'
    'RecordingDate', '%s'
    'RecordingDuration', '%f'
    'RecordingResolution', '%s'
    'FixationFilter', '%s'
    'MediaName', '%s'
    'MediaPosX_ADCSpx', '%f'
    'MediaPosY_ADCSpx', '%f'
    'MediaWidth', '%f'
    'MediaHeight', '%f'
    'SegmentName', '%s'
    'SegmentStart', '%f'
    'SegmentEnd', '%f'
    'SegmentDuration', '%f'
    'SceneName', '%s'
    'SceneSegmentStart', '%f'
    'SceneSegmentEnd', '%f'
    'SceneSegmentDuration', '%f'
    'RecordingTimestamp', '%f'
    'LocalTimeStamp', '%s'
    'EyeTrackerTimestamp', '%f'
    'MouseEventIndex', '%f'
    'MouseEvent', '%s'
    'MouseEventX_ADCSpx', '%f'
    'MouseEventY_ADCSpx', '%f'
    'MouseEventX_MCSpx', '%f'
    'MouseEventY_MCSpx', '%f'
    'KeyPressEventIndex', '%f'
    'KeyPressEvent', '%s'
    'StudioEventIndex', '%f'
    'StudioEvent', '%s'
    'StudioEventData', '%s'
    'ExternalEventIndex', '%f'
    'ExternalEvent', '%s'
    'ExternalEventValue', '%s'
    'FixationIndex', '%f'
    'SaccadeIndex', '%f'
    'GazeEventType', '%s'
    'GazeEventDuration', '%f'
    'FixationPointX_MCSpx', '%f'
    'FixationPointY_MCSpx', '%f'
    'GazePointIndex', '%f'
    'GazePointLeftX_ADCSpx', '%f'
    'GazePointLeftY_ADCSpx', '%f'
    'GazePointRightX_ADCSpx', '%f'
    'GazePointRightY_ADCSpx', '%f'
    'GazePointX_ADCSpx', '%f'
    'GazePointY_ADCSpx', '%f'
    'GazePointX_MCSpx', '%f'
    'GazePointY_MCSpx', '%f'
    'GazePointLeftX_ADCSmm', '%f'
    'GazePointLeftY_ADCSmm', '%f'
    'GazePointRightX_ADCSmm', '%f'
    'GazePointRightY_ADCSmm', '%f'
    'StrictAverageGazePointX_ADCSmm', '%f'
    'StrictAverageGazePointY_ADCSmm', '%f'
    'EyePosLeftX_ADCSmm', '%f'
    'EyePosLeftY_ADCSmm', '%f'
    'EyePosLeftZ_ADCSmm', '%f'
    'EyePosRightX_ADCSmm', '%f'
    'EyePosRightY_ADCSmm', '%f'
    'EyePosRightZ_ADCSmm', '%f'
    'CamLeftX', '%f'
    'CamLeftY', '%f'
    'CamRightX', '%f'
    'CamRightY', '%f'
    'DistanceLeft', '%f'
    'DistanceRight', '%f'
    'PupilLeft', '%f'
    'PupilRight', '%f'
    'ValidityLeft', '%f'
    'ValidityRight', '%f'
    };