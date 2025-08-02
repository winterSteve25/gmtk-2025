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

    pub fn update(this: *Camera) void {
        this.cam.target = this.cam.target.lerp(this.target.*, 10 * rl.getFrameTime());
    }
};

pub const Player = struct {
    hitbox: CircularEntity,
    camera: *const Camera,

    shoot_cooldown: f32 = max_shoot_cooldown,
    show_hp: bool = false,
    show_hp_duration: f32 = 0,
    show_prev_hp: f32 = 0,
    show_dest_hp: f32 = 0,

    pub const player_speed: f32 = 180;
    pub const player_maxhp: f32 = 10;
    pub const max_shoot_cooldown: f32 = 0.2;
    pub const max_hp_display_duration = 2;

    pub fn draw(this: *Player) void {
        rl.drawCircleV(this.hitbox.position, this.hitbox.radius, rl.Color.white);

        if (this.show_hp) {
            const x: i32 = @intFromFloat(this.hitbox.position.x - this.hitbox.radius * 3);
            const y: i32 = @intFromFloat(this.hitbox.position.y - this.hitbox.radius * 1.5);
            const clr: rl.Color = .fromHSV(356, 0.75, 0.85);
            const clr2: rl.Color = .fromHSV(339, 0.75, 0.85);
            const w: i32 = @intFromFloat(this.hitbox.radius * 0.8);
            const h: i32 = @intFromFloat(this.hitbox.radius * 3);
            const t = this.show_hp_duration / max_hp_display_duration;
            const hDeducted: i32 = @intFromFloat(@as(f32, @floatFromInt(h)) * (math.lerp(this.show_prev_hp, this.show_dest_hp, t)) / player_maxhp);

            rl.drawRectangle(x, y, w, h, .gray);
            rl.drawRectangleGradientV(x, y + (h - hDeducted), w, hDeducted, clr2, clr);

            this.show_hp_duration += rl.getFrameTime();
            if (this.show_hp_duration >= max_hp_display_duration) {
                this.show_hp_duration = 0;
                this.show_hp = false;
            }
        }
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

    pub fn on_hurt(this: *collision.Entity, preHp: f32, nowHp: f32) void {
        const as_player: *Player = @ptrCast(this);

        if (as_player.show_hp) {
            as_player.show_dest_hp = nowHp;
            as_player.show_hp_duration = 0;
        } else {
            as_player.show_hp = true;
            as_player.show_prev_hp = preHp;
            as_player.show_dest_hp = nowHp;
            as_player.show_hp_duration = 0;
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
