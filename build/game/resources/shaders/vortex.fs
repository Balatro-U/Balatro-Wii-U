extern float vortex_amt;

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    vec2 uv = (vertex_position.xy - 0.5*love_ScreenSize.xy)/length(love_ScreenSize.xy);

    float effectRadius = 1.6 - 0.05*vortex_amt;
    float effectAngle = 0.5 + 0.15*vortex_amt;
    
    float len = length(uv * vec2(love_ScreenSize.x / love_ScreenSize.y, 1.));
    float angle = atan(uv.y, uv.x) + effectAngle * smoothstep(effectRadius, 0., len);
    float radius = length(uv);

    vec2 center = 0.5*love_ScreenSize.xy/length(love_ScreenSize.xy);

    vertex_position.x = (radius * cos(angle) + center.x)*length(love_ScreenSize.xy);
    vertex_position.y = (radius * sin(angle) + center.y)*length(love_ScreenSize.xy);
    return transform_projection * vertex_position;
}
#endif