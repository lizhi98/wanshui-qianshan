shader_type spatial;
uniform sampler2D rock_map:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D earth_map:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D rock_normal:hint_normal,filter_linear_mipmap;
uniform bool path_surface=false;
varying vec3 world;
varying vec3 n_world;
varying float path_weight;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;n_world=normalize(MODEL_NORMAL_MATRIX*NORMAL);path_weight=COLOR.r;}
void fragment(){
 vec3 w=pow(abs(n_world),vec3(4.0));w/=max(.001,w.x+w.y+w.z);
 vec3 rock=texture(rock_map,world.zy*.25).rgb*w.x+texture(rock_map,world.xz*.25).rgb*w.y+texture(rock_map,world.xy*.25).rgb*w.z;
 vec3 soil=texture(earth_map,world.xz*.5).rgb*vec3(.40,.46,.30);
 float patches=sin(world.x*.37+sin(world.z*.18)*2.0)*sin(world.z*.26-world.x*.12);
 float snow=smoothstep(21.0,74.0,world.y+patches*12.0)*smoothstep(.23,.78,n_world.y);
 float flatness=smoothstep(.60,.95,n_world.y);
 vec3 stone=mix(rock*vec3(.42,.45,.47),soil,flatness*(1.0-smoothstep(15.0,40.0,world.y)));
 float grain=sin(world.x*39.0+world.z*17.0)*sin(world.z*43.0)*.012;
 ALBEDO=mix(stone,vec3(.73,.80,.86)+grain,snow);
 if(path_surface){vec3 worn=mix(texture(earth_map,world.xz*.5).rgb*vec3(.62,.57,.45),vec3(.57,.65,.72)+grain,snow);ALBEDO=mix(ALBEDO,worn,path_weight*.63);}
 ROUGHNESS=mix(.88,.77,snow);SPECULAR=.25;
 vec2 detail=texture(rock_normal,world.xz*.25).xy*2.0-1.0;
 NORMAL=normalize(NORMAL+vec3(detail.x,0,detail.y)*.1*(1.0-snow));
}
