const std = @import("std");

const mem = std.mem;
const testing = std.testing;

const ENet = @import("../enet.zig").ENet;
const Address = @import("../address.zig");

test "Address.parse" {
    const api_handle = try ENet.init();
    defer api_handle.deinit();

    {
        const localhost_enet = try Address.parse(api_handle, "127.0.0.1", 25575);

        const localhost = mem.nativeToBig(u32, (127 << 24) + 1);

        try testing.expectEqual(localhost, localhost_enet.impl.host);
    }
}

test "Address.to_string" {
    const api_handle = try ENet.init();
    defer api_handle.deinit();

    const localhost = mem.nativeToBig(u32, (127 << 24) + 1);
    {
        const localhost_enet: Address = .{
            .impl = .{
                .host = localhost,
                .port = undefined,
            },
        };

        var buffer: [15:0]u8 = undefined;
        try localhost_enet.to_string(api_handle, &buffer);

        // std.mem.span used to ensure the length ends at the zero terminator
        try testing.expectEqualStrings("127.0.0.1", mem.span(@as([*:0]const u8, &buffer)));
    }
}

test "Address.resolve_dns" {
    const api_handle = try ENet.init();
    defer api_handle.deinit();

    // 1.1.1.1
    const warp_ip_primary = mem.nativeToBig(u32, (1 << 24) + (1 << 16) + (1 << 8) + 1);

    {
        // Cloudflare 1.1.1.1 (WARP)
        const warp = try Address.resolve_dns(api_handle, "one.one.one.one", 0);

        // 1.0.0.1; DNS resolution could result in either one
        const warp_ip_secondary = mem.nativeToBig(u32, (1 << 24) + 1);

        try testing.expect(
            warp.impl.host == warp_ip_primary or
                warp.impl.host == warp_ip_secondary,
        );
    }
}

test "Address.reverse_lookup" {
    const api_handle = try ENet.init();
    defer api_handle.deinit();

    // 1.1.1.1
    const warp_ip_primary = mem.nativeToBig(u32, (1 << 24) + (1 << 16) + (1 << 8) + 1);

    {
        const warp: Address = .{
            .impl = .{
                .host = warp_ip_primary,
                .port = undefined,
            },
        };

        var buffer: [15:0]u8 = undefined;

        try warp.reverse_lookup(api_handle, &buffer);

        try testing.expectEqualStrings("one.one.one.one", mem.span(@as([*:0]const u8, &buffer)));
    }
}
