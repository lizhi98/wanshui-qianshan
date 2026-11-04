shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled;
uniform vec4 water_color:source_color=vec4(.14,.22,.185,.79);
uniform float darkness=0.;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; VERTEX.y+=sin(world_pos.x*1.7+TIME*.9)*.008+sin(world_pos.z*2.3-TIME*.7)*.005;}
void fragment(){
 float w1=sin(dot(world_pos.xz,vec2(8.1,3.7))+TIME*1.2);
 float w2=sin(dot(world_pos.xz,vec2(-4.8,12.6))-TIME*.9);
 float w3=sin(dot(world_pos.xz,vec2(21.3,16.4))+TIME*1.8);
 float wave=w1*.45+w2*.35+w3*.20;
 vec2 q=(world_pos.xz-vec2(14.,world_pos.z< -21.? -40.:-2.))/vec2(6.5,8.);
 float a=atan(q.y,q.x);float d=length(q)/(1.+sin(a*3.+.3)*.09+cos(a*7.)*.055+sin(a*11.-.6)*.025);
 float edge=smoothstep(.78,1.03,d);
 ALBEDO=mix(water_color.rgb*.56,vec3(.27,.29,.18),edge*.54)+wave*.009-darkness*.028;
 ROUGHNESS=.24+edge*.22+wave*.025;METALLIC=.04;SPECULAR=.48;ALPHA=mix(.80,.62,edge);
 NORMAL_MAP=normalize(vec3(w1*.018+w3*.006,w2*.018-w3*.008,1.))*.5+.5;
}
