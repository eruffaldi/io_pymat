function ds = loaddat(filename)

metafile = [filename(1:end-3),'xml'];
fid = fopen(metafile,'r');
if fid == -1
    error(['Cannot load ' metafile]);
end
tline = fgets(fid);
names = {};
params = [];
while ischar(tline)
    k = strfind(tline,'<column name="');
    if isempty(k) == 0
       tline = tline(k+(length('<column name="')):end);
       k = strfind(tline,'"');
       names{end+1} = tline(1:k-1);
    else 
        k = strfind(tline,'<param name="');
        if isempty(k) == 0
           k2 = strfind(tline,'value="');
           tmp = tline(k2+(length('value="')):end);
           k2 = strfind(tmp,'"');
           tmp = tmp(1:k2-1);                      
           
           tline = tline(k+(length('<param name="')):end);
           k = strfind(tline,'"');
           
           params.(tline(1:k-1)) = tmp;
        end
    end    
    tline = fgets(fid);
end
fclose(fid);

if isfield(params,'baseTime_epoch_ms')
    params.baseTime_epoch_ms = str2mat(params.baseTime_epoch_ms );
end

[u,i] = unique(names);
if length(u) < length(names)
	names
end

fields = names;
    fp = fopen(filename,'rb');
if fp == -1
    error(['Cannot load ' filename]);
end
    d = fread(fp,[length(fields) Inf],'single')';
    if isempty(d)
        d = zeros(1,length(fields));
    end
    ds = dataset([d,fields]);
    fclose(fp);
ds = set(ds,'UserData',params);