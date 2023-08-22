const std = @import("std");

const enet = @cImport({
    @cInclude("enet/enet.h");
});

var enet_handle: ENet = .{};

pub const ENet = struct {
    ref_count: u16 = 0,
    mutex: std.Thread.Mutex = .{},

    const Self = @This();

    pub fn init() !*Self {
        enet_handle.mutex.lock();
        defer enet_handle.mutex.unlock();

        if (enet_handle.ref_count == 0) {
            if (enet.enet_initialize() != 0) {
                return error.ENet_Initialization_Failure;
            }
        }

        enet_handle.ref_count += 1;

        return &enet_handle;
    }

    pub fn deinit(self: *Self) void {
        std.debug.assert(self == &enet_handle);

        enet_handle.mutex.lock();
        defer enet_handle.mutex.unlock();

        if (enet_handle.ref_count > 0) {
            enet_handle.ref_count -= 1;

            if (enet_handle.ref_count == 0) {
                enet.enet_deinitialize();
            }
        }
    }
};

test ENet {
    var handle = try ENet.init();
    defer handle.deinit();
}
