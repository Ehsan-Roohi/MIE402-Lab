function [t,x,meta] = Lab5_Read_Vernier(file,columns,sheet)
% Read Vernier CSV/XLSX/XLS exports. Return original timestamps and position.
% columns = [timeColumn positionColumn]; omit only for unambiguous headers.
if nargin<2, columns=[]; end
if nargin<3, sheet=1; end
[~,~,ext]=fileparts(file);
if any(strcmpi(ext,{'.xlsx','.xls'}))
    raw=readcell(file,'Sheet',sheet);
else
    raw=readcell(file);
end
n=size(raw,1); p=size(raw,2); data=nan(n,p);
for j=1:p
    for i=1:n
        v=raw{i,j};
        if isnumeric(v)&&isscalar(v), data(i,j)=double(v);
        elseif ischar(v)||isstring(v), data(i,j)=str2double(strtrim(string(v))); end
    end
end
if isempty(columns)
    tc=[]; xc=[];
    for j=1:p
        for i=1:min(n,30)
            v=raw{i,j};
            if ischar(v)||isstring(v)
                s=lower(char(string(v)));
                if contains(s,'time'), tc(end+1)=j; end %#ok<AGROW>
                if contains(s,'position')||contains(s,'distance'), xc(end+1)=j; end %#ok<AGROW>
            end
        end
    end
    tc=unique(tc); xc=unique(xc);
    if numel(tc)~=1||numel(xc)~=1||tc==xc
        error('Lab5:Columns','Multiple runs or unclear headers. Specify [time position] column numbers; use one run per export.');
    end
    columns=[tc xc];
end
if numel(columns)~=2||any(columns<1)||any(columns>p)||any(columns~=fix(columns))||columns(1)==columns(2)
    error('Lab5:Columns','Enter two distinct valid column numbers.');
end
valid=all(isfinite(data(:,columns)),2);
% Do not join separated runs or sort a recording with time resets.
edges=diff([false;valid;false]); starts=find(edges==1); stops=find(edges==-1)-1;
if isempty(starts), error('Lab5:Data','No paired numeric time and position data.'); end
[~,q]=max(stops-starts+1); rows=starts(q):stops(q);
t=data(rows,columns(1)); x=data(rows,columns(2));
if numel(t)<30||any(diff(t)<=0)
    error('Lab5:Time','Need at least 30 samples with increasing time; export a single run.');
end
dt=median(diff(t));
if max(abs(diff(t)-dt))>0.05*dt
    error('Lab5:Sampling','Time spacing varies by more than 5%%. Check the export and missing samples.');
end
meta=struct('columns',columns,'sheet',sheet,'fs_Hz',1/dt,'rows',rows);
end
