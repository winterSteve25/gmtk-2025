#version 330

in vec2 fragTexCoord;
in vec3 fragPosition;
in vec4 fragColor;
out vec4 finalColor;

uniform vec2 iResolution;
uniform float iTime;


// Shader Created by NULL_US3R
// https://www.shadertoy.com/view/MXjBRK

const float pi = 3.1415926535897;

float rand2(vec2 uv) {
    return fract(sin(dot(uv, vec2(13.337, 61.998))) * 48675.75647);
}

vec2 rotate(vec2 uv, float a) {
    return vec2(uv.y * cos(a) + uv.x * sin(a), uv.x * cos(a) - uv.y * sin(a));
}

vec2 rand2x2(vec2 uv) {
    return vec2(rand2(uv), rand2(-uv));
}

vec3 rand2x3(vec2 uv) {
    return vec3(rand2(uv), rand2(-uv), rand2(vec2(-uv.x - 5., uv.y + 1.)));
}

float perl(vec2 uv, float t) {
    vec2 id = floor(uv);
    vec2 loc = fract(uv);
    vec2 sloc = smoothstep(0., 1., loc);
    return mix(mix(dot(loc, rotate(vec2(1.), rand2(id) * (pi * 2. + t))), dot(loc - vec2(1., 0.), rotate(vec2(1.), rand2(id + vec2(1., 0.)) * (pi * 2. + t))), sloc.x), mix(dot(loc - vec2(0., 1.), rotate(vec2(1.), rand2(id + vec2(0., 1.)) * (pi * 2. + t))), dot(loc - vec2(1., 1.), rotate(vec2(1.), rand2(id + vec2(1., 1.)) * (pi * 2. + t))), sloc.x), sloc.y);
}

float fperl(vec2 uv, float t, float iter) {
    float o = 0., k = 0., p = 1.;
    for(float i = 0.; i < iter; i++) {
        o += perl(uv * p, t * p) / p;
        k += 1. / p;
        p *= 2.;
    }
    return o / k;
}

float vor(vec2 uv) {
    vec2 id = floor(uv);
    vec2 loc = fract(uv);
    float o = 100.;
    for(float x = -1.; x <= 1.; x++) {
        for(float y = -1.; y <= 1.; y++) {
            o = min(o, distance(sin(2.5 * pi * rand2x2(id + vec2(x, y))) * 0.8 + 0.2, loc - vec2(x, y)));
        }
    }
    return o;
}

vec3 vorid3(vec2 uv) {
    vec2 id = floor(uv);
    vec2 loc = fract(uv);
    float o = 1000.;
    vec3 ou = vec3(0);
    for(float x = -1.; x <= 1.; x++) {
        for(float y = -1.; y <= 1.; y++) {
            float d = distance(sin(2.5 * pi * rand2x2(id + vec2(x, y))) * 0.8 + 0.2, loc - vec2(x, y));
            if(o > d) {
                o = d;
                ou = rand2x3(id + vec2(x, y));
            }
        }
    }
    return ou;
}

vec3 star(vec2 uv) {
    float val = vor(uv * 3.);
    val = 0.01 / val;
    val = pow(val, 1.7);
    vec3 col = vec3(val) * (vorid3(uv * 3.));
    return col * fperl(uv / 2., 0., 2.);
}

vec3 fstar(vec2 uv, float iter, float t) {
    vec3 o = vec3(0);
    float p = 1.;
    for(float i = 0.; i < iter; i++) {
        o += star(rotate(uv + vec2(t, 0.) / p, i) * p);
        p *= 1.5;
    }
    return o;
}

float fnebula(vec2 uv, float iter, float t) {
    float o = 0., p = 1.;
    for(float i = 0.; i < iter; i++) {
        o += fperl(rotate(uv + vec2(t, 0.) / p, i) * p / 2., 0., 6.);
        p *= 1.5;
    }
    return o;
}

void main() {
    vec2 uv = (2. * fragPosition.xy - iResolution.xy) / min(iResolution.x, iResolution.y);

    vec3 col = fstar(uv, 7., iTime * 0.05);
    col *= 10.;
    col = pow(col, vec3(1));
    //col = col.r * vec3(1, 0.45, 0.4) + col.g * vec3(0.4, 0.4, 1) + col.b * vec3(1);
    col = mat3(1., .45, .4, .4, .4, 1., 1., 1., 1.) * col;
    col = vec3(0, 0, 0.05) + clamp(vec3(0, 0, 0.03) + col, vec3(0), vec3(1));

    float n = fnebula(uv, 7., iTime * 0.05);

    n = n * 0.4;
    n = clamp(n, 0., 1.);

    n = 1. - n;
    n = 0.5 / n;
    n = n - 0.5;

    vec3 vnb = n * vec3(0.7, 0.1, 1);
    vnb = clamp(vnb, vec3(0), vec3(1));

    finalColor = vec4((vnb + col) * 0.9, .7);
}