import bpy,math,random
from pathlib import Path
S=Path(__file__).resolve().parents[2];OUT=S/'assets/golden_hook/models'
def reset():bpy.ops.wm.read_factory_settings(use_empty=True)
def mat(name,color,rough=.9,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*color,1);n.inputs['Roughness'].default_value=rough;n.inputs['Metallic'].default_value=metal;return m
def mesh(name,verts,faces,material):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update();o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);o.data.materials.append(material)
    for p in data.polygons:p.use_smooth=True
    return o
def curve(name,points,radius,material):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=radius;c.bevel_resolution=2;sp=c.splines.new('POLY');sp.points.add(len(points)-1)
    for p,v in zip(sp.points,points):p.co=(*v,1)
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(material);return o
def cube(name,loc,scale,material,bevel=.01):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    b=o.modifiers.new('Soft sewn corners','BEVEL');b.width=bevel;b.segments=4;bpy.ops.object.modifier_apply(modifier=b.name);o.data.materials.append(material);return o
def export(name):
    bpy.ops.wm.save_as_mainfile(filepath=str(S/'art_source'/(name+'_v11.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_animations=False,export_yup=True)
reset();cloth=mat('Worn cotton sack',(.32,.29,.20));seam=mat('Hemp seam thread',(.44,.39,.26));rope=mat('Hemp tying rope',(.39,.34,.23))
verts=[];faces=[];rings=25;sides=48
for j in range(rings):
    t=j/(rings-1);radius=(.17+.055*math.sin(t*math.pi))*max(.1,1-.78*max(0,(t-.77)/.23))
    for i in range(sides):
        a=i*math.tau/sides;fold=(math.sin(a*9+t*4)*.012+math.sin(a*17-t*2)*.005)*(t*.6+.4)
        verts.append(((radius+fold)*math.cos(a),(radius+fold)*math.sin(a)*.76,.025+t*.50))
for j in range(rings-1):
    for i in range(sides):a=j*sides+i;b=j*sides+(i+1)%sides;faces.append((a,b,b+sides,a+sides))
faces.append(tuple(reversed(tuple(range(sides)))))
mesh('Folded empty ration sack',verts,faces,cloth)
for side in [0,math.pi]:
    points=[verts[j*sides+int(side/math.tau*sides)%sides] for j in range(rings)];curve('Double sewn side seam',points,.0016,seam)
curve('Twice tied rope',[(.065*math.cos(i*.15),.049*math.sin(i*.15),.46+i*.0002) for i in range(84)],.005,rope)
curve('Loose rope ends',[(.045,0,.47),(.09,-.02,.43),(.08,-.04,.35)],.004,rope)
export('ration_sack')
reset();cloth=mat('Faded canvas bag',(.26,.29,.23));trim=mat('Dark worn leather',(.18,.15,.10));metal=mat('Dull oxidized buckle',(.25,.24,.19),.55,.65)
cube('Canvas satchel body',(0,0,.18),(.34,.18,.34),cloth,.035)
flap=cube('Worn flap',(0,-.105,.31),(.35,.035,.17),cloth,.018);flap.rotation_euler.x=-.2
for x in [-.10,.10]:
    cube('Leather fastening strap',(x,-.134,.19),(.028,.014,.18),trim,.004)
    curve('Metal rectangular buckle',[(x-.025,-.148,.20),(x+.025,-.148,.20),(x+.025,-.148,.25),(x-.025,-.148,.25),(x-.025,-.148,.20)],.003,metal)
    curve('Blanket straps',[(x,.1,.07),(x,.115,.24),(x,.1,.37)],.009,trim)
curve('Frayed canvas shoulder strap',[(-.16,0,.33),(-.23,.01,.48),(0,.04,.53),(.23,.01,.48),(.16,0,.33)],.014,cloth)
export('camp_satchel')
reset();blanket=mat('Worn blanket wool',(.27,.29,.22));tie=mat('Hemp roll ties',(.38,.33,.22))
verts=[];faces=[]
for j in range(33):
    x=-.30+j/32*.60
    for i in range(32):
        a=i*math.tau/32;rad=.095+math.sin(x*15+a*3)*.004
        verts.append((x,math.cos(a)*rad,.095+math.sin(a)*rad*.77))
for j in range(32):
    for i in range(32):a=j*32+i;b=j*32+(i+1)%32;faces.append((a,b,b+32,a+32))
faces.extend([tuple(range(31,-1,-1)),tuple(range(32*32,33*32))]);mesh('Layered rolled blanket',verts,faces,blanket)
for x in [-.19,.19]:curve('Blanket tying cord',[(x,.099*math.cos(i*.12),.095+.078*math.sin(i*.12)) for i in range(54)],.004,tie)
for x in [-.3,.3]:
    for rad in [.025,.05,.075]:curve('Visible folded cloth layers',[(x,.0+rad*math.cos(i*.16),.095+rad*.77*math.sin(i*.16)) for i in range(41)],.0025,tie)
export('bedroll')
reset();fabric=mat('Weathered shelter cotton canvas',(.31,.33,.23));stitch=mat('Shelter hem and patches',(.38,.38,.26));wood=mat('Worn wooden shelter pole',(.22,.17,.11));rope=mat('Tarp guy rope',(.40,.36,.25))
for side in [-1,1]:
    verts=[];faces=[];nx=28;ny=30
    for j in range(ny+1):
        y=-1.4+j/ny*2.8
        for i in range(nx+1):
            u=i/nx;x=side*u*1.9;z=.14+(1-u)*1.76-.08*math.sin((j/ny)*math.pi)*(1-u)
            z+=math.sin(u*math.pi)*(.022*math.sin(y*5+u*11)+.015*math.sin(y*13));verts.append((x,y,z))
    for j in range(ny):
        for i in range(nx):a=j*(nx+1)+i;faces.append((a,a+1,a+nx+2,a+nx+1))
    o=mesh('Sagging woven canvas panel',verts,faces,fabric);solid=o.modifiers.new('Canvas thickness','SOLIDIFY');solid.thickness=.004
    for y in [-1.4,0,1.4]:curve('Stitched panel seam',[(side*(i/28)*1.9,y,.14+(1-i/28)*1.76+.005) for i in range(29)],.004,stitch)
for y in [-1.4,1.4]:curve('Weathered ridge support',[(0,y,0),(0,y,1.93)],.028,wood)
curve('Ridge pole',[(0,-1.5,1.92),(0,1.5,1.92)],.025,wood)
for x in [-2.5,2.5]:
    for y in [-1.8,1.8]:curve('Tied guy rope',[(x,y,.015),(math.copysign(1.9,x),y*.77,.15)],.006,rope)
export('canvas_shelter')
print('CAMP ART COMPLETE')
