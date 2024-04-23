const dino = @import("dino.zig");
const zigTime = @import("std").time;

const game_data = struct {
    time_ms: i64,
    dino: dino.dinosaur,
    fp_ms: i64,
    start_time: i64,

    fn update_game_time(self: *game_data) i64 {
        var current_time = zigTime.timestamp() - self.start_time;
        var dt = current_time - self.time_ms;
        self.time_ms += dt;
        return dt;
    }

    //fn process_frames(frames_to_compute: u32) void {}
};

pub fn run_game() void {
    var game = game_data{
        .time_ms = 0,
        .dino = dino.create_dinosaur(),
        .fp_ms = 30 * 1000_000,
        .start_time = zigTime.timestamp(),
    };

    while (true) {
        var dt = game.update_game_time();
        var frames_to_compute = @divFloor(dt, game.fp_ms);
        dt -= frames_to_compute * game.fp_ms;
    }
}
