const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn usage(allocator: Allocator) !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var stderr = std.io.getStdErr();
    try stderr.writer().print("\nGENZIG-TREX Version 1.0.0\n\n" ++
        "USAGE:\n" ++
        " - Play the game:\n\t{s}\n" ++
        " - Watch model loaded from <filename>:\n\t{s} <filename>\n" ++
        " - Train new model and save it to <filename>:\n\t{s} train <filename> [options]\n" ++
        "   Availible options:\n" ++
        "\t -c[=2]  \tNumber of influential cacti\n" ++
        "\t -p[=1]  \tNumber of influential pterodactyls\n" ++
        "\t -s[=100]\tPopulation size\n" ++
        "\t -g[=100]\tMaximal number of generations\n\n" ++
        "AUTHORS: Piotr Kucharczyk | Borys Kurdek | Marek Mytkowski\n", .{ args[0], args[0], args[0] });
}

pub const GameMode = enum { play, watch, train };

pub const PlayParameters = void;
pub const WatchParameters = struct {
    allocator: Allocator,
    load_filename: []const u8,
};
pub const TrainParameters = struct {
    allocator: Allocator,
    save_filename: []const u8,
    influential_cacti_count: u4 = 2,
    influential_birds_count: u4 = 1,
    population_size: u32 = 100,
    max_generations: u32 = 100,
};

pub const CommandLineError = error{
    SaveFileNotSpecified,
    SaveFileSpecifiedMultipleTimes,
    OptionSpecifiedMultipleTimes,
    InvalidOption,
    InvalidOptionValue,
    NoOptionValue,
    LoadFileSpecifiedMultipleTimes,
};

pub const GameModeParameters = union(GameMode) {
    play: PlayParameters,
    watch: WatchParameters,
    train: TrainParameters,

    pub fn fromCommandLineArguments(allocator: Allocator) !GameModeParameters {
        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);

        if (args.len == 1) return .{ .play = PlayParameters{} };

        if (std.mem.eql(u8, args[1], "train")) {
            var parameters = TrainParameters{
                .allocator = allocator,
                .save_filename = undefined,
            };
            var file_specified = false;
            errdefer if (file_specified) allocator.free(parameters.save_filename);
            var c_specified = false;
            var p_specified = false;
            var s_specified = false;
            var g_specified = false;
            var arg_index: usize = 2;
            while (arg_index < args.len) {
                if (args[arg_index][0] == '-') {
                    if (args[arg_index].len > 2) return CommandLineError.InvalidOption;
                    switch (args[arg_index][1]) {
                        'c' => {
                            if (c_specified) return CommandLineError.OptionSpecifiedMultipleTimes;
                            if (arg_index + 1 >= args.len) return CommandLineError.NoOptionValue;
                            parameters.influential_cacti_count = std.fmt.parseInt(u4, args[arg_index + 1], 10) catch return CommandLineError.InvalidOptionValue;
                            c_specified = true;
                            arg_index += 2;
                        },
                        'p' => {
                            if (p_specified) return CommandLineError.OptionSpecifiedMultipleTimes;
                            if (arg_index + 1 >= args.len) return CommandLineError.NoOptionValue;
                            parameters.influential_birds_count = std.fmt.parseInt(u4, args[arg_index + 1], 10) catch return CommandLineError.InvalidOptionValue;
                            p_specified = true;
                            arg_index += 2;
                        },
                        's' => {
                            if (s_specified) return CommandLineError.OptionSpecifiedMultipleTimes;
                            if (arg_index + 1 >= args.len) return CommandLineError.NoOptionValue;
                            parameters.population_size = std.fmt.parseInt(u32, args[arg_index + 1], 10) catch return CommandLineError.InvalidOptionValue;
                            s_specified = true;
                            arg_index += 2;
                        },
                        'g' => {
                            if (g_specified) return CommandLineError.OptionSpecifiedMultipleTimes;
                            if (arg_index + 1 >= args.len) return CommandLineError.NoOptionValue;
                            parameters.max_generations = std.fmt.parseInt(u32, args[arg_index + 1], 10) catch return CommandLineError.InvalidOptionValue;
                            g_specified = true;
                            arg_index += 2;
                        },
                        else => return CommandLineError.InvalidOption,
                    }
                } else {
                    if (file_specified) return CommandLineError.SaveFileSpecifiedMultipleTimes;
                    const save_filename = try allocator.alloc(u8, args[arg_index].len);
                    std.mem.copyForwards(u8, save_filename, args[arg_index]);
                    parameters.save_filename = save_filename;
                    file_specified = true;
                    arg_index += 1;
                }
            }

            if (!file_specified) return CommandLineError.SaveFileNotSpecified;

            return .{ .train = parameters };
        }

        if (args.len == 2) {
            const load_filename = try allocator.alloc(u8, args[1].len);
            std.mem.copyForwards(u8, load_filename, args[1]);
            return .{ .watch = .{ .allocator = allocator, .load_filename = load_filename } };
        }

        return CommandLineError.LoadFileSpecifiedMultipleTimes;
    }

    pub fn deinit(self: *const GameModeParameters) void {
        switch (self.*) {
            .play => |_| {},
            .watch => |parameters| parameters.allocator.free(parameters.load_filename),
            .train => |parameters| parameters.allocator.free(parameters.save_filename),
        }
    }
};
