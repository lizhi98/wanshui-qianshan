shader_type spatial;
render_mode cull_disabled;
void fragment(){
 float x=UV.x/.18;float y=abs(UV.y)/.24;
 float id=floor(x)+floor(y)*37.0;
 float variation=fract(sin(id*17.137)*43758.5453);
 float ridge=.5+.5*cos(x*6.283185);
 float seam=smoothstep(.02,.11,fract(y));
 ALBEDO=vec3(.12,.15,.15)*(0.78+variation*.24+ridge*.16)*mix(.6,1.0,seam);
 NORMAL_MAP=normalize(vec3(sin(x*6.283185)*.30,(1.0-seam)*.22,1.0))*.5+.5;
 NORMAL_MAP_DEPTH=.65;ROUGHNESS=.68+variation*.17;
}
