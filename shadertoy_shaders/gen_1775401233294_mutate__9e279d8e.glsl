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
    vec2 p = uv * 4.0; 
    vec2 p_flow = p * 2.0;
    float time = iTime;

    // Use complex sin/cos interaction for flow
    vec2 flow = vec2(sin(p_flow.x * 5.0 + time * 1.1), cos(p_flow.y * 6.0 + time * 0.8));

    // Calculate base coordinates
    vec2 base = uv + flow * 0.7;

    // Radial distance and oscillation
    float r = length(base - 0.5);

    // Oscillation based on modified distance and time interaction
    float f1 = sin(r * 8.0 + time * 1.8);
    float f2 = cos(r * 5.0 - time * 1.0);

    // Color modulation based on flow and radial effects
    float color_t = sin(f1 * 1.5 + f2 * 0.3) * 0.5 + 0.5;

    // Apply panning effect based on flow magnitude
    vec3 final_color = pal(color_t + uv.x * 0.8 + flow.x * 0.4);

    // Apply a distance-dependent transparency, emphasizing closer areas
    float alpha = 1.0 - r * 3.0;
    alpha = smoothstep(0.0, 0.3, alpha * (1.0 + sin(time * 1.5) * 0.1));

    fragColor = vec4(final_color, alpha);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
