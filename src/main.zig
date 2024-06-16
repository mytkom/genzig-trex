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

            try runWatchMode(brain, gpa.allocator(), prng.random());
        },
        .train => |parameters| {
            const allocator = gpa.allocator();
            const brains = try allocator.alloc(GeneticBrain, parameters.population_size);
            defer allocator.free(brains);

            for (brains) |*brain| {
                brain.* = GeneticBrain.generateRandom(prng.random(), allocator, parameters.influential_cacti_count, parameters.influential_birds_count) catch |err| {
                    _ = try stderr.writer().print("An error occured while generating random data: {}.\n", .{err});
                    return;
                };
            }
            defer for (brains) |brain| brain.deinit();

            const bestIndex = try runTrainMode(brains, allocator, prng.random(), parameters.max_generations);

            brains[bestIndex].save(parameters.save_filename) catch |err| {
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
    // gameUI.drawColissionRectangles = true;

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
            gameUI.DrawScene(&scene, &sprite, scaleFactor, animationBoolean, null, 1);
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
            gameUI.DrawScene(&scene, &sprite, scaleFactor, animationBoolean, null, 1);
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

fn watchGame(brains: []const GeneticBrain, scores: []f32, sprite: *raylib.Texture2D, scaleFactor: f32, allocator: std.mem.Allocator, rand: std.Random, wait_for_input: bool, generation: ?u32) !void {
    const jump_triggered = try allocator.alloc(bool, brains.len);
    defer allocator.free(jump_triggered);
    const duck_triggered = try allocator.alloc(bool, brains.len);
    defer allocator.free(duck_triggered);
    var scene = try Scene.init(allocator, brains.len, 3, rand);
    defer scene.deinit();
    const game_states = try allocator.alloc(InfluentialGameState, brains.len);
    defer allocator.free(game_states);
    for (game_states, brains) |*state, brain| {
        state.* = try InfluentialGameState.init(allocator, brain.influential_cacti_count, brain.influential_birds_count);
    }
    defer for (game_states) |state| {
        state.deinit();
    };

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

        // Update influential game states
        scene.updateInfluentialGameStates(game_states);

        // Think
        for (brains, game_states, jump_triggered, duck_triggered) |brain, *state, *jump, *duck| {
            jump.* = brain.shouldJump(state);
            duck.* = brain.shouldDuck(state);
        }

        // Update scene
        alive_ctr = scene.update(delta_time, jump_triggered, duck_triggered);

        // Render
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        gameUI.DrawScene(&scene, sprite, scaleFactor, animationBoolean, generation, alive_ctr);
        raylib.EndDrawing();
    }

    for (scores, scene.scores) |*dst, src| {
        dst.* = src;
    }

    // Game over screen
    var key_down_released = !raylib.IsKeyDown(raylib.KEY_SPACE);
    while (wait_for_input and !raylib.WindowShouldClose()) {

        // Update animation
        animationDeltaTime += raylib.GetFrameTime();
        while (animationDeltaTime >= statics.animationDeltaTime) {
            animationBoolean = !animationBoolean;
            animationDeltaTime -= statics.animationDeltaTime;
        }

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        gameUI.DrawScene(&scene, sprite, scaleFactor, animationBoolean, generation, alive_ctr);
        gameUI.DrawGameOver(scaleFactor);
        raylib.EndDrawing();

        if (raylib.IsKeyDown(raylib.KEY_SPACE)) {
            if (key_down_released) break;
        } else {
            key_down_released = true;
        }
    }
}

fn runWatchMode(brain: GeneticBrain, allocator: std.mem.Allocator, rand: std.Random) !void {
    const brains: [1]GeneticBrain = .{brain};
    const scores = try allocator.alloc(f32, 1);
    defer allocator.free(scores);

    const initWindowWidth: f32 = 1280;
    const initWindowHeight: f32 = 720;
    raylib.InitWindow(initWindowWidth, initWindowHeight, "Chrome dino game");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    const scaleFactor: f32 = @min(initWindowWidth / statics.desiredWidth, initWindowHeight / statics.desiredHeight);
    var sprite = raylib.LoadTexture(statics.spriteFilepath);
    // gameUI.drawColissionRectangles = true;

    // Start screen
    while (!raylib.WindowShouldClose() and !raylib.IsKeyDown(raylib.KEY_SPACE)) {
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        gameUI.DrawMenu(&sprite, scaleFactor);
        raylib.EndDrawing();
    }

    while (!raylib.WindowShouldClose()) { // Game loop
        try watchGame(&brains, scores, &sprite, scaleFactor, allocator, rand, true, null);
    }
}

fn runTrainMode(brains: []GeneticBrain, allocator: std.mem.Allocator, rand: std.Random, auto_iters: u32) !usize {
    const scores = try allocator.alloc(f32, brains.len);
    defer allocator.free(scores);
    const scores_prefix_sums = try allocator.alloc(f32, brains.len + 1);
    defer allocator.free(scores_prefix_sums);
    const brains_buffer = try allocator.alloc(GeneticBrain, brains.len);
    defer allocator.free(brains_buffer);
    for (brains, brains_buffer) |brain, *buffer| {
        buffer.* = try GeneticBrain.init(brain);
    }
    defer for (brains_buffer) |buffer| buffer.deinit();
    var generation: u32 = 1;

    const initWindowWidth: f32 = 1280;
    const initWindowHeight: f32 = 720;
    raylib.InitWindow(initWindowWidth, initWindowHeight, "Chrome dino game");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    const scaleFactor: f32 = @min(initWindowWidth / statics.desiredWidth, initWindowHeight / statics.desiredHeight);
    var sprite = raylib.LoadTexture(statics.spriteFilepath);
    // gameUI.drawColissionRectangles = true;

    // Start screen
    while (!raylib.WindowShouldClose() and !raylib.IsKeyDown(raylib.KEY_SPACE)) {
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);
        gameUI.DrawMenu(&sprite, scaleFactor);
        raylib.EndDrawing();
    }

    while (!raylib.WindowShouldClose()) { // Game loop
        try watchGame(brains, scores, &sprite, scaleFactor, allocator, rand, generation % auto_iters == 0, generation);

        // Select
        scores_prefix_sums[0] = 0.0;
        for (0..scores.len) |i| {
            scores_prefix_sums[i + 1] = scores_prefix_sums[i] + scores[i];
        }
        for (brains_buffer) |buffer| {
            const x = rand.float(f32) * scores_prefix_sums[scores.len];
            var selected_index: usize = 0;
            while (scores_prefix_sums[selected_index + 1] <= x) selected_index += 1;
            buffer.copyFrom(&brains[selected_index]);
        }
        for (brains, brains_buffer) |brain, buffer| {
            brain.copyFrom(&buffer);
        }

        // Crossover
        var i: usize = 0;
        while (i + 1 < brains.len) : (i += 2)
            GeneticBrain.crossover(brains[i], brains[i + 1], rand);

        // Mutate
        for (brains) |brain| brain.mutate(rand);

        generation += 1;
    }

    var max_score: f32 = 0.0;
    var best_index: usize = 0;
    for (scores, 0..) |score, i| {
        if (score > max_score) {
            max_score = score;
            best_index = i;
        }
    }
    return best_index;
}
