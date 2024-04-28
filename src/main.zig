const raylib = @cImport(@cInclude("raylib.h"));
const gameUI = @import("game_ui.zig");

pub fn main() !void {
    const initWindowWidth: i32 = 960;
    const initWindowHeight: i32 = 540;
    raylib.InitWindow(initWindowWidth, initWindowHeight, "Chrome dino game");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(144);

    const UIConfig = gameUI.GameUIConfig{
        .width = initWindowWidth,
        .height = initWindowHeight,
        .dinoPosition = raylib.Vector2{ .x = initWindowWidth / 12, .y = initWindowHeight / 2 },
        .sprite = raylib.LoadTexture("resources/sprite.png"),
        .dino = gameUI.DinoTextures{
            .standing = raylib.Rectangle{ .x = 848, .y = 2, .width = 43, .height = 46 },
            .dead = raylib.Rectangle{ .x = 1068, .y = 2, .width = 45, .height = 50 },
            .leftStep = raylib.Rectangle{ .x = 936, .y = 2, .width = 45, .height = 50 },
            .rightStep = raylib.Rectangle{ .x = 980, .y = 2, .width = 45, .height = 50 },
            .crouchLeftStep = raylib.Rectangle{ .x = 1112, .y = 20, .width = 58, .height = 28 },
            .crouchRightStep = raylib.Rectangle{ .x = 1170, .y = 20, .width = 58, .height = 28 },
            .menuIcon = raylib.Rectangle{ .x = 40, .y = 4, .width = 43, .height = 46 },
        },
    };

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        gameUI.DrawMenu(UIConfig);

        raylib.EndDrawing();
    }
}
