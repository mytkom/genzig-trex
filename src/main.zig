const raylib = @cImport(@cInclude("raylib.h"));
const gameUI = @import("game_ui.zig");
const statics = @import("static_consts.zig");
const std = @import("std");
const brn = @import("brain.zig");
const GeneticBrain = brn.GeneticBrain;
const InfluentialGameState = brn.InfluentialGameState;
const gmp = @import("game_mode_parameters.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var stderr = std.io.getStdErr();

    const game_mode_parameters = gmp.GameModeParameters.fromCommandLineArguments(gpa.allocator()) catch |err| {
        _ = try stderr.writer().print("ERROR: {}", .{err});
        _ = try gmp.usage(gpa.allocator());
        return;
    };
    defer game_mode_parameters.deinit();

    const initWindowWidth: f32 = 1280;
    const initWindowHeight: f32 = 720;
    raylib.InitWindow(initWindowWidth, initWindowHeight, "Chrome dino game");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    const scaleFactor: f32 = @min(initWindowWidth / statics.desiredWidth, initWindowHeight / statics.desiredHeight);
    var sprite = raylib.LoadTexture(statics.spriteFilepath);
    var state = statics.GameState.startScreen;

    // DEBUG: Uncomment if you want to see collision rectangles
    // gameUI.drawColissionRectangles = true;

    const brain = GeneticBrain.load("test.brain", gpa.allocator()) catch |err| {
        _ = try stderr.writer().print("An error occured while loading brain data: {}.\n", .{err});
        return;
    };

    // var prng = std.rand.DefaultPrng.init(100);
    // const brain = GeneticBrain.generateRandom(prng.random(), gpa.allocator(), 3, 3) catch |err| {
    //    _ = try stderr.writer().print("An error occured while generating random data: {}.\n", .{err});
    //    return;
    //};
    defer brain.deinit();

    const game_state = try InfluentialGameState.init(gpa.allocator(), brain.influential_cacti_count, brain.influential_birds_count);
    defer game_state.deinit();

    _ = brain.shouldJump(&game_state);
    _ = brain.shouldDuck(&game_state);

    brain.save("test.brain") catch |err| {
        _ = try stderr.writer().print("An error occured while saving brain data: {}.\n", .{err});
        return;
    };

    while (!raylib.WindowShouldClose()) {
        const deltaTime: f32 = raylib.GetFrameTime();

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        try gameUI.DrawUI(&allocator, &state, &sprite, deltaTime, scaleFactor);

        raylib.EndDrawing();
    }
}
