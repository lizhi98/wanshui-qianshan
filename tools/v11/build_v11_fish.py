import bpy,math
from pathlib import Path
S=Path(__file__).resolve().parents[2];bpy.ops.wm.read_factory_settings(use_empty=True)
def mat(name,c,rough=.4):
    m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=rough;return m
skin=mat('Small silver grassland fish skin',(.36,.41,.30),.25);finmat=mat('Translucent olive fin',(.30,.34,.23),.37);eye=mat('Fish dark eyes',(.012,.016,.012),.13);gill=mat('Gill and fin rays',(.19,.23,.15),.6)
verts=[];faces=[];rings=42;sides=32
for i in range(rings):
    t=i/(rings-1);z=-.13+t*.275
    radius=(.007+math.sin(t*math.pi)**.75*.031)*(1-.25*t)
    for j in range(sides):
        a=j/sides*math.tau;verts.append((math.cos(a)*radius*.74,math.sin(a)*radius,z))
for i in range(rings-1):
    for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
faces.extend([tuple(reversed(range(sides))),tuple(range((rings-1)*sides,rings*sides))])
mesh=bpy.data.meshes.new('Contoured fish body');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('FishBody',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(skin)
uv=mesh.uv_layers.new(name='ScalesUV')
for polygon in mesh.polygons:
    polygon.use_smooth=True
    for li in polygon.loop_indices:
        n=mesh.loops[li].vertex_index;uv.data[li].uv=(n//sides/(rings-1),(n%sides)/sides)
def membrane(name,points,material,parent=None):
    m=bpy.data.meshes.new(name);m.from_pydata(points,[],[tuple(range(len(points)))]);m.update();x=bpy.data.objects.new(name,m);bpy.context.collection.objects.link(x);x.data.materials.append(material)
    if parent:x.parent=parent
    return x
def line(name,points,radius,material,parent=None):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=radius;c.bevel_resolution=2;sp=c.splines.new('POLY');sp.points.add(len(points)-1)
    for p,v in zip(sp.points,points):p.co=(*v,1)
    x=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(x);x.data.materials.append(material)
    if parent:x.parent=parent
tail=bpy.data.objects.new('TailPivot',None);bpy.context.collection.objects.link(tail);tail.location=(0,0,-.128)
membrane('Forked tail membrane',[(0,0,0),(0,.043,-.070),(0,.012,-.051),(0,0,-.034),(0,-.012,-.051),(0,-.043,-.070)],finmat,tail)
for sign in [-1,1]:
    for j in range(1,6):line('Tail fin ray',[(0,0,0),(0,sign*.043*j/5,-.035-.035*j/5)],.00045,gill,tail)
membrane('Dorsal fin',[(0,.025,.035),(0,.058,.008),(0,.048,-.045),(0,.025,-.062)],finmat)
for z in [.025,.005,-.015,-.035]:line('Dorsal ray',[(0,.026,z),(0,.05,z-.012)],.0005,gill)
for side in [-1,1]:
    membrane('Pectoral fin',[(side*.018,-.009,.065),(side*.06,-.027,.015),(side*.024,-.022,-.01)],finmat)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=(side*.019,.009,.104));x=bpy.context.object;x.name='FishEye';x.scale=(.005,.0055,.006);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);x.data.materials.append(eye)
    line('Curved gill cover',[(side*(.018+math.sin(i/12*math.pi)*.007),-.021+i/12*.045,.073-math.sin(i/12*math.pi)*.01) for i in range(13)],.0009,gill)
line('Small mouth opening',[(-.005,-.002,.144),(0,-.004,.148),(.005,-.002,.144)],.0013,gill)
bpy.ops.wm.save_as_mainfile(filepath=str(S/'art_source/grassland_fish_v11.blend'))
bpy.ops.export_scene.gltf(filepath=str(S/'assets/golden_hook/models/grassland_fish.glb'),export_format='GLB',export_animations=False,export_yup=False)
print('Detailed fork-tailed small fish exported with movable tail pivot')
