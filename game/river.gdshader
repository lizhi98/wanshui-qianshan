shader_type spatial;
render_mode cull_disabled;
varying vec3 world;
void vertex(){
 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.y += sin(world.x*0.65+TIME*3.0)*0.09+cos(world.z*1.9+world.x*0.27+TIME*2.0)*0.06;
}
void fragment(){
 float flow=sin(world.x*0.45+world.z*3.4+TIME*4.5);
 float ridge=pow(max(0.0,sin(world.x*1.5+world.z*2.8+TIME*5.0)),18.0);
 float foam=smoothstep(0.68,0.94,sin(world.z*4.5+sin(world.x*0.3+TIME*2.0)))*ridge;
 ALBEDO=mix(vec3(0.075,0.25,0.25),vec3(0.23,0.40,0.38),flow*0.5+0.5);
 ALBEDO=mix(ALBEDO,vec3(0.68,0.76,0.65),foam*0.85);
 ROUGHNESS=0.28; METALLIC=0.2;
 NORMAL=normalize(vec3(cos(world.x*0.65+TIME*3.0)*0.14,1.0,sin(world.z*1.9+TIME*2.0)*0.20));
}
