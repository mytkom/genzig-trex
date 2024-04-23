const raylib = @cImport(@cInclude("raylib.h"));
const zigTime = @import("std").time;
const fp_ms = @import("game.zig").fp_ms;

const jump_height = 100;
const jump_time = 3 * 1000_000;
const jump_dist_frame = jump_height * fp_ms / jump_time;
const dino_speed = 1;

const jump = struct { jump_start_time: i64, is_jumping: bool };

pub const dinosaur = struct {
    position: raylib.Vector2,
    height: i32,
    width: i32,
    jump: jump,
    ducking: bool,
    fn do_jump(self: *dinosaur) void {
        self.jump.is_jumping = true;
        self.jump.jump_start_time = zigTime.timestamp();
    }
    fn do_duck(self: *dinosaur) void {
        self.ducking = true;
    }

    fn move_right(self: *dinosaur, frames_to_process: i32) void {
        self.position.x += frames_to_process * dino_speed;
    }
    fn move_up(self: *dinosaur, frames_to_process: i32) void {
        self.position.y += frames_to_process * jump_dist_frame;
    }

    fn move_down(self: *dinosaur, frames_to_process: i32) void {
        self.position.y -= frames_to_process * jump_dist_frame;
    }

    fn process_jump(self: *dinosaur, frames_to_process: i32) void {
        if (self.jump.is_jumping == false) return;

        var current_jump_time = zigTime.timestamp() - self.jump.jump_start_time;
        if (current_jump_time > jump_time) {
            self.jump.is_jumping = false;
            self.position.y = 0;
            return;
        } else if (current_jump_time < jump_time) {
            move_up(self, frames_to_process);
        } else {
            move_down(self, frames_to_process);
        }
    }
};

pub fn create_dinosaur() dinosaur {
    var dino = dinosaur{
        .position = raylib.Vector2{ .x = 0, .y = 0 },
        .height = 100,
        .width = 10,
        .ducking = false,
        .jump = jump{ .jump_start_time = 0, .is_jumping = false },
    };
    return dino;
}

pub fn do_jump(dino: dinosaur) void {
    dino.jumping = true;
}

pub fn do_duck(dino: dinosaur) void {
    dino.ducking = true;
}
