#version 330 core
uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;
uniform vec4 iDate;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform float iChannelTime[4];
uniform vec3 iChannelResolution[4];
out vec4 FragColor;

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.05,0.35,0.75)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    vec2 p = 1.0 - 2.0*uv;
    vec2 abs_p = abs(p);
    float r = length(uv), a = atan(uv.y,uv.x);

    // Use iTime and iFrame to create dynamic shifting
    float time_factor = iTime * 0.4 + iFrame * 0.1;

    // Calculate depth based on polar coordinates and time
    float z = floor((1.0/(r+0.1) + time_factor)*4.0)/4.0;

    // Introduce complexity via sine/cosine based on angle and depth
    float f1 = sin(15.0*a + z*3.0);
    float f2 = cos(r * 6.28318 * (1.0 + time_factor));

    // Masking function based on interaction
    float m = smoothstep(0.1, 0.0, abs(f1 * f2 * 1.5));

    // Color manipulation: base color depends on angle and depth
    vec3 base_color = pal(0.1*z + 0.3*a);

    // Apply scaling using inverse distance and phase interaction
    vec3 final_color = base_color * m * (1.0 / (r*r + 0.01)) * (1.0 + f2*0.7);

    // Add subtle motion based on time
    final_color += pow(sin(iTime*1.2), 1.5) * 0.1;

    fragColor = vec4(final_color,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
