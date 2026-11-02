"""Blender regression check for the actual editable cap and its head attachment."""
import bpy, pathlib, sys, math
from mathutils import Vector

project = pathlib.Path(__file__).resolve().parents[1]
failures = []
for name in ['linchuan', 'amu', 'zhou']:
    bpy.ops.wm.open_mainfile(filepath=str(project / 'art_source' / (name + '.blend')))
    rig = bpy.data.objects['HumanRig']
    head = rig.data.bones['Head'].head_local
    body = bpy.data.objects[name + '_NaturalHuman']
    scalp = [body.matrix_world @ v.co for v in body.data.vertices if v.co.z > head.z + .06]
    print('SCALP', name, 'head', tuple(head), 'bounds', [(min(p[i] for p in scalp), max(p[i] for p in scalp)) for i in range(3)])
    cap = bpy.data.objects.get('Fitted_field_cap')
    if cap is None:
        failures.append(name + ': the fabric cap is still assembled from disconnected floating parts')
        continue
    assert cap.matrix_local.is_identity, name + ': cap must use the same body coordinates as the rig'
    assert cap.parent == rig
    assert len(cap.vertex_groups) == 1 and cap.vertex_groups[0].name == 'Head'
    assert all(len(v.groups) == 1 and abs(v.groups[0].weight - 1) < 1e-6 for v in cap.data.vertices)
    # Every fabric vertex belongs to one connected, watertight mesh, including the visor.
    adjacent = {v.index: set() for v in cap.data.vertices}
    edge_uses = {}
    for polygon in cap.data.polygons:
        for key in polygon.edge_keys:
            adjacent[key[0]].add(key[1]); adjacent[key[1]].add(key[0])
            key = tuple(sorted(key)); edge_uses[key] = edge_uses.get(key, 0) + 1
    pending = [0]; visited = set()
    while pending:
        i = pending.pop()
        if i in visited: continue
        visited.add(i); pending.extend(adjacent[i] - visited)
    assert len(visited) == len(cap.data.vertices), name + ': detached fabric component'
    assert all(n == 2 for n in edge_uses.values()), name + ': open seam in cap fabric'
    hair = next(o for o in bpy.context.scene.objects if o.type == 'MESH' and 'short02' in o.name.lower())
    band_bottom = cap.get('band_bottom',cap['band_top'] - .025 * max(v.co.z for v in body.data.vertices) / 1.72)
    rim=[v.co for v in cap.data.vertices[:64]]
    center_y=sum(p.y for p in rim)/len(rim)
    inner_width=max(abs(p.x) for p in rim)-.003
    inner_depth=(max(p.y for p in rim)-min(p.y for p in rim))*.5-.003
    for point in scalp:
        if band_bottom+.003 < point.z < cap['band_top']:
            radius=(point.x/inner_width)**2+((point.y-center_y)/inner_depth)**2
            assert radius<1, name + ': forehead protrudes through the cap band'
    for v in hair.data.vertices:
        if v.co.z > band_bottom - .002:
            radius = (v.co.x / inner_width)**2 + ((v.co.y-center_y)/ inner_depth)**2
            assert radius <= 1.001, name + ': hair penetrates the fitted band'
    assert max(v.co.z for v in hair.data.vertices) < cap['band_top']-.005, name + ': hair penetrates the crown'
    assert cap['crown_top'] > max(p.z for p in scalp) + .003, name + ': crown cuts through the scalp'
    # Rigid head weighting must retain the exact local fit under a strong head turn.
    point = cap.data.vertices[0].co.copy()
    original_head = rig.pose.bones['Head'].matrix.copy()
    rig.pose.bones['Head'].rotation_mode = 'XYZ'
    rig.pose.bones['Head'].rotation_euler = (.25, -.4, .5)
    bpy.context.view_layer.update()
    expected = rig.matrix_world @ rig.pose.bones['Head'].matrix @ rig.data.bones['Head'].matrix_local.inverted() @ point
    evaluated = cap.evaluated_get(bpy.context.evaluated_depsgraph_get())
    actual = evaluated.matrix_world @ evaluated.data.vertices[0].co
    assert (expected - actual).length < 1e-5, name + ': cap slips when the head rotates'
    print('PASS fitted connected cap, hair clearance and head turn:', name)
if failures:
    print('\n'.join('FAIL ' + f for f in failures))
    sys.exit(1)
