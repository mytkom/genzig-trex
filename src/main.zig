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
        .dinoStep = 0.75 * initWindowWidth,
        .dinoJumpHeight = 70,
        .dinoJumpTime = 0.6,
        .groundY = 2 * initWindowHeight / 3,
        .animationDeltaTime = 0.25,
        .scaleFactor = initWindowWidth / desiredGameWidth,
        .sprite = raylib.LoadTexture("resources/sprite.png"),
        .dino = .{
            .standing = .{ .x = 848, .y = 2, .width = 44, .height = 46 },
            .dead = .{ .x = 1068, .y = 2, .width = 44, .height = 46 },
            .leftStep = .{ .x = 936, .y = 2, .width = 44, .height = 46 },
            .rightStep = .{ .x = 980, .y = 2, .width = 44, .height = 46 },
            .crouchLeftStep = .{ .x = 1112, .y = 20, .width = 58, .height = 28 },
            .crouchRightStep = .{ .x = 1170, .y = 20, .width = 58, .height = 28 },
            .menuIcon = .{ .x = 40, .y = 4, .width = 44, .height = 46 },
        },
        .cactus = .{
            .shortSingle = .{ .x = 228, .y = 2, .width = 16, .height = 32 },
            .shortDouble = .{ .x = 245, .y = 2, .width = 33, .height = 32 },
            .shortTriple = .{ .x = 279, .y = 2, .width = 50, .height = 32 },
            .highSingle = .{ .x = 332, .y = 2, .width = 24, .height = 48 },
            .highDouble = .{ .x = 357, .y = 2, .width = 49, .height = 48 },
            .highTriple = .{ .x = 407, .y = 2, .width = 74, .height = 48 },
        },
        .pterodactyl = .{
            .wingsDown = .{ .x = 134, .y = 2, .width = 45, .height = 39 },
            .wingsUp = .{ .x = 180, .y = 2, .width = 45, .height = 39 },
        },
        .groundTexture = .{ .x = 2, .y = 52, .width = 1200, .height = 14 },
    };

    var state = gameUI.GameState.startScreen;
    var obstacles = [3]gameUI.Obstacle{
        gameUI.Obstacle{
            .pos = .{ .x = initWindowWidth, .y = 0, .width = UIConfig.cactus.shortSingle.width, .height = UIConfig.cactus.shortSingle.height },
            .type = gameUI.ObstacleType.CactusShortSingle,
        },
        gameUI.Obstacle{
            .pos = .{ .x = initWindowWidth + UIConfig.dinoStep, .y = 0, .width = UIConfig.cactus.shortSingle.width, .height = UIConfig.cactus.shortSingle.height },
            .type = gameUI.ObstacleType.CactusShortSingle,
        },
        gameUI.Obstacle{
            .pos = .{ .x = initWindowWidth + UIConfig.dinoStep * 2, .y = 0, .width = UIConfig.cactus.shortSingle.width, .height = UIConfig.cactus.shortSingle.height },
            .type = gameUI.ObstacleType.CactusShortSingle,
        },
    };
    var lines = [2]raylib.Rectangle{
        .{ .x = 0, .y = 0, .width = UIConfig.groundTexture.width, .height = UIConfig.groundTexture.height },
        .{ .x = UIConfig.groundTexture.width * UIConfig.scaleFactor, .y = 0, .width = UIConfig.groundTexture.width, .height = UIConfig.groundTexture.height },
    };
    var scene = gameUI.Scene{
        .ground = gameUI.Ground{
            .lines = &lines,
        },
        .obstacles = &obstacles,
        .dino = gameUI.Dino{
            .pos = .{ .x = initWindowWidth / 12, .y = 0, .width = UIConfig.dino.standing.width, .height = UIConfig.dino.standing.height },
        },
    };

    while (!raylib.WindowShouldClose()) {
        const deltaTime: f32 = raylib.GetFrameTime();

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        gameUI.DrawUI(&state, &UIConfig, &scene, deltaTime);

        raylib.EndDrawing();
    }
}
