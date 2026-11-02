"""Blender/MPFB character build. Upstream MPFB is used unchanged; asset output is CC0.
Run with portable Blender --background --factory-startup --python this_file.
"""
import bpy,sys,json,pathlib,math,bmesh,os
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[4]
PROJECT=pathlib.Path(__file__).resolve().parents[2]
WORK=next((parent/'work' for parent in [PROJECT,*PROJECT.parents] if (parent/'work/mpfb2').is_dir()),PROJECT/'.art_cache')
WORK=pathlib.Path(os.environ.get('LUDING_ART_CACHE',str(WORK)))
sys.path.insert(0,str(WORK/'mpfb2/src'))
USER=WORK/'mpfb_userdata'; USER.mkdir(exist_ok=True)
bpy.utils.extension_path_user=lambda package,path='',create=False: str(USER/path)
import mpfb
bpy.context.preferences.addons.new().module='mpfb'
mpfb.register()
from mpfb.services.humanservice import HumanService
from mpfb.services.targetservice import TargetService
from mpfb.services.rigservice import RigService
OUT=PROJECT/'assets/remaster/characters'; OUT.mkdir(parents=True,exist_ok=True)
SOURCES=PROJECT/'art_source'; SOURCES.mkdir(exist_ok=True)
SYSTEM=WORK/'mh_system'

def activate(obj):
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj

def mat(name,color,rough=.8,texture=None,normal=None):
    material=bpy.data.materials.new(name); material.use_nodes=True
    bsdf=material.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value=(*color,1)
    bsdf.inputs['Roughness'].default_value=rough
    if texture:
        image=material.node_tree.nodes.new('ShaderNodeTexImage'); image.image=bpy.data.images.load(str(texture),check_existing=True)
        material.node_tree.links.new(image.outputs['Color'],bsdf.inputs['Base Color'])
    if normal:
        image=material.node_tree.nodes.new('ShaderNodeTexImage'); image.image=bpy.data.images.load(str(normal),check_existing=True); image.image.colorspace_settings.name='Non-Color'
        normal_node=material.node_tree.nodes.new('ShaderNodeNormalMap'); normal_node.inputs['Strength'].default_value=.35
        material.node_tree.links.new(image.outputs['Color'],normal_node.inputs['Color']); material.node_tree.links.new(normal_node.outputs['Normal'],bsdf.inputs['Normal'])
    return material

def bind(obj,rig,bone):
    obj.parent=rig
    group=obj.vertex_groups.new(name=bone); group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    mod=obj.modifiers.new('Skinning','ARMATURE'); mod.object=rig

def cube(name,pos,size,material,rig,bone,bevel=.008):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos); obj=bpy.context.object; obj.name=name
    obj.dimensions=size; activate(obj); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=obj.modifiers.new('Tailored edges','BEVEL'); mod.width=bevel; mod.segments=3; bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.materials.append(material)
    bind(obj,rig,bone)
    return obj

def field_cap(rig,body,hair,cloth):
    """One sewn cloth shell and visor, fitted in body space and rigidly weighted to Head."""
    head=rig.data.bones['Head'].head_local
    # The skull is forward of the world origin. Using y=0 made the old cap sit
    # behind the forehead, exposing a wedge of hair underneath a floating crown.
    center_y=head.y+.005
    band_bottom=head.z+.078
    band_top=head.z+.103
    crown_top=max(v.co.z for v in body.data.vertices)+.024
    for vertex in hair.data.vertices:
        if vertex.co.z>band_bottom-.004:
            vertex.co.z=min(vertex.co.z,band_bottom+.006)
            radius=math.sqrt((vertex.co.x/.074)**2+((vertex.co.y-center_y)/.107)**2)
            if radius>1:
                vertex.co.x/=radius
                vertex.co.y=center_y+(vertex.co.y-center_y)/radius
    # Short hair is a rigid head accessory. Neck blending otherwise pulls the
    # clipped hair rim through the band when the head looks at another actor.
    hair.vertex_groups.clear()
    hair.vertex_groups.new(name='Head').add(list(range(len(hair.data.vertices))),1,'REPLACE')
    count=64
    profiles=[(.086,.120,band_bottom),(.087,.121,band_top),
              (.094,.122,band_top+.006),(.092,.119,crown_top-.042),
              (.078,.101,crown_top-.013),(.049,.064,crown_top-.003)]
    verts=[]; faces=[]
    for width,depth,z in profiles:
        for i in range(count):
            angle=math.tau*i/count
            soft_octagon=1+.009*math.cos(8*angle)
            verts.append((math.sin(angle)*width*soft_octagon,
                          center_y-math.cos(angle)*depth*soft_octagon,z))
    for row in range(len(profiles)-1):
        for i in range(count):
            j=(i+1)%count
            faces.append((row*count+i,row*count+j,(row+1)*count+j,(row+1)*count+i))
    top=len(verts); verts.append((0,center_y,crown_top))
    for i in range(count): faces.append(((len(profiles)-1)*count+i,(len(profiles)-1)*count+(i+1)%count,top))
    # A curved visor grows directly out of the lower front seam. Its endpoints
    # share the band vertices, so Solidify closes one continuous fabric boundary.
    arc=list(range(-11,12))
    outer=[]
    for index,i in enumerate(arc):
        original=i%count
        if index in [0,len(arc)-1]:
            outer.append(original)
        else:
            angle=math.tau*i/count
            extend=.055*math.sin(math.pi*index/(len(arc)-1))**.65
            point=Vector(verts[original]); point.y-=extend
            point.z-=.006+.009*(abs(math.sin(angle)))
            outer.append(len(verts)); verts.append(point)
    for i in range(len(arc)-1):
        a=arc[i]%count; b=arc[i+1]%count
        polygon=[outer[i],outer[i+1],b,a]
        polygon=list(dict.fromkeys(polygon))
        faces.append(tuple(polygon))
    mesh=bpy.data.meshes.new('Continuous_cap_fabric'); mesh.from_pydata(verts,[],faces); mesh.update()
    cap=bpy.data.objects.new('Fitted_field_cap',mesh); bpy.context.collection.objects.link(cap)
    cap.data.materials.append(cloth)
    activate(cap)
    bm=bmesh.new(); bm.from_mesh(mesh); bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(mesh); bm.free()
    for polygon in mesh.polygons: polygon.use_smooth=True
    solid=cap.modifiers.new('Sewn cloth thickness','SOLIDIFY'); solid.thickness=.003; solid.offset=-1
    bpy.ops.object.modifier_apply(modifier=solid.name)
    bind(cap,rig,'Head')
    cap['band_bottom']=band_bottom; cap['band_top']=band_top; cap['crown_top']=crown_top
    # Badge follows the fitted front of the crown rather than world y=0.
    center=Vector((0,center_y-.123,band_top+.023)); star_verts=[center]
    for i in range(10):
        angle=i*math.tau/10; radius=.014 if i%2==0 else .006
        star_verts.append(center+Vector((math.sin(angle)*radius,-.001,math.cos(angle)*radius)))
    star_mesh=bpy.data.meshes.new('Star'); star_mesh.from_pydata(star_verts,[],[(0,i+1,(i+1)%10+1) for i in range(10)])
    star=bpy.data.objects.new('Red_cloth_star',star_mesh); bpy.context.collection.objects.link(star)
    star.data.materials.append(mat('Red fabric',(.42,.035,.022),.9)); bind(star,rig,'Head')

def build(name,age,muscle,height,cloth_color):
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    macro=TargetService.get_default_macro_info_dict()
    macro.update({'gender':1.0,'age':age,'muscle':muscle,'weight':.40,'height':height,'proportions':.5,'race':{'asian':.96,'caucasian':.04,'african':0.0}})
    body=HumanService.create_human(macro_detail_dict=macro)
    body.name=name+'_NaturalHuman'
    face_targets={
      'linchuan':[('chin/chin-width-decr',.20),('nose/nose-volume-decr',.10)],
      'amu':[('chin/chin-width-incr',.17),('nose/nose-width1-incr',.14)],
      'zhou':[('chin/chin-prominent-incr',.18),('eyebrows/eyebrows-angle-down',.14)]}
    for target,weight in face_targets[name]:
        TargetService.load_target(body,str(WORK/'mpfb2/src/mpfb/data/targets'/(target+'.target.gz')),weight=weight)
    rig=HumanService.add_builtin_rig(body,'game_engine')
    rig.name='HumanRig'
    assets=[]
    for path,typ in [('clothes/male_casualsuit01/male_casualsuit01.mhclo','Clothes'),('clothes/shoes02/shoes02.mhclo','Clothes'),('eyes/high-poly/high-poly.mhclo','Eyes'),('eyebrows/eyebrow001/eyebrow001.mhclo','Eyebrows'),('hair/short02/short02.mhclo','Hair')]:
        obj=HumanService.add_mhclo_asset(str(SYSTEM/path),body,asset_type=typ,subdiv_levels=0,material_type='MAKESKIN')
        assets.append(obj)
    pose=json.loads((WORK/'mpfb2/src/mpfb/data/poses/game_engine_fk/t-pose.json').read_text())
    activate(rig); bpy.ops.object.mode_set(mode='POSE')
    RigService.set_pose_from_dict(rig,pose)
    bpy.ops.object.mode_set(mode='OBJECT')
    RigService.apply_pose_as_rest_pose(rig)
    bpy.context.view_layer.update()
    # Evaluate the masks and preserve weights before adding facial morphs.
    for obj in [body]+assets:
        activate(obj)
        for modifier in list(obj.modifiers):
            if modifier.type in ['MASK','SUBSURF']:
                bpy.ops.object.modifier_apply(modifier=modifier.name)
        for polygon in obj.data.polygons: polygon.use_smooth=True
    body.data.materials.clear()
    body.data.materials.append(mat('Natural skin',(.55,.36,.25),.58,SYSTEM/('skins/middleage_asian_male/middleage_lightskinned_male_diffuse2.png' if age>.58 else 'skins/young_asian_male/young_lightskinned_male_diffuse3.png')))
    cloth=mat('1935 cotton tunic and trousers',cloth_color,.92,normal=SYSTEM/'clothes/male_casualsuit01/male_casualsuit01_normal.png')
    assets[0].name='Tailored_Tunic_Trousers'
    assets[0].data.materials.clear(); assets[0].data.materials.append(cloth)
    shoes=mat('Worn cloth shoes',(.045,.040,.032),.94)
    assets[1].data.materials.clear(); assets[1].data.materials.append(shoes)
    # Keep authored eyes/brow textures; hair is intentionally short under the cap.
    for obj in assets[2:]:
        for material in obj.data.materials:
            if material and material.use_nodes:
                p=material.node_tree.nodes.get('Principled BSDF')
                if p: p.inputs['Roughness'].default_value=.6
    # Rename the few casing differences for the shared runtime and UAL clips.
    rig.data.bones['head'].name='Head'; rig.data.bones['Root'].name='root'
    for obj in [body]+assets:
        for a,b in [('head','Head'),('Root','root')]:
            if a in obj.vertex_groups: obj.vertex_groups[a].name=b
    # Clothing is real garment geometry with separate collar, pocket flaps, buttons and hem.
    pelvis=rig.data.bones['pelvis'].head_local
    chest=rig.data.bones['neck_01'].head_local.copy(); chest.z-=.08
    head=rig.data.bones['Head'].head_local
    front=-.12
    beltmat=mat('Canvas and leather',(.15,.115,.075),.87)
    brass=mat('Aged button',(.19,.17,.12),.72)
    cube('Tunic_hem',(0,front+.035,pelvis.z+.09),(.33,.035,.12),cloth,rig,'pelvis',.006)
    cube('Closed_neck_placket',(0,-.110,chest.z),(.065,.016,.10),cloth,rig,'spine_03',.004)
    for side in [-1,1]:
        x=side*.095
        cube('Chest_pocket',(x,front-.005,chest.z-.10),(.085,.017,.095),cloth,rig,'spine_03',.007)
        cube('Pocket_flap',(x,front-.016,chest.z-.052),(.092,.025,.025),cloth,rig,'spine_03',.005)
        collar=cube('Collar_leaf',(side*.034,-.100,chest.z+.045),(.055,.025,.055),cloth,rig,'neck_01',.005)
        collar.rotation_euler.y=side*.22
        cube('Belt_pouch',(side*.16,-.115,pelvis.z+.025),(.075,.065,.11),beltmat,rig,'pelvis',.01)
    for i in range(5):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.008,location=(0,front-.027,chest.z+.025-i*.062))
        obj=bpy.context.object; obj.name='Tunic_button'; obj.scale=(1,.38,1); obj.data.materials.append(brass); bind(obj,rig,'spine_02')
    field_cap(rig,body,assets[-1],cloth)
    # Rounded pack, rolled blanket and two canvas shoulder straps.
    packmat=mat('Worn canvas pack',(.18,.19,.12),.97)
    cube('Canvas_backpack',(0,.145,chest.z-.08),(.28,.12,.33),packmat,rig,'spine_03',.025)
    cube('Rolled_blanket',(0,.15,chest.z+.12),(.32,.13,.075),cloth,rig,'spine_03',.03)
    for side in [-1,1]: cube('Shoulder_strap',(side*.125,-.01,chest.z),(.026,.19,.028),beltmat,rig,'spine_03',.007)
    # Game facial morphs preserve original mesh structure and skin UVs.
    body.shape_key_add(name='Basis')
    blink=body.shape_key_add(name='Blink')
    smile=body.shape_key_add(name='Resolve')
    zmax=max(v.co.z for v in body.data.vertices)
    for i,v in enumerate(body.data.vertices):
        p=v.co
        if abs(p.x)<.075 and p.y<-.02 and zmax-.16<p.z<zmax-.09:
            weight=max(0,1-abs(abs(p.x)-.035)/.032)
            blink.data[i].co.z-=.009*weight
        if abs(p.x)<.04 and p.y<-.02 and zmax-.235<p.z<zmax-.18:
            smile.data[i].co.z+=.0025*(abs(p.x)/.04)
    # All children follow a uniform scale to metres; apply the scale to the export root.
    bpy.context.view_layer.update()
    height_current=max(v.co.z for v in body.data.vertices)
    factor=(1.72 if name=='linchuan' else (1.68 if name=='amu' else 1.77))/height_current
    for obj in list(bpy.context.scene.objects):
        if obj.type=='MESH':
            obj.location*=factor
            original=[v.co.copy() for v in obj.data.vertices]
            key_data=[(key,[p.co.copy() for p in key.data]) for key in obj.data.shape_keys.key_blocks] if obj.data.shape_keys else []
            for v,p in zip(obj.data.vertices,original): v.co=p*factor
            if obj.data.shape_keys:
                for key,points in key_data:
                    for p,original_point in zip(key.data,points): p.co=original_point*factor
            if obj.name=='Fitted_field_cap':
                obj['band_bottom']*=factor; obj['band_top']*=factor; obj['crown_top']*=factor
    activate(rig); bpy.ops.object.mode_set(mode='EDIT')
    for bone in rig.data.edit_bones: bone.head*=factor; bone.tail*=factor
    bpy.ops.object.mode_set(mode='OBJECT')
    # Export without facial animation; runtime supplies blink, look-at and dialogue emotion.
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH': obj.select_set(True)
    rig.select_set(True)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCES/(name+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'_base.glb')),export_format='GLB',use_selection=True,export_animations=False,export_apply=False,export_morph=True,export_skins=True)
    print('CHARACTER_EXPORT',name,'height',height_current*factor,'bones',len(rig.data.bones))

for spec in [('linchuan',.46,.30,.52,(.15,.19,.20)),('amu',.47,.38,.47,(.20,.24,.23)),('zhou',.64,.40,.57,(.11,.15,.16))]:
    build(*spec)
