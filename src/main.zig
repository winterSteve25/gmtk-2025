const rl = @import("raylib");
const player = @import("player.zig");
const Zone = @import("zones.zig").Zone;
const std = @import("std");
const ObjectPool = @import("utils.zig").ObjectPool;

pub fn main() !void {
    rl.setConfigFlags(.{ .vsync_hint = true, .window_resizable = true });
    rl.initWindow(900, 900, "GMTK Loop");

    var zones = std.ArrayList(Zone).init(std.heap.page_allocator);
    defer zones.deinit();

    var bullets = try ObjectPool(player.Bullet).init(
        std.heap.page_allocator,
        40,
        player.Bullet.new,
        player.Bullet.enable,
        player.Bullet.disable,
    );
    defer bullets.deinit();

    try zones.append(.{
        .position = .init(0, 0),
        .radius = 250,
    });

    var c = player.Camera{
        .target = undefined,
        .cam = .{
            .offset = .init(0, 0),
            .target = .init(0, 0),
            .rotation = 0,
            .zoom = 1.5,
        },
    };
    var p = player.Player{ .camera = &c };
    c.target = &p.position;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        rl.drawFPS(0, 0);

        // camera
        c.cam.begin();
        defer c.cam.end();
        c.update();

        // zones
        for (zones.items) |zone| {
            zone.draw();
        }

        // bullets
        var i: usize = 0;
        while (i < bullets.active_items.items.len) {
            player.Bullet.update(bullets.active_items.items[i], &zones);
            bullets.active_items.items[i].draw();

            if (bullets.active_items.items[i].delete) {
                try bullets.free(bullets.active_items.items[i]);
            } else {
                i += 1;
            }
        }

        // player
        p.update(&bullets);
        p.draw();
    }
}
