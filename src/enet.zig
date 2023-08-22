const std = @import("std");

const enet = @cImport({
    @cInclude("enet/enet.h");
});

var enet_handle: ENet = .{};

pub const ENet = struct {
    ref_count: u16 = 0,
    mutex: std.Thread.Mutex = .{},

    // TODO: put these in a helper struct for enet.ENetCallbacks instead
    pub const MallocFn = ?*const fn (usize) callconv(.C) ?*anyopaque;
    pub const FreeFn = ?*const fn (?*anyopaque) callconv(.C) void;
    pub const MoNemFn = ?*const fn () callconv(.C) void;

    pub const InitError = error{ ENet_Initialization_Failure, ENet_Already_Initialized };

    const Self = @This();

    pub fn init() InitError!*Self {
        enet_handle.mutex.lock();
        defer enet_handle.mutex.unlock();

        if (enet_handle.ref_count == 0) {
            if (enet.enet_initialize() != 0) {
                return InitError.ENet_Initialization_Failure;
            }
        }

        enet_handle.ref_count += 1;

        return &enet_handle;
    }

    /// This function will error if ENet is already initialized.
    /// TODO: provide a structure for setting ENetCallbacks from the user's choice of allocator
    pub fn init_callbacks(
        version: enet.ENetVersion,
        inits: *const enet.ENetCallbacks,
    ) InitError!*Self {
        enet_handle.mutex.lock();
        defer enet_handle.mutex.unlock();

        if (enet_handle.ref_count > 0) {
            return InitError.ENet_Already_Initialized;
        }

        if (enet.enet_initialize_with_callbacks(version, inits) != 0) {
            return InitError.ENet_Initialization_Failure;
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
