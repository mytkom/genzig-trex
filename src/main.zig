const raylib = @cImport(@cInclude("raylib.h"));

pub fn main() !void {
    const initScreenWidth = 960;
    const initScreenHeight = 540;

    raylib.InitWindow(initScreenWidth, initScreenHeight, "Mr. Pralinka");
    raylib.SetTargetFPS(144);
    defer raylib.CloseWindow();

    const sprite = raylib.LoadTexture("resources/sprite.png");
    const dino = raylib.Rectangle{ .x = 30, .y = 0, .width = 60, .height = 50 };

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.BLACK);

        raylib.DrawTextureRec(sprite, dino, raylib.Vector2{ .x = 0, .y = 0 }, raylib.WHITE);

        raylib.EndDrawing();
    }
}
