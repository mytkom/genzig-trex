const raylib = @cImport(@cInclude("raylib.h"));
const statics = @import("static_consts.zig");
const std = @import("std");
const rndGen = std.rand.DefaultPrng;

pub const Dino = struct {
    pos: raylib.Rectangle,
    velocityUp: f32,
    points: f32 = 0,
};

pub const Obstacle = struct {
    pos: raylib.Rectangle,
    type: statics.ObstacleType,
};

pub const Ground = struct {
    lines: *[2]raylib.Rectangle,
};

pub const Scene = struct {
    obstacles: *[3]Obstacle,
    ground: Ground,
    dino: Dino,
};

pub var rand = rndGen.init(0);
pub var obstacles = [3]Obstacle{
    Obstacle{
        .pos = .{ .x = statics.desiredWidth, .y = 0, .width = statics.cactus.shortSingle.width, .height = statics.cactus.shortSingle.height },
        .type = statics.ObstacleType.CactusShortSingle,
    },
    Obstacle{
        .pos = .{ .x = statics.desiredWidth + statics.dinoVelocity, .y = 0, .width = statics.cactus.shortSingle.width, .height = statics.cactus.shortSingle.height },
        .type = statics.ObstacleType.CactusShortSingle,
    },
    Obstacle{
        .pos = .{ .x = statics.desiredWidth + statics.dinoVelocity * 2, .y = 0, .width = statics.cactus.shortSingle.width, .height = statics.cactus.shortSingle.height },
        .type = statics.ObstacleType.CactusShortSingle,
    },
};

pub var groundLines = [2]raylib.Rectangle{
    .{ .x = 0, .y = 0, .width = statics.groundTexture.width, .height = statics.groundTexture.height },
    .{ .x = statics.groundTexture.width, .y = 0, .width = statics.groundTexture.width, .height = statics.groundTexture.height },
};

pub var dino = Dino{
    .pos = .{ .x = statics.desiredWidth / 12, .y = 0, .width = statics.dino.standing.width, .height = statics.dino.standing.height },
    .velocityUp = 0,
};

pub fn Init() void {
    rand = rndGen.init(@as(u64, @intCast(std.time.timestamp())));

    dino = Dino{
        .pos = .{ .x = statics.desiredWidth / 12, .y = 0, .width = statics.dino.standing.width, .height = statics.dino.standing.height },
        .velocityUp = 0,
        .points = 0,
    };

    obstacles = [3]Obstacle{
        Obstacle{
            .pos = .{ .x = statics.desiredWidth, .y = 0, .width = statics.cactus.shortSingle.width, .height = statics.cactus.shortSingle.height },
            .type = statics.ObstacleType.CactusShortSingle,
        },
        Obstacle{
            .pos = .{ .x = statics.desiredWidth + statics.dinoVelocity, .y = 0, .width = statics.cactus.shortSingle.width, .height = statics.cactus.shortSingle.height },
            .type = statics.ObstacleType.CactusShortSingle,
        },
        Obstacle{
            .pos = .{ .x = statics.desiredWidth + statics.dinoVelocity * 2, .y = 0, .width = statics.cactus.shortSingle.width, .height = statics.cactus.shortSingle.height },
            .type = statics.ObstacleType.CactusShortSingle,
        },
    };

    groundLines = [2]raylib.Rectangle{
        .{ .x = 0, .y = 0, .width = statics.groundTexture.width, .height = statics.groundTexture.height },
        .{ .x = statics.groundTexture.width, .y = 0, .width = statics.groundTexture.width, .height = statics.groundTexture.height },
    };
}
