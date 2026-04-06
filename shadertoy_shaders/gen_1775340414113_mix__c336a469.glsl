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

vec2 waveA(vec2 uv)
{
    return uv * 1.5 + vec2(sin(uv.x * 15.0 + iTime * 3.0) * 0.6, cos(uv.y * 8.0 + iTime * 4.0) * 0.3);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 2.5) * cos(uv.y * 7.0), cos(uv.y * 12.0 + iTime * 1.8) * sin(uv.x * 6.0));
}

float palette(float t)
{
    return 0.5 + 0.5 * sin(t * 5.0 + iTime * 0.5);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.5) * 0.5 + 0.5;
    float c = cos(t * 1.2) * 0.4 + 0.5;
    float shift = sin(uv.x * 10.0 + t * 0.3) * 0.15;
    float ripple = cos(uv.y * 10.0 - t * 0.5) * 0.1;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 4.5 + t * 0.5) * 0.5 + 0.5;
    float e = cos(uv.y * 9.0 - t * 0.6) * 0.4 + 0.5;
    float f = 0.1 + sin(uv.x * 3.0 + uv.y * 2.0 + t * 0.7) * 0.3;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 1.2;
    return vec2(
        sin(uv.x * 18.0 + t * 6.0),
        cos(uv.y * 11.0 + t * 5.0)
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
    // Enhanced color definition for plasma effect
    float r = 0.2 + 0.8 * sin(w.x * 30.0 + iTime * 0.8);
    float g = 0.4 + 0.6 * cos(w.y * 15.0 - iTime * 1.0);
    float b = 0.1 + 0.7 * sin(w.x * 12.0 + w.y * 6.0 + iTime * 0.3);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.4;
    // Increased coupling
    float scale = 1.0 + 0.08 * sin(t + uv.x * 15.0);
    float shift = 1.0 + 0.06 * cos(t + uv.y * 12.0);
    uv.x *= scale;
    uv.y *= shift;
    // More aggressive displacement feedback
    uv.x += sin(uv.y * 15.0 + t * 5.0) * 0.4;
    uv.y += cos(uv.x * 10.0 + t * 3.0) * 0.3;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 wave_B(vec2 uv)
{
    return uv + vec2(sin(uv.x * 5.0 + iTime * 0.5) * tan(uv.y * 2.0 + iTime * 0.8), cos(uv.y * 3.0 + iTime * 0.6) * sin(uv.x * 1.5 + iTime * 0.5));
}

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.34,0.68)+t)); }

vec3 pattern(vec2 uv, float t)
{
    float g = sin(uv.x * 12.0 + t * 0.5);
    float h = cos(uv.y * 8.0 + t * 0.6);
    float index = (uv.x * 3.0 + uv.y * 4.0) * 20.0 - iTime * 0.05 * t;
    float v = fract(sin(index * 2.5) * 30.0);
    return vec3(g, h, 0.5 + 0.5 * sin(v + t * 2.0));
}

vec2 curl(vec2 uv)
{
    float angle = iTime * 0.4 + sin(uv.x * 1.5) * cos(uv.y * 1.5) * 1.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    return rotationMatrix * uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Initial UV setup and flow field generation (Shader B flow)
    vec2 flow = uv * vec2(10.0, 5.0) - vec2(1.0, 0.5);
    flow.x += sin(uv.y * 10.0 + iTime * 1.5) * 0.5;
    flow.y += cos(uv.x * 5.0 + iTime * 0.8) * 0.3;

    // Apply curl to create swirling motion
    vec2 f = curl(flow);
    f = curl(f);
    f = curl(f);
    f = curl(f); 

    // Apply distortion
    f = distort(f * 1.2);

    // Calculate radial and angular features (Shader B structure)
    float r = length(f), a = atan(f.y, f.x);
    float petals = cos(6.0*a + 1.5*sin(iTime + 6.0*r));
    float d = r - (0.28 + 0.08*petals);
    float fill = smoothstep(0.02,0.0,d);
    float line = smoothstep(0.03,0.0,abs(d));

    // Wave calculations (Mixing A and B wave types)
    vec2 wA = waveA(f);
    vec2 wB = waveB(f);

    // Layering masks based on field geometry
    float z = 1.0/(length(f)+0.25) + iTime*1.5;
    float y1 = 0.22*sin(3.0*z + iTime);
    float y2 = 0.22*sin(3.0*z + iTime + 3.14159);
    float l1 = smoothstep(0.05,0.0,abs(f.y-y1));
    float l2 = smoothstep(0.05,0.0,abs(f.y-y2));

    // Combine masking logic
    float mask = (0.25*fill + 1.8*line) * l1 + (0.5*l2);

    // Apply base coloring using Shader A's palette based on modulated 'z'
    vec3 col = pal(0.1*z) * mask;
    col += pal(0.1*z+0.5) * (1.0 - l1) * l2;

    // Apply pattern colors (from Shader B)
    vec3 col1 = pattern(f * 1.8, iTime * 3.0);
    vec3 col2 = pattern(f * 0.6 + iTime * 1.5, iTime * 2.5);

    vec3 finalCol = col1 * 0.5 + col2 * 0.5;

    // Introduce secondary color shifts based on the field influence 'd' and wave colors
    finalCol.r = colorFromWave(f * 2.0).r * 0.6 + 0.4 * d;
    finalCol.g = colorFromWave(f * 1.5).g * 0.7 + 0.3 * d;
    finalCol.b = colorFromWave(f * 4.0).b * 0.8;

    // Modulate colors using the field influence 'd' and time
    finalCol *= (0.5 + 0.5 * sin(d * 2.5 + iTime * 1.0));

    // Apply final time and frame influence
    finalCol.r += sin(iTime * 5.0) * 0.1;
    finalCol.g += cos(iTime * 4.5) * 0.15;
    finalCol.b += sin(iFrame * 2.0) * 0.1;

    fragColor = vec4(finalCol, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
