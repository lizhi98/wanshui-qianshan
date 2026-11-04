shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,blend_mix;
void vertex(){MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);}
void fragment(){float edge=1.-smoothstep(.06,.50,length(UV-vec2(.5))); ALBEDO=vec3(.70,.77,.72); ALPHA=edge*COLOR.a*.13;}
