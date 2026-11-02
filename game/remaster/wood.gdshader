shader_type spatial;
uniform sampler2D diffuse_map : source_color, filter_linear_mipmap;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap;
uniform sampler2D rough_map : filter_linear_mipmap;
void fragment(){
 ALBEDO=texture(diffuse_map,UV).rgb*vec3(0.70,0.57,0.41);
 NORMAL_MAP=texture(normal_map,UV).rgb;
 NORMAL_MAP_DEPTH=0.6;
 ROUGHNESS=texture(rough_map,UV).r;
}
