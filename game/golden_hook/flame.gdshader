shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,blend_mix;
uniform float phase=0.;
void fragment(){
 vec2 p=vec2(UV.x-.5,1.-UV.y);
 float sway=sin(TIME*5.1+p.y*9.+phase)*p.y*.065;
 float width=(1.-p.y)*.43+.015;
 float core=1.-smoothstep(width*.55,width,abs(p.x+sway));
 float fade=smoothstep(0.,.09,p.y)*(1.-smoothstep(.70,1.,p.y));
 ALBEDO=mix(vec3(1.,.29,.045),vec3(1.,.79,.27),core*(1.-p.y*.65));
 EMISSION=ALBEDO*.5; ALPHA=core*fade*.76;
}
