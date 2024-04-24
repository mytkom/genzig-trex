const dino = @import("dino.zig");
const zigTime = @import("std").time;

pub const fp_ms = 60 * 1000_000;

const game_data = struct {
    time_ms: i64,
    dino: dino.dinosaur,
    start_time: i64,

    fn update_game_time(self: *game_data) i64 {
        var current_time = zigTime.timestamp() - self.start_time;
        var dt = current_time - self.time_ms;
        self.time_ms += dt;
        return dt;
    }

    pub fn process(game: *game_data) void {
        var dt = game.update_game_time();
        var frames_to_compute = @divFloor(dt, fp_ms);
        game.dino.process_frames(frames_to_compute);
    }

    //fn process_frames(frames_to_compute: u32) void {}
};

pub fn create_game() game_data {
    var game = game_data{
        .time_ms = 0,
        .dino = dino.create_dinosaur(),
        .start_time = zigTime.timestamp(),
    };
    return game;
}

pub fn process_game(game: game_data) void {
    var dt = game.update_game_time();
    var frames_to_compute = @divFloor(dt, fp_ms);
    game.dino.process_frames(frames_to_compute);
    //dt -= frames_to_compute * fp_ms;
}
