const raylib = @cImport(@cInclude("raylib.h"));
const statics = @import("static_consts.zig");
const std = @import("std");
const brn = @import("brain.zig");
const InfluentialGameState = brn.InfluentialGameState;

pub const Dino = struct {
    pos: raylib.Rectangle = .{
        .x = statics.desiredWidth / 12,
        .y = 0,
        .width = statics.dino.standing.width,
        .height = statics.dino.standing.height,
    },
    velocityUp: f32 = 0,
    isCrouching: bool = false,
    isJumping: bool = false,
    wantToJump: bool = false,
    alive: bool = true,
};

pub const Obstacle = struct {
    pos: raylib.Rectangle,
    type: statics.ObstacleType,
};

pub const Scene = struct {
    allocator: std.mem.Allocator,
    rand: std.Random,
    obstacles: []Obstacle,
    ground_lines: [2]raylib.Rectangle,
    dinos: []Dino,
    scores: []f32,
    points: f32,

    pub fn init(allocator: std.mem.Allocator, dino_count: u32, obstacle_count: u32, rand: std.Random) !Scene {
        const obstacles = try allocator.alloc(Obstacle, obstacle_count);
        errdefer allocator.free(obstacles);
        const dinos = try allocator.alloc(Dino, dino_count);
        errdefer allocator.free(dinos);
        const scores = try allocator.alloc(f32, dino_count);
        errdefer allocator.free(scores);

        for (obstacles, 0..) |*obstacle, index| {
            const new_obstacle_type: statics.ObstacleType = @enumFromInt(rand.int(u32) % @typeInfo(statics.ObstacleType).Enum.fields.len);
            const new_obstacle_sprite: raylib.Rectangle = statics.getObstacleSpriteRectangle(new_obstacle_type, false);
            var new_obstacle_y: f32 = 0;
            if (new_obstacle_type == statics.ObstacleType.Pterodactyl) {
                new_obstacle_y = statics.pterodactylHeights[rand.int(u32) % statics.pterodactylHeights.len];
            }
            const indexU32: u32 = @intCast(index);
            const indexF32: f32 = @floatFromInt(indexU32);
            obstacle.pos = .{
                .x = statics.desiredWidth + statics.dinoVelocity * indexF32,
                .y = 0,
                .width = new_obstacle_sprite.width,
                .height = new_obstacle_sprite.height,
            };
            obstacle.type = new_obstacle_type;
        }

        const ground_lines = [2]raylib.Rectangle{
            .{ .x = 0, .y = 0, .width = statics.groundTexture.width, .height = statics.groundTexture.height },
            .{ .x = statics.groundTexture.width, .y = 0, .width = statics.groundTexture.width, .height = statics.groundTexture.height },
        };

        for (dinos) |*dino| {
            dino.* = Dino{
                .pos = raylib.Rectangle{
                    .x = statics.desiredWidth / 12,
                    .y = 0,
                    .width = statics.dino.standing.width,
                    .height = statics.dino.standing.height,
                },
                .velocityUp = 0,
                .isCrouching = false,
                .isJumping = false,
                .wantToJump = false,
                .alive = true,
            };
        }

        for (scores) |*score| {
            score.* = 0;
        }

        return .{
            .allocator = allocator,
            .rand = rand,
            .obstacles = obstacles,
            .ground_lines = ground_lines,
            .dinos = dinos,
            .scores = scores,
            .points = 0,
        };
    }

    pub fn update(self: *Scene, deltaTime: f32, jump_triggered: []const bool, duck_triggered: []const bool) u32 {

        // Update obstacles
        for (&self.ground_lines) |*line| {
            line.x -= statics.dinoVelocity * deltaTime;
        }

        if (self.ground_lines[0].x <= -statics.groundTexture.width) {
            self.ground_lines[0].x = self.ground_lines[1].x;
            self.ground_lines[1].x = self.ground_lines[1].x + statics.groundTexture.width;
        }

        for (self.obstacles) |*obstacle| {
            obstacle.pos.x -= statics.dinoVelocity * deltaTime;
        }

        if (self.obstacles[0].pos.x + self.obstacles[0].pos.width <= 0) {
            for (0..self.obstacles.len - 1) |index| {
                self.obstacles[index] = self.obstacles[index + 1];
            }

            const new_obstacle_type: statics.ObstacleType = @enumFromInt(self.rand.int(u32) % @typeInfo(statics.ObstacleType).Enum.fields.len);
            const new_obstacle_sprite: raylib.Rectangle = statics.getObstacleSpriteRectangle(new_obstacle_type, false);
            var new_obstacle_y: f32 = 0;
            if (new_obstacle_type == statics.ObstacleType.Pterodactyl) {
                new_obstacle_y = statics.pterodactylHeights[self.rand.int(u32) % statics.pterodactylHeights.len];
            }

            self.obstacles[self.obstacles.len - 1] = Obstacle{
                .pos = raylib.Rectangle{
                    .x = self.obstacles[self.obstacles.len - 2].pos.x + statics.dinoVelocity,
                    .y = new_obstacle_y,
                    .width = new_obstacle_sprite.width,
                    .height = new_obstacle_sprite.height,
                },
                .type = new_obstacle_type,
            };
        }

        self.points += deltaTime * 10;

        // Update dinos
        var alive_dino_count: u32 = 0;
        for (self.dinos, jump_triggered, duck_triggered, self.scores) |*dino, is_jump_triggered, is_duck_triggered, *score| {
            if (!dino.alive) continue;

            if (is_duck_triggered) {
                dino.isCrouching = true;
                dino.pos.width = statics.dinoCrouchingWidth;
                dino.pos.height = statics.dinoCrouchingHeight;
            } else {
                dino.isCrouching = false;
                if (is_jump_triggered and !dino.isJumping) {
                    dino.velocityUp = std.math.sqrt(2 * statics.gravityForce * statics.dinoJumpHeight);
                    dino.isJumping = true;
                }
                dino.pos.width = statics.dinoStandingWidth;
                dino.pos.height = statics.dinoStandingHeight;
            }

            if (dino.isCrouching) {
                dino.velocityUp -= statics.gravityForce * deltaTime * 2;
            } else {
                dino.velocityUp -= statics.gravityForce * deltaTime;
            }
            dino.pos.y += dino.velocityUp * deltaTime;

            if (dino.pos.y < 0) {
                dino.pos.y = 0;
                dino.velocityUp = 0;
                dino.isJumping = false;
            }

            if (dino.isCrouching) {
                dino.pos.width = statics.dinoCrouchingWidth;
                dino.pos.height = statics.dinoCrouchingHeight;
            } else if (dino.isJumping) {
                dino.pos.width = statics.dinoStandingWidth;
                dino.pos.height = statics.dinoStandingHeight;
            }

            if (raylib.CheckCollisionRecs(getCollisionRec(dino.pos, statics.collisionOffset), getCollisionRec(self.obstacles[0].pos, statics.collisionOffset))) {
                dino.alive = false;
                score.* = self.points;
            } else {
                alive_dino_count += 1;
            }
        }

        return alive_dino_count;
    }

    pub fn deinit(self: *const Scene) void {
        self.allocator.free(self.dinos);
        self.allocator.free(self.scores);
        self.allocator.free(self.obstacles);
    }
};

pub fn getCollisionRec(rect: raylib.Rectangle, offset: f32) raylib.Rectangle {
    return raylib.Rectangle{
        .x = rect.x + offset,
        .y = rect.y + offset,
        .width = rect.width - 2 * offset,
        .height = rect.height - 2 * offset,
    };
}
