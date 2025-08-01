const rl = @import("raylib");
const std = @import("std");
const math = std.math;
const Zone = @import("zones.zig").Zone;
const ObjectPool = @import("utils.zig").ObjectPool;
const collision = @import("collision.zig");
const CircularEntity = collision.CircularEntity;

pub const Bullet = struct {
    rectangle: rl.Rectangle,
    tracker: collision.RectCollisionTracker,
    direction: rl.Vector2,
    life_time: f32,
    speed: f32 = max_speed,
    delete: bool = false,
    enabled: bool = false,

    const max_lifetime = 6;
    const max_speed = 150;

    pub fn new() Bullet {
        var tracker = collision.RectCollisionTracker.new(std.heap.page_allocator);
        tracker.on_collided_with = collided_with;

        return .{
            .rectangle = .{
                .x = 0,
                .y = 0,
                .width = 3,
                .height = 8,
            },
            .tracker = tracker,
            .direction = .init(0, 0),
            .life_time = 0,
        };
    }

    pub fn enable(this: *Bullet) void {
        this.life_time = 0;
        this.delete = false;
        this.enabled = true;
    }

    pub fn disable(this: *Bullet) void {
        this.enabled = false;
    }

    pub fn set_position(this: *Bullet, position: rl.Vector2) void {
        this.rectangle.x = position.x;
        this.rectangle.y = position.y;
    }

    pub fn get_position(this: *const Bullet) rl.Vector2 {
        return .{
            .x = this.rectangle.x,
            .y = this.rectangle.y,
        };
    }

    pub fn update(this: *Bullet, zones: *std.ArrayList(Zone), collidables: *std.ArrayList(*collision.CollidableEntity)) void {
        const speed = this.speed * rl.getFrameTime();
        const movement = this.direction.multiply(.init(speed, speed));
        this.set_position(this.get_position().add(movement));
        this.life_time += rl.getFrameTime();

        if (this.life_time >= max_lifetime) {
            this.delete = true;
            return;
        }

        // loop around
        for (zones.items) |zone| {
            const relPos = this.get_position().subtract(zone.hitbox.position);
            if (math.approxEqAbs(f32, relPos.length() - zone.hitbox.radius, 0, 0.75)) {
                const angle: f32 = math.atan2(relPos.y, relPos.x) + math.pi;
                this.rectangle.x = math.cos(angle) * (zone.hitbox.radius - 0.8);
                this.rectangle.y = math.sin(angle) * (zone.hitbox.radius - 0.8);
            }
        }

        // collision
        this.tracker.update(this.rectangle, collidables);
    }

    pub fn draw(this: Bullet) void {
        rl.gl.rlPushMatrix();
        defer rl.gl.rlPopMatrix();

        rl.gl.rlTranslatef(this.rectangle.x, this.rectangle.y, 0);
        rl.gl.rlRotatef(math.radiansToDegrees(math.atan2(this.direction.y, this.direction.x)) + 90, 0, 0, 1);
        rl.gl.rlTranslatef(-this.rectangle.x, -this.rectangle.y, 0);

        rl.drawEllipse(@intFromFloat(this.rectangle.x), @intFromFloat(this.rectangle.y), this.rectangle.width, this.rectangle.height, .red);
    }

    fn collided_with(entity: *collision.CollidableEntity) void {
        entity.hp -= 1;
    }
};

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
