const raylib = @cImport(@cInclude("raylib.h"));
const statics = @import("static_consts.zig");
const scene = @import("scene.zig");
const std = @import("std");

var animationBoolean: bool = false;
var animationDeltaTime: f32 = 0;
pub var drawColissionRectangles: bool = false;

pub fn DrawUI(allocator: *const std.mem.Allocator, state: *statics.GameState, sprite: *raylib.Texture2D, deltaTime: f32, scaleFactor: f32) !void {
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
                scene.Init();
            }
        },
        statics.GameState.running => {
            UpdateScene(deltaTime);
            if (raylib.CheckCollisionRecs(
                GetCollisionRec(scene.dino.pos, statics.collisionOffset),
                GetCollisionRec(scene.obstacles[0].pos, statics.collisionOffset),
            )) {
                state.* = statics.GameState.gameOver;
            }
            try DrawScene(allocator, sprite, state.*, scaleFactor);
        },
        statics.GameState.gameOver => {
            try DrawScene(allocator, sprite, state.*, scaleFactor);
            DrawGameOver(scaleFactor);

            if (raylib.IsKeyDown(raylib.KEY_SPACE)) {
                state.* = statics.GameState.running;
                scene.Init();
            }
        },
    }
}

fn GetCollisionRec(rect: raylib.Rectangle, offset: f32) raylib.Rectangle {
    return raylib.Rectangle{
        .x = rect.x + offset,
        .y = rect.y + offset,
        .width = rect.width - 2 * offset,
        .height = rect.height - 2 * offset,
    };
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

fn DrawScene(allocator: *const std.mem.Allocator, sprite: *raylib.Texture2D, state: statics.GameState, scaleFactor: f32) !void {
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

    const dinoSprite = GetDinoSpriteRectangle(state);
    scene.dino.pos.width = dinoSprite.width;
    scene.dino.pos.height = dinoSprite.height;

    DrawTexture(
        sprite,
        dinoSprite,
        scene.dino.pos,
        scaleFactor,
    );

    var text = try std.fmt.allocPrintZ(
        allocator.*,
        "Points: {d}",
        .{@as(u32, @intFromFloat(scene.dino.points))},
    );
    defer allocator.free(text);

    raylib.DrawText(
        @as([*:0]const u8, text),
        @intFromFloat(statics.desiredWidth * scaleFactor * 0.95),
        @intFromFloat(statics.desiredHeight * scaleFactor * 0.1),
        25,
        raylib.BLACK,
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
    if (raylib.IsKeyDown(raylib.KEY_DOWN)) {
        scene.dino.isCrouching = true;
    } else {
        scene.dino.isCrouching = false;
        if (raylib.IsKeyDown(raylib.KEY_SPACE) or raylib.IsKeyDown(raylib.KEY_UP)) {
            scene.dino.wantToJump = true;
        } else {
            scene.dino.wantToJump = false;
        }
    }

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
            newObstacleY = statics.pterodactylHeights[scene.rand.random().int(u32) % statics.pterodactylHeights.len];
        }
        scene.obstacles[2] = scene.Obstacle{
            .pos = raylib.Rectangle{ .x = scene.obstacles[1].pos.x + statics.dinoVelocity, .y = newObstacleY, .width = newObstacleSprite.width, .height = newObstacleSprite.height },
            .type = newObstacleType,
        };
    }

    const lineWidth = statics.groundTexture.width;
    if (scene.groundLines[0].x <= -lineWidth) {
        scene.groundLines[0].x = scene.groundLines[1].x;
        scene.groundLines[1].x = scene.groundLines[1].x + lineWidth;
    }

    // Jumping logic
    if (scene.dino.wantToJump and !scene.dino.isJumping) {
        scene.dino.velocityUp = std.math.sqrt(2 * statics.gravityForce * statics.dinoJumpHeight);
        scene.dino.isJumping = true;
    }

    scene.dino.velocityUp -= statics.gravityForce * deltaTime;
    if (scene.dino.isCrouching) {
        scene.dino.velocityUp -= statics.gravityForce * deltaTime;
    }
    scene.dino.pos.y += scene.dino.velocityUp * deltaTime;

    // End jump
    if (scene.dino.pos.y < 0) {
        scene.dino.pos.y = 0;
        scene.dino.velocityUp = 0;
        scene.dino.isJumping = false;
    }

    scene.dino.points += deltaTime * 10.0;
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
    } else if (scene.dino.isJumping) {
        if (scene.dino.isCrouching) {
            return statics.dino.crouchLeftStep;
        } else {
            return statics.dino.standing;
        }
    } else if (scene.dino.isCrouching) {
        if (animationBoolean) {
            return statics.dino.crouchLeftStep;
        } else {
            return statics.dino.crouchRightStep;
        }
    } else {
        if (animationBoolean) {
            return statics.dino.leftStep;
        } else {
            return statics.dino.rightStep;
        }
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

    if (drawColissionRectangles and destinationGlobal.width < statics.desiredWidth * scaleFactor) {
        destinationGlobal.y -= destinationGlobal.height;
        raylib.DrawRectangleLinesEx(
            GetCollisionRec(destinationGlobal, statics.collisionOffset * scaleFactor),
            4,
            raylib.RED,
        );
    }
}
