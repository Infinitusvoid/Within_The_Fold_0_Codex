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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.0,0.25,0.6)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Scale and shift coordinates
    vec2 p = uv * 5.0; 
    vec2 p_flow = p * 3.0;
    float time = iTime;

    // Introduce flow based on a different trigonometric mix
    vec2 flow = vec2(sin(p_flow.x * 3.0 + time), cos(p_flow.y * 4.0 + time * 0.5));

    // Calculate base coordinates
    vec2 base = uv + flow * 1.2;

    // Radial distance and oscillation
    float r = length(base - 0.5);

    // Oscillation based on modified distance and time interaction
    float f1 = sin(r * 10.0 + time * 2.5);
    float f2 = cos(r * 3.0 - time * 1.5);

    // Color modulation based on flow and radial effects
    float color_t = sin(f1 * 2.0 + f2 * 0.5) * 0.5 + 0.5;

    // Apply panning effect based on flow magnitude
    vec3 final_color = pal(color_t + uv.y * 1.2 + flow.x * 0.5);

    // Apply a distance-dependent transparency, emphasizing closer areas
    float alpha = 1.0 - r * 4.0;
    alpha = smoothstep(0.0, 0.2, alpha * (1.0 + sin(time * 2.0) * 0.15));

    fragColor = vec4(final_color, alpha);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
