shader_type spatial;
uniform sampler2D ground_tex:source_color,repeat_enable;
uniform sampler2D ground_normal:hint_normal,repeat_enable;
uniform sampler2D mud_tex:source_color,repeat_enable;
uniform sampler2D mud_normal:hint_normal,repeat_enable;
uniform sampler2D mud_orm:repeat_enable;
varying vec3 p;
float shore(vec2 point,vec2 center,vec2 radius){vec2 q=(point-center)/radius;float a=atan(q.y,q.x);return length(q)/(1.+sin(a*3.+.3)*.09+cos(a*7.)*.055+sin(a*11.-.6)*.025);}
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 uv=p.xz*.31;
 float noise=sin(p.x*.29+sin(p.z*.37))*sin(p.z*.23+p.x*.12)*.5+.5;
 float bank=min(shore(p.xz,vec2(14.,-2.),vec2(6.5,8.)),shore(p.xz,vec2(14.,-40.),vec2(6.2,7.)));
 float path=1.-smoothstep(.5,1.55,abs(p.x-sin(p.z*.09)*2.));
 float camp=1.-smoothstep(3.,6.7,distance(p.xz,vec2(-8.,10.)));
 float mudpatch=1.-smoothstep(.7,1.2,length((p.xz-vec2(2.,1.))/vec2(5.2,4.)));
 float wet=max(1.-smoothstep(1.04,1.47,bank),max(path*.64,camp*.78));wet=clamp(max(wet,mudpatch)+noise*.12,0.,1.);
 vec3 grass=texture(ground_tex,uv).rgb*mix(vec3(.71,.76,.54),vec3(.91,.88,.64),noise);
 vec3 mud=texture(mud_tex,uv*1.5).rgb*mix(vec3(.61,.67,.56),vec3(.83,.81,.66),noise);
 ALBEDO=mix(grass,mud,wet);ROUGHNESS=mix(.97,.57,wet*(1.-noise*.35));SPECULAR=.24;
 NORMAL_MAP=mix(texture(ground_normal,uv).rgb,texture(mud_normal,uv*1.5).rgb,wet);NORMAL_MAP_DEPTH=.35;
 AO=mix(1.,texture(mud_orm,uv*1.5).r,wet*.6);
}
