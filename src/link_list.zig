const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn DoublyLinkedList(T: type) type {
    return struct {
        const Self = @This();
        first: ?*Node = null,
        last: ?*Node = null,
        allocator: Allocator,

        pub const Node = struct {
            prev: ?*Node = null,
            next: ?*Node = null,
            value: T,
        };

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .first = null,
                .last = null,
            };
        }

        pub fn deinit(self: *Self) void {
            var current = self.first;

            while (current != null) {
                const tmp_node = current.?.next;
                self.allocator.destroy(current.?);
                current = tmp_node;
            }
        }

        pub fn empty(self: Self) bool {
            return self.first == null and self.last == null;
        }

        pub fn append(self: *Self, value: T) !void {
            const new_node = try self.allocator.create(Node);
            new_node.* = .{
                .value = value,
                .prev = null,
                .next = null,
            };

            if (self.last) |last| {
                // Insert after last.
                self.insertAfter(last, new_node);
            } else {
                // Empty list.
                self.prepend(new_node);
            }
        }

        pub fn popFirst(self: *Self) ?T {
            const first = self.first orelse return null;
            self.remove(first);
            const tmp_value = first.value;
            self.allocator.destroy(first);
            return tmp_value;
        }

        pub fn remove(list: *Self, node: *Node) void {
            if (node.prev) |prev_node| {
                // Intermediate node.
                prev_node.next = node.next;
            } else {
                // First element of the list.
                list.first = node.next;
            }

            if (node.next) |next_node| {
                // Intermediate node.
                next_node.prev = node.prev;
            } else {
                // Last element of the list.
                list.last = node.prev;
            }
        }

        pub fn insertAfter(list: *Self, existing_node: *Node, new_node: *Node) void {
            new_node.prev = existing_node;
            if (existing_node.next) |next_node| {
                // Intermediate node.
                new_node.next = next_node;
                next_node.prev = new_node;
            } else {
                // Last element of the list.
                new_node.next = null;
                list.last = new_node;
            }
            existing_node.next = new_node;
        }

        pub fn prepend(list: *Self, new_node: *Node) void {
            if (list.first) |first| {
                // Insert before first.
                list.insertBefore(first, new_node);
            } else {
                // Empty list.
                list.first = new_node;
                list.last = new_node;
                new_node.prev = null;
                new_node.next = null;
            }
        }

        pub fn insertBefore(list: *Self, existing_node: *Node, new_node: *Node) void {
            new_node.next = existing_node;
            if (existing_node.prev) |prev_node| {
                // Intermediate node.
                new_node.prev = prev_node;
                prev_node.next = new_node;
            } else {
                // First element of the list.
                new_node.prev = null;
                list.first = new_node;
            }
            existing_node.prev = new_node;
        }
    };
}

test "test doubly link list" {
    var list: DoublyLinkedList(i32) = .init(std.testing.allocator);
    defer list.deinit();

    try list.append(1);
    try list.append(2);

    const one = list.popFirst();
    try std.testing.expect(one == 1);

    try list.append(3);
    try list.append(4);
    try list.append(5);

    const two = list.popFirst();
    try std.testing.expect(two == 2);

    const three = list.popFirst();
    try std.testing.expect(three == 3);
}
