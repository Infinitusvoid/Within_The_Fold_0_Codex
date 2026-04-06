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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 0.5), cos(uv.y * 8.0 - iTime * 0.4));
}

vec2 waveC(vec2 uv)
{
    return vec2(sin(uv.x * 6.2 + iTime * 0.5), cos(uv.y * 7.0 - iTime * 0.45));
}

vec2 waveD(vec2 uv)
{
    return vec2(sin(uv.y * 4.0 + iTime * 0.6), cos(uv.x * 8.0 + iTime * 0.3));
}

vec3 palette(float t)
{
    float r = 0.05 + 0.65 * sin(t * 1.2 - iTime * 0.2);
    float g = 0.2 + 0.5 * cos(t * 0.9 + iTime * 0.1);
    float b = 0.8 - 0.4 * sin(t * 0.7 + iTime * 0.05);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply initial coordinate transformation (from B)
    uv = uv * vec2(3.0, 1.0) - vec2(0.5, 0.0);

    // UV space dynamic perturbation defining an arbitrary field angle (from B)
    float angle = iTime * 1.5 + sin(uv.x * 8.0 + iTime * 0.1) * cos(uv.y * 4.0) * 0.4;
    mat2 rotationMatrix = mat2(cos(angle*0.8), -sin(angle*0.8), sin(angle*0.8), cos(angle*0.8));
    uv = rotationMatrix * uv;

    // Apply combined wave functions (A and C/D)
    vec2 flow1 = waveB(uv);
    vec2 flow2 = waveC(uv);
    vec2 flow3 = waveD(uv);

    // Combine the wave results
    vec2 final_uv = flow1 * 0.5 + flow2 * 0.3 + flow3 * 0.2;

    // Generate the color factor based on combined spatial interaction
    float t = sin(final_uv.x * 4.5 + iTime * 1.0) * 1.5 + final_uv.y * 3.0;
    vec3 base_color = palette(t);

    // Calculate flow interaction factors (from B)
    float flow_dot = sin(final_uv.y * 10.0 + iTime * 1.2) * cos(final_uv.x * 5.0);
    float flow_per = cos(final_uv.x * 6.0 + iTime * 0.7);

    // Blend base color based on combined spatial flow interaction
    float texture_warp = pow(flow_dot * flow_per, 2.0);

    // Mix base color with a vibrant flow
    vec3 flow_color = vec3(1.0, flow_dot * 0.7, 0.5);
    vec3 adjusted_color = mix(base_color, flow_color, texture_warp * 0.8);

    // Enhance contrast using a spatial frequency effect (from A)
    float contrast_factor = 1.0 + abs(sin(final_uv.x * 12.0 + iTime * 0.5)) * 0.5;
    adjusted_color *= contrast_factor;

    // Apply final color transformation
    adjusted_color = pow(adjusted_color, vec3(1.1));

    fragColor = vec4(adjusted_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
