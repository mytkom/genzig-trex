const raylib = @cImport(@cInclude("raylib.h"));
const gameUI = @import("game_ui.zig");

pub fn main() !void {
    const desiredGameWidth: f32 = 400;
    const initWindowWidth: f32 = 960;
    const initWindowHeight: f32 = 540;
    raylib.InitWindow(initWindowWidth, initWindowHeight, "Chrome dino game");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    var UIConfig = gameUI.GameUIConfig{
        .width = initWindowWidth,
        .height = initWindowHeight,
        .scaleFactor = initWindowWidth / desiredGameWidth,
        .dinoPosition = .{ .x = initWindowWidth / 12, .y = initWindowHeight / 2 },
        .sprite = raylib.LoadTexture("resources/sprite.png"),
        .dino = .{
            .standing = .{ .x = 848, .y = 2, .width = 43, .height = 46 },
            .dead = .{ .x = 1068, .y = 2, .width = 45, .height = 50 },
            .leftStep = .{ .x = 936, .y = 2, .width = 45, .height = 50 },
            .rightStep = .{ .x = 980, .y = 2, .width = 45, .height = 50 },
            .crouchLeftStep = .{ .x = 1112, .y = 20, .width = 58, .height = 28 },
            .crouchRightStep = .{ .x = 1170, .y = 20, .width = 58, .height = 28 },
            .menuIcon = .{ .x = 40, .y = 4, .width = 43, .height = 46 },
        },
        .groundTexture = .{ .x = 2, .y = 52, .width = 1200, .height = 14 },
    };

    var state = gameUI.GameState.startScreen;
    var obstacles = [1]gameUI.Obstacle{
        gameUI.Obstacle{
            .rect = .{ .x = 800, .y = UIConfig.dinoPosition.y, .width = 100, .height = 100 },
            .type = gameUI.ObstacleType.Cactus,
        },
    };
    var lines = [2]raylib.Vector2{
        .{ .x = 0, .y = UIConfig.dinoPosition.y + (UIConfig.dino.standing.height - UIConfig.groundTexture.height) * UIConfig.scaleFactor },
        .{ .x = UIConfig.groundTexture.width * UIConfig.scaleFactor, .y = UIConfig.dinoPosition.y + (UIConfig.dino.standing.height - UIConfig.groundTexture.height) * UIConfig.scaleFactor },
    };
    var scene = gameUI.Scene{
        .ground = gameUI.Ground{
            .lines = &lines,
        },
        .obstacles = &obstacles,
    };

    while (!raylib.WindowShouldClose()) {
        const deltaTime: f32 = raylib.GetFrameTime();

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        gameUI.UpdateScene(&scene, &UIConfig, deltaTime);
        gameUI.DrawUI(&state, &UIConfig, &scene);

        raylib.EndDrawing();
    }
}
