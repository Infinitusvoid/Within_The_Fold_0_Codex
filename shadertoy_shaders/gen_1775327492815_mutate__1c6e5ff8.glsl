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
    return vec3(0.05 + 0.65 * sin(t * 1.2 - iTime * 0.2), 0.2 + 0.5 * cos(t * 0.9 + iTime * 0.1), 0.8 - 0.4 * sin(t * 0.7 + iTime * 0.05));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = uv * vec2(3.0, 1.0) - vec2(0.5, 0.0);

    // UV space dynamic perturbation defining an arbitrary field angle
    float angle = iTime * 1.5 + sin(uv.x * 8.0 + iTime * 0.1) * cos(uv.y * 4.0) * 0.4;
    mat2 rotationMatrix = mat2(cos(angle*0.8), -sin(angle*0.8), sin(angle*0.8), cos(angle*0.8));
    uv = rotationMatrix * uv;

    uv = waveC(uv);
    uv = waveD(uv);

    float t = sin(uv.x * 4.5 + iTime * 1.0) * 1.5 + uv.y * 3.0;
    vec3 base_color = palette(t);

    float flow_dot = sin(uv.y * 10.0 + iTime * 1.2) * cos(uv.x * 5.0);
    float flow_per = cos(uv.x * 6.0 + iTime * 0.7);

    // Interaction mixing flows differently
    float texture_warp = pow(flow_dot * flow_per, 2.0);

    // Blend base color based on combined spatial flow interaction
    vec3 adjusted_color = mix(base_color, vec3(1.0, flow_dot * 0.7, 0.5), texture_warp * 0.8);

    fragColor = vec4(adjusted_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
