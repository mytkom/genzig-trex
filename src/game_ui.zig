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

pub const GameUIConfig = struct {
    sprite: raylib.Texture2D,
    width: i32,
    height: i32,
    scaleFactor: f32,
    dino: DinoTextures,
    dinoPosition: raylib.Vector2,
    groundTexture: raylib.Rectangle,
};

pub const ObstacleType = enum {
    Cactus,
    Pterodile,
};

pub const Obstacle = struct {
    rect: raylib.Rectangle,
    type: ObstacleType,
};

pub const Ground = struct {
    lines: *[2]raylib.Vector2,
};

pub const Scene = struct {
    obstacles: []Obstacle,
    ground: Ground,
};

pub const GameState = enum {
    startScreen,
    running,
    gameOver,
};

pub fn DrawUI(state: *GameState, config: *GameUIConfig, scene: *Scene) void {
    if (raylib.IsKeyDown(raylib.KEY_SPACE) and state.* == GameState.startScreen) {
        state.* = GameState.running;
    }

    switch (state.*) {
        GameState.startScreen => {
            DrawMenu(config);
        },
        GameState.running => {
            DrawScene(config, scene);
        },
        GameState.gameOver => {},
    }
}

fn DrawMenu(config: *const GameUIConfig) void {
    const destination = raylib.Rectangle{
        .x = config.dinoPosition.x,
        .y = config.dinoPosition.y,
        .width = config.dino.menuIcon.width * config.scaleFactor,
        .height = config.dino.menuIcon.height * config.scaleFactor,
    };
    raylib.DrawTexturePro(
        config.sprite,
        config.dino.menuIcon,
        destination,
        raylib.Vector2{ .x = 0, .y = 0 },
        0,
        raylib.WHITE,
    );
    raylib.DrawText(
        "Press space to play",
        @intFromFloat(config.dinoPosition.x),
        @intFromFloat(config.dinoPosition.y + (config.dino.standing.height * config.scaleFactor)),
        30,
        raylib.BLACK,
    );
}

fn DrawScene(config: *const GameUIConfig, scene: *Scene) void {
    for (scene.ground.lines) |line| {
        const groundLineDestination = raylib.Rectangle{
            .x = line.x,
            .y = line.y,
            .width = config.groundTexture.width * config.scaleFactor,
            .height = config.groundTexture.height * config.scaleFactor,
        };

        raylib.DrawTexturePro(
            config.sprite,
            config.groundTexture,
            groundLineDestination,
            raylib.Vector2{ .x = 0, .y = 0 },
            0,
            raylib.WHITE,
        );
    }

    const dinoDestination = raylib.Rectangle{
        .x = config.dinoPosition.x,
        .y = config.dinoPosition.y,
        .width = config.dino.standing.width * config.scaleFactor,
        .height = config.dino.standing.height * config.scaleFactor,
    };

    raylib.DrawTexturePro(
        config.sprite,
        config.dino.standing,
        dinoDestination,
        raylib.Vector2{ .x = 0, .y = 0 },
        0,
        raylib.WHITE,
    );
}

pub fn UpdateScene(scene: *Scene, config: *GameUIConfig, deltaTime: f32) void {
    const step: i32 = 100;

    for (scene.ground.lines) |*line| {
        line.x -= step * deltaTime;
    }

    if (scene.ground.lines[0].x <= -config.groundTexture.width * config.scaleFactor) {
        scene.ground.lines[0].x = 0;
        scene.ground.lines[1].x = config.groundTexture.width * config.scaleFactor;
    }
}
