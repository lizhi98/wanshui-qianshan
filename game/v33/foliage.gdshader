shader_type spatial;
render_mode cull_disabled;
varying vec3 tint;
varying float height_mix;
varying float leafness;
void vertex(){
 vec3 origin=(MODEL_MATRIX*vec4(0.0,0.0,0.0,1.0)).xyz;
 float h=max(VERTEX.y,0.0);float gust=sin(TIME*1.8+origin.x*.37+origin.z*.19)+sin(TIME*2.7+origin.x*.71)*.3;
 VERTEX.x+=gust*h*h*.075;VERTEX.z+=sin(TIME*1.2+origin.x*.22)*h*h*.04;
 tint=COLOR.rgb;height_mix=clamp(h*1.8,0.0,1.0);leafness=1.0-step(.8,COLOR.a);
}
void fragment(){
 float veins=exp(-abs(UV.x-.5)*75.0)*.12+pow(max(0.0,cos((UV.y*7.0-abs(UV.x-.5)*2.0)*6.283)),18.0)*.03;
 ALBEDO=tint*mix(.74,1.05,height_mix)*(1.0+veins*leafness);
 ROUGHNESS=.92;BACKLIGHT=tint*.18;
}
