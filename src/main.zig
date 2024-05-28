const raylib = @cImport(@cInclude("raylib.h"));
const brn = @import("brain.zig");
const GeneticBrain = brn.GeneticBrain;
const InfluentialGameState = brn.InfluentialGameState;
const std = @import("std");

pub fn main() !void {
    raylib.InitWindow(960, 540, "Mr. Pralinka");
    raylib.SetTargetFPS(144);
    defer raylib.CloseWindow();

    var stderr = std.io.getStdErr();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

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
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.BLACK);
        raylib.EndDrawing();
    }
}
