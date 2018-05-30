% Binary Tensor Loader
%
% This function loads data from a file f (filename or fid) with type t (e.g. float64,int64)
% and it loads as specified by the dimensions in xdims
%
% When loadall is true the file is consumed in a way to repeat the xdims
% copies otherwise exactly xdims items are being loaded
%
% major specifies the storage major (Matlab is col, Numpy is row). In row
% major the repetition of xdims (when loadall=1) is outer, while in col
% major it is inner (when loadall=1).
%
% This function allows to reload binary tensor content from numpy as saved 
% with tofile
%
% Verification: generate using ngrid and compare result with meshgrid
% interpolant
%
% Emanuele Ruffaldi 2016
function r = binload(f,t,xdims,loadall,major)

if nargin == 3
    loadall = 1;
end

if nargin < 5
    major = 'column'; % as matlab
end

if ischar(f)
    f = fopen(f,'r');
end
% load all possible
if loadall
    r = fread(f,Inf,t);
    
    if length(r) == prod(xdims)
        n = 0;
    else
        n = length(r)/prod(xdims);
    end
else
    r = fread(f,prod(xdims),t);    
    n = 0;
end

if n == 0
    % we have exactly the content
    if strcmp(major,'column')
        r = reshape(r,xdims);
    else
        r = reshape(r,xdims(end:-1:1));
        r = permute(r,length(xdims):-1:1);
    end
else
    % we have n blocks with given columns: 
    % row major = blocks are outer
    % col major = blocks are inner
    if strcmp(major,'column')
        r = reshape(r,[xdims n]);
    else
        xdims = [n xdims];
        r = reshape(r,xdims(end:-1:1));
        r = permute(r,length(xdims):-1:1);
    end
end