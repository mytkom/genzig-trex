const raylib = @cImport(@cInclude("raylib.h"));
const gameUI = @import("game_ui.zig");
const statics = @import("static_consts.zig");

pub fn main() !void {
    const initWindowWidth: f32 = 1280;
    const initWindowHeight: f32 = 720;
    raylib.InitWindow(initWindowWidth, initWindowHeight, "Chrome dino game");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    const scaleFactor: f32 = @min(initWindowWidth / statics.desiredWidth, initWindowHeight / statics.desiredHeight);
    var sprite = raylib.LoadTexture(statics.spriteFilepath);

    var state = statics.GameState.startScreen;

    while (!raylib.WindowShouldClose()) {
        const deltaTime: f32 = raylib.GetFrameTime();

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        gameUI.DrawUI(&state, &sprite, deltaTime, scaleFactor);

        raylib.EndDrawing();
    }
}
