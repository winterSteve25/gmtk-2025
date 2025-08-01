const rl = @import("raylib");
const std = @import("std");
const math = std.math;
const Zone = @import("zones.zig").Zone;
const ObjectPool = @import("utils.zig").ObjectPool;
const collision = @import("collision.zig");
const CircularEntity = collision.CircularEntity;
const Bullet = @import("bullet.zig").Bullet;

pub const Camera = struct {
    target: *const rl.Vector2,
    cam: rl.Camera2D,

    pub fn update(c: *Camera) void {
        c.cam.target = c.cam.target.lerp(c.target.*, 10 * rl.getFrameTime());
        c.cam.offset = .{
            .x = @as(f32, @floatFromInt(@divFloor(rl.getScreenWidth(), 2))),
            .y = @as(f32, @floatFromInt(@divFloor(rl.getScreenHeight(), 2))),
        };
    }
};

pub const Player = struct {
    hitbox: CircularEntity,
    camera: *const Camera,
    shoot_cooldown: f32 = max_shoot_cooldown,

    pub const player_speed: f32 = 180;
    pub const player_maxhp: f32 = 10;
    pub const max_shoot_cooldown: f32 = 0.5;

    pub fn draw(this: *const Player) void {
        rl.drawCircleV(this.hitbox.position, this.hitbox.radius, rl.Color.white);
    }

    pub fn update(this: *Player, bullets: *ObjectPool(Bullet)) void {
        update_movement(this);

        this.shoot_cooldown += rl.getFrameTime();
        if (this.shoot_cooldown >= max_shoot_cooldown and rl.isMouseButtonDown(.left)) {
            this.shoot_cooldown = 0;

            const bullet = bullets.get() catch unreachable;
            bullet.direction = rl.getScreenToWorld2D(rl.getMousePosition(), this.camera.cam)
                .subtract(this.hitbox.position)
                .normalize();

            bullet.set_position(this.hitbox.position
                .add(bullet.direction
                .multiply(.init(this.hitbox.radius * 2, this.hitbox.radius * 2))));
        }
    }

    fn update_movement(p: *Player) void {
        var movement: rl.Vector2 = .{ .x = 0, .y = 0 };

        if (rl.isKeyDown(.w)) {
            movement.y -= 1;
        }

        if (rl.isKeyDown(.s)) {
            movement.y += 1;
        }

        if (rl.isKeyDown(.a)) {
            movement.x -= 1;
        }

        if (rl.isKeyDown(.d)) {
            movement.x += 1;
        }

        const speed = player_speed * rl.getFrameTime();
        movement = movement.normalize()
            .multiply(.init(speed, speed));

        p.hitbox.position = p.hitbox.position.add(movement);
    }
};
