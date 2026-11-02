shader_type spatial;
uniform vec4 cloth_color:source_color=vec4(.20,.26,.27,1.0);
uniform sampler2D cloth_normal:hint_normal,filter_linear_mipmap;
uniform float use_normal=1.0;
uniform float canvas=0.0;
varying vec3 rest_position;
void vertex(){rest_position=VERTEX;}
float hash(vec3 p){return fract(sin(dot(p,vec3(17.1,51.7,93.3)))*43758.5453);}
void fragment(){
 vec3 p=rest_position;float coarse=hash(floor(p*22.0));
 float grime=(1.0-smoothstep(.12,.75,p.y))*.32;
 float wear=sin(p.x*53.0+p.y*14.0)*sin(p.z*21.0-p.y*29.0)*.035;
 vec2 weave=UV*600.0;float antialias=1.0-smoothstep(.35,1.0,max(fwidth(weave.x),fwidth(weave.y)));
 float fiber=sin(weave.x*6.283)*sin(weave.y*6.283)*antialias*.025;
 ALBEDO=cloth_color.rgb*(.93+coarse*.12+wear+fiber)*mix(vec3(1.0),vec3(.58,.49,.36),grime);
 vec3 base_normal=mix(vec3(.5,.5,1.0),texture(cloth_normal,UV).rgb,use_normal);
 NORMAL_MAP=base_normal+vec3(sin(p.y*370.0)*.025,sin(p.x*370.0)*.025,0.0)*antialias;
 NORMAL_MAP_DEPTH=.65;ROUGHNESS=.94;SPECULAR=.18;
}
