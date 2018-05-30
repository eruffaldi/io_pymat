# Numerizer by Emanuele Ruffaldi 2018
import datetime,csv,argparse,sys,time,signal,json,collections
import numpy as np,os

allinfo = []
def find(a,what):
    try:
        return a.index(what)
    except:
        return -1
def handler(signum, frame):
    for f in allinfo.values():
        f.flush()
    raise IOError("Quit")

def fixduplicate(fieldnames,what):
    i = find(fieldnames,what)
    if i < 0:
        return -1
    i2 = find(fieldnames[i+1:],what)
    if i2 >= 0:
        fieldnames[i2+i+1] = "_"+what
    return i
class binwriter:
    def __init__(self,of,fieldnames,precision,rows,missing):
        self.rows = rows
        self.missing = missing
        self.of = of
        self.fieldnames = fieldnames
        self.precision = precision
        self.typecode = "f" if precision == "single" else "d"
        #self.numpytype = np.float32 if precision == "float" else np.float64
        self.emitheader()
    @staticmethod
    def emitpureheader(outfile,header):
        w = json.dumps(header)+"\r\n\r\n"
        outfile.write("%08X" % len(w))
        outfile.write(w)
    def emitheader(self):
        self.header = dict(fieldnames=self.fieldnames,precision=self.precision)
        if self.rows != -1:
            self.header["rows"] = self.rows
        binwriter.emitpureheader(self.of,self.header)
        # for incremental during writerow
        self.header["rows"] = 0;
    def writerow(self,x):
        a = array.array(self.typecode)
        v = [self.missing if y == "" else float(y) for y in x]
        a.fromlist(v)
        #a[0] = x[0]
        #print a,a[1],x[1],v[1],type(x[1]),type(a[1]),a
        a.tofile(self.of)
        self.header["rows"] += 1  

def loadheader(inf):
    # for manually written files or pure JSON we put FFFFFFFF as size of JSON part
    q = inf.read(8)
    if q == "FFFFFFFF":
        return json.loads(inf.read())
    else:
        n = int(q,16)
        return json.loads(inf.read(n).rstrip())

def loadnumpy(inf,filesize=-1):
    h = loadheader(inf)
    p = h["precision"]
    if p == "single":
        cs = 4
        pt = np.float32
    elif p == "double" or p is None:
        cs = 8
        pt = np.float64
    elif p == "int32":
        cs = 4
        pt = np.int32
    elif p == "int64":
        cs = 8
        pt = np.int64
    elif p == "uint8":
        cs = 1
        pt = np.uint8
    else:
        raise Exception("unsupported precision: %s. Supported: single,double,uint8,int32,int64" % p)
    nc = len(h["fieldnames"])

    # external resource
    df = h.get("datafile")
    if df is not None:        
        if not os.path.isabs(df):        
            # TODO use special prefixs 
            if inf.name is not None:
                bp = os.path.dirname(inf.name) 
                df = os.path.join(bp,df)
        inf = open(df,"rb")
        filesize = os.stat(df).st_size
        if h.get("autooffset",False) == True:
            # ignore the existing header
            loadheader(inf)
        # additional
        dfo = h.get("offset",0)
        inf.seek(dfo,0) # e.g. for skipping the other JSON header
    if "rows" in h:
        nr = h["rows"]
        q = np.fromfile(inf,pt,nc*nr)
        print >>sys.stderr,"from file",pt,nc,nr,nc*nr,q.shape
        q = np.reshape(q,(nr,nc))
    else:
        q = np.fromfile(inf,pt)
        nr = len(q)/nc
        q = np.reshape(q,(nc,nr))
    print >>sys.stderr,"found",q.shape,"rows",nr,"cols",nc

    w = [(n.encode("latin1"), pt,1) for n in h["fieldnames"]]
    ddtype=np.dtype(w)
    return np.frombuffer(np.getbuffer(q),dtype=ddtype)


"""
def savenumpy(out,np):
    pass

def savedata(out,fieldnames,data):
    pass
"""
def main():
    parser = argparse.ArgumentParser(description='Convert')
    parser.add_argument('input',nargs="+")
    parser.add_argument('-O',"--output")
    parser.add_argument('-a','--action',choices=["header","dump","count"])
    parser.add_argument('-k','--key')

    args = parser.parse_args()
    fis = os.fdopen(sys.stdin.fileno(),"rb")
    if args.action == "header":
        for i in args.input:
            print loadheader(open(i,"rb"))
    elif args.action == "dump":
        for i in args.input:
            print loadnumpy(fis if i == "-" else open(i,"rb"),-1 if i == "-" else os.stat(i).st_size)
    elif args.action == "count":
        c= collections.Counter()
        for i in args.input:
            d = loadnumpy(fis if i == "-" else open(i,"rb"),-1 if i == "-" else os.stat(i).st_size)
            for j in range(0,d.shape[0]):
                c[float(d[j][args.key])] += 1
        for k,v in c.items():
            print int(k),v
    else:
        print "unknown action"


"""Writer TODO

                if args.format == "csv":
                    y = csv.writer(of,rfieldnames,delimiter=args.delimiter)                
                else:
                    y = binwriter(of,rfieldnames,args.precision,args.rows,vnan)
                continue
            if infotime != -1:
                v[infotime] = parseTime(v[infotime])
            for index,name,dicts in info:        
                v[index] = dicts.numerize(v[index])
            if ofields is not None:
                for src,dst in v2v:
                    vfields[dst] = v[src]
                v = vfields
            y.writerow(v)            
        if args.format == "binary" and args.output != "-":
            h = y.header
            h["maps"] = {}
            for i,name,dd in info:
                h["maps"][name] = dd.d
            h["datafile"] = args.output
            h["autooffset"] = True
            binwriter.emitpureheader(open(args.output+".meta","wb"),h)
        print >>sys.stderr,"done",rowsdone

"""
if __name__ == '__main__':
    main()