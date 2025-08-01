const rl = @import("raylib");
const std = @import("std");
const math = std.math;
const Zone = @import("zones.zig").Zone;
const ObjectPool = @import("utils.zig").ObjectPool;

pub const Bullet = struct {
    position: rl.Vector2,
    direction: rl.Vector2,
    life_time: f32,
    speed: f32 = 150,
    delete: bool = false,
    enabled: bool = false,

    const max_lifetime = 2;

    pub fn new() Bullet {
        return .{
            .position = .init(0, 0),
            .direction = .init(0, 0),
            .life_time = 0,
        };
    }

    pub fn enable(this: *Bullet) void {
        this.enabled = true;
    }

    pub fn disable(this: *Bullet) void {
        this.enabled = false;
    }

    pub fn update(this: *Bullet, zones: *std.ArrayList(Zone)) void {
        const speed = this.speed * rl.getFrameTime();
        const movement = this.direction.multiply(.init(speed, speed));
        this.position = this.position.add(movement);
        this.life_time += rl.getFrameTime();

        if (this.life_time >= max_lifetime) {
            this.delete = true;
            return;
        }

        for (zones.items) |zone| {
            const relPos = this.position.subtract(zone.position);
            if (math.approxEqAbs(f32, relPos.length() - zone.radius, 0, 0.75)) {
                const angle: f32 = math.atan2(relPos.y, relPos.x) + math.pi;
                this.position = .init(math.cos(angle) * (zone.radius - 0.8), math.sin(angle) * (zone.radius - 0.8));
            }
        }
    }

    pub fn draw(this: Bullet) void {
        rl.drawCircleV(this.position, 10, .green);
    }
};

pub const Camera = struct {
    target: *const rl.Vector2,
    cam: rl.Camera2D,

    pub fn update(c: *Camera) void {
        c.cam.target = c.cam.target.lerp(c.target.*, 0.01);
        c.cam.offset = .{
            .x = @as(f32, @floatFromInt(@divFloor(rl.getScreenWidth(), 2))),
            .y = @as(f32, @floatFromInt(@divFloor(rl.getScreenHeight(), 2))),
        };
    }
};

pub const Player = struct {
    position: rl.Vector2 = .{ .x = 0, .y = 0 },
    camera: *const Camera,

    const player_speed: f32 = 180;

    pub fn draw(p: *const Player) void {
        rl.drawCircleV(p.position, 10, rl.Color.white);
    }

    pub fn update(p: *Player, bullets: *ObjectPool(Bullet)) void {
        update_movement(p);

        if (rl.isMouseButtonDown(.left)) {
            const bullet = bullets.get() catch unreachable;
            bullet.position = p.position;
            bullet.direction = rl.getScreenToWorld2D(rl.getMousePosition(), p.camera.cam)
                .subtract(p.position)
                .normalize();
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

        p.position = p.position.add(movement);
    }
};
