const enet = @import("enet.zig");
const c = @import("enet.zig").enet;
const ENet = enet.ENet;

impl: c.ENetAddress,

const Self = @This();

pub fn reverse_lookup(self: Self, api_handle: *const ENet, buffer: [:0]u8) !void {
    api_handle.validate();

    if (c.enet_address_get_host(&self.impl, buffer.ptr, buffer.len + 1) != 0) {
        return error.ENet_Address_ReverseLookup_Failure;
    }
}

pub fn resolve_dns(api_handle: *const ENet, hostname: [:0]const u8, port: u16) !Self {
    api_handle.validate();

    var address: c.ENetAddress = .{
        .host = undefined,
        .port = port,
    };

    if (c.enet_address_set_host(&address, hostname.ptr) != 0) {
        return error.ENet_Address_Lookup_Failure;
    }

    return .{ .impl = address };
}

pub fn to_string(self: Self, api_handle: *const ENet, buffer: [:0]u8) !void {
    api_handle.validate();

    if (c.enet_address_get_host_ip(&self.impl, buffer.ptr, buffer.len + 1) != 0) {
        return error.ENet_Address_Conversion_Failure;
    }
}

pub fn parse(api_handle: *const ENet, ip: [:0]const u8, port: u16) !Self {
    api_handle.validate();

    var address: c.ENetAddress = .{
        .host = undefined,
        .port = port,
    };

    if (c.enet_address_set_host_ip(&address, ip.ptr) != 0) {
        return error.ENet_Address_Invalid;
    }

    return .{ .impl = address };
}

test {
    _ = @import("tests/address.zig");
}
