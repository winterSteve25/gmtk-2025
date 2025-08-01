const rl = @import("raylib");
const player = @import("player.zig");
const Zones = @import("zones.zig").ZonesArray;
const std = @import("std");
const ObjectPool = @import("utils.zig").ObjectPool;
const collision = @import("collision.zig");

pub fn main() !void {
    rl.setConfigFlags(.{ .vsync_hint = true, .window_resizable = true });
    rl.initWindow(900, 900, "GMTK Loop");

    var bulletClipShader = try rl.loadShader("resources/bullet.glsl.vs", "resources/bullet.glsl.fs");
    var zones = Zones.init(std.heap.page_allocator, &bulletClipShader);
    defer zones.deinit();
    try zones.append(.init(0, 0), 250);

    var bullets = try ObjectPool(player.Bullet).init(
        std.heap.page_allocator,
        3,
        player.Bullet.new,
        player.Bullet.enable,
        player.Bullet.disable,
    );
    defer bullets.deinit();

    var c = player.Camera{
        .target = undefined,
        .cam = .{
            .offset = .init(0, 0),
            .target = .init(0, 0),
            .rotation = 0,
            .zoom = 1.5,
        },
    };
    var p = player.Player{
        .hitbox = .new(.init(0, 0), 10, player.Player.player_maxhp),
        .camera = &c,
    };
    c.target = &p.hitbox.position;

    var collidingEntities = std.ArrayList(*collision.CollidableEntity).init(std.heap.page_allocator);
    defer collidingEntities.deinit();
    try collidingEntities.append(&p.hitbox.collidable);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        rl.drawFPS(0, 0);

        std.log.debug("{d}", .{p.hitbox.collidable.hp});

        // camera
        c.cam.begin();
        defer c.cam.end();
        c.update();

        // zones
        for (zones.arr.items) |zone| {
            zone.draw();
        }

        // bullets
        var i: usize = 0;
        while (i < bullets.active_items.items.len) {
            var bullet: *player.Bullet = &bullets.arr.items[bullets.active_items.items[i]];
            player.Bullet.update(bullet, &zones.arr, &collidingEntities);

            rl.beginShaderMode(bulletClipShader);
            bullet.draw();
            rl.endShaderMode();

            if (bullet.delete) {
                try bullets.free(bullet);
            } else {
                i += 1;
            }
        }

        // player
        p.update(&bullets);
        p.draw();
    }
}
