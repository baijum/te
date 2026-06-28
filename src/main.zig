const std = @import("std");

const cc: std.builtin.CallingConvention = .c;

// ── GTK4 / GLib opaque types ────────────────────────────────────────────────

const GtkApplication = opaque {};
const GtkWidget = opaque {};
const GtkTextBuffer = opaque {};
const GtkFileDialog = opaque {};
const GFile = opaque {};
const GAsyncResult = opaque {};
const GCancellable = opaque {};

const GError = extern struct {
    domain: u32,
    code: c_int,
    message: ?[*:0]const u8,
};

const GtkTextIter = extern struct {
    dummy1: ?*anyopaque = null,
    dummy2: ?*anyopaque = null,
    dummy3: c_int = 0,
    dummy4: c_int = 0,
    dummy5: c_int = 0,
    dummy6: c_int = 0,
    dummy7: c_int = 0,
    dummy8: c_int = 0,
    dummy9: ?*anyopaque = null,
    dummy10: ?*anyopaque = null,
    dummy11: c_int = 0,
    dummy12: c_int = 0,
    dummy13: c_int = 0,
    dummy14: ?*anyopaque = null,
};

const GCallback = *const fn () callconv(cc) void;
const GAsyncReadyCallback = *const fn (*anyopaque, *GAsyncResult, ?*anyopaque) callconv(cc) void;

// ── GTK4 / GLib extern functions ────────────────────────────────────────────

extern fn gtk_application_new(id: [*:0]const u8, flags: c_uint) ?*GtkApplication;
extern fn g_application_run(app: *GtkApplication, argc: c_int, argv: ?[*]const [*:0]const u8) c_int;
extern fn g_object_unref(obj: *anyopaque) void;
extern fn g_signal_connect_data(
    instance: *anyopaque,
    signal: [*:0]const u8,
    handler: GCallback,
    data: ?*anyopaque,
    destroy: ?GCallback,
    flags: c_uint,
) c_ulong;

extern fn gtk_application_window_new(app: *GtkApplication) *GtkWidget;
extern fn gtk_window_set_title(win: *GtkWidget, title: [*:0]const u8) void;
extern fn gtk_window_set_default_size(win: *GtkWidget, w: c_int, h: c_int) void;
extern fn gtk_window_set_child(win: *GtkWidget, child: ?*GtkWidget) void;
extern fn gtk_window_set_titlebar(win: *GtkWidget, titlebar: ?*GtkWidget) void;
extern fn gtk_window_present(win: *GtkWidget) void;

extern fn gtk_header_bar_new() *GtkWidget;
extern fn gtk_header_bar_pack_start(bar: *GtkWidget, child: *GtkWidget) void;
extern fn gtk_header_bar_pack_end(bar: *GtkWidget, child: *GtkWidget) void;

extern fn gtk_button_new_with_label(label: [*:0]const u8) *GtkWidget;

extern fn gtk_text_view_new() *GtkWidget;
extern fn gtk_text_view_get_buffer(tv: *GtkWidget) *GtkTextBuffer;
extern fn gtk_text_view_set_monospace(tv: *GtkWidget, monospace: c_int) void;
extern fn gtk_text_view_set_wrap_mode(tv: *GtkWidget, mode: c_int) void;
extern fn gtk_text_view_set_top_margin(tv: *GtkWidget, margin: c_int) void;
extern fn gtk_text_view_set_bottom_margin(tv: *GtkWidget, margin: c_int) void;
extern fn gtk_text_view_set_left_margin(tv: *GtkWidget, margin: c_int) void;
extern fn gtk_text_view_set_right_margin(tv: *GtkWidget, margin: c_int) void;

extern fn gtk_text_buffer_set_text(buf: *GtkTextBuffer, text: [*]const u8, len: c_int) void;
extern fn gtk_text_buffer_get_text(
    buf: *GtkTextBuffer,
    start: *const GtkTextIter,
    end_iter: *const GtkTextIter,
    include_hidden: c_int,
) ?[*:0]u8;
extern fn gtk_text_buffer_get_start_iter(buf: *GtkTextBuffer, iter: *GtkTextIter) void;
extern fn gtk_text_buffer_get_end_iter(buf: *GtkTextBuffer, iter: *GtkTextIter) void;
extern fn gtk_text_buffer_get_modified(buf: *GtkTextBuffer) c_int;
extern fn gtk_text_buffer_set_modified(buf: *GtkTextBuffer, modified: c_int) void;

extern fn gtk_scrolled_window_new() *GtkWidget;
extern fn gtk_scrolled_window_set_child(sw: *GtkWidget, child: *GtkWidget) void;

extern fn gtk_widget_set_vexpand(w: *GtkWidget, expand: c_int) void;
extern fn gtk_widget_set_hexpand(w: *GtkWidget, expand: c_int) void;

extern fn gtk_file_dialog_new() *GtkFileDialog;
extern fn gtk_file_dialog_open(
    dialog: *GtkFileDialog,
    parent: ?*GtkWidget,
    cancellable: ?*GCancellable,
    callback: ?GAsyncReadyCallback,
    data: ?*anyopaque,
) void;
extern fn gtk_file_dialog_open_finish(
    dialog: *GtkFileDialog,
    result: *GAsyncResult,
    err: ?*?*GError,
) ?*GFile;
extern fn gtk_file_dialog_save(
    dialog: *GtkFileDialog,
    parent: ?*GtkWidget,
    cancellable: ?*GCancellable,
    callback: ?GAsyncReadyCallback,
    data: ?*anyopaque,
) void;
extern fn gtk_file_dialog_save_finish(
    dialog: *GtkFileDialog,
    result: *GAsyncResult,
    err: ?*?*GError,
) ?*GFile;

extern fn g_file_get_path(file: *GFile) ?[*:0]u8;
extern fn g_file_get_contents(
    filename: [*:0]const u8,
    contents: *?[*]u8,
    length: ?*usize,
    err: ?*?*GError,
) c_int;
extern fn g_file_set_contents(
    filename: [*:0]const u8,
    contents: [*]const u8,
    length: isize,
    err: ?*?*GError,
) c_int;

extern fn g_free(ptr: ?*anyopaque) void;
extern fn g_error_free(err: *GError) void;
extern fn g_strdup(str: [*:0]const u8) ?[*:0]u8;

extern fn gtk_event_controller_key_new() *anyopaque;
extern fn gtk_widget_add_controller(widget: *GtkWidget, controller: *anyopaque) void;

// ── Constants ───────────────────────────────────────────────────────────────

const GTK_WRAP_WORD_CHAR: c_int = 3;
const GDK_KEY_s: c_uint = 0x73;
const GDK_KEY_o: c_uint = 0x6f;
const GDK_KEY_n: c_uint = 0x6e;
const GDK_CONTROL_MASK: c_uint = 4;

// ── Application state ───────────────────────────────────────────────────────

var current_file: ?[*:0]u8 = null;
var text_buffer: ?*GtkTextBuffer = null;
var main_window: ?*GtkWidget = null;

// ── Title management ────────────────────────────────────────────────────────

fn updateTitle() void {
    const win = main_window orelse return;
    const buf = text_buffer orelse return;
    const modified = gtk_text_buffer_get_modified(buf) != 0;

    var name: []const u8 = "untitled";
    if (current_file) |f| {
        const full = std.mem.span(f);
        if (std.mem.lastIndexOfScalar(u8, full, '/')) |idx| {
            name = full[idx + 1 ..];
        } else {
            name = full;
        }
    }

    const prefix = "te - ";
    const suffix: []const u8 = if (modified) " [modified]" else "";
    const name_len = @min(name.len, 490 - prefix.len - suffix.len);

    var title: [500]u8 = undefined;
    @memcpy(title[0..prefix.len], prefix);
    @memcpy(title[prefix.len..][0..name_len], name[0..name_len]);
    @memcpy(title[prefix.len + name_len ..][0..suffix.len], suffix);
    title[prefix.len + name_len + suffix.len] = 0;

    gtk_window_set_title(win, @ptrCast(&title));
}

// ── File I/O ────────────────────────────────────────────────────────────────

fn loadFile(path: [*:0]const u8) void {
    var contents: ?[*]u8 = null;
    var length: usize = 0;
    var err: ?*GError = null;

    if (g_file_get_contents(path, &contents, &length, &err) != 0) {
        if (text_buffer) |buf| {
            if (contents) |c| {
                gtk_text_buffer_set_text(buf, c, @intCast(length));
            } else {
                gtk_text_buffer_set_text(buf, "", 0);
            }
            gtk_text_buffer_set_modified(buf, 0);
        }
        if (contents) |c| g_free(@ptrCast(c));

        if (current_file) |old| g_free(@ptrCast(old));
        current_file = g_strdup(path);
        updateTitle();
    } else {
        if (err) |e| g_error_free(e);
    }
}

fn saveToFile(path: [*:0]const u8) void {
    const buf = text_buffer orelse return;

    var start: GtkTextIter = .{};
    var end_iter: GtkTextIter = .{};
    gtk_text_buffer_get_start_iter(buf, &start);
    gtk_text_buffer_get_end_iter(buf, &end_iter);

    const text = gtk_text_buffer_get_text(buf, &start, &end_iter, 0) orelse return;
    defer g_free(@ptrCast(text));

    const text_len: isize = @intCast(std.mem.span(text).len);
    var err: ?*GError = null;

    if (g_file_set_contents(path, text, text_len, &err) != 0) {
        gtk_text_buffer_set_modified(buf, 0);
        if (current_file) |old| g_free(@ptrCast(old));
        current_file = g_strdup(path);
        updateTitle();
    } else {
        if (err) |e| g_error_free(e);
    }
}

// ── Actions ─────────────────────────────────────────────────────────────────

fn doNew() void {
    if (text_buffer) |buf| {
        gtk_text_buffer_set_text(buf, "", 0);
        gtk_text_buffer_set_modified(buf, 0);
    }
    if (current_file) |old| {
        g_free(@ptrCast(old));
        current_file = null;
    }
    updateTitle();
}

fn doOpen() void {
    const dialog = gtk_file_dialog_new();
    gtk_file_dialog_open(dialog, main_window, null, &openFinishCb, null);
}

fn doSave() void {
    if (current_file) |path| {
        saveToFile(path);
    } else {
        const dialog = gtk_file_dialog_new();
        gtk_file_dialog_save(dialog, main_window, null, &saveFinishCb, null);
    }
}

// ── GTK signal callbacks ────────────────────────────────────────────────────

fn activateCb(app: *GtkApplication, _: ?*anyopaque) callconv(cc) void {
    const win = gtk_application_window_new(app);
    main_window = win;
    gtk_window_set_title(win, "te - untitled");
    gtk_window_set_default_size(win, 800, 600);

    const header = gtk_header_bar_new();
    gtk_window_set_titlebar(win, header);

    const btn_new = gtk_button_new_with_label("New");
    const btn_open = gtk_button_new_with_label("Open");
    const btn_save = gtk_button_new_with_label("Save");

    gtk_header_bar_pack_start(header, btn_new);
    gtk_header_bar_pack_start(header, btn_open);
    gtk_header_bar_pack_end(header, btn_save);

    _ = g_signal_connect_data(@ptrCast(btn_new), "clicked", @ptrCast(&newClickedCb), null, null, 0);
    _ = g_signal_connect_data(@ptrCast(btn_open), "clicked", @ptrCast(&openClickedCb), null, null, 0);
    _ = g_signal_connect_data(@ptrCast(btn_save), "clicked", @ptrCast(&saveClickedCb), null, null, 0);

    const text_view = gtk_text_view_new();
    gtk_text_view_set_monospace(text_view, 1);
    gtk_text_view_set_wrap_mode(text_view, GTK_WRAP_WORD_CHAR);
    gtk_text_view_set_top_margin(text_view, 6);
    gtk_text_view_set_bottom_margin(text_view, 6);
    gtk_text_view_set_left_margin(text_view, 6);
    gtk_text_view_set_right_margin(text_view, 6);

    text_buffer = gtk_text_view_get_buffer(text_view);

    if (text_buffer) |buf| {
        _ = g_signal_connect_data(@ptrCast(buf), "modified-changed", @ptrCast(&modifiedChangedCb), null, null, 0);
    }

    const scrolled = gtk_scrolled_window_new();
    gtk_scrolled_window_set_child(scrolled, text_view);
    gtk_widget_set_vexpand(scrolled, 1);
    gtk_widget_set_hexpand(scrolled, 1);

    gtk_window_set_child(win, scrolled);

    const key_ctrl = gtk_event_controller_key_new();
    _ = g_signal_connect_data(key_ctrl, "key-pressed", @ptrCast(&keyPressedCb), null, null, 0);
    gtk_widget_add_controller(win, key_ctrl);

    gtk_window_present(win);
}

fn openFinishCb(source: *anyopaque, result: *GAsyncResult, _: ?*anyopaque) callconv(cc) void {
    const dialog: *GtkFileDialog = @ptrCast(@alignCast(source));
    var err: ?*GError = null;
    const file = gtk_file_dialog_open_finish(dialog, result, &err);
    if (file) |f| {
        defer g_object_unref(@ptrCast(f));
        if (g_file_get_path(f)) |path| {
            defer g_free(@ptrCast(path));
            loadFile(path);
        }
    } else if (err) |e| {
        g_error_free(e);
    }
}

fn saveFinishCb(source: *anyopaque, result: *GAsyncResult, _: ?*anyopaque) callconv(cc) void {
    const dialog: *GtkFileDialog = @ptrCast(@alignCast(source));
    var err: ?*GError = null;
    const file = gtk_file_dialog_save_finish(dialog, result, &err);
    if (file) |f| {
        defer g_object_unref(@ptrCast(f));
        if (g_file_get_path(f)) |path| {
            defer g_free(@ptrCast(path));
            saveToFile(path);
        }
    } else if (err) |e| {
        g_error_free(e);
    }
}

fn newClickedCb(_: *GtkWidget, _: ?*anyopaque) callconv(cc) void {
    doNew();
}

fn openClickedCb(_: *GtkWidget, _: ?*anyopaque) callconv(cc) void {
    doOpen();
}

fn saveClickedCb(_: *GtkWidget, _: ?*anyopaque) callconv(cc) void {
    doSave();
}

fn modifiedChangedCb(_: *GtkTextBuffer, _: ?*anyopaque) callconv(cc) void {
    updateTitle();
}

fn keyPressedCb(
    _: *anyopaque,
    keyval: c_uint,
    _: c_uint,
    state: c_uint,
    _: ?*anyopaque,
) callconv(cc) c_int {
    if ((state & GDK_CONTROL_MASK) != 0) {
        switch (keyval) {
            GDK_KEY_s => {
                doSave();
                return 1;
            },
            GDK_KEY_o => {
                doOpen();
                return 1;
            },
            GDK_KEY_n => {
                doNew();
                return 1;
            },
            else => {},
        }
    }
    return 0;
}

// ── Entry point ─────────────────────────────────────────────────────────────

pub fn main(_: std.process.Init) !void {
    const app = gtk_application_new("com.github.te", 0) orelse return;
    defer g_object_unref(@ptrCast(app));
    _ = g_signal_connect_data(@ptrCast(app), "activate", @ptrCast(&activateCb), null, null, 0);
    _ = g_application_run(app, 0, null);
}
