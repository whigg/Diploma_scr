function FINwd1 = readCRD(filename, startRow, endRow)
%readCRD Import numeric data from a text file as a matrix.
%   FINWD1 = readCRD(FILENAME) Reads data from text file FILENAME for
%   the default selection.
%
%   FINWD1 = readCRD(FILENAME, STARTROW, ENDROW) Reads data from rows
%   STARTROW through ENDROW of text file FILENAME.
%
% Example:
%   FINwd1 = readCRD('FIN_wd1.CRD', 5, 223);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2016/01/21 13:05:30

%% Initialize variables.
if nargin<=2
    startRow = 5;
    endRow = inf;
end

%% Format string for each line of text:
%   column1: double (%f)
%	column3: text (%s)
%   column5: text (%s)
%	column6: double (%f)
%   column7: double (%f)
%	column8: double (%f)
%   column10: text (%s)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%3f%2*s%4s%1*s%11s%15f%15f%15f%4*s%1s%[^\n\r]';

%% Open the text file.

if exist(filename, 'file') == 2
    fileID = fopen(filename,'r');


    %% Read columns of data according to format string.
    % This call is based on the structure of the file used to generate this
    % code. If an error occurs for a different file, try regenerating the code
    % from the Import Tool.
    textscan(fileID, '%[^\n\r]', startRow(1)-1, 'ReturnOnError', false);
    dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', '', 'WhiteSpace', '', 'ReturnOnError', false);
    for block=2:length(startRow)
        frewind(fileID);
        textscan(fileID, '%[^\n\r]', startRow(block)-1, 'ReturnOnError', false);
        dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', '', 'WhiteSpace', '', 'ReturnOnError', false);
        for col=1:length(dataArray)
            dataArray{col} = [dataArray{col};dataArrayBlock{col}];
        end
    end

    %% Close the text file.
    fclose(fileID);

    %% Post processing for unimportable data.
    % No unimportable data rules were applied during the import, so no post
    % processing code is included. To generate code which works for
    % unimportable data, select unimportable cells in a file and regenerate the
    % script.

    %% Create output variable
    dataArray([1, 4, 5, 6]) = cellfun(@(x) num2cell(x), dataArray([1, 4, 5, 6]), 'UniformOutput', false);
    FINwd1 = [dataArray{1:end-1}];

else 
    disp(['Error, no such file: ',filename])
end

end
