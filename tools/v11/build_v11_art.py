import bpy,math,json,random
from pathlib import Path
from mathutils import Vector
S=Path(__file__).resolve().parents[2]
OUT=S/'assets/golden_hook/models';OUT.mkdir(parents=True,exist_ok=True)
ENV=S/'assets/golden_hook/environment';ENV.mkdir(parents=True,exist_ok=True)
stats=[]
def export(path):
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animations=True,export_yup=True,export_apply=False)
def reset():bpy.ops.wm.read_factory_settings(use_empty=True)
def material(name,color,rough=.8,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*color,1);n.inputs['Roughness'].default_value=rough;n.inputs['Metallic'].default_value=metal;return m
def activate(o):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def cube(name,loc,size,mat,bevel=.008):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;activate(o);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        b=o.modifiers.new('Rounded worn edges','BEVEL');b.width=bevel;b.segments=3;bpy.ops.object.modifier_apply(modifier=b.name)
    o.data.materials.append(mat);return o
def curve(name,points,radius,mat):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=6;c.bevel_depth=radius;c.bevel_resolution=3
    sp=c.splines.new('POLY');sp.points.add(len(points)-1)
    for p,co in zip(sp.points,points):p.co=(*co,1)
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(mat);return o

# A fourth actual skinned mesh, with edited facial anatomy and a different cap,
# hair silhouette, sleeve patch and satchel. All facial shape keys get the same
# anatomical offsets, so speech/blink do not snap to the old face.
bpy.ops.wm.open_mainfile(filepath=str(S/'art_source/linchuan.blend'))
body=next(o for o in bpy.data.objects if o.type=='MESH' and o.name=='linchuan_NaturalHuman')
def head_delta(co):
    x,y,z=co
    mask=math.exp(-((z-1.585)/.105)**4)
    jaw=math.exp(-((z-1.535)/.042)**2)
    cheek=math.exp(-((z-1.59)/.035)**2)
    nose=math.exp(-(x/.024)**2-((z-1.582)/.032)**2)*max(0,min(1,(-y-.07)/.06))
    return Vector((x*(-.17*jaw+.08*cheek)*mask,-.012*nose,.006*jaw))
blocks=body.data.shape_keys.key_blocks if body.data.shape_keys else []
if blocks:
    deltas=[head_delta(v.co) for v in blocks[0].data]
    for block in blocks:
        for v,d in zip(block.data,deltas):v.co+=d
else:
    for v in body.data.vertices:v.co+=head_delta(v.co)
for o in list(bpy.data.objects):
    if any(x in o.name for x in ['Fitted_field_cap','Canvas_backpack','Rolled_blanket','Shoulder_strap']):bpy.data.objects.remove(o,do_unlink=True)
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
cloth=material('Qing faded indigo cotton',(.20,.28,.27));patch=material('Hand sewn repair patch',(.32,.35,.26))
for o in bpy.data.objects:
    if o.type=='MESH' and 'Tailored' in o.name:
        for i in range(len(o.data.materials)):o.data.materials[i]=cloth
def bind(o,bone):
    o.parent=rig;g=o.vertex_groups.new(name=bone);g.add(list(range(len(o.data.vertices))),1,'REPLACE');m=o.modifiers.new('Shared 53 bone skin','ARMATURE');m.object=rig
# Soft cloth field cap with a shorter asymmetric peak.
bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=12,location=(0,-.055,1.682));cap=bpy.context.object;cap.name='Qing_SoftClothCap';cap.scale=(.102,.112,.057);activate(cap);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);cap.data.materials.append(cloth);bind(cap,'Head')
visor=cube('Qing_short_visor',(0,-.167,1.663),(.165,.072,.012),cloth,.009);visor.rotation_euler.x=.16;bind(visor,'Head')
p=cube('Qing_stitched_left_sleeve_patch',(.219,-.123,1.36),(.073,.008,.094),patch,.006);bind(p,'upperarm_l')
bag=cube('Qing_flat_canvas_satchel',(.244,.04,.92),(.19,.12,.23),patch,.025);bind(bag,'spine_01')
strap=curve('Qing_satchel_strap',[(-.17,-.14,1.47),(.04,-.175,1.22),(.24,-.13,1.01)],.012,cloth);activate(strap);bpy.ops.object.convert(target='MESH');bind(bpy.context.object,'spine_03')
for o in bpy.data.objects:
    if o.type=='MESH':
        for p in o.data.polygons:p.use_smooth=True
bpy.ops.wm.save_as_mainfile(filepath=str(S/'art_source/qing_v11.blend'))
export(OUT/'qing.glb');print('QING EXPORTED',flush=True)

for ident in ['grass_medium_01','grass_bermuda_01','shrub_02','rock_moss_set_01','pot_enamel_01']:
    reset();bpy.ops.import_scene.gltf(filepath=str(S/'art_source/V1_1_vendor'/ident/(ident+'.gltf')))
    before=sum(len(o.data.polygons) for o in bpy.data.objects if o.type=='MESH')
    target=2200 if 'grass' in ident else (2400 if 'shrub' in ident else 6000)
    for o in bpy.data.objects:
        if o.type!='MESH':continue
        if len(o.data.polygons)>target:
            activate(o);d=o.modifiers.new('Game mesh decimation','DECIMATE');d.ratio=target/len(o.data.polygons);bpy.ops.object.modifier_apply(modifier=d.name)
        for p in o.data.polygons:p.use_smooth=True
    export(ENV/(ident+'.glb'))
    after=sum(len(o.data.polygons) for o in bpy.data.objects if o.type=='MESH')
    stats.append({'asset':ident,'source_polygons':before,'near_polygons':after})
    if 'grass' in ident or 'shrub' in ident:
        for o in bpy.data.objects:
            if o.type=='MESH' and len(o.data.polygons)>150:
                activate(o);d=o.modifiers.new('Mid distance LOD','DECIMATE');d.ratio=.35;bpy.ops.object.modifier_apply(modifier=d.name)
        export(ENV/(ident+'_lod.glb'))
    print(ident,before,'->',after,flush=True)

# Curved, folded cloth with hem stitching. The wrapping state uses its real
# edge vertices, rather than replacing the hook with a box.
reset();fabric=material('Worn cotton keepsake cloth',(.42,.39,.29),.98)
verts=[];faces=[];N=20
for y in range(N+1):
    for x in range(N+1):
        px=(x/N-.5)*.24;py=(y/N-.5)*.21
        verts.append((px,py,.0015*math.sin(x*1.7)*math.sin(y*.8)))
for y in range(N):
    for x in range(N):
        a=y*(N+1)+x;faces.append((a,a+1,a+N+2,a+N+1))
mesh=bpy.data.meshes.new('Woven cloth surface');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('KeepsakeCloth',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(fabric)
o.shape_key_add(name='Basis');fold=o.shape_key_add(name='Wrapped')
for v in fold.data:
    x,y,z=v.co
    a=max(0,(abs(x)-.025)/.095)*math.pi*.87
    v.co.x=math.copysign(.025+math.sin(a)*.027,x)
    v.co.z=z+(1-math.cos(a))*.017+max(0,abs(y)-.045)*.19
    v.co.y=y*.72
solid=o.modifiers.new('Cloth thickness','SOLIDIFY');solid.thickness=.0008
export(OUT/'keepsake_cloth.glb')
bpy.ops.wm.save_as_mainfile(filepath=str(S/'art_source/keepsake_cloth_v11.blend'))
(S/'docs/golden_hook/V1_1_ASSET_OPTIMIZATION.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
print('ART BUILD COMPLETE',flush=True)
