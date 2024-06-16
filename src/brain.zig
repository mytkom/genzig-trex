const std = @import("std");
const Allocator = std.mem.Allocator;
const Random = std.Random;

pub const InfluentialGameState = struct {
    allocator: Allocator,
    dino_velocity_x: f32,
    dino_velocity_y: f32,
    cactus_offset_x: []f32,
    cactus_width: []f32,
    cactus_height: []f32,
    bird_offset_x: []f32,
    bird_offset_y: []f32,

    pub fn init(allocator: Allocator, cacti_count: u4, birds_count: u4) !InfluentialGameState {
        const cactus_offset_x = try allocator.alloc(f32, cacti_count);
        const cactus_width = try allocator.alloc(f32, cacti_count);
        const cactus_height = try allocator.alloc(f32, cacti_count);
        const bird_offset_x = try allocator.alloc(f32, birds_count);
        const bird_offset_y = try allocator.alloc(f32, birds_count);

        return .{
            .allocator = allocator,
            .dino_velocity_x = 0.0,
            .dino_velocity_y = 0.0,
            .cactus_offset_x = cactus_offset_x,
            .cactus_width = cactus_width,
            .cactus_height = cactus_height,
            .bird_offset_x = bird_offset_x,
            .bird_offset_y = bird_offset_y,
        };
    }

    pub fn deinit(self: *const InfluentialGameState) void {
        self.allocator.free(self.cactus_offset_x);
        self.allocator.free(self.cactus_width);
        self.allocator.free(self.cactus_height);
        self.allocator.free(self.bird_offset_x);
        self.allocator.free(self.bird_offset_y);
    }
};

pub const GeneticBrainError = error{
    CorruptedData,
    TooLargeInfluenceParameters,
};

pub const GeneticBrain = struct {
    allocator: Allocator,
    influential_cacti_count: u4,
    influential_birds_count: u4,
    jump_chromosome: []f32,
    duck_chromosome: []f32,

    pub fn init(brain: GeneticBrain) !GeneticBrain {
        const jump_chromosome = try brain.allocator.alloc(f32, brain.jump_chromosome.len);
        errdefer brain.allocator.free(jump_chromosome);
        const duck_chromosome = try brain.allocator.alloc(f32, brain.duck_chromosome.len);
        errdefer brain.allocator.free(duck_chromosome);

        return .{
            .allocator = brain.allocator,
            .influential_cacti_count = brain.influential_cacti_count,
            .influential_birds_count = brain.influential_birds_count,
            .jump_chromosome = jump_chromosome,
            .duck_chromosome = duck_chromosome,
        };
    }

    pub fn copyFrom(dst: *const GeneticBrain, src: *const GeneticBrain) void {
        for (dst.jump_chromosome, src.jump_chromosome) |*gene, brain_gene| {
            gene.* = brain_gene;
        }
        for (dst.duck_chromosome, src.duck_chromosome) |*gene, brain_gene| {
            gene.* = brain_gene;
        }
    }

    pub fn load(filename: []const u8, allocator: Allocator) !GeneticBrain {
        var file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();
        var encoded_infulential_counts: u8 = 0;
        var bytes_read = try file.read(std.mem.asBytes(&encoded_infulential_counts));
        if (bytes_read != 1) return GeneticBrainError.CorruptedData;
        const influential_cacti_count: u4 = @truncate(encoded_infulential_counts >> 4);
        const influential_birds_count: u4 = @truncate(encoded_infulential_counts);

        const powerOf2 = 2 + 3 * @as(u8, influential_cacti_count) + 2 * @as(u8, influential_birds_count);
        if (powerOf2 >= @bitSizeOf(usize)) return GeneticBrainError.TooLargeInfluenceParameters;
        const chromosome_length = @as(usize, 1) << @truncate(powerOf2);
        const jump_chromosome = try allocator.alloc(f32, chromosome_length);
        errdefer allocator.free(jump_chromosome);
        const duck_chromosome = try allocator.alloc(f32, chromosome_length);
        errdefer allocator.free(duck_chromosome);

        bytes_read = try file.read(std.mem.sliceAsBytes(jump_chromosome));
        if (bytes_read != @sizeOf(f32) * chromosome_length) return GeneticBrainError.CorruptedData;
        bytes_read = try file.read(std.mem.sliceAsBytes(duck_chromosome));
        if (bytes_read != @sizeOf(f32) * chromosome_length) return GeneticBrainError.CorruptedData;

        return .{
            .influential_cacti_count = influential_cacti_count,
            .influential_birds_count = influential_birds_count,
            .allocator = allocator,
            .jump_chromosome = jump_chromosome,
            .duck_chromosome = duck_chromosome,
        };
    }

    pub fn generateRandom(rand: Random, allocator: Allocator, influential_cacti_count: u4, influential_birds_count: u4) !GeneticBrain {
        const powerOf2 = 2 + 3 * @as(u8, influential_cacti_count) + 2 * @as(u8, influential_birds_count);
        if (powerOf2 >= @bitSizeOf(usize)) return GeneticBrainError.TooLargeInfluenceParameters;
        const chromosome_length = @as(usize, 1) << @truncate(powerOf2);
        const jump_chromosome = try allocator.alloc(f32, chromosome_length);
        errdefer allocator.free(jump_chromosome);
        const duck_chromosome = try allocator.alloc(f32, chromosome_length);
        errdefer allocator.free(duck_chromosome);

        for (jump_chromosome) |*gene| {
            gene.* = 2 * rand.float(f32) - 1;
        }
        for (duck_chromosome) |*gene| {
            gene.* = 2 * rand.float(f32) - 1;
        }

        return .{
            .allocator = allocator,
            .influential_cacti_count = influential_cacti_count,
            .influential_birds_count = influential_birds_count,
            .jump_chromosome = jump_chromosome,
            .duck_chromosome = duck_chromosome,
        };
    }

    pub fn shouldJump(self: *const GeneticBrain, game_state: *const InfluentialGameState) bool {
        return evalDecisionPolynomial(self.jump_chromosome, game_state, self.influential_cacti_count, self.influential_birds_count) > 0.0;
    }

    pub fn shouldDuck(self: *const GeneticBrain, game_state: *const InfluentialGameState) bool {
        return evalDecisionPolynomial(self.duck_chromosome, game_state, self.influential_cacti_count, self.influential_birds_count) > 0.0;
    }

    fn evalDecisionPolynomial(coefficients: []f32, game_state: *const InfluentialGameState, cacti_count: u4, birds_count: u4) f32 {
        var sum: f32 = 0.0;
        for (coefficients, 0..) |a, i| {
            var monomial = a;
            var mask: usize = 0b1;
            if ((i & mask) != 0) monomial *= game_state.dino_velocity_x;
            mask <<= 1;
            if ((i & mask) != 0) monomial *= game_state.dino_velocity_y;
            mask <<= 1;
            for (0..cacti_count) |cactus_index| {
                if ((i & mask) != 0) monomial *= game_state.cactus_offset_x[cactus_index];
                mask <<= 1;
                if ((i & mask) != 0) monomial *= game_state.cactus_width[cactus_index];
                mask <<= 1;
                if ((i & mask) != 0) monomial *= game_state.cactus_height[cactus_index];
                mask <<= 1;
            }
            for (0..birds_count) |bird_index| {
                if ((i & mask) != 0) monomial *= game_state.bird_offset_x[bird_index];
                mask <<= 1;
                if ((i & mask) != 0) monomial *= game_state.bird_offset_y[bird_index];
                mask <<= 1;
            }
            sum += monomial;
        }
        return sum;
    }

    pub fn save(self: *const GeneticBrain, filename: []const u8) !void {
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();
        const encoded_infulential_counts = (@as(u8, self.influential_cacti_count) << 4) + self.influential_birds_count;
        try file.writeAll(std.mem.asBytes(&encoded_infulential_counts));
        try file.writeAll(std.mem.sliceAsBytes(self.jump_chromosome));
        try file.writeAll(std.mem.sliceAsBytes(self.duck_chromosome));
    }

    pub fn deinit(self: GeneticBrain) void {
        self.allocator.free(self.jump_chromosome);
        self.allocator.free(self.duck_chromosome);
    }
};
