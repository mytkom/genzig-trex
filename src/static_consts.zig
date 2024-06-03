const raylib = @cImport(@cInclude("raylib.h"));

const DinoTextures = struct {
    menuIcon: raylib.Rectangle,
    standing: raylib.Rectangle,
    leftStep: raylib.Rectangle,
    rightStep: raylib.Rectangle,
    crouchLeftStep: raylib.Rectangle,
    crouchRightStep: raylib.Rectangle,
    dead: raylib.Rectangle,
};

const CactusTextures = struct {
    shortSingle: raylib.Rectangle,
    shortDouble: raylib.Rectangle,
    shortTriple: raylib.Rectangle,
    highSingle: raylib.Rectangle,
    highDouble: raylib.Rectangle,
    highTriple: raylib.Rectangle,
};

const PterodactylTextures = struct {
    wingsDown: raylib.Rectangle,
    wingsUp: raylib.Rectangle,
};

pub const desiredWidth: f32 = 600;
pub const desiredHeight: f32 = 400;
pub const dinoVelocity: f32 = 450;
pub const groundY: f32 = 300;
pub const gravityForce: f32 = 1100;
pub const collisionOffset: f32 = 4;
pub const dinoJumpHeight: f32 = 70;
pub const spriteFilepath = "resources/sprite.png";
pub const animationDeltaTime: f32 = 0.25;
pub const dinoStandingWidth: f32 = 44;
pub const dinoStandingHeight: f32 = 46;
pub const dinoCrouchingWidth: f32 = 58;
pub const dinoCrouchingHeight: f32 = 28;
pub const dino: DinoTextures = .{
    .standing = .{ .x = 848, .y = 2, .width = 44, .height = 46 },
    .dead = .{ .x = 1068, .y = 2, .width = 44, .height = 46 },
    .leftStep = .{ .x = 936, .y = 2, .width = 44, .height = 46 },
    .rightStep = .{ .x = 980, .y = 2, .width = 44, .height = 46 },
    .crouchLeftStep = .{ .x = 1112, .y = 20, .width = 58, .height = 28 },
    .crouchRightStep = .{ .x = 1170, .y = 20, .width = 58, .height = 28 },
    .menuIcon = .{ .x = 40, .y = 4, .width = 44, .height = 46 },
};
pub const cactus: CactusTextures = .{
    .shortSingle = .{ .x = 228, .y = 2, .width = 16, .height = 32 },
    .shortDouble = .{ .x = 245, .y = 2, .width = 33, .height = 32 },
    .shortTriple = .{ .x = 279, .y = 2, .width = 50, .height = 32 },
    .highSingle = .{ .x = 332, .y = 2, .width = 24, .height = 48 },
    .highDouble = .{ .x = 357, .y = 2, .width = 49, .height = 48 },
    .highTriple = .{ .x = 407, .y = 2, .width = 74, .height = 48 },
};
pub const pterodactyl: PterodactylTextures = .{
    .wingsDown = .{ .x = 134, .y = 2, .width = 45, .height = 39 },
    .wingsUp = .{ .x = 180, .y = 2, .width = 45, .height = 39 },
};
pub const pterodactylHeights: [3]f32 = .{ 0, 25, 50 };
pub const groundTexture: raylib.Rectangle = .{ .x = 2, .y = 52, .width = 1200, .height = 14 };

pub const ObstacleType = enum {
    CactusShortSingle,
    CactusShortDouble,
    CactusShortTriple,
    CactusHighSingle,
    CactusHighDouble,
    CactusHighTriple,
    Pterodactyl,
};

pub const GameState = enum {
    startScreen,
    running,
    gameOver,
};

pub fn getObstacleSpriteRectangle(obstacle_type: ObstacleType, animation_boolean: bool) raylib.Rectangle {
    return switch (obstacle_type) {
        ObstacleType.CactusShortSingle => cactus.shortSingle,
        ObstacleType.CactusShortDouble => cactus.shortDouble,
        ObstacleType.CactusShortTriple => cactus.shortTriple,
        ObstacleType.CactusHighSingle => cactus.highSingle,
        ObstacleType.CactusHighDouble => cactus.highDouble,
        ObstacleType.CactusHighTriple => cactus.highTriple,
        ObstacleType.Pterodactyl => if (animation_boolean) pterodactyl.wingsDown else pterodactyl.wingsUp,
    };
}

pub fn getDinoSpriteRectangle(alive: bool, jumping: bool, crouching: bool, animation_boolean: bool) raylib.Rectangle {
    if (!alive) return dino.dead;
    if (jumping) return if (crouching) dino.crouchLeftStep else dino.standing;
    if (crouching) return if (animation_boolean) dino.crouchLeftStep else dino.crouchRightStep;
    return if (animation_boolean) dino.leftStep else dino.rightStep;
}
