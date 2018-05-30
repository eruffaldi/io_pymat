
function r = mydataload(bn,ifrom,ito,xtype)
% 
% Emanuele Ruffaldi PERCRO-SSSA 2012-2018
%
% See also:
% loadcompdata

if nargin < 4
    xtype = 'double';
end
if nargin < 3
    ito = [];
end
if nargin < 2
    ifrom =[];
end
if isempty(ifrom)
    ifrom = -1;
end
if isempty(ito)
    ito = -1;
end


gzfile = [bn,'.dat.gz'];
datfile = [bn,'.dat'];
matfile = [bn,'.mat'];
metafile = [bn,'.meta'];

if exist(matfile,'file') > 0 & isempty(ifrom) & isempty(ito)
    disp(['loading from matfile',matfile])
    f = load(matfile);
    r = f.data;
    return;
end

generatednow = 0;

if exist(datfile,'file') == 0
    if exist(gzfile,'file') > 0
        gunzip(gzfile);
        if exist(datfile,'file') == 0
            error(['decompression failed for:',gzfile])
        end
        generatednow = 1;
    else
        error(['missing data gz:' gzfile])
    end
end

fid = fopen(datfile,'rb');
if fid <= 0
    error('missingdat');
end
bp = loadmeta(metafile);

fields = bp.names;

if isfield(bp,'rows') == 0
    fseek(fid,0,'eof');
    bp.rows = ftell(fid)/8/bp.columns;
    fseek(fid,0,'bof');
end

if ifrom > 1
    fseek(fid,8*(ifrom-1)*bp.columns,'bof');
elseif ifrom <= 0
    ifrom = 0; % beginning
end
if ito < 1 | ito > bp.rows
    ito = bp.rows;
end

rep = 'X';
nrows = ito-ifrom+1;

d = fread(fid,[bp.columns,nrows],'double')';
if strcmp(xtype,'double') == 0
    dx = cast(d,xtype);
else
    dx = d;
end
fclose(fid);

if strcmp(fields{1},'time_unix') % compatibility
    % special here
    r = dataset([d(:,1:3),{'time_unix','pow_MW','blower'}]);
    r.mm = d(:,4:end);
else
    fpow = 'SP31.3AB191';
    fblow  ='SP31.3CC1200';
    ffirst = 'SP31.3SIB01CAAC';
    flevel = 'SP31.SIBIDANOMBLOW';
    mapping = {'SP31.SIBIDANOMLOCX','SP31.SIBIDANOMLOCY','SP31.SIBIDANOMLOCZ','SP31.SIBIDANOMLEVEL','SP31.SIBIDANOMLOCZONA','SP31.SIBIDANOMMIC','SP31.SIBIDANOMSTATUS'};
    
    ipow = find(strcmp(fields,fpow),1,'first');
    iblow = find(strcmp(fields,fblow),1,'first');
    ifirst = find(strcmp(fields,ffirst),1,'first');
    pitimeUnix = find(strcmp(fields,'pitimeUnix'),1,'first');
    r = dataset();
    if isempty(ipow) == 0    & bp.step > 0
        warning('old style loading');
        r.blower = d(:,iblow);
        r.pow_MW = d(:,ipow);
        r.mm = d(:,ifirst:(ifirst+21-1));
    else
        for J=1:length(bp.names)
            nn = bp.names{J};
            if isempty(nn)
                bp.names
                bp.columns
            else
                nn(nn == '.') = rep;
                nn(nn == '&') = rep;
                nn(nn == ' ') = rep;
                nn(nn == '-') = rep;
                if strcmp(bp.timefield,nn)
                    r.(nn) = d(:,J);
                else
                    r.(nn) = dx(:,J);
                end
            end
        end
    end
    if bp.step == 0
        if isfield(bp,'timefield')
            hastimefield = 1;
            if strcmp('time_unix',bp.timefield) == 0
                r.time_unix = r.(bp.timefield);
            end
        else
            hastimefield = 0;
        end
    else
        hastimefield = 1;
        r.time_unix = (bp.firsttime_unix:bp.step:(bp.firsttime_unix+bp.step*(size(d,1)-1)))';
    end
    if isempty(pitimeUnix) == 0
        r.pitime = timeunix2mat(r.pitimeUnix);
    end
    
    nmic = 0;
    i1 = find(strcmp(fields,'mm01'),1,'first');
    if isempty(i1)
        i1 = find(strcmp(fields,'mm1'),1,'first');
    end
    for J=1:100
        idx = find(strcmp(fields,sprintf('mm%02d',J)),1,'first');
        if isempty(idx) == 0
                nmic = J;
        else
            idx = find(strcmp(fields,sprintf('mm%d',J)),1,'first');
            if isempty(idx) == 0
                nmic = J;
            else
                break;
            end
        end
    end
    if nmic > 0
        mm = zeros(length(r),nmic);
        for J=1:nmic
            mm(:,J) = r.(fields{i1+J-1});
            r.(fields{i1+J-1}) = [];
        end
        r.mm = mm;
        
        i1 = find(strcmp(fields,'mmb01'),1,'first');
if isempty(i1) == 0
                mm = zeros(length(r),nmic);
        for J=1:nmic
            mm(:,J) = r.(fields{i1+J-1});
            r.(fields{i1+J-1}) = [];
        end
        r.mmb = mm;
end
        
        i1 = find(strcmp(fields,'mmg01'),1,'first');
        if isempty(i1) == 0
        mm = zeros(length(r),nmic);
        for J=1:nmic
            mm(:,J) = r.(fields{i1+J-1});
            r.(fields{i1+J-1}) = [];
        end
        r.mmg = mm;
        end
        
        i1 = find(strcmp(fields,'loc01'),1,'first');
        if isempty(i1) == 0
        loc = zeros(length(r),3);
        for J=1:3
            loc(:,J) = r.(fields{i1+J-1});
            r.(fields{i1+J-1}) = [];
        end
        r.loc = loc;
        end
    end


end

first = datenum([1970 1 1 0 0 double(r.time_unix(1))]);
if hastimefield 
    r.time = (r.time_unix-r.time_unix(1))/(24*3600) + first;
end

ud = [];
ud.meta = bp;
ud.datfile = datfile;
ud.basename =bn;
if length(r) > 1
    ud.timestep_sec = r.time_unix(2)-r.time_unix(1);
else
    ud.timestep_sec = NaN;
end

data = set(r,'UserData',ud);


%    save(matfile,'data');

r = data;

% DELETE datfile ONLY if we unzipped this time
%if generatednow == 1
%    delete(datfile);
%end