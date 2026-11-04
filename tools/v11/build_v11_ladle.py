import bpy,math
from pathlib import Path
S=Path(__file__).resolve().parents[2];bpy.ops.wm.read_factory_settings(use_empty=True)
m=bpy.data.materials.new('Worn wooden soup ladle');m.diffuse_color=(.26,.19,.11,1);m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.26,.19,.11,1);m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.82
verts=[];faces=[];profile=[(0,.0),(.025,.001),(.04,.012),(.048,.029),(.044,.032),(.036,.014),(.022,.006),(0,.006)]
for radius,height in profile:
    for j in range(40):a=j/40*math.tau;verts.append((math.cos(a)*radius,height,math.sin(a)*radius*1.15))
for i in range(len(profile)-1):
    for j in range(40):a=i*40+j;b=i*40+(j+1)%40;faces.append((a,b,b+40,a+40))
mesh=bpy.data.meshes.new('Hollow ladle cup');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('LadleCup',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(m)
for p in mesh.polygons:p.use_smooth=True
c=bpy.data.curves.new('Bent wooden handle','CURVE');c.dimensions='3D';c.bevel_depth=.0075;c.bevel_resolution=3;sp=c.splines.new('POLY');sp.points.add(12)
for j,p in enumerate(sp.points):t=j/12;p.co=(0,.026+t*.34,-.037-t*.012,1)
o=bpy.data.objects.new('LadleHandle',c);bpy.context.collection.objects.link(o);o.data.materials.append(m)
bpy.ops.wm.save_as_mainfile(filepath=str(S/'art_source/soup_ladle_v11.blend'))
bpy.ops.export_scene.gltf(filepath=str(S/'assets/golden_hook/models/soup_ladle.glb'),export_format='GLB',export_animations=False,export_yup=False)
print('Hollow wooden soup ladle exported')
