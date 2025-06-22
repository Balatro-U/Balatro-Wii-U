extern vec4 gold_seal;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    //r controls timing
    //a controls alpha, but white will always be 1
    vec4 pixel;
    pixel = Texel(texture, texture_coords);
    number low = min(pixel.r, min(pixel.g, pixel.b));
    number high = max(pixel.r, max(pixel.g, pixel.b));
	number delta;
    delta = high*0.5;

    number fac;
    fac = 0.3+sin((texture_coords.x*450. + sin(gold_seal.r*6.)*180.)-700.*gold_seal.r) - sin((texture_coords.x*190. + texture_coords.y*30.)+1080.3*gold_seal.r);

    pixel.r = max(pixel.r, (1. - pixel.r)*delta*fac + pixel.r);
    pixel.g = max(pixel.g, (1. - pixel.g)*delta*fac + pixel.g);
    pixel.b = max(pixel.b, (1. - pixel.b)*delta*fac + pixel.b);

    return pixel;
}