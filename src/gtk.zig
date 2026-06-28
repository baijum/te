const std = @import("std");

pub const cc: std.builtin.CallingConvention = .c;

// ── Opaque types ────────────────────────────────────────────────────────────

pub const GtkApplication = opaque {};
pub const GtkWidget = opaque {};
pub const GtkTextBuffer = opaque {};
pub const GtkFileDialog = opaque {};
pub const GFile = opaque {};
pub const GAsyncResult = opaque {};
pub const GCancellable = opaque {};
pub const GtkCssProvider = opaque {};
pub const GdkDisplay = opaque {};

// ── Struct types ────────────────────────────────────────────────────────────

pub const GError = extern struct {
    domain: u32,
    code: c_int,
    message: ?[*:0]const u8,
};

pub const GtkTextIter = extern struct {
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

// ── Callback types ──────────────────────────────────────────────────────────

pub const GCallback = *const fn () callconv(cc) void;
pub const GAsyncReadyCallback = *const fn (*anyopaque, *GAsyncResult, ?*anyopaque) callconv(cc) void;

// ── GLib / GObject ──────────────────────────────────────────────────────────

pub extern fn g_application_run(app: *GtkApplication, argc: c_int, argv: ?[*]const [*:0]const u8) c_int;
pub extern fn g_object_unref(obj: *anyopaque) void;
pub extern fn g_signal_connect_data(
    instance: *anyopaque,
    signal: [*:0]const u8,
    handler: GCallback,
    data: ?*anyopaque,
    destroy: ?GCallback,
    flags: c_uint,
) c_ulong;
pub extern fn g_free(ptr: ?*anyopaque) void;
pub extern fn g_error_free(err: *GError) void;
pub extern fn g_strdup(str: [*:0]const u8) ?[*:0]u8;
pub extern fn g_get_home_dir() [*:0]const u8;
pub extern fn g_mkdir_with_parents(pathname: [*:0]const u8, mode: c_uint) c_int;

// ── GFile ───────────────────────────────────────────────────────────────────

pub extern fn g_file_get_path(file: *GFile) ?[*:0]u8;
pub extern fn g_file_get_contents(
    filename: [*:0]const u8,
    contents: *?[*]u8,
    length: ?*usize,
    err: ?*?*GError,
) c_int;
pub extern fn g_file_set_contents(
    filename: [*:0]const u8,
    contents: [*]const u8,
    length: isize,
    err: ?*?*GError,
) c_int;

// ── GtkApplication / GtkWindow ──────────────────────────────────────────────

pub extern fn gtk_application_new(id: [*:0]const u8, flags: c_uint) ?*GtkApplication;
pub extern fn gtk_application_window_new(app: *GtkApplication) *GtkWidget;
pub extern fn gtk_window_set_title(win: *GtkWidget, title: [*:0]const u8) void;
pub extern fn gtk_window_set_default_size(win: *GtkWidget, w: c_int, h: c_int) void;
pub extern fn gtk_window_set_child(win: *GtkWidget, child: ?*GtkWidget) void;
pub extern fn gtk_window_set_titlebar(win: *GtkWidget, titlebar: ?*GtkWidget) void;
pub extern fn gtk_window_present(win: *GtkWidget) void;

// ── GtkHeaderBar ────────────────────────────────────────────────────────────

pub extern fn gtk_header_bar_new() *GtkWidget;
pub extern fn gtk_header_bar_pack_start(bar: *GtkWidget, child: *GtkWidget) void;
pub extern fn gtk_header_bar_pack_end(bar: *GtkWidget, child: *GtkWidget) void;

// ── GtkButton ───────────────────────────────────────────────────────────────

pub extern fn gtk_button_new_with_label(label: [*:0]const u8) *GtkWidget;

// ── GtkTextView / GtkTextBuffer ─────────────────────────────────────────────

pub extern fn gtk_text_view_new() *GtkWidget;
pub extern fn gtk_text_view_get_buffer(tv: *GtkWidget) *GtkTextBuffer;
pub extern fn gtk_text_view_set_monospace(tv: *GtkWidget, monospace: c_int) void;
pub extern fn gtk_text_view_set_wrap_mode(tv: *GtkWidget, mode: c_int) void;
pub extern fn gtk_text_view_set_top_margin(tv: *GtkWidget, margin: c_int) void;
pub extern fn gtk_text_view_set_bottom_margin(tv: *GtkWidget, margin: c_int) void;
pub extern fn gtk_text_view_set_left_margin(tv: *GtkWidget, margin: c_int) void;
pub extern fn gtk_text_view_set_right_margin(tv: *GtkWidget, margin: c_int) void;

pub extern fn gtk_text_buffer_set_text(buf: *GtkTextBuffer, text: [*]const u8, len: c_int) void;
pub extern fn gtk_text_buffer_get_text(
    buf: *GtkTextBuffer,
    start: *const GtkTextIter,
    end_iter: *const GtkTextIter,
    include_hidden: c_int,
) ?[*:0]u8;
pub extern fn gtk_text_buffer_get_start_iter(buf: *GtkTextBuffer, iter: *GtkTextIter) void;
pub extern fn gtk_text_buffer_get_end_iter(buf: *GtkTextBuffer, iter: *GtkTextIter) void;
pub extern fn gtk_text_buffer_get_modified(buf: *GtkTextBuffer) c_int;
pub extern fn gtk_text_buffer_set_modified(buf: *GtkTextBuffer, modified: c_int) void;

// ── GtkScrolledWindow ──────────────────────────────────────────────────────

pub extern fn gtk_scrolled_window_new() *GtkWidget;
pub extern fn gtk_scrolled_window_set_child(sw: *GtkWidget, child: *GtkWidget) void;

// ── GtkCssProvider ──────────────────────────────────────────────────────────

pub extern fn gtk_css_provider_new() *GtkCssProvider;
pub extern fn gtk_css_provider_load_from_string(provider: *GtkCssProvider, string: [*:0]const u8) void;
pub extern fn gdk_display_get_default() ?*GdkDisplay;
pub extern fn gtk_style_context_add_provider_for_display(
    display: *GdkDisplay,
    provider: *anyopaque,
    priority: c_uint,
) void;

// ── GtkWidget helpers ───────────────────────────────────────────────────────

pub extern fn gtk_widget_set_vexpand(w: *GtkWidget, expand: c_int) void;
pub extern fn gtk_widget_set_hexpand(w: *GtkWidget, expand: c_int) void;
pub extern fn gtk_event_controller_key_new() *anyopaque;
pub extern fn gtk_widget_add_controller(widget: *GtkWidget, controller: *anyopaque) void;

// ── GtkFileDialog ───────────────────────────────────────────────────────────

pub extern fn gtk_file_dialog_new() *GtkFileDialog;
pub extern fn gtk_file_dialog_open(
    dialog: *GtkFileDialog,
    parent: ?*GtkWidget,
    cancellable: ?*GCancellable,
    callback: ?GAsyncReadyCallback,
    data: ?*anyopaque,
) void;
pub extern fn gtk_file_dialog_open_finish(
    dialog: *GtkFileDialog,
    result: *GAsyncResult,
    err: ?*?*GError,
) ?*GFile;
pub extern fn gtk_file_dialog_save(
    dialog: *GtkFileDialog,
    parent: ?*GtkWidget,
    cancellable: ?*GCancellable,
    callback: ?GAsyncReadyCallback,
    data: ?*anyopaque,
) void;
pub extern fn gtk_file_dialog_save_finish(
    dialog: *GtkFileDialog,
    result: *GAsyncResult,
    err: ?*?*GError,
) ?*GFile;

// ── GtkNotebook ─────────────────────────────────────────────────────────────

pub extern fn gtk_notebook_new() *GtkWidget;
pub extern fn gtk_notebook_append_page(nb: *GtkWidget, child: *GtkWidget, tab_label: ?*GtkWidget) c_int;
pub extern fn gtk_notebook_remove_page(nb: *GtkWidget, page_num: c_int) void;
pub extern fn gtk_notebook_get_current_page(nb: *GtkWidget) c_int;
pub extern fn gtk_notebook_set_current_page(nb: *GtkWidget, page_num: c_int) void;
pub extern fn gtk_notebook_get_nth_page(nb: *GtkWidget, page_num: c_int) ?*GtkWidget;
pub extern fn gtk_notebook_get_n_pages(nb: *GtkWidget) c_int;
pub extern fn gtk_notebook_set_scrollable(nb: *GtkWidget, scrollable: c_int) void;
pub extern fn gtk_notebook_set_tab_reorderable(nb: *GtkWidget, child: *GtkWidget, reorderable: c_int) void;

// ── GtkLabel ────────────────────────────────────────────────────────────────

pub extern fn gtk_label_new(text: [*:0]const u8) *GtkWidget;
pub extern fn gtk_label_set_text(label: *GtkWidget, text: [*:0]const u8) void;

// ── GtkBox ──────────────────────────────────────────────────────────────────

pub extern fn gtk_box_new(orientation: c_int, spacing: c_int) *GtkWidget;
pub extern fn gtk_box_append(box: *GtkWidget, child: *GtkWidget) void;

// ── GtkMenuButton ───────────────────────────────────────────────────────────

pub extern fn gtk_menu_button_new() *GtkWidget;
pub extern fn gtk_menu_button_set_popover(button: *GtkWidget, popover: ?*GtkWidget) void;
pub extern fn gtk_menu_button_set_label(button: *GtkWidget, label: [*:0]const u8) void;
pub extern fn gtk_menu_button_popup(button: *GtkWidget) void;

// ── GtkPopover ──────────────────────────────────────────────────────────────

pub extern fn gtk_popover_new() *GtkWidget;
pub extern fn gtk_popover_set_child(popover: *GtkWidget, child: ?*GtkWidget) void;

// ── Additional widget helpers ───────────────────────────────────────────────

pub extern fn gtk_widget_set_size_request(widget: *GtkWidget, width: c_int, height: c_int) void;
pub extern fn gtk_scrolled_window_set_policy(sw: *GtkWidget, h: c_int, v: c_int) void;
pub extern fn gtk_widget_get_first_child(widget: *GtkWidget) ?*GtkWidget;
pub extern fn gtk_widget_get_next_sibling(widget: *GtkWidget) ?*GtkWidget;
pub extern fn gtk_box_remove(box: *GtkWidget, child: *GtkWidget) void;

// ── Constants ───────────────────────────────────────────────────────────────

pub const GTK_WRAP_WORD_CHAR: c_int = 3;
pub const GTK_ORIENTATION_HORIZONTAL: c_int = 0;
pub const GTK_ORIENTATION_VERTICAL: c_int = 1;
pub const GTK_POLICY_NEVER: c_int = 0;
pub const GTK_POLICY_AUTOMATIC: c_int = 1;
pub const GDK_KEY_s: c_uint = 0x73;
pub const GDK_KEY_o: c_uint = 0x6f;
pub const GDK_KEY_n: c_uint = 0x6e;
pub const GDK_KEY_r: c_uint = 0x72;
pub const GDK_KEY_w: c_uint = 0x77;
pub const GDK_KEY_Tab: c_uint = 0xff09;
pub const GDK_KEY_ISO_Left_Tab: c_uint = 0xfe20;
pub const GDK_KEY_equal: c_uint = 0x3d;
pub const GDK_KEY_minus: c_uint = 0x2d;
pub const GDK_KEY_plus: c_uint = 0x2b;
pub const GDK_KEY_0: c_uint = 0x30;
pub const GDK_CONTROL_MASK: c_uint = 4;
pub const GDK_SHIFT_MASK: c_uint = 1;
pub const GTK_STYLE_PROVIDER_PRIORITY_APPLICATION: c_uint = 600;
