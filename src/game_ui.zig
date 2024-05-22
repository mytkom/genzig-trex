const raylib = @cImport(@cInclude("raylib.h"));
const statics = @import("static_consts.zig");
const scene = @import("scene.zig");
const std = @import("std");

var animationBoolean: bool = false;
var animationDeltaTime: f32 = 0;

pub fn DrawUI(state: *statics.GameState, sprite: *raylib.Texture2D, deltaTime: f32, scaleFactor: f32) void {
    animationDeltaTime += deltaTime;

    if (animationDeltaTime >= statics.animationDeltaTime) {
        animationBoolean = !animationBoolean;
        animationDeltaTime = 0;
    }

    switch (state.*) {
        statics.GameState.startScreen => {
            DrawMenu(sprite, scaleFactor);

            if (raylib.IsKeyDown(raylib.KEY_SPACE)) {
                state.* = statics.GameState.running;
            }
        },
        statics.GameState.running => {
            UpdateScene(deltaTime);
            if (raylib.CheckCollisionRecs(scene.dino.pos, scene.obstacles[0].pos)) {
                state.* = statics.GameState.gameOver;
            }
            DrawScene(sprite, state.*, scaleFactor);
        },
        statics.GameState.gameOver => {
            DrawScene(sprite, state.*, scaleFactor);
            DrawGameOver(scaleFactor);

            if (raylib.IsKeyDown(raylib.KEY_SPACE)) {
                state.* = statics.GameState.running;
                scene.Init();
            }
        },
    }
}

fn DrawMenu(sprite: *raylib.Texture2D, scaleFactor: f32) void {
    const destination = raylib.Rectangle{
        .x = scene.dino.pos.x,
        .y = scene.dino.pos.y,
        .width = statics.dino.menuIcon.width,
        .height = statics.dino.menuIcon.height,
    };
    DrawTexture(
        sprite,
        statics.dino.menuIcon,
        destination,
        scaleFactor,
    );
    raylib.DrawText(
        "Press space to play",
        @intFromFloat(scene.dino.pos.x * scaleFactor),
        @intFromFloat(statics.groundY * scaleFactor),
        30,
        raylib.BLACK,
    );
}

fn DrawScene(sprite: *raylib.Texture2D, state: statics.GameState, scaleFactor: f32) void {
    for (scene.groundLines) |line| {
        const groundLineDestination = raylib.Rectangle{
            .x = line.x,
            .y = line.y,
            .width = statics.groundTexture.width,
            .height = statics.groundTexture.height,
        };

        DrawTexture(
            sprite,
            statics.groundTexture,
            groundLineDestination,
            scaleFactor,
        );
    }

    for (scene.obstacles) |obstacle| {
        const obstacleSpriteRect = GetObstacleSpriteRectangle(obstacle.type);

        DrawTexture(
            sprite,
            obstacleSpriteRect,
            obstacle.pos,
            scaleFactor,
        );
    }

    DrawTexture(
        sprite,
        GetDinoSpriteRectangle(state),
        scene.dino.pos,
        scaleFactor,
    );
}

fn DrawGameOver(scaleFactor: f32) void {
    raylib.DrawText(
        "Game Over",
        @intFromFloat(statics.desiredWidth * scaleFactor / 2),
        @intFromFloat(statics.desiredHeight * scaleFactor / 2),
        30,
        raylib.BLACK,
    );
    raylib.DrawText(
        "Press space to restart",
        @intFromFloat(statics.desiredWidth * scaleFactor / 2),
        @intFromFloat(statics.desiredHeight * scaleFactor / 2 + 35),
        18,
        raylib.BLACK,
    );
}

fn UpdateScene(deltaTime: f32) void {
    for (&scene.groundLines) |*line| {
        line.x -= statics.dinoVelocity * deltaTime;
    }

    for (&scene.obstacles) |*obstacle| {
        obstacle.pos.x -= statics.dinoVelocity * deltaTime;
    }

    if (scene.obstacles[0].pos.x + GetObstacleSpriteRectangle(scene.obstacles[0].type).width <= 0) {
        scene.obstacles[0] = scene.obstacles[1];
        scene.obstacles[1] = scene.obstacles[2];

        const newObstacleType: statics.ObstacleType = @enumFromInt(scene.rand.random().int(u32) % @typeInfo(statics.ObstacleType).Enum.fields.len);
        const newObstacleSprite: raylib.Rectangle = GetObstacleSpriteRectangle(newObstacleType);
        var newObstacleY: f32 = 0;
        if (newObstacleType == statics.ObstacleType.Pterodactyl) {
            if (scene.rand.random().int(u32) % 2 == 0) {
                newObstacleY = 0;
            } else {
                newObstacleY = 20;
            }
        }
        scene.obstacles[2] = scene.Obstacle{
            .pos = raylib.Rectangle{ .x = scene.obstacles[1].pos.x + statics.dinoVelocity, .y = 0, .width = newObstacleSprite.width, .height = newObstacleSprite.height },
            .type = newObstacleType,
        };
    }

    const lineWidth = statics.groundTexture.width;
    if (scene.groundLines[0].x <= -lineWidth) {
        scene.groundLines[0].x = scene.groundLines[1].x;
        scene.groundLines[1].x = scene.groundLines[1].x + lineWidth;
    }

    // Jumping logic
    if (raylib.IsKeyDown(raylib.KEY_SPACE) and scene.dino.velocityUp == 0) {
        scene.dino.velocityUp = std.math.sqrt(2 * statics.gravityForce * statics.dinoJumpHeight);
    }

    scene.dino.velocityUp -= statics.gravityForce * deltaTime;
    scene.dino.pos.y += scene.dino.velocityUp * deltaTime;

    // End jump
    if (scene.dino.pos.y < 0) {
        scene.dino.pos.y = 0;
        scene.dino.velocityUp = 0;
    }
}

fn GetObstacleSpriteRectangle(obstacleType: statics.ObstacleType) raylib.Rectangle {
    switch (obstacleType) {
        statics.ObstacleType.CactusShortSingle => {
            return statics.cactus.shortSingle;
        },
        statics.ObstacleType.CactusShortDouble => {
            return statics.cactus.shortDouble;
        },
        statics.ObstacleType.CactusShortTriple => {
            return statics.cactus.shortTriple;
        },
        statics.ObstacleType.CactusHighSingle => {
            return statics.cactus.highSingle;
        },
        statics.ObstacleType.CactusHighDouble => {
            return statics.cactus.highDouble;
        },
        statics.ObstacleType.CactusHighTriple => {
            return statics.cactus.highTriple;
        },
        statics.ObstacleType.Pterodactyl => {
            if (animationBoolean) {
                return statics.pterodactyl.wingsDown;
            } else {
                return statics.pterodactyl.wingsUp;
            }
        },
    }
}

fn GetDinoSpriteRectangle(state: statics.GameState) raylib.Rectangle {
    if (state == statics.GameState.gameOver) {
        return statics.dino.dead;
    } else if (animationBoolean) {
        return statics.dino.leftStep;
    } else {
        return statics.dino.rightStep;
    }
}

fn DrawTexture(sprite: *raylib.Texture2D, spriteRect: raylib.Rectangle, destRect: raylib.Rectangle, scaleFactor: f32) void {
    var destinationGlobal = raylib.Rectangle{
        .x = destRect.x * scaleFactor,
        .y = (statics.groundY - destRect.y) * scaleFactor,
        .width = destRect.width * scaleFactor,
        .height = destRect.height * scaleFactor,
    };

    raylib.DrawTexturePro(
        sprite.*,
        spriteRect,
        destinationGlobal,
        raylib.Vector2{ .x = 0, .y = destinationGlobal.height },
        0,
        raylib.WHITE,
    );

    // destinationGlobal.y -= destinationGlobal.height;
    // raylib.DrawRectangleLinesEx(destinationGlobal, 4, raylib.RED);
}
