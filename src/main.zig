const raylib = @cImport(@cInclude("raylib.h"));
const gameUI = @import("game_ui.zig");
const statics = @import("static_consts.zig");
const std = @import("std");
const brn = @import("brain.zig");
const GeneticBrain = brn.GeneticBrain;
const InfluentialGameState = brn.InfluentialGameState;
const gmp = @import("game_mode_parameters.zig");
const scn = @import("scene.zig");
const Scene = scn.Scene;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    var stderr = std.io.getStdErr();

    const game_mode_parameters = gmp.GameModeParameters.fromCommandLineArguments(gpa.allocator()) catch |err| {
        _ = try stderr.writer().print("ERROR: {}", .{err});
        _ = try gmp.usage(gpa.allocator());
        return;
    };
    defer game_mode_parameters.deinit();

    // const seed = @as(u64, @intCast(std.time.timestamp()));
    const seed = 100;
    var prng = std.rand.DefaultPrng.init(seed);

    switch (game_mode_parameters) {
        .play => try runPlayMode(gpa.allocator(), prng.random()),
        .watch => |parameters| {
            const brain = GeneticBrain.load(parameters.load_filename, gpa.allocator()) catch |err| {
                _ = try stderr.writer().print("Could not load data from file {s}: {}.\n", .{ parameters.load_filename, err });
                return;
            };
            defer brain.deinit();

            // TODO: Run game
        },
        .train => |parameters| {
            const brain = GeneticBrain.generateRandom(prng.random(), gpa.allocator(), parameters.influential_cacti_count, parameters.influential_birds_count) catch |err| {
                _ = try stderr.writer().print("An error occured while generating random data: {}.\n", .{err});
                return;
            };
            defer brain.deinit();

            // TODO: Run evolution

            brain.save(parameters.save_filename) catch |err| {
                _ = try stderr.writer().print("Could not save data to file {s}: {}.\n", .{ parameters.save_filename, err });
                return;
            };
        },
    }
}

fn runPlayMode(allocator: std.mem.Allocator, rand: std.Random) !void {
    var jump_triggered: [1]bool = undefined;
    var duck_triggered: [1]bool = undefined;
    const initWindowWidth: f32 = 1280;
    const initWindowHeight: f32 = 720;
    raylib.InitWindow(initWindowWidth, initWindowHeight, "Chrome dino game");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    const scaleFactor: f32 = @min(initWindowWidth / statics.desiredWidth, initWindowHeight / statics.desiredHeight);
    var sprite = raylib.LoadTexture(statics.spriteFilepath);
    gameUI.drawColissionRectangles = true;

    // Start screen
    while (!raylib.WindowShouldClose() and !raylib.IsKeyDown(raylib.KEY_SPACE)) {
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        gameUI.DrawMenu(&sprite, scaleFactor);
        raylib.EndDrawing();
    }

    while (!raylib.WindowShouldClose()) { // Game loop
        var scene = try Scene.init(allocator, 1, 3, rand);
        defer scene.deinit();

        var animationBoolean: bool = false;
        var animationDeltaTime: f32 = 0;
        var alive_ctr: u32 = 1;
        while (!raylib.WindowShouldClose() and alive_ctr > 0) { // Scene update and render loop

            // Update animation
            const delta_time = raylib.GetFrameTime();
            animationDeltaTime += delta_time;
            while (animationDeltaTime >= statics.animationDeltaTime) {
                animationBoolean = !animationBoolean;
                animationDeltaTime -= statics.animationDeltaTime;
            }

            // Update scene
            jump_triggered[0] = raylib.IsKeyDown(raylib.KEY_SPACE) or raylib.IsKeyDown(raylib.KEY_UP);
            duck_triggered[0] = raylib.IsKeyDown(raylib.KEY_DOWN);
            alive_ctr = scene.update(delta_time, &jump_triggered, &duck_triggered);

            // Render
            raylib.BeginDrawing();
            raylib.ClearBackground(raylib.WHITE);
            gameUI.DrawScene(&scene, &sprite, scaleFactor, animationBoolean);
            raylib.EndDrawing();
        }

        // Game over screen
        var key_down_released = !raylib.IsKeyDown(raylib.KEY_SPACE);
        while (!raylib.WindowShouldClose()) {

            // Update animation
            animationDeltaTime += raylib.GetFrameTime();
            while (animationDeltaTime >= statics.animationDeltaTime) {
                animationBoolean = !animationBoolean;
                animationDeltaTime -= statics.animationDeltaTime;
            }

            raylib.BeginDrawing();
            raylib.ClearBackground(raylib.WHITE);
            gameUI.DrawScene(&scene, &sprite, scaleFactor, animationBoolean);
            gameUI.DrawGameOver(scaleFactor);
            raylib.EndDrawing();

            if (raylib.IsKeyDown(raylib.KEY_SPACE)) {
                if (key_down_released) break;
            } else {
                key_down_released = true;
            }
        }
    }
}
