shader_type spatial;
render_mode cull_disabled,alpha_to_coverage;
uniform sampler2D diffuse_tex:source_color,filter_linear_mipmap;
uniform sampler2D normal_tex:hint_normal,filter_linear_mipmap;
uniform sampler2D alpha_tex:filter_linear_mipmap;
varying float variation;
void vertex(){
 vec3 w=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 variation=sin(w.x*.7+w.z*.4)*.5+.5;
 VERTEX.x+=sin(TIME*1.4+w.x*.61+w.z*.3)*smoothstep(0.,.5,VERTEX.y)*.018;
}
void fragment(){
 ALBEDO=texture(diffuse_tex,UV).rgb*mix(vec3(.72,.79,.57),vec3(.98,.92,.65),variation);
 ALPHA=texture(alpha_tex,UV).r;ALPHA_SCISSOR_THRESHOLD=.38;
 ALPHA_ANTIALIASING_EDGE=.30;
 NORMAL_MAP=texture(normal_tex,UV).rgb;NORMAL_MAP_DEPTH=.45;ROUGHNESS=.89;BACKLIGHT=vec3(.12,.14,.07);
}
