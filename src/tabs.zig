const std = @import("std");
const gtk = @import("gtk.zig");
const recent = @import("recent.zig");

const cc = gtk.cc;
const GtkWidget = gtk.GtkWidget;
const GtkTextBuffer = gtk.GtkTextBuffer;
const GtkTextIter = gtk.GtkTextIter;
const GError = gtk.GError;

// ── Per-tab state ───────────────────────────────────────────────────────────

pub const TabInfo = struct {
    scrolled: *GtkWidget,
    buffer: *GtkTextBuffer,
    file_path: ?[*:0]u8,
    label: *GtkWidget,
};

pub const MAX_TABS = 64;
pub var tabs: [MAX_TABS]TabInfo = undefined;
pub var tab_count: usize = 0;
pub var notebook_widget: ?*GtkWidget = null;
pub var main_window: ?*GtkWidget = null;

// ── Tab helpers ─────────────────────────────────────────────────────────────

pub fn currentTab() ?*TabInfo {
    const nb = notebook_widget orelse return null;
    const page = gtk.gtk_notebook_get_current_page(nb);
    if (page < 0) return null;
    const child = gtk.gtk_notebook_get_nth_page(nb, page) orelse return null;
    for (tabs[0..tab_count]) |*t| {
        if (t.scrolled == child) return t;
    }
    return null;
}

pub fn tabName(tab: *const TabInfo) [*:0]const u8 {
    if (tab.file_path) |f| {
        const full = std.mem.span(f);
        if (std.mem.lastIndexOfScalar(u8, full, '/')) |idx| {
            return @ptrCast(full.ptr + idx + 1);
        }
        return f;
    }
    return "untitled";
}

pub fn updateTabLabel(tab: *const TabInfo) void {
    const name = std.mem.span(tabName(tab));
    const modified = gtk.gtk_text_buffer_get_modified(tab.buffer) != 0;
    const suffix: []const u8 = if (modified) " \xe2\x97\x8f" else "";
    const name_len = @min(name.len, 250 - suffix.len);

    var buf: [256]u8 = undefined;
    @memcpy(buf[0..name_len], name[0..name_len]);
    @memcpy(buf[name_len..][0..suffix.len], suffix);
    buf[name_len + suffix.len] = 0;

    gtk.gtk_label_set_text(tab.label, @ptrCast(&buf));
}

// ── Title management ────────────────────────────────────────────────────────

pub fn updateTitle() void {
    const win = main_window orelse return;
    const tab = currentTab() orelse {
        gtk.gtk_window_set_title(win, "te");
        return;
    };
    const modified = gtk.gtk_text_buffer_get_modified(tab.buffer) != 0;
    const name = std.mem.span(tabName(tab));

    const prefix = "te - ";
    const suffix: []const u8 = if (modified) " [modified]" else "";
    const name_len = @min(name.len, 490 - prefix.len - suffix.len);

    var title: [500]u8 = undefined;
    @memcpy(title[0..prefix.len], prefix);
    @memcpy(title[prefix.len..][0..name_len], name[0..name_len]);
    @memcpy(title[prefix.len + name_len ..][0..suffix.len], suffix);
    title[prefix.len + name_len + suffix.len] = 0;

    gtk.gtk_window_set_title(win, @ptrCast(&title));
}

// ── File I/O ────────────────────────────────────────────────────────────────

pub fn loadFileIntoTab(tab: *TabInfo, path: [*:0]const u8) void {
    var contents: ?[*]u8 = null;
    var length: usize = 0;
    var err: ?*GError = null;

    if (gtk.g_file_get_contents(path, &contents, &length, &err) != 0) {
        if (contents) |c| {
            gtk.gtk_text_buffer_set_text(tab.buffer, c, @intCast(length));
        } else {
            gtk.gtk_text_buffer_set_text(tab.buffer, "", 0);
        }
        gtk.gtk_text_buffer_set_modified(tab.buffer, 0);
        if (contents) |c| gtk.g_free(@ptrCast(c));

        if (tab.file_path) |old| gtk.g_free(@ptrCast(old));
        tab.file_path = gtk.g_strdup(path);
        updateTabLabel(tab);
        updateTitle();
        recent.addPath(path);
    } else {
        if (err) |e| gtk.g_error_free(e);
    }
}

pub fn saveToFile(path: [*:0]const u8) void {
    const tab = currentTab() orelse return;

    var start: GtkTextIter = .{};
    var end_iter: GtkTextIter = .{};
    gtk.gtk_text_buffer_get_start_iter(tab.buffer, &start);
    gtk.gtk_text_buffer_get_end_iter(tab.buffer, &end_iter);

    const text = gtk.gtk_text_buffer_get_text(tab.buffer, &start, &end_iter, 0) orelse return;
    defer gtk.g_free(@ptrCast(text));

    const text_len: isize = @intCast(std.mem.span(text).len);
    var err: ?*GError = null;

    if (gtk.g_file_set_contents(path, text, text_len, &err) != 0) {
        gtk.gtk_text_buffer_set_modified(tab.buffer, 0);
        if (tab.file_path) |old| gtk.g_free(@ptrCast(old));
        tab.file_path = gtk.g_strdup(path);
        updateTabLabel(tab);
        updateTitle();
        recent.addPath(path);
    } else {
        if (err) |e| gtk.g_error_free(e);
    }
}

// ── Tab management ──────────────────────────────────────────────────────────

pub fn createTab(file_path: ?[*:0]const u8) void {
    if (tab_count >= MAX_TABS) return;
    const nb = notebook_widget orelse return;

    const text_view = gtk.gtk_text_view_new();
    gtk.gtk_text_view_set_monospace(text_view, 1);
    gtk.gtk_text_view_set_wrap_mode(text_view, gtk.GTK_WRAP_WORD_CHAR);
    gtk.gtk_text_view_set_top_margin(text_view, 6);
    gtk.gtk_text_view_set_bottom_margin(text_view, 6);
    gtk.gtk_text_view_set_left_margin(text_view, 6);
    gtk.gtk_text_view_set_right_margin(text_view, 6);

    const buf = gtk.gtk_text_view_get_buffer(text_view);
    _ = gtk.g_signal_connect_data(@ptrCast(buf), "modified-changed", @ptrCast(&modifiedChangedCb), null, null, 0);

    const scrolled = gtk.gtk_scrolled_window_new();
    gtk.gtk_scrolled_window_set_child(scrolled, text_view);
    gtk.gtk_widget_set_vexpand(scrolled, 1);
    gtk.gtk_widget_set_hexpand(scrolled, 1);

    const label = gtk.gtk_label_new("untitled");
    const close_btn = gtk.gtk_button_new_with_label("\xc3\x97");
    _ = gtk.g_signal_connect_data(@ptrCast(close_btn), "clicked", @ptrCast(&closeButtonCb), @ptrCast(scrolled), null, 0);

    const hbox = gtk.gtk_box_new(gtk.GTK_ORIENTATION_HORIZONTAL, 4);
    gtk.gtk_box_append(hbox, label);
    gtk.gtk_box_append(hbox, close_btn);

    // Store tab before appending to notebook (switch-page signal may fire)
    tabs[tab_count] = .{
        .scrolled = scrolled,
        .buffer = buf,
        .file_path = null,
        .label = label,
    };
    tab_count += 1;

    const page_idx = gtk.gtk_notebook_append_page(nb, scrolled, hbox);
    gtk.gtk_notebook_set_tab_reorderable(nb, scrolled, 1);

    if (file_path) |path| {
        loadFileIntoTab(&tabs[tab_count - 1], path);
    }

    if (page_idx >= 0) {
        gtk.gtk_notebook_set_current_page(nb, page_idx);
    }

    updateTitle();
}

pub fn closeTab(page_index: c_int) void {
    const nb = notebook_widget orelse return;
    const child = gtk.gtk_notebook_get_nth_page(nb, page_index) orelse return;

    var tab_idx: ?usize = null;
    for (tabs[0..tab_count], 0..) |t, i| {
        if (t.scrolled == child) {
            tab_idx = i;
            break;
        }
    }
    const idx = tab_idx orelse return;

    if (tabs[idx].file_path) |old| gtk.g_free(@ptrCast(old));
    gtk.gtk_notebook_remove_page(nb, page_index);

    var i = idx;
    while (i + 1 < tab_count) : (i += 1) {
        tabs[i] = tabs[i + 1];
    }
    tab_count -= 1;

    if (tab_count == 0) {
        createTab(null);
    } else {
        updateTitle();
    }
}

pub fn doCloseCurrentTab() void {
    const nb = notebook_widget orelse return;
    const page = gtk.gtk_notebook_get_current_page(nb);
    if (page >= 0) closeTab(page);
}

pub fn switchToNextTab() void {
    const nb = notebook_widget orelse return;
    const n = gtk.gtk_notebook_get_n_pages(nb);
    if (n <= 1) return;
    const cur = gtk.gtk_notebook_get_current_page(nb);
    gtk.gtk_notebook_set_current_page(nb, if (cur + 1 >= n) 0 else cur + 1);
}

pub fn switchToPrevTab() void {
    const nb = notebook_widget orelse return;
    const n = gtk.gtk_notebook_get_n_pages(nb);
    if (n <= 1) return;
    const cur = gtk.gtk_notebook_get_current_page(nb);
    gtk.gtk_notebook_set_current_page(nb, if (cur <= 0) n - 1 else cur - 1);
}

// ── Tab-internal callbacks ──────────────────────────────────────────────────

pub fn switchPageCb(_: *GtkWidget, _: *GtkWidget, _: c_uint, _: ?*anyopaque) callconv(cc) void {
    updateTitle();
}

fn modifiedChangedCb(buf: *GtkTextBuffer, _: ?*anyopaque) callconv(cc) void {
    for (tabs[0..tab_count]) |*t| {
        if (t.buffer == buf) {
            updateTabLabel(t);
            break;
        }
    }
    updateTitle();
}

fn closeButtonCb(_: *GtkWidget, data: ?*anyopaque) callconv(cc) void {
    const scrolled: *GtkWidget = @ptrCast(@alignCast(data orelse return));
    const nb = notebook_widget orelse return;
    const n = gtk.gtk_notebook_get_n_pages(nb);
    var i: c_int = 0;
    while (i < n) : (i += 1) {
        if (gtk.gtk_notebook_get_nth_page(nb, i)) |page| {
            if (page == scrolled) {
                closeTab(i);
                return;
            }
        }
    }
}
