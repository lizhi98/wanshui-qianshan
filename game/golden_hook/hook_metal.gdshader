shader_type spatial;
uniform float worn=0.;
uniform float heat=0.;
varying vec3 local_point;
void vertex(){local_point=VERTEX;}
void fragment(){
 float grain=sin(local_point.x*7523.+local_point.y*3917.)*sin(local_point.y*9863.+local_point.z*7301.);
 float rust=smoothstep(-.17,.55,grain+sin(local_point.y*740.)*.3)*worn;
 vec3 iron=mix(vec3(.39,.42,.38),vec3(.25,.105,.037),rust*.82);
 ALBEDO=mix(iron,vec3(.62,.16,.032),heat*.70);
 METALLIC=mix(.88,.29,rust);ROUGHNESS=mix(.28,.83,rust);
 EMISSION=vec3(.72,.11,.015)*heat*heat*.26;
 NORMAL_MAP=normalize(vec3(grain*.14,grain*.08,1.))*.5+.5;
}
