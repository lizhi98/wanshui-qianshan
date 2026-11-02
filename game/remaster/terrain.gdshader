shader_type spatial;
uniform sampler2D ground_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D stone_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap;
uniform sampler2D rock_rough : filter_linear_mipmap;
varying vec3 world;
varying vec3 world_normal;
void vertex(){
 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment(){
 vec3 weights=pow(abs(world_normal),vec3(4.0));
 weights/=max(weights.x+weights.y+weights.z,0.001);
 vec3 rock=texture(stone_map,world.zy*.30).rgb*weights.x+texture(stone_map,world.xz*.30).rgb*weights.y+texture(stone_map,world.xy*.30).rgb*weights.z;
 vec3 ground=texture(ground_map,world.xz*.52).rgb;
 float flatness=smoothstep(.65,.94,world_normal.y);
 float distant=smoothstep(12.0,45.0,world.y);
 float soil=flatness*(1.0-distant*.75);
 float macro=.90+.10*sin(world.x*.063+sin(world.z*.041)*2.0)*sin(world.z*.074);
 float wet=1.0-smoothstep(-14.5,-8.0,world.y);
 float growth=.5+.5*sin(world.x*.21+sin(world.z*.16)*1.3)*sin(world.z*.19);
 vec3 earth_tint=mix(vec3(.56,.54,.40),vec3(.34,.46,.25),growth);
 ALBEDO=mix(rock*vec3(.58,.58,.54),ground*earth_tint,soil)*macro*mix(1.0,.64,wet);
 vec2 micro=texture(rock_normal,world.zy*.30).xy*weights.x+texture(rock_normal,world.xz*.30).xy*weights.y+texture(rock_normal,world.xy*.30).xy*weights.z;
 micro=mix(micro,texture(ground_normal,world.xz*.52).xy,soil)*2.0-1.0;
 vec3 n=normalize(world_normal);vec3 tangent=abs(n.y)>.95?vec3(1,0,0):normalize(cross(vec3(0,1,0),n));
 vec3 bitangent=normalize(cross(n,tangent));
 NORMAL=normalize((VIEW_MATRIX*vec4(normalize(n+(tangent*micro.x+bitangent*micro.y)*.18),0.0)).xyz);
 ROUGHNESS=mix(clamp(texture(rock_rough,world.zy*.3).r,.5,.94),.94,soil)-wet*.18;
}
