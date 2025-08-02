const rl = @import("raylib");
const std = @import("std");
const enemies = @import("enemies/enemy.zig");
const Player = @import("player.zig").Player;

var ENTITY_COUNT: u32 = 0;

pub const OnHurtCallback = ?*const fn (this: *Entity, preHp: f32, nowHp: f32) void;
pub const CircularEntity = struct {
    entity: Entity = .{
        .collide_rect = collide_rect,
        .collide_circle = collide_circle,
        .hp = undefined,
        .id = undefined,
    },

    position: rl.Vector2,
    radius: f32,

    pub fn new(position: rl.Vector2, radius: f32, hp: f32, on_hurt: OnHurtCallback) CircularEntity {
        var entity: CircularEntity = .{
            .position = position,
            .radius = radius,
        };

        entity.entity.hp = hp;
        entity.entity.id = ENTITY_COUNT;
        entity.entity.on_hurt = on_hurt;

        ENTITY_COUNT += 1;
        return entity;
    }

    pub fn collide_rect(this: *const Entity, rect: rl.Rectangle) bool {
        const circle: *const CircularEntity = @ptrCast(this);
        return rl.checkCollisionCircleRec(circle.position, circle.radius, rect);
    }

    pub fn collide_circle(this: *const Entity, other: *const CircularEntity) bool {
        const circle: *const CircularEntity = @ptrCast(this);
        return rl.checkCollisionCircles(circle.position, circle.radius, other.position, other.radius);
    }
};

pub const Entity = struct {
    collide_rect: *const fn (this: *const Entity, rect: rl.Rectangle) bool,
    collide_circle: *const fn (this: *const Entity, circle: *const CircularEntity) bool,
    hp: f32,
    id: u32,
    on_hurt: OnHurtCallback = null,

    pub fn hit(this: *Entity, damage: f32) void {
        this.hp -= damage;
        if (this.on_hurt != null) {
            this.on_hurt.?(this, this.hp + damage, this.hp);
        }
    }
};

pub fn find_entity(id: u32, list: *std.ArrayList(*Entity)) ?*Entity {
    for (list.items) |entity| {
        if (entity.id == id) return entity;
    }

    return null;
}

pub const RectCollisionTracker = struct {
    collided_with: std.ArrayList(u32),
    on_collided_with: ?*const fn (entity: *Entity) void,

    pub fn new(allocator: std.mem.Allocator) RectCollisionTracker {
        return .{
            .collided_with = std.ArrayList(u32).init(allocator),
            .on_collided_with = null,
        };
    }

    pub fn update(this: *RectCollisionTracker, rect: rl.Rectangle, es: *enemies.EnemySpawner, player: *Player) void {
        var entity: *Entity = &player.hitbox.entity;
        var prev_idx = std.mem.indexOfScalar(u32, this.collided_with.items, entity.id);
        var is_colliding = entity.collide_rect(entity, rect);

        if (prev_idx != null and !is_colliding) {
            // already colliding no longer colliding
            _ = this.collided_with.swapRemove(prev_idx orelse unreachable);
        } else if (prev_idx == null and is_colliding) {
            // started colliding
            this.collided_with.append(entity.id) catch unreachable;
            if (this.on_collided_with != null) {
                this.on_collided_with.?(entity);
            }
        }

        for (es.enemies.items) |*enemy| {
            entity = &enemy.hitbox.entity;
            prev_idx = std.mem.indexOfScalar(u32, this.collided_with.items, entity.id);
            is_colliding = entity.collide_rect(entity, rect);

            if (prev_idx != null and is_colliding) {
                // already colliding still colliding
                continue;
            }

            if (prev_idx != null and !is_colliding) {
                // already colliding no longer colliding
                _ = this.collided_with.swapRemove(prev_idx orelse unreachable);
                continue;
            }

            if (is_colliding) {
                // started colliding
                this.collided_with.append(entity.id) catch unreachable;
                if (this.on_collided_with != null) {
                    this.on_collided_with.?(entity);
                }
            }
        }
    }
};
