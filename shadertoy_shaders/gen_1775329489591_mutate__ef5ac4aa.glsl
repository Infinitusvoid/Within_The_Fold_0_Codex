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

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec2 wave(vec2 uv)
{
    float t = iTime * 0.8;
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.5 + 0.5 * sin(w.x * 8.0 + iTime * 0.3);
    float g = 0.5 + 0.5 * cos(w.y * 6.0 - iTime * 0.15);
    float b = 0.1 + 0.4 * sin(w.x * 3.0 + w.y * 3.0 + iTime * 0.5);
    return vec3(r, g, b);
}

vec2 applyTransform(vec2 uv)
{
    // Combined coordinate stretch
    float t = iTime * 0.6 + uv.x * 1.5;
    float scale_x = 1.0 + 0.1 * sin(t * 6.2 + uv.x * 30.0);
    float scale_y = 1.0 + 0.12 * cos(t * 5.8 + uv.y * 25.0);
    uv.x *= scale_x;
    uv.y *= scale_y;
    uv.x += iTime * 0.15;
    uv.y += iTime * 0.1;
    return uv;
}

vec2 intersectPlane(vec2 uv, float t)
{
    // Hybrid distortion/flow logic
    float t1 = iTime * 0.5;
    vec2 temp_uv = uv;
    temp_uv.x += sin(uv.y * 7.0 + t1 * 2.5) * 0.12; // Distorts x-coord
    temp_uv.y += cos(uv.x * 4.5 + t1 * 1.5) * 0.11; // Distorts y-coord

    // Incorporate noise
    temp_uv *= noise(temp_uv * 1.8);

    // Offset applied based on relative position complexity
    temp_uv.x += uv.x * 0.8 + t1;
    temp_uv.y += uv.y * 0.5 + t1 * 0.5;

    return temp_uv;
}

mat2 rotateMatrix(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Combined Deformation chain
    uv = applyTransform(uv);
    uv = intersectPlane(uv, 0.5);

    // Apply Rotation System Base Flow
    float flow_time = iTime * 1.5 + uv.x * 20.0;
    float motion_y = iTime * 0.9 + uv.y * 25.0;

    // Geometric Rotation setup (Introduce higher dependence factors)
    float rotation_X = flow_time * 0.5 + uv.x * 40.0;
    float rotation_Y = motion_y * 0.8 + uv.y * 35.0;

    vec2 uv_rot = vec2( uv.x, uv.y );

    // Vector calculation input (W input changes depending on combined movement)
    vec2 wave_input = vec2( rotation_X * 3.0, rotation_Y * 2.5 ); 
    vec2 w = wave(uv_rot * 1.2);

    // Positional/Interaction Setup (Modulating frequencies aggressively)
    float freq_x = uv_rot.x * 15.0 + flow_time * 0.5;
    float freq_y = uv_rot.y * 10.0 + motion_y * 0.6;

    float ripple = sin(freq_x * 25.0) * cos(freq_y * 4.0) * 0.3;

    // Base Color Structure using refined w inputs
    vec3 color = colorFromWave(w);

    // Intensity Modulation using complex phase interactions
    float intensity_phase = sin(freq_x * 0.5 + motion_y * 0.7) * cos(uv_rot.x * 10.0) * 1.5;
    float intensity = smoothstep(0.1, 0.8, color.x * 0.7 + iTime * 0.4 + intensity_phase);

    // Dynamic G multiplication using reflected energy flows
    color.g = (color.y * 0.8 + intensity_phase * 0.5) / (1.0 + uv_rot.y * 5.0 + 0.1);

    // Dynamic B modulation based on flow variance
    color.b = 0.6 + (fract(freq_x * 2.0 + uv_rot.y)) * 0.4 + color.r * 0.4;

    // Final Texture Feedback Loop reflecting displacement gradients
    float spiral_energy = sin(uv_rot.x * 7.0 + flow_time + ripple * uv_rot.y * 5.0);

    color.r = mix(color.r, spiral_energy, pow(flow_time, 0.5));
    color.g = color.g * pow(spiral_energy, 0.8);
    color.b = iTime * 0.5 + mix(color.b, sin(uv_rot.y * 5.0), flow_time * 1.2);

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
