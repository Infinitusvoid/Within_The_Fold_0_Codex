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
    return vec2(sin(uv.x * 7.0 + iTime * 0.5), cos(uv.y * 5.5 - iTime * 0.4));
}

vec2 waveD(vec2 uv)
{
    return vec2(sin(uv.y * 6.0 + iTime * 0.6), cos(uv.x * 9.0 + iTime * 0.3));
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.7 * sin(t * 1.5 - iTime * 0.3), 0.3 + 0.5 * cos(t * 0.8 + iTime * 0.2), 0.9 - 0.5 * sin(t * 0.7 + iTime * 0.1));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = uv * vec2(3.0, 1.0) - vec2(0.5, 0.0);

    // UV space dynamic perturbation defining an arbitrary field angle
    float angle = iTime * 1.6 + sin(uv.x * 10.0 + iTime * 0.1) * cos(uv.y * 5.0) * 0.5;
    mat2 rotationMatrix = mat2(cos(angle*0.9), -sin(angle*0.9), sin(angle*0.9), cos(angle*0.9));
    uv = rotationMatrix * uv;

    uv = waveC(uv);
    uv = waveD(uv);

    float t = sin(uv.x * 5.0 + iTime * 1.1) * 2.0 + uv.y * 4.0;
    vec3 base_color = palette(t);

    // Flow calculation
    float flow_dot = sin(uv.y * 12.0 + iTime * 1.3) * cos(uv.x * 7.0);
    float flow_per = sin(uv.x * 8.0 + iTime * 0.8) * cos(uv.y * 6.0);

    // Interaction mixing flows differently
    float texture_warp = pow(flow_dot * flow_per, 2.5);

    // Apply a secondary distortion based on flow direction
    float secondary_flow = flow_dot * 1.5;

    // Blend base color based on combined spatial flow interaction and secondary flow
    vec3 flow_color = mix(vec3(1.0, 0.5, 0.0), vec3(0.0, 1.0, 0.0), secondary_flow);

    vec3 adjusted_color = mix(base_color, flow_color, texture_warp * 1.2);

    fragColor = vec4(adjusted_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
