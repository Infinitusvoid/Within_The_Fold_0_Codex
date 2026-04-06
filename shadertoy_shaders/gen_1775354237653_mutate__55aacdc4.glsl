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
    vec2 base_uv = uv * 2.0 - 1.0;

    // Introduce heavy noise warp
    base_uv += noise(base_uv * 15.0 + iTime * 2.0) * 0.1;

    // Apply initial timing modulation
    base_uv *= 1.0 + sin(iTime * 0.7) * 0.25;

    // 1. Complex Motion Baseline (Rotation based on A structure)
    float angle1 = sin(iTime * 0.5) + base_uv.x * base_uv.y * 3.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    base_uv = rotationMatrix * base_uv;

    float angle2 = iTime * 0.8 + base_uv.x * 1.5;
    base_uv = rotate(base_uv, angle2);

    // 2. Distortion (Combined A/B distortion)
    vec2 distorted_uv = distort(base_uv, iTime * 1.5);

    // 3. Chain Wave Patterns (Using A's specific waves)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval (Combining A and B color derivation)
    vec3 col_base = colorFromUV(distorted_uv, iTime * 0.5);
    vec2 w = waveB(distorted_uv);
    vec3 wave_color = colorFromWave(w);

    // 5. Dynamic Variable Generation ? Depth Mapping
    float t = distorted_uv.x * 4.0 + distorted_uv.y * 5.0 + iTime * 0.5;
    vec3 col_palette = colorFromUV(distorted_uv, t); 

    // Apply dynamic flow based on the noise value
    float flow_factor = sin(distorted_uv.x * 20.0 + iTime * 2.5) * 0.1;
    float warp_factor = cos(distorted_uv.y * 10.0 + iTime * 1.2) * 0.1;

    // Mix base color and palette heavily
    vec3 final_color = mix(col_base, col_palette, flow_factor * 0.7);

    // 6. Advanced R/G/B Sculpting (Mixing A's complexity and B's depth interaction)
    float radius = length(distorted_uv);
    float smooth_dist = smoothstep(0.0, 0.3, radius * 2.5); 

    // Introduce a swirling effect based on radius
    final_color = mix(final_color, wave_color, smooth_dist * 0.5 + 0.5);

    // R Channel complexity (High frequency displacement using noise)
    final_color.r = sin(distorted_uv.x * 22.0 + iTime * 1.2) * 1.5 + noise(distorted_uv * 10.0 + iTime * 3.0).x * 0.5;

    // G Channel complexity (mixing wave interaction and radial distortion from B)
    final_color.g = cos(distorted_uv.y * 11.0 + iTime * 1.0) * 0.7 + sin(distorted_uv.x * 30.0 + iTime * 1.8) * 0.3;

    // B Channel definition (using contrast based on the distance from center)
    float contrast = 1.0 - smooth_dist; // Use inverse of smoothstep
    final_color.b = 0.5 + contrast * 0.5;

    // Final texture application mixing color depth and noise
    float texture_depth = noise(distorted_uv * 25.0 + iTime * 1.0).x;
    final_color = mix(final_color, vec3(texture_depth), 0.2);

    // Introduce final chromatic shift based on channel interactions
    final_color.b = 0.5 + 0.4 * abs(sin(abs(sin((final_color.g * final_color.r) * 120.0 + texture_depth * 60.0)) / (final_color.g * 3.0 + final_color.r * 2.5)) * 0.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
