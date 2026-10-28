function names=Lab4_Vernier_Sheets(file)
% Return exact worksheet names; do not guess a sheet when several exist.
try
    names=cellstr(sheetnames(file));
catch
    [~,names]=xlsfinfo(file);
end
if isempty(names),error('No readable Excel worksheets found.');end
names=reshape(names,1,[]);
end
