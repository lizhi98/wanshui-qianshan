shader_type spatial;
render_mode cull_disabled;
varying vec3 world;
void vertex(){
 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.y+=sin(world.x*.72+TIME*2.9)*.15+sin(world.z*2.2-world.x*.5+TIME*3.3)*.09;
}
void fragment(){
 float flow=world.x*.73-TIME*2.8;
 float swell=sin(flow+sin(world.z*.61)*1.5)+sin(flow*1.73+world.z*2.2)*.38;
 float ripple=sin(world.x*4.1-TIME*9.0+sin(world.z*1.7))*sin(world.z*7.3-world.x*1.1+TIME*3.2);
 float patches=.5+.5*sin(world.z*.21+sin(world.x*.18-TIME*.45));
 float foam=smoothstep(1.0,1.35,swell)*smoothstep(-.2,.7,ripple)*patches*.6;
 ALBEDO=mix(vec3(.07,.145,.135),vec3(.12,.20,.17),swell*.18+.4);
 ALBEDO=mix(ALBEDO,vec3(.67,.72,.66),foam);
 METALLIC=.02; SPECULAR=.42;
 ROUGHNESS=.36+foam*.4;
 NORMAL=normalize(NORMAL+vec3(cos(flow)*.10+ripple*.04,0.0,cos(world.z*2.2+flow*1.73)*.08));
}
