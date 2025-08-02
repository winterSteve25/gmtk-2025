const rl = @import("raylib");
const collision = @import("collision.zig");
const std = @import("std");
const math = std.math;
const Zone = @import("zones.zig").Zone;
const enemies = @import("enemies/enemy.zig");
const Player = @import("player.zig").Player;

pub const Bullet = struct {
    rectangle: rl.Rectangle,
    tracker: collision.RectCollisionTracker,
    direction: rl.Vector2,
    life_time: f32,
    speed: f32 = max_speed,
    delete: bool = false,
    enabled: bool = false,

    const max_lifetime = 6;
    const max_speed = 300;

    pub fn new() Bullet {
        var tracker = collision.RectCollisionTracker.new(std.heap.page_allocator);
        tracker.on_collided_with = collided_with;

        return .{
            .rectangle = .{
                .x = 0,
                .y = 0,
                .width = 6,
                .height = 10,
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

    pub fn update(this: *Bullet, zones: *std.ArrayList(Zone), entities: *enemies.EnemySpawner, player: *Player) void {
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
        this.tracker.update(this.rectangle, entities, player);
    }

    pub fn draw(this: Bullet) void {
        rl.gl.rlPushMatrix();
        defer rl.gl.rlPopMatrix();

        rl.gl.rlTranslatef(this.rectangle.x, this.rectangle.y, 0);
        rl.gl.rlRotatef(math.radiansToDegrees(math.atan2(this.direction.y, this.direction.x)) + 90, 0, 0, 1);
        rl.gl.rlTranslatef(-this.rectangle.x, -this.rectangle.y, 0);

        rl.drawEllipse(@intFromFloat(this.rectangle.x), @intFromFloat(this.rectangle.y), this.rectangle.width, this.rectangle.height, .red);
    }

    fn collided_with(entity: *collision.Entity) void {
        entity.hit(1);
    }
};
