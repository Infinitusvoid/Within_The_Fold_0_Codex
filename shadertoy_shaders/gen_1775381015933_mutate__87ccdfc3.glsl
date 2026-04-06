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

mat2 rot(float a){ float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }
vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.0,0.33,0.65)+t)); }
float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
float circle(vec2 p, vec2 c, float r)
{
    return length(p - c) - r;
}
vec2 waveA(vec2 uv)
{
    return uv + vec2(sin(uv.x * 8.0 + iTime * 1.0) * 0.4, cos(uv.y * 7.0 + iTime * 0.5) * 0.3);
}
vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 1.5) * cos(uv.y * 4.0), cos(uv.y * 8.0 + iTime * 0.8) * sin(uv.x * 3.0));
}
float palette(float t)
{
    return 0.5 + 0.5 * sin(t * 3.0);
}
vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.1) * 0.4 + 0.5;
    float c = cos(t * 1.3) * 0.3 + 0.6;
    float shift = sin(uv.x * 9.0 + t * 0.3) * 0.15;
    float ripple = cos(uv.y * 14.0 - t * 0.6) * 0.1;
    return uv * vec2(s, c) + vec2(shift, ripple);
}
vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.5 + t * 0.4) * 0.5 + 0.5;
    float e = cos(uv.y * 9.5 - t * 0.5) * 0.4 + 0.5;
    float f = 0.2 + sin(uv.x * 4.5 + uv.y * 3.5 + t * 0.6) * 0.3;
    return vec3(d, e, f);
}
vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}
vec2 wave(vec2 uv) {
    float t = iTime * 0.7;
    return vec2(
        sin(uv.x * 12.0 + t * 4.0),
        cos(uv.y * 8.0 + t * 2.5)
    );
}
vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}
vec3 colorFromWave(vec2 w)
{
    float r = 0.1 + 0.6 * sin(w.x * 25.0 + iTime * 0.5);
    float g = 0.4 + 0.5 * cos(w.y * 10.0 - iTime * 0.7);
    float b = 0.3 + 0.3 * sin(w.x * 8.0 + w.y * 4.0 + iTime * 0.2);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Initial UV manipulation and noise injection
    vec2 base_uv = uv * 3.0 - 1.0;

    // Introduce subtle, high-frequency noise shift
    base_uv += noise(base_uv * 10.0 + iTime * 3.0) * 0.05;

    // Apply time-based flow and scaling
    base_uv *= 1.1 + sin(iTime * 0.5) * 0.1;

    // 1. Complex Motion Baseline (Twisted rotation)
    float angle1 = iTime * 0.6 + base_uv.x * base_uv.y * 4.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    base_uv = rotationMatrix * base_uv;

    float angle2 = iTime * 1.2 + base_uv.x * 1.8;
    base_uv = rotate(base_uv, angle2);

    // 2. Distortion (More aggressive warping)
    vec2 distorted_uv = distort(base_uv, iTime * 2.0);

    // 3. Chain Wave Patterns (Interacting waves)
    vec2 w1 = waveA(distorted_uv * 1.5);
    vec2 w2 = waveB(distorted_uv * 0.8);

    // 4. Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime * 0.8);
    vec3 wave_color = colorFromWave(w1);

    // 5. Dynamic Variable Generation (Depth based on flow)
    float flow = sin(distorted_uv.x * 25.0 + iTime * 3.0) * 0.3;
    float depth = cos(distorted_uv.y * 15.0 + iTime * 1.5) * 0.5;

    // Mix base color and wave color based on depth interaction
    vec3 combined_color = mix(col_base, wave_color, depth * 0.8);

    // 6. Advanced Sculpting (Fractal detail injection)
    float radius = length(distorted_uv);
    float smooth_dist = smoothstep(0.0, 0.35, radius * 1.8); 

    // Introduce a secondary noise layer for texture shifting
    float texture_shift = noise(distorted_uv * 30.0 + iTime * 5.0).x * 0.2;

    combined_color = mix(combined_color, vec3(1.0, 0.3, 0.1), smooth_dist);

    // R Channel complexity (High frequency displacement)
    combined_color.r = sin(distorted_uv.x * 35.0 + iTime * 1.5) * 1.2 + texture_shift * 0.5;

    // G Channel complexity (Vertical warp based on time)
    combined_color.g = cos(distorted_uv.y * 10.0 + iTime * 1.0) * 0.6 + sin(distorted_uv.x * 50.0 + iTime * 2.0) * 0.3;

    // B Channel definition (Using depth for contrast)
    float contrast = 1.0 - smooth_dist; 
    combined_color.b = 0.5 + contrast * 0.4;

    // Final chromatic shift based on the derived channel interactions
    float final_mix = abs(combined_color.r - combined_color.g);
    combined_color.b = 0.5 + final_mix * 0.5;

    // Final output color based on noise depth
    vec3 final_color = mix(combined_color, vec3(0.0, 0.0, 0.0), noise(distorted_uv * 40.0 + iTime * 10.0).r * 0.3);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
