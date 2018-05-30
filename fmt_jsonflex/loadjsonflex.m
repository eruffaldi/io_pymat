% read extended binary file
%
% Emanuele Ruffaldi 2018
function [r,h] = fancybin(x,headonly)

if nargin == 1
    headonly = 0;
end
if ischar(x)
    fid = fopen(x,'r');
    fopened = 1;
else
    fid = x;
    fopened = 0;
end
n = fscanf(fid,'%08X');
if n == -1
    h = jsondecode(fread(fid,'*char'));
else
    h = jsondecode(fread(fid,n,'uint8=>char'));
end
if headonly
    if ischar(x)
        fclose(fid);
    end
    % otherwise keep open
    r = [];
    return;
end
if isfield(h,'datafile')
    nx = h.datafile;
    [PATHSTR,NAME,EXT] = fileparts(x);
    file=java.io.File(nx);
    if ~file.isAbsolute()
    	nx = [pathstr,nx];
    end
    if fopened
        fclose(fid);
    end
    fid = fopen(nx,'r');
    fopend = 1;
    if isfield(h,'autooffset') && h.autooffset == 1
        fancybin(fid,1); % ignore header
    end
    if isfield(h,'offset')
        fseek(fid,h.offset,0);
    end
    % continu as original
end 
if isfield(h,'precision')
    p = h.precision;
else
    p = 'double';
end
nc = length(h.fieldnames);
[t,s] = precision2mat(p);
if isfield(h,'rows')
    nr = h.rows;
    % fixed size
    d = fread(fid,nr*nc,t);
else
    % as much as possible
    d = fread(fid,Inf,t);
    nr = length(d)/nc;
end
d = reshape(d,[nc,nr])';
% make it a dataset
r = mat2dataset(d,'VarNames',h.fieldnames);
r.UserData = h;
if fopened
    fclose(fid);
end
  
% then reshape and quit

function [t,s] = precision2mat(p)
    t = p;
    switch(p)
        case 'double'
            s = 8;
        case 'single'
            s = 4;
        case 'int32'
            s = 4
        case 'int64'
            s = 8
        case 'uint8'
            s = 1;
    end
            