shader_type spatial;
uniform sampler2D skin_texture:source_color,filter_linear_mipmap_anisotropic;
uniform vec3 eye_center=vec3(0.,1.60,.132);
uniform float age=0.;
varying vec3 rest_position;
void vertex(){rest_position=vec3(UV2.x,UV2.y,COLOR.r-.5);}
void fragment(){
 vec3 color=texture(skin_texture,UV).rgb;
 float front=smoothstep(eye_center.z-.01,eye_center.z+.02,rest_position.z);
 float brow=exp(-pow((rest_position.y-eye_center.y-.037)/.022,2.))*exp(-pow(rest_position.x/.075,4.));
 float line=pow(.5+.5*sin(rest_position.y*670.+rest_position.x*13.),18.);
 float side=exp(-pow((abs(rest_position.x)-.049)/.018,2.)-pow((rest_position.y-eye_center.y)/.018,2.));
 float crease=pow(.5+.5*sin((rest_position.y-eye_center.y)*540.+abs(rest_position.x)*180.),12.);
 float bags=exp(-pow((abs(rest_position.x)-.031)/.026,2.)-pow((rest_position.y-eye_center.y+.019)/.011,2.));
 float smile_line=exp(-pow((abs(rest_position.x)-(.024+(eye_center.y-rest_position.y)*.24))/.0036,2.))*exp(-pow((rest_position.y-eye_center.y+.049)/.033,2.));
 color*=1.-age*front*(brow*line*.27+side*crease*.14+bags*.11+smile_line*.16);
 color=mix(color,vec3(dot(color,vec3(.3,.59,.11))),age*.06);
 ALBEDO=color; ROUGHNESS=.80+age*.12; SPECULAR=.24;
 NORMAL_MAP=vec3(.5+age*front*side*crease*.045,.5+age*front*brow*line*.055,1.0);
}
