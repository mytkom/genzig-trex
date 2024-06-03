const raylib = @cImport(@cInclude("raylib.h"));
const statics = @import("static_consts.zig");
const scn = @import("scene.zig");
const std = @import("std");
const Scene = scn.Scene;

pub var drawColissionRectangles: bool = false;

pub fn DrawMenu(sprite: *raylib.Texture2D, scaleFactor: f32) void {
    const destination = raylib.Rectangle{
        .x = statics.desiredWidth / 12,
        .y = 0,
        .width = statics.dino.menuIcon.width,
        .height = statics.dino.menuIcon.height,
    };
    DrawTexture(
        sprite,
        statics.dino.menuIcon,
        destination,
        scaleFactor,
    );
    raylib.DrawText(
        "Press space to play",
        @intFromFloat(statics.desiredWidth * scaleFactor / 12),
        @intFromFloat(statics.groundY * scaleFactor),
        30,
        raylib.BLACK,
    );
}

pub fn DrawScene(scene: *const Scene, sprite: *raylib.Texture2D, scaleFactor: f32, animation_boolean: bool) void {
    var buffer: [20]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    for (scene.ground_lines) |line| {
        const groundLineDestination = raylib.Rectangle{
            .x = line.x,
            .y = line.y,
            .width = statics.groundTexture.width,
            .height = statics.groundTexture.height,
        };

        DrawTexture(
            sprite,
            statics.groundTexture,
            groundLineDestination,
            scaleFactor,
        );
    }

    for (scene.obstacles) |obstacle| {
        const obstacleSpriteRect = statics.getObstacleSpriteRectangle(obstacle.type, animation_boolean);

        DrawTexture(
            sprite,
            obstacleSpriteRect,
            obstacle.pos,
            scaleFactor,
        );
    }

    for (scene.dinos) |dino| {
        DrawTexture(
            sprite,
            statics.getDinoSpriteRectangle(dino.alive, dino.isJumping, dino.isCrouching, animation_boolean),
            dino.pos,
            scaleFactor,
        );
    }

    const text = std.fmt.allocPrintZ(
        allocator,
        "Points: {d}",
        .{@as(u32, @intFromFloat(scene.points))},
    ) catch "Points: ???";
    defer allocator.free(text);

    raylib.DrawText(
        @as([*:0]const u8, text),
        @intFromFloat(statics.desiredWidth * scaleFactor * 0.95),
        @intFromFloat(statics.desiredHeight * scaleFactor * 0.1),
        25,
        raylib.BLACK,
    );
}

pub fn DrawGameOver(scaleFactor: f32) void {
    raylib.DrawText(
        "Game Over",
        @intFromFloat(statics.desiredWidth * scaleFactor / 2),
        @intFromFloat(statics.desiredHeight * scaleFactor / 2),
        30,
        raylib.BLACK,
    );
    raylib.DrawText(
        "Press space to restart",
        @intFromFloat(statics.desiredWidth * scaleFactor / 2),
        @intFromFloat(statics.desiredHeight * scaleFactor / 2 + 35),
        18,
        raylib.BLACK,
    );
}

fn DrawTexture(sprite: *raylib.Texture2D, spriteRect: raylib.Rectangle, destRect: raylib.Rectangle, scaleFactor: f32) void {
    var destinationGlobal = raylib.Rectangle{
        .x = destRect.x * scaleFactor,
        .y = (statics.groundY - destRect.y) * scaleFactor,
        .width = destRect.width * scaleFactor,
        .height = destRect.height * scaleFactor,
    };

    raylib.DrawTexturePro(
        sprite.*,
        spriteRect,
        destinationGlobal,
        raylib.Vector2{ .x = 0, .y = destinationGlobal.height },
        0,
        raylib.WHITE,
    );

    if (drawColissionRectangles and destinationGlobal.width < statics.desiredWidth * scaleFactor) {
        destinationGlobal.y -= destinationGlobal.height;
        raylib.DrawRectangleLinesEx(
            scn.getCollisionRec(destinationGlobal, statics.collisionOffset * scaleFactor),
            4,
            raylib.RED,
        );
    }
}
