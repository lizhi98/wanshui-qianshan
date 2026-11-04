shader_type spatial;
uniform float shadow=0.;
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
 float back=smoothstep(-.016,.025,p.y);
 vec3 color=mix(vec3(.53,.54,.39),vec3(.15,.22,.17),back);
 vec2 cell=UV*vec2(72.,30.);cell.y+=mod(floor(cell.x),2.)*.5;
 float edge=smoothstep(.31,.49,length(fract(cell)-.5));
 color*=1.-edge*.12;
 ALBEDO=mix(color,vec3(.08,.13,.10),shadow*.75);
 METALLIC=.19;ROUGHNESS=.29+shadow*.25;SPECULAR=.48;
}
