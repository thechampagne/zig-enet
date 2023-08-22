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

    /// It is safe to call this function without initializing ENet.
    pub fn get_version() enet.ENetVersion {
        return enet.ENET_VERSION;
    }

    pub fn deinit(self: *Self) void {
        // There is only one valid pointer value for the handle; the one declared in this library.
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

fn enet_malloc_testfn(size: usize) callconv(.C) ?*anyopaque {
    _ = size;
    return null;
}

test ENet {
    {
    var handle = try ENet.init();
    defer handle.deinit();
        var handle2 = try ENet.init();
        defer handle2.deinit();

        try std.testing.expect(handle == handle2);
    }

    try std.testing.expect(enet_handle.ref_count == 0);

    {
        var handle3 = try ENet.init_callbacks(
            enet.ENET_VERSION_CREATE(1, 3, 0),
            &.{
                .malloc = null,
                .free = null,
                .no_memory = null,
            },
        );
        defer handle3.deinit();
    }

    try std.testing.expect(enet_handle.ref_count == 0);

    try std.testing.expectError(
        ENet.InitError.ENet_Initialization_Failure,
        ENet.init_callbacks(
            enet.ENET_VERSION_CREATE(1, 3, 0),
            &.{
                // NOTE: Possible Zig bug: setting malloc or free to undefined instead of an actual
                // function will cause the other function to also become undefined if it was set as
                // null
                .malloc = &enet_malloc_testfn,
                .free = null,
                .no_memory = undefined,
            },
        ),
    );

    {
        var handle4 = try ENet.init();
        defer handle4.deinit();

        try std.testing.expectError(
            ENet.InitError.ENet_Already_Initialized,
            ENet.init_callbacks(
                enet.ENET_VERSION_CREATE(1, 3, 0),
                undefined,
            ),
        );
    }
}

// TODO: add multithread test for ENet struct
