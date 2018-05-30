import array,os,datetime
import numpy as np
import math
import pandas as pd
from xml.etree.ElementTree import ElementTree

def findtime(d,t,a=0):
	if a < 0:
		a = 0		
	w = d[d >= t]
	if len(w) == 0:
		return -1
	else:
		return w.index[0]
def findendlambda(d):
	w = d[d >= 0.95]
	if len(w) == 0:
		return -1
	else:
		return w.index[0]
		
class WithParams:
	def loadfromtree(self,tree):
		self.params = {}
		for p in tree.findall("params/param"):
			self.params[p.attrib["name"]] = p.attrib["value"]


class Stream(WithParams):
	def __init__(self):
		self.columns = []
		self.icolumns = {}
		self.type = ""
		self.data = None
		self.filename = ""
		self.name = ""
		self.creationTime = ""
	def loadheader(self,name):
		xmlname = name
		datname = name
		if name.endswith(".xml"):
			datname = name[0:-4] + ".dat"
		elif name.endswith(".dat"):
			xmlname = name[0:-4] + ".xml"
		else:
			xmlname = xmlname + ".xml"
			datname = datname + ".dat"
		tree = ElementTree()		
		if self.type == "data":
			tree.parse(xmlname)
			self.loadfromtree(tree)
			self.columns = []
			self.icolumns = {}
			for c in tree.findall("columns/column"):
				name = c.attrib["name"]
				self.columns.append(name)
				self.icolumns[name] = len(self.columns)-1
		self.datname = os.path.abspath(datname)
		self.xmlname = os.path.abspath(xmlname)

	def load(self):
		if self.type == "data":
			s = os.stat(self.datname).st_size
			rows = s/4/len(self.columns)
			shape = (rows,len(self.columns))
			v = np.fromfile(file=open(self.datname,"rb"), dtype=np.float32).reshape(shape)
			d = {}
			#v is a numpy matrix rows x columns
			# create a managed DataFrame object that is made of columns colled Series
			for i,c in enumerate(self.columns):
				d[c] = pd.Series(v[:,i])
			self.data = pd.DataFrame(d)
		else:
			print "Not Implemented load from event file"
