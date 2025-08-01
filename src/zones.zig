const rl = @import("raylib");

pub const Zone = struct {
    radius: f32,
    position: rl.Vector2,

    pub fn draw(this: Zone) void {
        rl.drawCircleLinesV(this.position, this.radius, rl.Color.sky_blue);
    }
};
