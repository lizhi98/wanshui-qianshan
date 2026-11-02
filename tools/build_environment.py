"""Prepare CC0 Poly Haven environment assets for the real-time Godot scene."""
import bpy,pathlib,os
P=pathlib.Path(__file__).resolve().parents[1]
ROOT=P.parents[1]
cache=next((parent/'work' for parent in [P,*P.parents] if (parent/'work/source_pine_sapling_medium').is_dir()),P/'.art_cache')
cache=pathlib.Path(os.environ.get('LUDING_ART_CACHE',str(cache)))
source=cache/'source_pine_sapling_medium/pine_sapling_medium.gltf'
out=P/'assets/remaster/environment';out.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
meshes.sort(key=lambda o:o.name)
keep=meshes[0]
for obj in meshes[1:]: bpy.data.objects.remove(obj,do_unlink=True)
keep.location=(0,0,0)
bpy.context.view_layer.objects.active=keep
keep.select_set(True)
tris=sum(len(p.vertices)-2 for p in keep.data.polygons)
decimate=keep.modifiers.new('Game budget 65000 triangles','DECIMATE');decimate.ratio=min(1,65000/tris)
bpy.ops.object.modifier_apply(modifier=decimate.name)
for p in keep.data.polygons:p.use_smooth=True
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(P/'art_source/pine_game.blend'))
bpy.ops.export_scene.gltf(filepath=str(out/'pine_game.glb'),export_format='GLB',export_animations=False,use_selection=False)
print('PINE_GAME',tris,'->',sum(len(p.vertices)-2 for p in keep.data.polygons),flush=True)
