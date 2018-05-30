#
# Deserialization of binary blocks using CTypes or Numpy
#
# Emanuele Ruffaldi 2017
#

import ctypes
import numpy as np
import json
class Field:
	def __init__(self,name,type,sizes):
		self.name = name
		self.type = type
		self.sizes = sizes
		self.byteSize = dict(float=4,double=8,uint32_t=4,int32_t=4,int16_t=2,uint16_t=2)[type]*reduce(lambda x, y: x*y, self.sizes,1)
	@staticmethod
	def parse(f):
		type,nontype = f.strip().split(" ",1)
		nontype = nontype.split("[")
		name = nontype[0]
		sizes = [int(x.rstrip("]")) for x in nontype[1:]]
		return Field(name,type,sizes)
	def makectype(self):
		bt = dict(float=ctypes.c_float,double=ctypes.c_double,int16_t=ctypes.c_short,int32_t=ctypes.c_int,uint32_t=ctypes.c_uint,uint16_t=ctypes.c_ushort)[self.type]
		for s in reversed(self.sizes): # reversed!
			bt = bt * s
		return (self.name, bt )
	def makenumpy(self):
		bt = dict(float=np.float32,double=np.float64,int32_t=np.int32,int16_t=np.int16,uint32_t=np.uint32,uint16_t=np.uint16)[self.type]
		return (self.name, bt, tuple(self.sizes)) # by row
class Data:
	def __init__(self):
		self.rowsize = 0
		self.fields = []
		self.ctype = None
		self.nptype = None
		self.extra = {}
	
def ctypesStructMaker(name, fields, BaseClass=ctypes.Structure):
    newclass = type(name, (BaseClass,),{"_pack_":1, "_fields_" : fields})
    return newclass

def loadheader(inf):
	stage = 0
	d = Data()
	while True:
		x = inf.readline().strip()
		if len(x) == 0:
			break
		if x[0] == "#":
			continue
		if x == "":
			break
		if stage == 0:
			d.fields = [Field.parse(y) for y in x.split(";") if y.strip() != ""]
			stage = 1
		elif stage == 1:
			stage = 2;
			d.size = int(x)
			n = sum([y.byteSize for y in d.fields])
			if n != d.size:
				print "size mismatch ",d.size," ",n
				return None
			# create the structure ctypes on the fly
			tts = [f.makectype() for f in d.fields]
			d.ctype = ctypesStructMaker("data",tts)
			if n != ctypes.sizeof(d.ctype):
				print "size mismatch ctype",d.size,ctypes.sizeof(self)
			d.nptype = [f.makenumpy() for f in d.fields]
		else:
			a,b = x.split(":",1)
			d.extra[a] = json.loads(b) if a == "json" else b
	return d

def loadall(infile):
	inf = open(x,"rb")
	d = loadheader(inf)
	return np.fromfile(inf,d.nptype)
def main():
	import sys
	import argparse

	parser = argparse.ArgumentParser(description='Check Data')
	parser.add_argument('--info',action="store_true")
	parser.add_argument('--ctype',action="store_true",help="ctype mode")
	parser.add_argument('--atonce',action="store_true",help="one big array")
	parser.add_argument('filename',nargs="+")

	args = parser.parse_args()

	for x in args.filename:
		inf = open(x,"rb")
		d = loadheader(inf)
		if args.info:
			print "Input:",x
			print "\tSize",d.size
			print "\tCTypes",d.ctype
			print "\tNumpy",d.nptype
			print "\tJSON",d.extra.get("json","")
			continue
		if args.atonce:
			print np.fromfile(inf,d.nptype)
		else:
			tt = d.ctype()
			while True:
				z = inf.read(d.size)
				if len(z) < d.size:
					break
				if args.ctype:
					ctypes.memmove(ctypes.addressof(tt),z,len(z))
					for field_name, field_type in tt._fields_:
						print field_name, getattr(tt, field_name)
					print ""
				else:
					v = np.frombuffer(z,d.nptype)
					print v


if __name__ == '__main__':
	main()
