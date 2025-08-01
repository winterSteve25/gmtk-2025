const rl = @import("raylib");
const std = @import("std");

var ENTITY_COUNT: u32 = 0;

pub const CircularEntity = struct {
    collidable: CollidableEntity = .{
        .collide_rect = collide_rect,
        .collide_circle = collide_circle,
        .hp = undefined,
        .id = undefined,
    },

    position: rl.Vector2,
    radius: f32,

    pub fn new(position: rl.Vector2, radius: f32, hp: f32) CircularEntity {
        var entity: CircularEntity = .{
            .position = position,
            .radius = radius,
        };

        entity.collidable.hp = hp;
        entity.collidable.id = ENTITY_COUNT;

        ENTITY_COUNT += 1;
        return entity;
    }

    pub fn collide_rect(this: *const CollidableEntity, rect: rl.Rectangle) bool {
        const circle: *const CircularEntity = @ptrCast(this);
        return rl.checkCollisionCircleRec(circle.position, circle.radius, rect);
    }

    pub fn collide_circle(this: *const CollidableEntity, other: *const CircularEntity) bool {
        const circle: *const CircularEntity = @ptrCast(this);
        return rl.checkCollisionCircles(circle.position, circle.radius, other.position, other.radius);
    }
};

pub const CollidableEntity = struct {
    collide_rect: *const fn (this: *const CollidableEntity, rect: rl.Rectangle) bool,
    collide_circle: *const fn (this: *const CollidableEntity, circle: *const CircularEntity) bool,
    hp: f32,
    id: u32,
};

pub fn find_entity(id: u32, list: *std.ArrayList(*CollidableEntity)) ?*CollidableEntity {
    for (list.items) |entity| {
        if (entity.id == id) return entity;
    }

    return null;
}

pub const RectCollisionTracker = struct {
    collided_with: std.ArrayList(u32),
    on_collided_with: ?*const fn (entity: *CollidableEntity) void,

    pub fn new(allocator: std.mem.Allocator) RectCollisionTracker {
        return .{
            .collided_with = std.ArrayList(u32).init(allocator),
            .on_collided_with = null,
        };
    }

    pub fn update(this: *RectCollisionTracker, rect: rl.Rectangle, entities: *std.ArrayList(*CollidableEntity)) void {
        for (entities.items) |entity| {
            const prev_idx = std.mem.indexOfScalar(u32, this.collided_with.items, entity.id);
            const is_colliding = entity.collide_rect(entity, rect);

            if (prev_idx != null and is_colliding) {
                // already colliding still colliding
                continue;
            }

            if (prev_idx != null and !is_colliding) {
                // already colliding no longer colliding
                _ = this.collided_with.swapRemove(prev_idx orelse unreachable);
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
