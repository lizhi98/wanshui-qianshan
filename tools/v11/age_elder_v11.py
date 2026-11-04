import bpy,math
from mathutils import Vector
from pathlib import Path
S=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(S/'art_source/zhou.blend'))
body=next(o for o in bpy.data.objects if o.name=='zhou_NaturalHuman')
eyes=next(o for o in bpy.data.objects if o.name.endswith('.high-poly'))
ez=sum(v.co.z for v in eyes.data.vertices)/len(eyes.data.vertices)
def delta(co):
    x,y,z=co;front=max(0,min(1,(-y-.04)/.06));face=math.exp(-((z-ez)/.12)**4)*front
    cheek=math.exp(-((abs(x)-.056)/.025)**2-((z-ez+.035)/.035)**2)*face
    jaw=math.exp(-((z-ez+.083)/.034)**2)*face
    nose=math.exp(-(x/.021)**2-((z-ez+.035)/.026)**2)*front
    lid=math.exp(-((abs(x)-.028)/.021)**2-((z-ez-.009)/.010)**2)*front
    return Vector((x*.07*jaw,.006*cheek-.005*nose,-.007*cheek-.004*jaw-.002*lid))
blocks=body.data.shape_keys.key_blocks
offsets=[delta(v.co) for v in blocks[0].data]
for block in blocks:
    for v,d in zip(block.data,offsets):v.co+=d
for o in bpy.data.objects:
    if o.type=='MESH' and ('short02' in o.name or 'eyebrow' in o.name):
        for m in o.data.materials:
            if m and m.use_nodes:
                nodes=m.node_tree.nodes;bsdf=nodes.get('Principled BSDF')
                for link in list(bsdf.inputs['Base Color'].links):m.node_tree.links.remove(link)
                bsdf.inputs['Base Color'].default_value=(.25,.255,.225,1);bsdf.inputs['Roughness'].default_value=.96
bpy.ops.wm.save_as_mainfile(filepath=str(S/'art_source/elder_v11.blend'))
bpy.ops.export_scene.gltf(filepath=str(S/'assets/golden_hook/models/elder.glb'),export_format='GLB',export_animations=False,export_yup=True,export_apply=False)
print('ELDER AGED ANATOMY EXPORTED',ez)
