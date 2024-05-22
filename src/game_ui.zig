const raylib = @cImport(@cInclude("raylib.h"));
const std = @import("std");
const rndGen = std.rand.DefaultPrng;

pub const DinoTextures = struct {
    menuIcon: raylib.Rectangle,
    standing: raylib.Rectangle,
    leftStep: raylib.Rectangle,
    rightStep: raylib.Rectangle,
    crouchLeftStep: raylib.Rectangle,
    crouchRightStep: raylib.Rectangle,
    dead: raylib.Rectangle,
};

pub const CactusTextures = struct {
    shortSingle: raylib.Rectangle,
    shortDouble: raylib.Rectangle,
    shortTriple: raylib.Rectangle,
    highSingle: raylib.Rectangle,
    highDouble: raylib.Rectangle,
    highTriple: raylib.Rectangle,
};

pub const PterodactylTextures = struct {
    wingsDown: raylib.Rectangle,
    wingsUp: raylib.Rectangle,
};

pub const GameUIConfig = struct {
    sprite: raylib.Texture2D,
    width: f32,
    height: f32,
    dinoStep: f32,
    dinoJumpTime: f32,
    dinoJumpHeight: f32,
    groundY: f32,
    animationDeltaTime: f32,
    scaleFactor: f32,
    dino: DinoTextures,
    cactus: CactusTextures,
    pterodactyl: PterodactylTextures,
    groundTexture: raylib.Rectangle,
};

pub const ObstacleType = enum {
    CactusShortSingle,
    CactusShortDouble,
    CactusShortTriple,
    CactusHighSingle,
    CactusHighDouble,
    CactusHighTriple,
    Pterodactyl,
};

pub const Dino = struct {
    pos: raylib.Rectangle,
    isJumping: bool = false,
    jumpTime: f32 = 0,
};

pub const Obstacle = struct {
    pos: raylib.Rectangle,
    type: ObstacleType,
};

pub const Ground = struct {
    lines: *[2]raylib.Rectangle,
};

pub const Scene = struct {
    obstacles: *[3]Obstacle,
    ground: Ground,
    dino: Dino,
};

pub const GameState = enum {
    startScreen,
    running,
    gameOver,
};

var animationBoolean: bool = false;
var animationDeltaTime: f32 = 0;
var rand = rndGen.init(1231222);

pub fn DrawUI(state: *GameState, config: *GameUIConfig, scene: *Scene, deltaTime: f32) void {
    animationDeltaTime += deltaTime;

    if (animationDeltaTime >= config.animationDeltaTime) {
        animationBoolean = !animationBoolean;
        animationDeltaTime = 0;
    }

    if (raylib.IsKeyDown(raylib.KEY_SPACE) and state.* == GameState.startScreen) {
        state.* = GameState.running;
    }

    switch (state.*) {
        GameState.startScreen => {
            DrawMenu(scene, config);
        },
        GameState.running => {
            UpdateScene(scene, config, deltaTime);
            var dinoScaledPos = scene.dino.pos;
            dinoScaledPos.width *= config.scaleFactor;
            dinoScaledPos.height *= config.scaleFactor;
            var obstacleScaledPos = scene.obstacles[0].pos;
            obstacleScaledPos.width *= config.scaleFactor;
            obstacleScaledPos.height *= config.scaleFactor;
            if (raylib.CheckCollisionRecs(dinoScaledPos, obstacleScaledPos)) {
                state.* = GameState.gameOver;
            }
            DrawScene(config, scene);
        },
        GameState.gameOver => {
            DrawGameOver(config);
        },
    }
}

fn DrawMenu(scene: *const Scene, config: *const GameUIConfig) void {
    const destination = raylib.Rectangle{
        .x = scene.dino.pos.x,
        .y = scene.dino.pos.y,
        .width = config.dino.menuIcon.width,
        .height = config.dino.menuIcon.height,
    };
    DrawTexture(
        config,
        config.dino.menuIcon,
        destination,
    );
    raylib.DrawText(
        "Press space to play",
        @intFromFloat(scene.dino.pos.x),
        @intFromFloat(config.groundY),
        30,
        raylib.BLACK,
    );
}

fn DrawScene(config: *const GameUIConfig, scene: *Scene) void {
    for (scene.ground.lines) |line| {
        const groundLineDestination = raylib.Rectangle{
            .x = line.x,
            .y = line.y,
            .width = config.groundTexture.width,
            .height = config.groundTexture.height,
        };

        DrawTexture(
            config,
            config.groundTexture,
            groundLineDestination,
        );
    }

    for (scene.obstacles) |obstacle| {
        const obstacleSpriteRect = GetObstacleSpriteRectangle(config, obstacle.type);

        DrawTexture(
            config,
            obstacleSpriteRect,
            obstacle.pos,
        );
    }

    DrawTexture(
        config,
        GetDinoSpriteRectangle(config),
        scene.dino.pos,
    );
}

fn DrawGameOver(config: *const GameUIConfig) void {
    raylib.DrawText(
        "Game Over",
        @intFromFloat(config.width / 2),
        @intFromFloat(config.height / 2),
        30,
        raylib.BLACK,
    );
}

fn UpdateScene(scene: *Scene, config: *GameUIConfig, deltaTime: f32) void {
    for (scene.ground.lines) |*line| {
        line.x -= config.dinoStep * deltaTime;
    }

    for (scene.obstacles) |*obstacle| {
        obstacle.pos.x -= config.dinoStep * deltaTime;
    }

    if (scene.obstacles[0].pos.x + GetObstacleSpriteRectangle(config, scene.obstacles[0].type).width * config.scaleFactor <= 0) {
        scene.obstacles[0] = scene.obstacles[1];
        scene.obstacles[1] = scene.obstacles[2];

        const newObstacleType: ObstacleType = @enumFromInt(rand.random().int(u32) % @typeInfo(ObstacleType).Enum.fields.len);
        const newObstacleSprite: raylib.Rectangle = GetObstacleSpriteRectangle(config, newObstacleType);
        scene.obstacles[2] = Obstacle{
            .pos = raylib.Rectangle{ .x = scene.obstacles[1].pos.x + config.dinoStep, .y = 0, .width = newObstacleSprite.width, .height = newObstacleSprite.height },
            .type = newObstacleType,
        };
    }

    const lineWidth = config.groundTexture.width * config.scaleFactor;
    if (scene.ground.lines[0].x <= -lineWidth) {
        scene.ground.lines[0].x = scene.ground.lines[1].x;
        scene.ground.lines[1].x = scene.ground.lines[1].x + lineWidth;
    }

    if (raylib.IsKeyDown(raylib.KEY_SPACE) and !scene.dino.isJumping) {
        scene.dino.isJumping = true;
        scene.dino.jumpTime = 0;
    }

    if (scene.dino.isJumping) {
        scene.dino.jumpTime += deltaTime;
        if (scene.dino.jumpTime > config.dinoJumpTime) {
            scene.dino.isJumping = false;
            scene.dino.jumpTime = 0;
            scene.dino.pos.y = 0;
        } else {
            const halfJumpTime: f32 = config.dinoJumpTime / 2;
            var factor: f32 = 0;
            if (scene.dino.jumpTime > halfJumpTime) {
                factor = (config.dinoJumpTime - scene.dino.jumpTime) / halfJumpTime;
            } else {
                factor = scene.dino.jumpTime / halfJumpTime;
            }
            scene.dino.pos.y = factor * config.dinoJumpHeight * config.scaleFactor;
        }
    }
}

fn GetObstacleSpriteRectangle(config: *const GameUIConfig, obstacleType: ObstacleType) raylib.Rectangle {
    switch (obstacleType) {
        ObstacleType.CactusShortSingle => {
            return config.cactus.shortSingle;
        },
        ObstacleType.CactusShortDouble => {
            return config.cactus.shortDouble;
        },
        ObstacleType.CactusShortTriple => {
            return config.cactus.shortTriple;
        },
        ObstacleType.CactusHighSingle => {
            return config.cactus.highSingle;
        },
        ObstacleType.CactusHighDouble => {
            return config.cactus.highDouble;
        },
        ObstacleType.CactusHighTriple => {
            return config.cactus.highTriple;
        },
        ObstacleType.Pterodactyl => {
            if (animationBoolean) {
                return config.pterodactyl.wingsDown;
            } else {
                return config.pterodactyl.wingsUp;
            }
        },
    }
}

fn GetDinoSpriteRectangle(config: *const GameUIConfig) raylib.Rectangle {
    if (animationBoolean) {
        return config.dino.leftStep;
    } else {
        return config.dino.rightStep;
    }
}

fn DrawTexture(config: *const GameUIConfig, spriteRect: raylib.Rectangle, destRect: raylib.Rectangle) void {
    var destinationGlobal = raylib.Rectangle{
        .x = destRect.x,
        .y = config.groundY - destRect.y,
        .width = destRect.width * config.scaleFactor,
        .height = destRect.height * config.scaleFactor,
    };

    raylib.DrawTexturePro(
        config.sprite,
        spriteRect,
        destinationGlobal,
        raylib.Vector2{ .x = 0, .y = destinationGlobal.height },
        0,
        raylib.WHITE,
    );

    // destinationGlobal.y -= destinationGlobal.height;

    // raylib.DrawRectangleLinesEx(destinationGlobal, 4, raylib.RED);
}
