const std = @import("std");
const gtk = @import("gtk.zig");
const tabs = @import("tabs.zig");

const cc = gtk.cc;

const MAX_RECENT = 10;
const CONFIG_DIR = ".config/te";
const CONFIG_FILE = ".config/te/recent";

var paths: [MAX_RECENT]?[*:0]u8 = .{null} ** MAX_RECENT;
var count: usize = 0;

pub var popover_box: ?*gtk.GtkWidget = null;
pub var menu_button: ?*gtk.GtkWidget = null;

// ── Persistence ─────────────────────────────────────────────────────────────

pub fn load() void {
    const home = std.mem.span(gtk.g_get_home_dir());
    var path_buf: [512]u8 = undefined;
    const path_slice = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ home, CONFIG_FILE }) catch return;
    path_buf[path_slice.len] = 0;
    const path_z: [*:0]const u8 = @ptrCast(path_buf[0..path_slice.len :0]);

    var contents: ?[*]u8 = null;
    var length: usize = 0;
    var err: ?*gtk.GError = null;

    if (gtk.g_file_get_contents(path_z, &contents, &length, &err) == 0) {
        if (err) |e| gtk.g_error_free(e);
        return;
    }
    defer if (contents) |c| gtk.g_free(@ptrCast(c));

    const data = contents orelse return;
    const text = @as([*]const u8, @ptrCast(data))[0..length];

    var start: usize = 0;
    for (text, 0..) |byte, i| {
        if (byte == '\n') {
            if (i > start and count < MAX_RECENT) {
                const line = text[start..i];
                var line_buf: [4096]u8 = undefined;
                if (line.len < line_buf.len) {
                    @memcpy(line_buf[0..line.len], line);
                    line_buf[line.len] = 0;
                    paths[count] = gtk.g_strdup(@ptrCast(line_buf[0..line.len :0]));
                    if (paths[count] != null) count += 1;
                }
            }
            start = i + 1;
        }
    }
    if (start < text.len and count < MAX_RECENT) {
        const line = text[start..];
        var line_buf: [4096]u8 = undefined;
        if (line.len < line_buf.len) {
            @memcpy(line_buf[0..line.len], line);
            line_buf[line.len] = 0;
            paths[count] = gtk.g_strdup(@ptrCast(line_buf[0..line.len :0]));
            if (paths[count] != null) count += 1;
        }
    }
}

fn save() void {
    const home = std.mem.span(gtk.g_get_home_dir());
    var dir_buf: [512]u8 = undefined;
    const dir_slice = std.fmt.bufPrint(&dir_buf, "{s}/{s}", .{ home, CONFIG_DIR }) catch return;
    dir_buf[dir_slice.len] = 0;
    const dir_z: [*:0]const u8 = @ptrCast(dir_buf[0..dir_slice.len :0]);

    _ = gtk.g_mkdir_with_parents(dir_z, 0o755);

    var path_buf: [512]u8 = undefined;
    const path_slice = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ home, CONFIG_FILE }) catch return;
    path_buf[path_slice.len] = 0;
    const path_z: [*:0]const u8 = @ptrCast(path_buf[0..path_slice.len :0]);

    var out_buf: [4096 * MAX_RECENT]u8 = undefined;
    var pos: usize = 0;

    for (paths[0..count]) |maybe_path| {
        const p = maybe_path orelse continue;
        const span = std.mem.span(p);
        if (pos + span.len + 1 > out_buf.len) break;
        @memcpy(out_buf[pos..][0..span.len], span);
        pos += span.len;
        out_buf[pos] = '\n';
        pos += 1;
    }

    var err: ?*gtk.GError = null;
    _ = gtk.g_file_set_contents(path_z, @ptrCast(&out_buf), @intCast(pos), &err);
    if (err) |e| gtk.g_error_free(e);
}

// ── Path management ─────────────────────────────────────────────────────────

pub fn addPath(path: [*:0]const u8) void {
    const new_span = std.mem.span(path);
    if (new_span.len == 0) return;

    var existing_idx: ?usize = null;
    for (paths[0..count], 0..) |maybe_p, i| {
        const p = maybe_p orelse continue;
        if (std.mem.eql(u8, std.mem.span(p), new_span)) {
            existing_idx = i;
            break;
        }
    }

    if (existing_idx) |idx| {
        const existing = paths[idx];
        var i = idx;
        while (i > 0) : (i -= 1) {
            paths[i] = paths[i - 1];
        }
        paths[0] = existing;
    } else {
        if (count >= MAX_RECENT) {
            if (paths[MAX_RECENT - 1]) |old| gtk.g_free(@ptrCast(old));
        } else {
            count += 1;
        }
        var i = count - 1;
        while (i > 0) : (i -= 1) {
            paths[i] = paths[i - 1];
        }
        paths[0] = gtk.g_strdup(path);
    }

    save();
    rebuildPopover();
}

// ── Popover UI ──────────────────────────────────────────────────────────────

pub fn rebuildPopover() void {
    const box = popover_box orelse return;

    // Remove all existing children
    while (gtk.gtk_widget_get_first_child(box)) |child| {
        gtk.gtk_box_remove(box, child);
    }

    if (count == 0) {
        const empty_label = gtk.gtk_label_new("No recent files");
        gtk.gtk_box_append(box, empty_label);
        return;
    }

    for (paths[0..count]) |maybe_path| {
        const path = maybe_path orelse continue;
        const span = std.mem.span(path);

        // Show just the basename for the button label
        var display_buf: [256]u8 = undefined;
        const basename_start = if (std.mem.lastIndexOfScalar(u8, span, '/')) |idx| idx + 1 else 0;
        const basename = span[basename_start..];
        const display_len = @min(basename.len, display_buf.len - 1);
        @memcpy(display_buf[0..display_len], basename[0..display_len]);
        display_buf[display_len] = 0;

        const btn = gtk.gtk_button_new_with_label(@ptrCast(display_buf[0..display_len :0]));
        gtk.gtk_widget_set_size_request(btn, 250, -1);
        _ = gtk.g_signal_connect_data(
            @ptrCast(btn),
            "clicked",
            @ptrCast(&recentItemClicked),
            @ptrCast(path),
            null,
            0,
        );
        gtk.gtk_box_append(box, btn);
    }
}

fn recentItemClicked(_: *gtk.GtkWidget, data: ?*anyopaque) callconv(cc) void {
    const path: [*:0]const u8 = @ptrCast(data orelse return);
    tabs.createTab(path);
}
