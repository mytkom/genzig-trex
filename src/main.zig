const raylib = @cImport(@cInclude("raylib.h"));
const gameUI = @import("game_ui.zig");
const statics = @import("static_consts.zig");
const std = @import("std");

pub fn main() !void {
    const initWindowWidth: f32 = 1280;
    const initWindowHeight: f32 = 720;
    raylib.InitWindow(initWindowWidth, initWindowHeight, "Chrome dino game");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    const scaleFactor: f32 = @min(initWindowWidth / statics.desiredWidth, initWindowHeight / statics.desiredHeight);
    var sprite = raylib.LoadTexture(statics.spriteFilepath);
    var state = statics.GameState.startScreen;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    // DEBUG: Uncomment if you want to see collision rectangles
    // gameUI.drawColissionRectangles = true;

    while (!raylib.WindowShouldClose()) {
        const deltaTime: f32 = raylib.GetFrameTime();

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        try gameUI.DrawUI(&allocator, &state, &sprite, deltaTime, scaleFactor);

        raylib.EndDrawing();
    }
}
