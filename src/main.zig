const rl = @import("raylib");
const player = @import("player.zig");
const Zones = @import("zones.zig").ZonesArray;
const std = @import("std");
const ObjectPool = @import("utils.zig").ObjectPool;
const collision = @import("collision.zig");
const Bullet = @import("bullet.zig").Bullet;
const enemies = @import("enemies/enemy.zig");

pub fn main() !void {
    rl.setConfigFlags(.{ .vsync_hint = true, .window_resizable = true });
    rl.initWindow(1980, 1080, "GMTK Loop");

    var renderTexture = try rl.loadRenderTexture(rl.getScreenWidth(), rl.getScreenHeight());
    var previousWidth = rl.getScreenWidth();
    var previousHeight = rl.getScreenHeight();

    var bulletClipShader = try rl.loadShader("resources/default.glsl.vs", "resources/bullet.glsl.fs");
    const bloomShader = try rl.loadShader(null, "resources/bloom.glsl.fs");
    const cloudShader = try rl.loadShader("resources/default.glsl.vs", "resources/cloud.glsl.fs");
    const cloudShaderResolutionLoc = rl.getShaderLocation(cloudShader, "iResolution");
    const cloudShaderTimeLoc = rl.getShaderLocation(cloudShader, "iTime");

    var resolution = [_]f32{ @floatFromInt(previousWidth), @floatFromInt(previousHeight) };
    var time: f32 = 0;
    rl.setShaderValue(cloudShader, cloudShaderResolutionLoc, &resolution, .vec2);
    rl.setShaderValue(cloudShader, cloudShaderTimeLoc, &time, .float);

    defer rl.unloadShader(bulletClipShader);
    defer rl.unloadShader(bloomShader);
    defer rl.unloadShader(cloudShader);

    var zones = Zones.init(std.heap.page_allocator, &bulletClipShader);
    defer zones.deinit();
    try zones.append(.init(0, 0), 250);

    var bullets = try ObjectPool(Bullet).init(
        std.heap.page_allocator,
        3,
        Bullet.new,
        Bullet.enable,
        Bullet.disable,
    );
    defer bullets.deinit();

    var c = player.Camera{
        .target = undefined,
        .cam = .{
            .offset = .{
                .x = @as(f32, @floatFromInt(@divFloor(rl.getScreenWidth(), 2))),
                .y = @as(f32, @floatFromInt(@divFloor(rl.getScreenHeight(), 2))),
            },
            .target = .init(0, 0),
            .rotation = 0,
            .zoom = 1.5,
        },
    };

    var p = player.Player{
        .hitbox = .new(.init(0, 0), 16, player.Player.player_maxhp, player.Player.on_hurt),
        .camera = &c,
    };
    c.target = &p.hitbox.position;

    try enemies.Basic.loadResources();
    defer enemies.Basic.unloadResources();

    var spawner = enemies.EnemySpawner.init(std.heap.page_allocator);
    _ = spawner.spawn(enemies.Basic.BasicEnemy());

    while (!rl.windowShouldClose()) {
        const currentScreenWidth = rl.getScreenWidth();
        const currentScreenHeight = rl.getScreenHeight();
        time += rl.getFrameTime();

        {
            rl.beginTextureMode(renderTexture);
            defer rl.endTextureMode();
            rl.clearBackground(rl.Color.black);

            // camera
            c.cam.begin();
            defer c.cam.end();
            c.update();

            // background cloud
            rl.setShaderValue(cloudShader, cloudShaderTimeLoc, &time, .float);
            rl.beginShaderMode(cloudShader);
            rl.drawRectangle(@as(i32, @intFromFloat(c.cam.target.x)) - @divFloor(currentScreenWidth, 2), @as(i32, @intFromFloat(c.cam.target.y)) - @divFloor(currentScreenHeight, 2), currentScreenWidth, currentScreenHeight, .white);
            rl.endShaderMode();

            // zones
            for (zones.arr.items) |zone| {
                zone.draw();
            }

            // player
            p.update(&bullets);
            p.draw();

            for (spawner.enemies.items) |*enemy| {
                enemy.update(enemy, &p);
                enemy.draw(enemy);
            }

            // bullets
            var i: usize = 0;
            while (i < bullets.active_items.items.len) {
                var bullet: *Bullet = &bullets.arr.items[bullets.active_items.items[i]];
                Bullet.update(bullet, &zones.arr, &spawner, &p);

                rl.beginShaderMode(bulletClipShader);
                bullet.draw();
                rl.endShaderMode();

                if (bullet.delete) {
                    try bullets.free(bullet);
                } else {
                    i += 1;
                }
            }
        }

        {
            rl.beginDrawing();
            defer rl.endDrawing();

            rl.beginShaderMode(bloomShader);
            defer rl.endShaderMode();

            rl.clearBackground(rl.Color.black);

            const width: f32 = @floatFromInt(@as(i32, renderTexture.texture.width));
            const height = -@as(f32, @floatFromInt(@as(i32, renderTexture.texture.height)));

            rl.drawTextureRec(renderTexture.texture, .{ .x = 0, .y = 0, .width = width, .height = height }, .init(0, 0), .white);
            rl.drawFPS(0, 0);
        }

        if (previousWidth != currentScreenWidth or previousHeight != currentScreenHeight) {
            c.cam.offset = .{
                .x = @as(f32, @floatFromInt(@divFloor(currentScreenWidth, 2))),
                .y = @as(f32, @floatFromInt(@divFloor(currentScreenHeight, 2))),
            };

            rl.unloadRenderTexture(renderTexture);
            renderTexture = try rl.loadRenderTexture(currentScreenWidth, currentScreenHeight);

            resolution[0] = @floatFromInt(currentScreenWidth);
            resolution[1] = @floatFromInt(currentScreenHeight);
            rl.setShaderValue(cloudShader, cloudShaderResolutionLoc, &resolution, .vec2);
        }

        previousWidth = currentScreenWidth;
        previousHeight = currentScreenHeight;
    }
}
