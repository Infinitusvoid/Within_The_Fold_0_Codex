#version 330 core
in vec2 TexCoord;
in vec3 WorldPos;
in vec3 LocalPos;

out vec4 FragColor;

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

uniform float time;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec3 iResolution;
uniform vec3 iPlayerPos;
uniform vec3 uCamPos;
uniform vec3 uCubePos;
uniform vec3 uColor;
uniform mat4 model;

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float mapScene(vec3 p)
{
    vec3 cubeCenter = model[3].xyz + vec3(0.5);
    vec3 q = p - cubeCenter;

    vec3 tiled = fract(q * 3.0 + 1.5) - 0.5;
    float node = sdSphere(tiled, 0.12 + 0.02 * sin(iTime * 2.0 + dot(uCubePos, vec3(7.0, 5.0, 3.0))));
    float spine = sdBox(q, vec3(0.42, 0.04, 0.04));
    spine = min(spine, sdBox(q.zxy, vec3(0.42, 0.04, 0.04)));
    spine = min(spine, sdBox(q.yzx, vec3(0.42, 0.04, 0.04)));

    return min(node, spine);
}

vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        mapScene(p + e.xyy) - mapScene(p - e.xyy),
        mapScene(p + e.yxy) - mapScene(p - e.yxy),
        mapScene(p + e.yyx) - mapScene(p - e.yyx)
    ));
}

void main()
{
    vec3 ro = uCamPos;
    vec3 rd = normalize(WorldPos - ro);

    float t = 0.0;
    bool hit = false;
    for (int i = 0; i < 88; ++i)
    {
        vec3 p = ro + rd * t;
        float d = mapScene(p);
        if (d < 0.001)
        {
            hit = true;
            break;
        }

        t += d * 0.92;
        if (t > 10.0)
        {
            break;
        }
    }

    vec3 color = vec3(0.005, 0.01, 0.02);

    if (hit)
    {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        vec3 lattice = p - (uCubePos + 0.5);

        vec3 tex0 = texture(iChannel0, lattice.xy * 1.6 + iTime * 0.04).rgb;
        vec3 tex1 = texture(iChannel1, lattice.zy * 1.4 - iTime * 0.03).rgb;
        vec3 tex2 = texture(iChannel2, lattice.xz * 1.2 + iTimeDelta * 6.0).rgb;
        vec3 tex3 = texture(iChannel3, TexCoord + float(iFrame) * 0.0008).rgb;

        float diffuse = max(dot(n, normalize(iPlayerPos - p)), 0.0);
        float grid = 0.5 + 0.5 * sin((lattice.x + lattice.y + lattice.z) * 18.0 + iTime * 3.0);
        vec3 tint = mix(tex0 + tex1, tex2 + tex3, grid) * 0.5;
        tint *= mix(vec3(0.2, 0.7, 0.9), max(uColor, vec3(0.18)), 0.5);

        color = tint * (0.15 + diffuse);
        color += pow(grid, 8.0) * vec3(0.4, 0.8, 1.0);
    }
    else
    {
        vec2 uv = gl_FragCoord.xy / max(iResolution.xy, vec2(1.0));
        float horizon = smoothstep(0.0, 1.0, 1.0 - uv.y);
        color += vec3(0.02, 0.04, 0.08) * horizon;
    }

    FragColor = vec4(sqrt(max(color, vec3(0.0))), 1.0);
}
