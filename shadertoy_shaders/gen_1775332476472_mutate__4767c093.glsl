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
    return vec2(sin(uv.x * 8.0 + iTime * 0.4), cos(uv.y * 6.0 - iTime * 0.3));
}

vec2 waveD(vec2 uv)
{
    return vec2(sin(uv.y * 9.0 + iTime * 0.5), cos(uv.x * 10.0 - iTime * 0.2));
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.7 * sin(t * 2.0 - iTime * 0.3), 0.3 + 0.5 * cos(t * 1.5 + iTime * 0.1), 0.8 - 0.3 * sin(t * 0.8 + iTime * 0.05));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = uv * vec2(5.0, 2.0) - vec2(0.5, 0.5);

    // UV space dynamic perturbation defining an arbitrary field angle
    float angle = iTime * 2.0 + sin(uv.x * 12.0 + iTime * 0.2) * cos(uv.y * 5.0) * 0.5;
    mat2 rotationMatrix = mat2(cos(angle*0.6), -sin(angle*0.6), sin(angle*0.6), cos(angle*0.6));
    uv = rotationMatrix * uv;

    uv = waveC(uv);
    uv = waveD(uv);

    // New variable t based on combined complex wave states
    float t = sin(uv.x * 4.0 + iTime * 1.8) + cos(uv.y * 4.5 + iTime * 1.3);
    vec3 base_color = palette(t);

    // Flow calculation based on product of wave components
    float flow_dot = sin(uv.y * 15.0 + iTime * 1.1) * cos(uv.x * 7.0);
    float flow_per = sin(uv.x * 10.0 + iTime * 0.9) * cos(uv.y * 6.0);

    // Interaction mixing flows based on a harmonic sum
    float texture_warp = pow(flow_dot * flow_per * 0.5, 2.0);

    // Introduce a secondary color modulation based on the flow magnitude and time
    vec3 flow_tint = vec3(flow_dot * 0.7 + flow_per * 0.3, 1.0 - flow_dot, flow_per);

    // Blend base color and flow tint dynamically
    vec3 final_color = mix(base_color, flow_tint, texture_warp * 2.0);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
