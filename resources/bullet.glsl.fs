#version 330

in vec3 fragPosition;
in vec4 fragColor;
out vec4 finalColor;

struct Zone {
    float radius;
    vec2 position;
};

#define MAX_ZONES 8
uniform Zone zones[MAX_ZONES];
uniform int numberOfZones;

void main()
{
    for (int i = 0; i < numberOfZones; i++) {
        vec2 delta = fragPosition.xy - zones[i].position;
        // if in a zone, display its color
        if (abs(length(delta) - zones[i].radius - 1) <= 6) {
            finalColor = vec4(0, 0, 0, 0);
            return;
        }
    }

    // invisible
    finalColor = fragColor;
}