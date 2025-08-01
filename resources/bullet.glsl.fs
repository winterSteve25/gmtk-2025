#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec3 fragPosition;
in vec4 fragColor;

struct Zone {
    float radius;
    vec2 position;
};

#define MAX_ZONES 8
uniform Zone zones[MAX_ZONES];
uniform int numberOfZones;

// Output fragment color
out vec4 finalColor;

void main()
{
    for (int i = 0; i < numberOfZones; i++) {
        vec2 delta = fragPosition.xy - zones[i].position;
        // if in a zone, display its color
        if (length(delta) <= zones[i].radius) {
            finalColor = fragColor;
            return;
        }
    }

    // invisible
    finalColor = vec4(0, 0, 0, 0);
}