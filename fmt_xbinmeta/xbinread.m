function [r,data] = xbinread(fid,keep)
% 
% Yet Another Metadata format: first text lines (cflf) then binary
%
% # comment(s)
% format strings C-Like, 1 packed
% size
% header: value
% <empty>
%
%
% Emanuele Ruffaldi 2017
%
% I am avoiding the use of c
% struct, so we'll load everything using fread.
% This has the side effect of reading the file multiple times. At least we
% do optimize contiguous types. E.g. if everything is int16 we'll have one
% single fread.
%
% [r,data] = xbinread(fid,keep)
% 
% FID can be a string or file descriptor (fopen)
% KEEP is optional (default 0). If 1 preserve the type otherwise converts
% to double
%
% R is the output metadata (fields, headers, rowsize, original content
% string)
% DATA is the output structure as N x S where S is the size of each field.
% This can be easily converted into Table (or dataset).
if isstr(fid)
	fid = fopen(fid,'r');
end
if nargin == 1
    keep = 0;
end
stage = 0;
content = '';
headers = [];
rowsize = 0;
while 1
	tline = fgetl(fid);
	if isempty(tline)
		break
	end
	if tline(1) == '#'
		continue
	end
	if stage == 0
		content = tline;
		stage = stage + 1;
	elseif stage == 1
		rowsize = str2double(tline);
		stage = stage + 1;
	else
		disp(tline)
		k = find(tline == ':',1,'first');
		headers.(tline(1:k-1)) = strtrim(tline(k+1:end));
        
        % TODO: json parse with available json parser
        % TODO: cmdline split by '\t'
	end
end
content = strsplit(content,';');
fields = [];
afields = {};
for J=1:length(content)
    c = strtrim(content{J});
    if isempty(c)
        break
    end
    q = strsplit(c,' ');
    xtype = q{1};
    qq = strsplit(q{2},'[');
    xname = qq{1};
    xsizes = [];
    for K=2:length(qq)
        xsizes(end+1) = str2double(qq{K}(1:end-1));
    end
    field = [];
    field.name = xname;
    field.sizes = xsizes;
    field.type = xtype;
    fields.(xname) = field;
    afields{end+1} = field;
end

r =[];
r.headers = headers;
r.content = content;
r.rowsize = rowsize;
r.fields = fields;

if nargout == 2
    % now process data
    datastart = ftell(fid);
    istart = 1;
    out = [];
    while istart <= length(afields)
        istart
        % all with the same type
        xt = afields{istart}.type;
        iend = istart+1;
        extent = prod(afields{istart}.sizes);
        while iend <= length(afields)
            if strcmp(afields{iend}.type,xt) == 0
                iend = iend - 1;
                break;
            else
                extent = extent + prod(afields{iend}.sizes);
                iend = iend +1;
            end
        end
        iend = min(iend,length(afields));
        sametype = [istart,iend,extent];
        fseek(fid,datastart,'bof');
        
        z = item2mat(xt);
        if keep 
            p = sprintf('%d*%s=>%s',extent,z,z);
        else
            p = sprintf('%d*%s',extent,z);
        end
        data = fread(fid,Inf,p,rowsize-extent*itemsize(xt));
        data = reshape(data,extent,[])'; % N x extent
        offset = 1;
        rows = size(data,1);
        for J=istart:iend
            if isempty(afields{J}.sizes)
                n = 1;
            else
                n = prod(afields{J}.sizes);
            end
            eoffset = offset+n-1;
            pdata = data(:,offset:eoffset);
            if length(afields{J}.sizes) > 1
                % data is stored in row major, matlab is col major
                % flip the target sizes
                w = fliplr([rows,afields{J}.sizes]);
                % transpose the input
                % and permute the indices
                pdata = permute(reshape(pdata',w),length(w):-1:1);
            end
            out.(afields{J}.name) = pdata;
            offset = offset + n;
        end
        
        istart = iend+1;
    end
    data =out;
end

function y =  itemsize(xt)

switch xt
    case {'uint32_t','int32_t','float'}
        y= 4;
    case {'double','int64_t','uint64_t'}
        y = 8;
    case {'int16_t','uint16_t'}
        y = 2;
    case {'byte','uint8_t','int8_t','char'}
        y = 1;
    otherwise
        y = 0;
             
end

function y =  item2mat(xt)

switch xt
    case {'uint32_t','uint16_t','int16_t','int32_t','int8_t','uint8_t'}
        y = xt(1:end-2);
    case 'float'
        y = 'float32';
    case 'char'
        y = 'schar';
    case 'double'
        y = xt;
    otherwise
        y                    
end