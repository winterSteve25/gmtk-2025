const std = @import("std");

pub fn ObjectPool(comptime T: type) type {
    return struct {
        arr: std.ArrayList(T),
        active_items: std.ArrayList(*T),
        free_items: std.ArrayList(usize),
        constructor: *const fn () T,
        enabler: *const fn (this: *T) void,
        disabler: *const fn (this: *T) void,

        pub fn init(
            allocator: std.mem.Allocator,
            default_len: usize,
            con: *const fn () T,
            ena: *const fn (this: *T) void,
            dis: *const fn (this: *T) void,
        ) !@This() {
            var arr = try std.ArrayList(T).initCapacity(allocator, default_len);
            var frees = try std.ArrayList(usize).initCapacity(allocator, default_len);
            const actives = std.ArrayList(*T).init(allocator);

            for (0..default_len) |_| {
                arr.appendAssumeCapacity(con());
            }

            for (0..default_len) |i| {
                frees.appendAssumeCapacity(i);
            }

            return .{
                .arr = arr,
                .active_items = actives,
                .free_items = frees,
                .constructor = con,
                .enabler = ena,
                .disabler = dis,
            };
        }

        pub fn deinit(this: *@This()) void {
            this.arr.deinit();
            this.active_items.deinit();
            this.free_items.deinit();
        }

        pub fn get(this: *@This()) !*T {
            if (this.free_items.items.len > 0) {
                // Reuse a previously freed object
                const index: usize = this.free_items.pop() orelse unreachable;
                const item = &this.arr.items[index];
                try this.active_items.append(item);
                this.enabler(item);
                return item;
            } else {
                // Add a new object to the pool
                try this.arr.append(this.constructor());
                const item = &this.arr.items[this.arr.items.len - 1];
                try this.active_items.append(item);
                this.enabler(item);
                return item;
            }
        }

        pub fn free(this: *@This(), obj: *T) !void {
            const base_ptr = this.arr.items.ptr;
            const index = @intFromPtr(obj) - @intFromPtr(base_ptr);
            const element_size = @sizeOf(T);
            const idx = index / element_size;
            try this.free_items.append(idx);
            this.disabler(obj);
            const active_idx = findIndex(this.active_items.items, obj) orelse unreachable;
            _ = this.active_items.orderedRemove(active_idx);
        }

        fn findIndex(slice: []const *T, value: *T) ?usize {
            for (slice, 0..) |v, i| {
                if (v == value) return i;
            }
            return null;
        }
    };
}

const testing = std.testing;

const MyObject = struct {
    id: usize,
    enabled: bool,
};

fn constructor() MyObject {
    return MyObject{ .id = 0, .enabled = false };
}

fn enabler(obj: *MyObject) void {
    obj.enabled = true;
}

fn disabler(obj: *MyObject) void {
    obj.enabled = false;
}

test "ObjectPool basic usage" {
    const allocator = testing.allocator;
    var pool = try ObjectPool(MyObject).init(allocator, 4, constructor, enabler, disabler);
    defer pool.deinit();

    // Get one object
    var obj1 = try pool.get();
    try testing.expect(obj1.enabled == true);

    obj1.id = 42;

    // Free the object
    try pool.free(obj1);
    try testing.expect(obj1.enabled == false);

    // Get again — should reuse the same object
    const obj2 = try pool.get();
    try testing.expect(obj2 == obj1);
    try testing.expect(obj2.enabled == true);
    try testing.expect(obj2.id == 42); // Data should persist

    // Free again
    try pool.free(obj2);

    // Fill up pool with new items
    var objs: [4]*MyObject = undefined;
    for (0..4) |i| {
        objs[i] = try pool.get();
        objs[i].id = i;
    }

    // All should be enabled
    for (objs) |o| {
        try testing.expect(o.enabled);
    }

    // Free all
    for (objs) |o| {
        try pool.free(o);
        try testing.expect(o.enabled == false);
    }
}

test "ObjectPool tracks active_items correctly" {
    const allocator = testing.allocator;

    var pool = try ObjectPool(MyObject).init(allocator, 3, constructor, enabler, disabler);
    defer pool.deinit();

    try testing.expect(pool.active_items.items.len == 0);

    const a = try pool.get();
    try testing.expect(pool.active_items.items.len == 1);
    try testing.expect(pool.active_items.items[0] == a);

    const b = try pool.get();
    try testing.expect(pool.active_items.items.len == 2);
    try testing.expect(pool.active_items.items[1] == b);

    // Free one item
    try pool.free(a);
    try testing.expect(pool.active_items.items.len == 1);
    try testing.expect(pool.active_items.items[0] == b);

    // Free the other item
    try pool.free(b);
    try testing.expect(pool.active_items.items.len == 0);
}
