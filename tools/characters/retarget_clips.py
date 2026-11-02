"""Retarget CC0 UAL global rest-space rotations onto MPFB game_engine rigs.
Run in Blender Python for mathutils; produces self-contained GLBs, not source-code dependencies.
"""
import json,struct,pathlib,bisect,math,os
from mathutils import Quaternion,Vector,Matrix
ROOT=pathlib.Path(__file__).resolve().parents[4]
OUT=pathlib.Path(__file__).resolve().parents[2]/'assets/remaster/characters'
def read(path):
    raw=path.read_bytes(); n=struct.unpack_from('<I',raw,12)[0]
    return json.loads(raw[20:20+n]),bytearray(raw[28+n:])
def quat(values): return Quaternion((values[3],values[0],values[1],values[2]))
def xyzw(q): return [q.x,q.y,q.z,q.w]
def locals_of(data):
    result=[]
    for n in data['nodes']:
        if 'matrix' in n:
            m=Matrix([n['matrix'][i::4] for i in range(4)])
            t,r,s=m.decompose()
        else:
            t=Vector(n.get('translation',[0,0,0])); r=quat(n.get('rotation',[0,0,0,1])); s=Vector(n.get('scale',[1,1,1]))
        result.append((t,r,s))
    return result
def parents(data):
    p={}
    for i,n in enumerate(data['nodes']):
        for c in n.get('children',[]): p[c]=i
    return p
def globals_of(local,parent):
    cache={}
    def get(i):
        if i not in cache:
            t,r,s=local[i]; m=Matrix.LocRotScale(t,r,s)
            cache[i]=get(parent[i])@m if i in parent else m
        return cache[i]
    return [get(i) for i in range(len(local))]
source,binary=read(OUT.parents[2]/'art_source/UAL1_Standard.glb')
slocal=locals_of(source); sp=parents(source); srest=globals_of(slocal,sp)
snames={n.get('name'):i for i,n in enumerate(source['nodes'])}
def values(data,binary,index):
    accessor=data['accessors'][index]; view=data['bufferViews'][accessor['bufferView']]
    count={'SCALAR':1,'VEC3':3,'VEC4':4}[accessor['type']]; stride=view.get('byteStride',count*4)
    offset=view.get('byteOffset',0)+accessor.get('byteOffset',0)
    return [struct.unpack_from('<'+'f'*count,binary,offset+i*stride) for i in range(accessor['count'])]
cache={}
for animation in source['animations']:
    channels=[]; duration=0
    for c in animation['channels']:
        sampler=animation['samplers'][c['sampler']]
        times=[v[0] for v in values(source,binary,sampler['input'])]
        vals=values(source,binary,sampler['output']); duration=max(duration,times[-1])
        channels.append((c['target']['node'],c['target']['path'],times,vals))
    samples=[]; times=[i/20 for i in range(math.ceil(duration*20)+1)]; times[-1]=duration
    for t in times:
        local=[(a.copy(),b.copy(),c.copy()) for a,b,c in slocal]
        for node,path,ts,vs in channels:
            k=min(max(bisect.bisect_right(ts,t)-1,0),len(ts)-1); j=min(k+1,len(ts)-1)
            f=(t-ts[k])/(ts[j]-ts[k]) if ts[j]>ts[k] else 0
            if path=='rotation': local[node]=(local[node][0],quat(vs[k]).slerp(quat(vs[j]),f),local[node][2])
            if path=='translation': local[node]=(Vector(vs[k]).lerp(Vector(vs[j]),f),local[node][1],local[node][2])
        samples.append(globals_of(local,sp))
    cache[animation['name']]=(times,samples)
for name in ['linchuan','amu','zhou']:
    data,buf=read(OUT/(name+'_base.glb')); tl=locals_of(data); tp=parents(data); tr=globals_of(tl,tp)
    joints=data['skins'][0]['joints']; tnames={n.get('name'):i for i,n in enumerate(data['nodes'])}
    mapped={i:snames[data['nodes'][i]['name']] for i in joints if data['nodes'][i].get('name') in snames}
    animations=[]
    def add_accessor(vals,typ):
        while len(buf)%4: buf.append(0)
        start=len(buf)
        for v in vals: buf.extend(struct.pack('<'+'f'*len(v),*v))
        data['bufferViews'].append({'buffer':0,'byteOffset':start,'byteLength':len(buf)-start})
        a={'bufferView':len(data['bufferViews'])-1,'componentType':5126,'count':len(vals),'type':typ}
        if typ=='SCALAR': a.update({'min':[vals[0][0]],'max':[vals[-1][0]]})
        data['accessors'].append(a)
        return len(data['accessors'])-1
    ratio=tr[tnames['Head']].translation.y/srest[snames['Head']].translation.y
    for clip,(times,samples) in cache.items():
        a={'name':clip,'channels':[],'samplers':[]}; time_id=add_accessor([[v] for v in times],'SCALAR')
        rotations={i:[] for i in mapped}; translations=[]
        for sg in samples:
            global_rot={}
            def target_rotation(i):
                if i in global_rot: return global_rot[i]
                if i in mapped:
                    si=mapped[i]
                    q=sg[si].to_quaternion()@srest[si].to_quaternion().inverted()@tr[i].to_quaternion()
                else: q=tr[i].to_quaternion()
                global_rot[i]=q
                return q
            for i in mapped:
                q=target_rotation(i)
                if i in tp: q=target_rotation(tp[i]).inverted()@q
                rotations[i].append(xyzw(q.normalized()))
            pi=tnames['pelvis']; si=snames['pelvis']
            delta=(sg[si].translation-srest[si].translation)*ratio
            # Preserve the target's pelvis rest offset, including the target's parent axes.
            delta=tr[tp[pi]].to_quaternion().inverted()@delta
            translations.append(list(tl[pi][0]+delta))
        for i,vals in rotations.items():
            output=add_accessor(vals,'VEC4'); index=len(a['samplers'])
            a['samplers'].append({'input':time_id,'output':output,'interpolation':'LINEAR'})
            a['channels'].append({'sampler':index,'target':{'node':i,'path':'rotation'}})
        output=add_accessor(translations,'VEC3'); index=len(a['samplers'])
        a['samplers'].append({'input':time_id,'output':output,'interpolation':'LINEAR'})
        a['channels'].append({'sampler':index,'target':{'node':tnames['pelvis'],'path':'translation'}})
        animations.append(a)
    data['animations']=animations
    data['asset']['extras']={'source':'MPFB 2.0.18 natural human + modified CC0 clothes','animation_source':'Quaternius UAL Standard, 43 CC0 clips','retarget':'global rest-space rotation deltas; pelvis translation; 20Hz'}
    data['buffers']=[{'byteLength':len(buf)}]
    raw=json.dumps(data,separators=(',',':')).encode(); raw+=b' '*((-len(raw))%4); buf+=b'\0'*((-len(buf))%4)
    total=12+8+len(raw)+8+len(buf)
    (OUT/(name+'.glb')).write_bytes(struct.pack('<III',0x46546c67,2,total)+struct.pack('<II',len(raw),0x4e4f534a)+raw+struct.pack('<II',len(buf),0x004e4942)+buf)
    print('RETARGET',name,len(joints),'bones',len(animations),'clips',total,'bytes')
