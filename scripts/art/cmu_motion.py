"""Read the original CMU ASF/AMC dataset without third-party conversion code.

Source data is retained with provenance. All motion axes are evaluated before
retargeting; this is not a hand-authored animation labelled as motion capture.
"""
from pathlib import Path
import math
from mathutils import Matrix, Vector, Euler

def rotation(values):
    return Euler(tuple(math.radians(x) for x in values), 'XYZ').to_matrix()

class Motion:
    def __init__(self, asf, amc, fps=120):
        self.fps=fps
        self.bones={}
        self.parents={}
        section=''
        current=None
        for line in Path(asf).read_text().splitlines():
            row=line.strip().split()
            if not row or row[0].startswith('#'): continue
            if row[0].startswith(':'): section=row[0]; continue
            if section==':bonedata':
                if row[0]=='begin': current={}
                elif row[0]=='end': self.bones[current['name']]=current
                elif row[0]=='name': current['name']=row[1]
                elif row[0]=='direction': current['direction']=Vector(tuple(map(float,row[1:])))
                elif row[0]=='length': current['length']=float(row[1])
                elif row[0]=='axis': current['axis']=rotation(tuple(map(float,row[1:4])))
                elif row[0]=='dof': current['dof']=row[1:]
            elif section==':hierarchy' and row[0] not in ('begin','end'):
                for child in row[1:]: self.parents[child]=row[0]
        self.frames=[]
        frame=None
        for line in Path(amc).read_text().splitlines():
            row=line.strip().split()
            if not row or row[0].startswith(('#',':')): continue
            if len(row)==1 and row[0].isdigit():
                if frame is not None: self.frames.append(frame)
                frame={}
            else: frame[row[0]]=list(map(float,row[1:]))
        if frame: self.frames.append(frame)
        self.evaluated=[self.evaluate(f) for f in self.frames]

    def evaluate(self,frame):
        # Original ASF is Y-up. Return Blender Z-up, forward = negative Y.
        conversion=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
        root=frame['root']
        rotations={'root':rotation(root[3:])}
        ends={'root':Vector(root[:3])}
        out={'root':(conversion@ends['root']*.056444, conversion@rotations['root']@conversion.inverted())}
        pending=set(self.bones)
        while pending:
            for name in list(pending):
                parent=self.parents[name]
                if parent not in rotations: continue
                bone=self.bones[name]
                angles=[0,0,0]
                for axis,value in zip(bone.get('dof',[]),frame.get(name,[])):
                    angles['xyz'.index(axis[-1])]=value
                basis=bone['axis']
                r=rotations[parent]@basis@rotation(angles)@basis.inverted()
                start=ends[parent]
                end=start+r@bone['direction']*bone['length']
                rotations[name]=r;ends[name]=end
                direction=(conversion@(end-start)).normalized()
                out[name]=(conversion@end*.056444, direction)
                out[name+'_head']=conversion@start*.056444
                pending.remove(name)
        return out

    def peak(self, joint='rhand'):
        speeds=[]
        for i in range(1,len(self.evaluated)-1):
            a=self.evaluated[i-1][joint][0];b=self.evaluated[i+1][joint][0]
            speeds.append(((b-a).length*self.fps*.5,i))
        # Select a whole body stroke with room for preparation and follow-through.
        eligible=[p for p in speeds if .35*self.fps<p[1]<len(self.frames)-.35*self.fps]
        return max(eligible or speeds)[1]

    def sample(self,index):
        a=max(0,min(len(self.evaluated)-1,int(index)))
        b=min(a+1,len(self.evaluated)-1)
        u=max(0,min(1,index-a))
        result={}
        for name,first in self.evaluated[a].items():
            second=self.evaluated[b][name]
            if name=='root': result[name]=(first[0].lerp(second[0],u),first[1].to_quaternion().slerp(second[1].to_quaternion(),u).to_matrix())
            elif isinstance(first,Vector): result[name]=first.lerp(second,u)
            else: result[name]=(first[0].lerp(second[0],u),first[1].lerp(second[1],u).normalized())
        return result
