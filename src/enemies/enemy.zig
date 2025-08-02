const collision = @import("../collision.zig");
const Player = @import("../player.zig").Player;
const std = @import("std");

pub const Basic = @import("basic.zig");

pub const EnemyData = union(enum) {
    basic: struct {
        atk_cd: f32,
    },
};

pub const Enemy = struct {
    hitbox: collision.CircularEntity,
    update: *const fn (this: *Enemy, player: *Player) void,
    draw: *const fn (this: *Enemy) void,
    data: EnemyData,
};

pub const EnemySpawner = struct {
    enemies: std.ArrayList(Enemy),

    pub fn init(allocator: std.mem.Allocator) EnemySpawner {
        return .{
            .enemies = std.ArrayList(Enemy).init(allocator),
        };
    }

    pub fn spawn(this: *EnemySpawner, etype: Enemy) *Enemy {
        const idx = this.enemies.items.len;
        this.enemies.append(etype) catch unreachable;
        return &this.enemies.items[idx];
    }

    // pub fn despawn(this: *EnemySpawner, e: *Enemy) void {

    // }

    pub fn draw(this: *EnemySpawner) void {
        for (this.enemies.items) |enemy| {
            enemy.draw(enemy);
        }
    }

    pub fn update(this: *EnemySpawner, player: *Player) void {
        for (this.enemies.items) |enemy| {
            enemy.update(enemy, player);
        }
    }
};
