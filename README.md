
# Collection of my experiments on data formats for conversion between Matlab and Python

The general approach has been with 1 or 2 files. The header has been XML, textual and more recently JSON getting the best flexibility. In most cases vectorial fields have been supported, in  one case also general tensor field.

Matlab loading moved from dataset to table, Python loading moved from flat numpy to record numpy. Most implementations are asymmetric due to the fact that writing has been done either in Python or C++.

Optimal design:
- header with JSON prefixed with magic and textual length of the JSON: magic length_hex JSON crlf binary
- arbitrary layout with flexible fields
- Matlab loading as table
- Python loading as numpy record or pandas DataFrame
- streaming: variable length (-1 rows) and then additional meta file

## fmt_jsonflex

Year: 2018

JSON header + uniform content

Used in: VF

Implementation:
- Matlab
- Python producer

## fmt_xbinmeta

Year: 2017

Metadata file and C-record like content. This is the most sophisticated structured output, where every variable can be a tensor

Used in: VI

Implementation:
- Matlab
- Python
- C++ producer: not shared

## fmt_binmeta

Year: 2011-2018

Metadata file and flat binary file uniformely typed

Used in: SG

Implementation:
- Matlab
- Python producer

## tensorload

Year: 2016

Loading a block of uniformely typed data with tensor shape as col or row major

Used in: https://github.com/eruffaldi/nested-tensors/blob/master/binload.m

Implementation:
- Matlab
- Python

## fmt_xbinmeta0 

Year: 2011-2014

Metadata file in XML and binary record

Used in: MO

Implementation:
- Matlab
- Python
- C++ producer: not shared


## fmt_traj

Year: 2006

Used in: standardized

http://jks-folks.stanford.edu/haptic_data/#code
