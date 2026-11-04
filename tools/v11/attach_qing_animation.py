from pathlib import Path
import struct,json,copy,shutil,sys
S=Path(__file__).resolve().parents[2]
profile=sys.argv[1] if len(sys.argv)>1 else 'qing'
target=S/'assets/golden_hook/models'/(profile+'.glb');base=S/'art_source'/(profile+'_v11_base.glb')
if not base.exists():shutil.copy2(target,base)
def read(p):
    raw=p.read_bytes();n=struct.unpack_from('<I',raw,12)[0];return json.loads(raw[20:20+n]),bytearray(raw[28+n:])
src,sbuf=read(S/'assets/remaster/characters'/('zhou.glb' if profile=='elder' else 'linchuan.glb'));dst,buf=read(base)
names={x.get('name'):i for i,x in enumerate(dst['nodes'])};accessors={};views={}
def accessor(index):
    if index in accessors:return accessors[index]
    a=copy.deepcopy(src['accessors'][index]);vi=a['bufferView']
    if vi not in views:
        v=copy.deepcopy(src['bufferViews'][vi]);start=v.get('byteOffset',0);length=v['byteLength']
        while len(buf)%4:buf.append(0)
        v['byteOffset']=len(buf);buf.extend(sbuf[start:start+length]);v['buffer']=0
        dst.setdefault('bufferViews',[]).append(v);views[vi]=len(dst['bufferViews'])-1
    a['bufferView']=views[vi];dst.setdefault('accessors',[]).append(a);accessors[index]=len(dst['accessors'])-1;return accessors[index]
dst['animations']=[]
for animation in src['animations']:
    a=copy.deepcopy(animation)
    for c in a['channels']:
        name=src['nodes'][c['target']['node']]['name'];c['target']['node']=names[name]
    for sp in a['samplers']:sp['input']=accessor(sp['input']);sp['output']=accessor(sp['output'])
    dst['animations'].append(a)
dst['buffers']=[{'byteLength':len(buf)}]
raw=json.dumps(dst,separators=(',',':')).encode();raw+=b' '*(-len(raw)%4);buf+=b'\0'*(-len(buf)%4)
target.write_bytes(struct.pack('<III',0x46546c67,2,28+len(raw)+len(buf))+struct.pack('<II',len(raw),0x4e4f534a)+raw+struct.pack('<II',len(buf),0x004e4942)+buf)
print('Qing: retained anatomy/skin and attached',len(dst['animations']),'shared rest-space clips')
