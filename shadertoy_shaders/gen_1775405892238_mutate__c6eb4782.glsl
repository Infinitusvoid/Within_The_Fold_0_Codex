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

float smin(float a,float b,float k){ float h=clamp(0.5+0.5*(b-a)/k,0.0,1.0); return mix(b,a,h)-k*h*(1.0-h); }
vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.38,0.68)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    float t = iTime * 0.5;

    // Define field complexity based on time and coordinates
    vec2 p = uv * 10.0 + t * 0.5;

    float flow = 0.0;
    float d = 100.0;

    // Introduce flow calculations, modified to interact with global time
    vec2 f1 = vec2(cos(t * 2.0 + p.x), sin(t * 1.5 + p.y) * 0.8);
    vec2 f2 = vec2(sin(t * 3.0 + p.x * 0.5) * 1.5, cos(t * 4.0 + p.y * 0.8));

    // Use smin iteratively for complexity generation, introducing a dynamic factor
    d = length(uv - f1) - 0.5;
    d = smin(d, d + 0.4, 0.15); // Increased interaction factor

    d = length(uv - f2) - 0.5;
    d = smin(d, d + 1.5, 0.25); // Increased interaction factor

    float maxD = 2.0;
    d = clamp(d / maxD, 0.0, 1.0);

    // Modify fill based on a different threshold
    float fill = smoothstep(0.06, 0.005, d);
    float contrast = abs(d - 0.5) * 3.0;

    // Calculate color based on flow and distance
    // Vary the time input for the color palettes
    vec3 color1 = pal(t + d * 20.0);
    vec3 color2 = pal(t + (d * 0.8) + iTime * 1.0);

    vec3 final_col = mix(color1, color2, contrast);

    // Apply flow based modulation
    final_col = mix(final_col, color1 * 0.5, d * 0.5);

    fragColor = vec4(final_col * (0.5 + fill * 1.8), 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
