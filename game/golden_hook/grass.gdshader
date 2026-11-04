shader_type spatial;
render_mode cull_disabled;
varying float blade_y;
void vertex(){blade_y=UV.y; vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; VERTEX.x+=sin(TIME*1.8+p.x*.9+p.z*.6)*pow(UV.y,2.)*.09;}
void fragment(){ALBEDO=mix(vec3(.025,.055,.018),vec3(.14,.18,.055),blade_y); ROUGHNESS=.95;}
