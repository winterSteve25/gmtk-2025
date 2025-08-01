const rl = @import("raylib");
const std = @import("std");
const CircularEntity = @import("collision.zig").CircularEntity;

pub const Zone = struct {
    hitbox: CircularEntity,

    // used to set shader value
    radius_shader_loc: i32 = undefined,
    position_shader_loc: i32 = undefined,

    pub fn draw(this: Zone) void {
        rl.drawCircleLinesV(this.hitbox.position, this.hitbox.radius, rl.Color.sky_blue);
    }
};

pub const ZonesArray = struct {
    arr: std.ArrayList(Zone),
    shader: *rl.Shader,
    number_shader_loc: i32,

    pub fn init(allocator: std.mem.Allocator, shader: *rl.Shader) ZonesArray {
        return .{
            .arr = std.ArrayList(Zone).init(allocator),
            .shader = shader,
            .number_shader_loc = rl.getShaderLocation(shader.*, "numberOfZones"),
        };
    }

    pub fn deinit(this: *ZonesArray) void {
        this.arr.deinit();
    }

    pub fn append(this: *ZonesArray, position: rl.Vector2, radius: f32) !void {
        var z = Zone{ .hitbox = .{
            .position = position,
            .radius = radius,
        } };

        z.radius_shader_loc = rl.getShaderLocation(this.shader.*, rl.textFormat("zones[%i].radius", .{this.arr.items.len}));
        z.position_shader_loc = rl.getShaderLocation(this.shader.*, rl.textFormat("zones[%i].position", .{this.arr.items.len}));

        try this.arr.append(z);
        this.update_shader();
    }

    fn update_shader(this: *ZonesArray) void {
        for (this.arr.items) |zone| {
            rl.setShaderValue(this.shader.*, zone.radius_shader_loc, &zone.hitbox.radius, .float);
            const position = [_]f32{ zone.hitbox.position.x, zone.hitbox.position.y };
            rl.setShaderValue(this.shader.*, zone.position_shader_loc, &position, .vec2);
        }

        rl.setShaderValue(this.shader.*, this.number_shader_loc, &this.arr.items.len, .int);
    }
};
