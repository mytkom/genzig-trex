const raylib = @cImport(@cInclude("raylib.h"));
const gamelib = @import("game/game.zig");

pub fn main() !void {
    raylib.InitWindow(960, 540, "Mr. Pralinka");
    raylib.SetTargetFPS(144);
    defer raylib.CloseWindow();

    var game = gamelib.create_game();

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.BLACK);
        raylib.EndDrawing();

        game.process();
    }
}
