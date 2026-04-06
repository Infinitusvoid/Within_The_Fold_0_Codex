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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.1,0.4,0.7)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Convert to polar coordinates centered at 0
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // Use r for falloff and theta for color modulation
    float dist_factor = 1.0 / (r * 4.0 + 0.5); // Adjusted falloff scale

    // Time modulation based on position and rotation
    float t = iTime * 2.0 + r * 1.5 + theta * 3.5;

    // Introduce high frequency oscillation using the polar components
    float r_mod = sin(t * 4.5 + theta * 8.0) * 0.5 + 0.5;
    float g_mod = cos(t * 3.5 + r * 7.0) * 0.5 + 0.5;
    float b_mod = sin(t * 5.0 + theta * 10.0) * 0.5 + 0.5;

    // Base palette input
    float p_input = dist_factor * 8.0 + t * 0.5;

    // Mix colors using the modulation function, incorporating radial falloff directly
    vec3 color = pal(p_input) * r_mod * 0.7 + pal(p_input + 0.1) * g_mod * 0.8 + pal(p_input + 0.2) * b_mod * 0.9;

    // Apply final ambient lighting based on distance and time
    float ambient = 0.15 + dist_factor * 1.2;
    color *= ambient * (1.0 + sin(t * 3.0));

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
