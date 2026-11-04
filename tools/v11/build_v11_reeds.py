import bpy,math,random
from pathlib import Path
S=Path(__file__).resolve().parents[2];bpy.ops.wm.read_factory_settings(use_empty=True);rng=random.Random(1935)
def mat(name,c):
    m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*c,1);m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.9;return m
stalk=mat('Autumn sedge stems',(.27,.31,.15));leaf=mat('Folded marsh sedge leaves',(.29,.34,.16));seed=mat('Brown dry sedge seed heads',(.25,.19,.10))
def tube(name,points,radius,material):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=radius;c.bevel_resolution=1;sp=c.splines.new('POLY');sp.points.add(len(points)-1)
    for p,v in zip(sp.points,points):p.co=(*v,1)
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(material)
for j in range(9):
    angle=rng.uniform(0,math.tau);r=rng.uniform(.01,.13);x=math.cos(angle)*r;y=math.sin(angle)*r;h=rng.uniform(.82,1.36);lean=rng.uniform(.06,.15)
    tube('Curved reed stem',[(x+math.cos(angle)*lean*t*t,y+math.sin(angle)*lean*t*t,h*t) for t in [i/12 for i in range(13)]],.004,stalk)
    for k in range(3):
        direction=angle+k*2.1;z=h*(.20+k*.18);length=rng.uniform(.28,.48);verts=[];faces=[]
        for i in range(11):
            t=i/10;w=math.sin(t*math.pi)**.7*.018;along=length*t
            center=(x+math.cos(direction)*along,y+math.sin(direction)*along,z+math.sin(t*math.pi)*.13-t*t*.08)
            for across in [-1,0,1]:verts.append((center[0]-math.sin(direction)*w*across,center[1]+math.cos(direction)*w*across,center[2]+(.005*math.sin(t*math.pi) if across==0 else 0)))
        for i in range(10):
            for a in range(2):b=i*3+a;faces.append((b,b+1,b+4,b+3))
        mesh=bpy.data.meshes.new('Tapered folded leaf');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Sedge leaf',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(leaf)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10,ring_count=6,location=(x+math.cos(angle)*lean,y+math.sin(angle)*lean,h-.035));o=bpy.context.object;o.name='Textured seed head';o.scale=(.013,.013,.075);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(seed)
    for p in o.data.polygons:p.use_smooth=True
bpy.ops.wm.save_as_mainfile(filepath=str(S/'art_source/marsh_reeds_v11.blend'))
bpy.ops.export_scene.gltf(filepath=str(S/'assets/golden_hook/models/marsh_reeds.glb'),export_format='GLB',export_animations=False)
print('Authored 9-stem marsh sedge tuft with 27 folded leaves exported')
