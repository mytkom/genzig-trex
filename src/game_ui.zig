const raylib = @cImport(@cInclude("raylib.h"));

pub const DinoTextures = struct {
    menuIcon: raylib.Rectangle,
    standing: raylib.Rectangle,
    leftStep: raylib.Rectangle,
    rightStep: raylib.Rectangle,
    crouchLeftStep: raylib.Rectangle,
    crouchRightStep: raylib.Rectangle,
    dead: raylib.Rectangle,
};

pub const GameUIConfig = struct { sprite: raylib.Texture2D, width: i32, height: i32, dino: DinoTextures, dinoPosition: raylib.Vector2 };

pub fn DrawMenu(config: GameUIConfig) void {
    const scale = @as(f32, @floatFromInt(config.width)) / 8.0 / config.dino.standing.height;
    const destination = raylib.Rectangle{ .x = config.dinoPosition.x, .y = config.dinoPosition.y, .width = config.dino.menuIcon.width * scale, .height = config.dino.menuIcon.height * scale };
    raylib.DrawTexturePro(config.sprite, config.dino.menuIcon, destination, raylib.Vector2{ .x = 0, .y = 0 }, 0, raylib.WHITE);
    raylib.DrawText("Press space to play", @intFromFloat(config.dinoPosition.x), @intFromFloat(config.dinoPosition.y + (config.dino.standing.height * scale)), 30, raylib.BLACK);
}
