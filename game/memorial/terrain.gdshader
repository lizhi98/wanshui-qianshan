shader_type spatial;
uniform sampler2D rock_map:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D earth_map:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D rock_normal:hint_normal,filter_linear_mipmap;
uniform bool path_surface=false;
uniform float snow_coverage=1.0;
varying vec3 world;varying vec3 n_world;varying float wear;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;n_world=normalize(MODEL_NORMAL_MATRIX*NORMAL);wear=COLOR.r;}
void fragment(){
 vec3 w=pow(abs(n_world),vec3(4.));w/=max(.001,w.x+w.y+w.z);
 vec3 fine=texture(rock_map,world.zy*.33).rgb*w.x+texture(rock_map,world.xz*.33).rgb*w.y+texture(rock_map,world.xy*.33).rgb*w.z;
 vec3 macro=texture(rock_map,world.zy*.049+vec2(.23,.6)).rgb*w.x+texture(rock_map,world.xz*.049).rgb*w.y+texture(rock_map,world.xy*.049).rgb*w.z;
 float layer=sin(world.y*1.1+sin(world.x*.09)*1.7+world.z*.12)*.045;
 float drift=sin(world.x*.18+world.z*.11)*sin(world.z*.09-world.x*.15);
 float snow=(.80+.18*smoothstep(-5.,50.,world.y+drift*16.))*smoothstep(.25,.85,n_world.y);
 snow*=snow_coverage;
 vec3 rock=mix(fine,macro,.32)*vec3(.50,.49,.46)+layer;
 vec3 soil=texture(earth_map,world.xz*.43).rgb*vec3(.56,.56,.42);
 vec3 ground=mix(rock,soil,smoothstep(.70,.99,n_world.y)*(1.-smoothstep(19.,40.,world.y)));
 float grain=sin(world.x*31.+world.z*17.)*sin(world.z*37.)*.01;
 ALBEDO=mix(ground,vec3(.77,.81,.83)+grain,snow);
 if(path_surface){vec3 compressed=mix(soil*1.16,vec3(.62,.68,.71),snow);ALBEDO=mix(ALBEDO,compressed,wear*(.30+drift*.08));}
 ROUGHNESS=.87;SPECULAR=.18;
 vec2 detail=texture(rock_normal,world.xz*.33).xy*2.-1.;NORMAL=normalize(NORMAL+vec3(detail.x,0,detail.y)*.11*(1.-snow));
}
