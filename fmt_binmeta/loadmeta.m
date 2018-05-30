function r = loadmeta(name)

fid = fopen(name,'r');
if isempty(fid)
    r = [];
    return;
end

c = textscan(fid, '%s','Delimiter','');
c = c{1};
r = [];
for I=1:length(c)
    v = c{I};
    k = find(v==':',1,'first');
    if isempty(k)
        try
            r.(k) = [];
        catch me
            r.(sprintf('item%d',I)) = k;
        end
    else
        n = v(1:k-1);
        v = v(k+1:end);
        try
            [vv,ok] = str2num(v);
            if ok == 1
                v = vv;
            else
                if v(1) == ' '
                    v = v(2:end);
                end
            end
            r.(n) = v;
        catch me
            r.(sprintf('item%d',I)) = {n,v};
        end
    end
end
if isfield(r,'names') == 0
    r.names = r.columns;
    r.columns = [];
end

if isfield(r,'names')    
    w = r.names;
    w = strsplit(w,'\t');
    if isempty(w{end})
        w = w(1:end-1);
    end
    r.names = w;
    if isempty(r.columns)
        r.columns = length(w);
    end
end
fclose(fid);
