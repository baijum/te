const std = @import("std");
const gtk = @import("gtk.zig");
const tabs = @import("tabs.zig");
const recent = @import("recent.zig");

const cc = gtk.cc;

// ── Font size state ─────────────────────────────────────────────────────────

const DEFAULT_FONT_SIZE: u8 = 12;
const MIN_FONT_SIZE: u8 = 6;
const MAX_FONT_SIZE: u8 = 72;
var font_size: u8 = DEFAULT_FONT_SIZE;
var css_provider: ?*gtk.GtkCssProvider = null;

fn applyFontSize() void {
    const provider = css_provider orelse return;
    var buf: [64]u8 = undefined;
    const css = std.fmt.bufPrint(&buf, "textview {{ font-size: {d}pt; }}\x00", .{font_size}) catch return;
    gtk.gtk_css_provider_load_from_string(provider, @ptrCast(css.ptr));
}

fn doZoomIn() void {
    if (font_size < MAX_FONT_SIZE) {
        font_size += 1;
        applyFontSize();
    }
}

fn doZoomOut() void {
    if (font_size > MIN_FONT_SIZE) {
        font_size -= 1;
        applyFontSize();
    }
}

fn doZoomReset() void {
    font_size = DEFAULT_FONT_SIZE;
    applyFontSize();
}

// ── Actions ─────────────────────────────────────────────────────────────────

fn doNew() void {
    tabs.createTab(null);
}

fn doOpen() void {
    const dialog = gtk.gtk_file_dialog_new();
    gtk.gtk_file_dialog_open(dialog, tabs.main_window, null, &openFinishCb, null);
}

fn doSave() void {
    const tab = tabs.currentTab() orelse return;
    if (tab.file_path) |path| {
        tabs.saveToFile(path);
    } else {
        const dialog = gtk.gtk_file_dialog_new();
        gtk.gtk_file_dialog_save(dialog, tabs.main_window, null, &saveFinishCb, null);
    }
}

fn doRecent() void {
    const btn = recent.menu_button orelse return;
    gtk.gtk_menu_button_popup(btn);
}

// ── GTK signal callbacks ────────────────────────────────────────────────────

fn activateCb(app: *gtk.GtkApplication, _: ?*anyopaque) callconv(cc) void {
    const win = gtk.gtk_application_window_new(app);
    tabs.main_window = win;
    gtk.gtk_window_set_title(win, "te - untitled");
    gtk.gtk_window_set_default_size(win, 800, 600);

    const header = gtk.gtk_header_bar_new();
    gtk.gtk_window_set_titlebar(win, header);

    const btn_new = gtk.gtk_button_new_with_label("New");
    const btn_open = gtk.gtk_button_new_with_label("Open");
    const btn_save = gtk.gtk_button_new_with_label("Save");

    // Recent files menu button with popover
    const btn_recent = gtk.gtk_menu_button_new();
    gtk.gtk_menu_button_set_label(btn_recent, "Recent");
    recent.menu_button = btn_recent;

    const popover = gtk.gtk_popover_new();
    const popover_scrolled = gtk.gtk_scrolled_window_new();
    gtk.gtk_widget_set_size_request(popover_scrolled, 280, 300);
    gtk.gtk_scrolled_window_set_policy(popover_scrolled, gtk.GTK_POLICY_NEVER, gtk.GTK_POLICY_AUTOMATIC);

    const popover_box = gtk.gtk_box_new(gtk.GTK_ORIENTATION_VERTICAL, 2);
    recent.popover_box = popover_box;
    gtk.gtk_scrolled_window_set_child(popover_scrolled, popover_box);
    gtk.gtk_popover_set_child(popover, popover_scrolled);
    gtk.gtk_menu_button_set_popover(btn_recent, popover);

    recent.load();
    recent.rebuildPopover();

    gtk.gtk_header_bar_pack_start(header, btn_new);
    gtk.gtk_header_bar_pack_start(header, btn_open);
    gtk.gtk_header_bar_pack_start(header, btn_recent);
    gtk.gtk_header_bar_pack_end(header, btn_save);

    _ = gtk.g_signal_connect_data(@ptrCast(btn_new), "clicked", @ptrCast(&newClickedCb), null, null, 0);
    _ = gtk.g_signal_connect_data(@ptrCast(btn_open), "clicked", @ptrCast(&openClickedCb), null, null, 0);
    _ = gtk.g_signal_connect_data(@ptrCast(btn_save), "clicked", @ptrCast(&saveClickedCb), null, null, 0);

    const nb = gtk.gtk_notebook_new();
    tabs.notebook_widget = nb;
    gtk.gtk_notebook_set_scrollable(nb, 1);
    gtk.gtk_widget_set_vexpand(nb, 1);
    gtk.gtk_widget_set_hexpand(nb, 1);
    _ = gtk.g_signal_connect_data(@ptrCast(nb), "switch-page", @ptrCast(&tabs.switchPageCb), null, null, 0);

    gtk.gtk_window_set_child(win, nb);

    tabs.createTab(null);

    const key_ctrl = gtk.gtk_event_controller_key_new();
    _ = gtk.g_signal_connect_data(key_ctrl, "key-pressed", @ptrCast(&keyPressedCb), null, null, 0);
    gtk.gtk_widget_add_controller(win, key_ctrl);

    css_provider = gtk.gtk_css_provider_new();
    if (gtk.gdk_display_get_default()) |display| {
        gtk.gtk_style_context_add_provider_for_display(display, @ptrCast(css_provider.?), gtk.GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
    applyFontSize();

    gtk.gtk_window_present(win);
}

fn openFinishCb(source: *anyopaque, result: *gtk.GAsyncResult, _: ?*anyopaque) callconv(cc) void {
    const dialog: *gtk.GtkFileDialog = @ptrCast(@alignCast(source));
    var err: ?*gtk.GError = null;
    const file = gtk.gtk_file_dialog_open_finish(dialog, result, &err);
    if (file) |f| {
        defer gtk.g_object_unref(@ptrCast(f));
        if (gtk.g_file_get_path(f)) |path| {
            defer gtk.g_free(@ptrCast(path));
            tabs.createTab(path);
        }
    } else if (err) |e| {
        gtk.g_error_free(e);
    }
}

fn saveFinishCb(source: *anyopaque, result: *gtk.GAsyncResult, _: ?*anyopaque) callconv(cc) void {
    const dialog: *gtk.GtkFileDialog = @ptrCast(@alignCast(source));
    var err: ?*gtk.GError = null;
    const file = gtk.gtk_file_dialog_save_finish(dialog, result, &err);
    if (file) |f| {
        defer gtk.g_object_unref(@ptrCast(f));
        if (gtk.g_file_get_path(f)) |path| {
            defer gtk.g_free(@ptrCast(path));
            tabs.saveToFile(path);
        }
    } else if (err) |e| {
        gtk.g_error_free(e);
    }
}

fn newClickedCb(_: *gtk.GtkWidget, _: ?*anyopaque) callconv(cc) void {
    doNew();
}

fn openClickedCb(_: *gtk.GtkWidget, _: ?*anyopaque) callconv(cc) void {
    doOpen();
}

fn saveClickedCb(_: *gtk.GtkWidget, _: ?*anyopaque) callconv(cc) void {
    doSave();
}

fn keyPressedCb(
    _: *anyopaque,
    keyval: c_uint,
    _: c_uint,
    state: c_uint,
    _: ?*anyopaque,
) callconv(cc) c_int {
    if ((state & gtk.GDK_CONTROL_MASK) != 0) {
        switch (keyval) {
            gtk.GDK_KEY_s => {
                doSave();
                return 1;
            },
            gtk.GDK_KEY_o => {
                doOpen();
                return 1;
            },
            gtk.GDK_KEY_n => {
                doNew();
                return 1;
            },
            gtk.GDK_KEY_r => {
                doRecent();
                return 1;
            },
            gtk.GDK_KEY_w => {
                tabs.doCloseCurrentTab();
                return 1;
            },
            gtk.GDK_KEY_Tab => {
                tabs.switchToNextTab();
                return 1;
            },
            gtk.GDK_KEY_ISO_Left_Tab => {
                tabs.switchToPrevTab();
                return 1;
            },
            gtk.GDK_KEY_equal, gtk.GDK_KEY_plus => {
                doZoomIn();
                return 1;
            },
            gtk.GDK_KEY_minus => {
                doZoomOut();
                return 1;
            },
            gtk.GDK_KEY_0 => {
                doZoomReset();
                return 1;
            },
            else => {},
        }
    }
    return 0;
}

// ── Entry point ─────────────────────────────────────────────────────────────

pub fn main(_: std.process.Init) !void {
    const app = gtk.gtk_application_new("com.github.te", 0) orelse return;
    defer gtk.g_object_unref(@ptrCast(app));
    _ = gtk.g_signal_connect_data(@ptrCast(app), "activate", @ptrCast(&activateCb), null, null, 0);
    _ = gtk.g_application_run(app, 0, null);
}
