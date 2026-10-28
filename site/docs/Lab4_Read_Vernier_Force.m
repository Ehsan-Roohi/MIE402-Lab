function [data,names,sheet] = Lab4_Read_Vernier_Force(file,sheet)
% Read a Vernier export with text header/unit rows, keeping worksheet columns.
% A worksheet is mandatory when a workbook has more than one sheet.
% Output is numeric with NaN for nonnumeric cells; the caller chooses columns.
if nargin<2, sheet=''; end
[~,~,ext]=fileparts(file); ext=lower(ext); sep='';
if ~exist(file,'file'),error('File does not exist: %s',file);end
if ismember(ext,{'.xlsx','.xls','.xlsm'})
    if exist('OCTAVE_VERSION','builtin')
        error('Excel reading requires MATLAB. In Octave export the worksheet as CSV.');
    end
    sheets=Lab4_Vernier_Sheets(file);
    if isempty(sheet)
        if numel(sheets)>1
            error('This workbook has multiple sheets. Select the worksheet containing Time and Force.');
        end
        sheet=sheets{1};
    elseif isnumeric(sheet)
        if ~isscalar(sheet)||sheet~=round(sheet)||sheet<1||sheet>numel(sheets),error('Invalid worksheet number.');end
        sheet=sheets{sheet};
    else
        sheet=char(sheet);
        if ~any(strcmp(sheets,sheet)),error('Worksheet not found in this workbook.');end
    end
    try
        cells=readcell(file,'Sheet',sheet);
    catch err
        error('Cannot read worksheet "%s": %s',sheet,err.message);
    end
elseif ismember(ext,{'.csv','.txt','.tsv'})
    sheet='';
    % Read text lines directly, allowing metadata lines with fewer delimiters.
    fid=fopen(file,'r'); if fid<0,error('Cannot open file: %s',file);end
    cleaner=onCleanup(@()fclose(fid));lines={};
    while true
        line=fgetl(fid);if ~ischar(line),break;end
        if ~isempty(line) && double(line(1))==65279,line=line(2:end);end
        lines{end+1,1}=line; %#ok<AGROW>
    end
    if isempty(lines),error('The selected file is empty.');end
    tabs=sum(cellfun(@(v)sum(v==sprintf('\t')),lines));
    commas=sum(cellfun(@(v)sum(v==','),lines));
    semis=sum(cellfun(@(v)sum(v==';'),lines));
    if tabs>=commas && tabs>=semis && tabs>0,sep=sprintf('\t');
    elseif semis>commas,sep=';';else,sep=',';end
    rows=cell(size(lines)); ncol=0;
    for i=1:numel(lines)
        % A comma inside a quoted field does not delimit a column.
        rows{i}=parseDelimitedLine(lines{i},sep); ncol=max(ncol,numel(rows{i}));
    end
    cells=cell(numel(rows),ncol);
    for i=1:numel(rows), cells(i,1:numel(rows{i}))=rows{i}; end
else
    error('Select a CSV, TXT, TSV, XLS, XLSX or XLSM file. If your Vernier file is a project file, export the data as CSV first.');
end
if isempty(cells),error('The selected sheet contains no data.');end
if ~iscell(cells),cells=num2cell(cells);end
[nrow,ncol]=size(cells);data=nan(nrow,ncol);names=cell(1,ncol);
for col=1:ncol
    labels={};
    for row=1:nrow
        item=cells{row,col};v=NaN;
        if isnumeric(item) && isscalar(item) && isreal(item)
            v=double(item);
        elseif ischar(item) || (isstring(item)&&isscalar(item))
            str=strtrim(char(item));
            if ~isempty(str)
                if strcmp(sepIfText(ext,sep),'semicolon') && ~isempty(regexp(str,'^[+-]?\d+,\d+([eE][+-]?\d+)?$','once'))
                    str=strrep(str,',','.');
                end
                v=str2double(str);
                if row<=20 && ~isfinite(v) && numel(str)<120
                    labels{end+1}=str; %#ok<AGROW>
                end
            end
        end
        data(row,col)=v;
    end
    labels=unique(labels,'stable');
    if isempty(labels),names{col}=sprintf('Column %d',col);
    else,names{col}=strjoin(labels,' | ');end
end
if sum(sum(isfinite(data),1)>=30)<2
    error('Could not find two columns with at least 30 numeric samples. Select the Time/Force worksheet or export one run as CSV.');
end
end
function s=sepIfText(ext,sep)
% Avoid accessing an unset delimiter for spreadsheets.
if ismember(ext,{'.csv','.txt','.tsv'}) && strcmp(sep,';'),s='semicolon';else,s='other';end
end
function c=parseDelimitedLine(line,sep)
c={};v='';quoted=false;i=1;
while i<=numel(line)
    ch=line(i);
    if ch=='"'
        if quoted && i<numel(line) && line(i+1)=='"',v=[v '"'];i=i+1;else,quoted=~quoted;end %#ok<AGROW>
    elseif ch==sep && ~quoted
        c{end+1}=v;v=''; %#ok<AGROW>
    else
        v=[v ch]; %#ok<AGROW>
    end
    i=i+1;
end
if quoted,error('Malformed CSV line: unmatched quotation mark.');end
c{end+1}=v;
end
