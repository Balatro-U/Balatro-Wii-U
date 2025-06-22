#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
	#define MY_HIGHP_OR_MEDIUMP highp
#else
	#define MY_HIGHP_OR_MEDIUMP mediump
#endif


extern MY_HIGHP_OR_MEDIUMP number time;
extern MY_HIGHP_OR_MEDIUMP number mid_flash;

#define PIXEL_SIZE_FAC 700.

vec4 effect( vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    //Convert to UV coords (0-1) and floor for pixel effect
    number pixel_size = length(love_ScreenSize.xy)/PIXEL_SIZE_FAC;
    vec2 uv = (floor(screen_coords.xy*(1./pixel_size))*pixel_size - 0.5*love_ScreenSize.xy)/length(love_ScreenSize.xy);

    float mid_white =  min(1.,(time > 2.5 ? max(0., sqrt(time - 2.5) - 60.*length(uv)) : 0.)
                        + (time > 11. ? max(0., (time-11.)*(time-11.) - 5.*length(uv)) : 0.));
                        
    return vec4(1., 1., 1., mid_flash*mid_white);
}