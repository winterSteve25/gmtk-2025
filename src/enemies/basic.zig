const rl = @import("raylib");
const Enemy = @import("enemy.zig").Enemy;
const EnemyData = @import("enemy.zig").EnemyData;
const Player = @import("../player.zig").Player;
const collision = @import("../collision.zig");
const std = @import("std");

var BasicSprite: rl.Texture2D = undefined;
const cd: f32 = 1;

fn update(this: *Enemy, player: *Player) void {
    const dir = player.hitbox.position.subtract(this.hitbox.position).normalize();
    const speed = 100 * rl.getFrameTime();
    this.hitbox.position = this.hitbox.position.add(dir.multiply(.init(speed, speed)));
    this.data.basic.atk_cd += rl.getFrameTime();

    if (this.hitbox.entity.collide_circle(&this.hitbox.entity, &player.hitbox) and this.data.basic.atk_cd > cd) {
        this.data.basic.atk_cd = 0;
        player.hitbox.entity.hit(1);
    }
}

fn draw(this: *Enemy) void {
    const w = @as(f32, @floatFromInt(@as(i32, BasicSprite.width)));
    const h = @as(f32, @floatFromInt(@as(i32, BasicSprite.height)));
    const scale = (2.0 * this.hitbox.radius) / w;

    rl.drawTextureEx(BasicSprite, this.hitbox.position.subtract(.init(w * scale * 0.5, h * scale * 0.5)), 0, scale, .white);
    rl.drawCircleLinesV(this.hitbox.position, this.hitbox.radius, .green);
}

pub fn BasicEnemy() Enemy {
    return .{ .hitbox = collision.CircularEntity.new(.init(0, 0), 20, 1, null), .update = update, .draw = draw, .data = EnemyData{ .basic = .{ .atk_cd = 0 } } };
}

pub fn loadResources() !void {
    BasicSprite = try rl.loadTexture("resources/sprites/basic.png");
}

pub fn unloadResources() void {
    rl.unloadTexture(BasicSprite);
}
