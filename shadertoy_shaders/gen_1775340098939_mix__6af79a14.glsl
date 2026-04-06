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

vec3 pal(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.04,0.32,0.62)+t));
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.8;
    float w1 = sin(uv.x * 15.0 + t * 1.5) * 0.3;
    float w2 = cos(uv.y * 10.0 + t * 1.2) * 0.3;
    float w3 = sin(length(uv) * 5.0 + t * 2.0) * 0.2;
    return vec2(w1, w2 + w3);
}

vec3 palette(float t) {
    float c1 = sin(t * 0.5) * 0.5 + 0.5;
    float c2 = cos(t * 0.7) * 0.5 + 0.5;
    float c3 = sin(t * 1.2) * 0.5 + 0.5;
    return vec3(c1, c2, c3);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // --- Dynamic Flow and Rotation (from B) ---
    float flow_speed = 2.5 + sin(iTime * 0.4) * 0.8;
    uv *= flow_speed;

    uv.x += iTime * 0.5;
    uv.y += iTime * 0.3;

    float angle1 = uv.x * 7.0 + iTime * 0.3;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv *= rotationMatrix;

    float angle2 = iTime * 1.1;
    uv = rotate(uv, angle2);

    // --- Wave Distortion (from B) ---
    uv = wave(uv);

    // --- Fractal Layering and Color Mixing (from A) ---
    // Use the specific fractal coordinate logic from A for structure
    float d = 1.0/(uv.y + 1.25);
    vec2 p = vec2(uv.x*d*3.5, d + iTime*2.2);

    float a = smoothstep(0.08,0.0,abs(fract(p.x)-0.5));
    float b = smoothstep(0.08,0.0,abs(fract(p.y)-0.5));
    float c = smoothstep(0.12,0.0,abs(fract(p.x+p.y)-0.5));

    float m = a + b + 0.7*c;

    // Use the complex pal function from A, modulated by the dynamic flow/wave context
    vec3 col = pal(0.05*iTime + 0.08*p.y + 0.05*p.x)*m;

    // Apply final subtle density scaling from A
    col *= 1.0/(1.0+0.12*d*d);

    // --- Final Intensity and Chromatic Shift (from B) ---
    float r = length(uv);
    float intensity = 0.5 + 0.5 * sin(r * 5.0 + iTime * 1.5);
    col *= intensity;

    float angle = atan(uv.y, uv.x);
    col.r = sin(angle * 6.0 + iTime * 1.0) * 0.5 + 0.5;
    col.g = cos(angle * 5.5 + iTime * 0.8) * 0.5 + 0.5;

    // --- Detail Layer (from B) ---
    float detail = sin(uv.x * 30.0 + iTime * 3.0) * 0.1;
    col += detail * 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
