#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

struct Zones {
    float radius;
    vec3 position;
}

#define MAX_ZONES 8
uniform Zone zones[MAX_ZONES];

// Output fragment color
out vec4 finalColor;

void main()
{
    finalColor = fragColor;
}