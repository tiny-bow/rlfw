const Window = @import("Window.zig");
const internal = @import("internal.zig");
const c = internal.c;
const errorCheck = internal.glfw.errorCheck;
const builtin = @import("builtin");

/// Makes the context of the specified window current for the calling thread.
///
/// This function makes the OpenGL or OpenGL ES context of the specified window current on the
/// calling thread. A context must only be made current on a single thread at a time and each
/// thread can have only a single current context at a time.
///
/// When moving a context between threads, you must make it non-current on the old thread before
/// making it current on the new one.
///
/// By default, making a context non-current implicitly forces a pipeline flush. On machines that
/// support `GL_KHR_context_flush_control`, you can control whether a context performs this flush
/// by setting the Hints.context.release_behavior hint.
///
/// The specified window must have an OpenGL or OpenGL ES context. Specifying a window without a
/// context will generate glfw.Error.NoWindowContext.
///
/// @thread_safety This function may be called from any thread.
pub fn makeCurrentContext(window: ?Window) WindowContextError!void {
    internal.requireInit();
    if (window) |w| c.glfwMakeContextCurrent(@ptrCast(w.handle)) else c.glfwMakeContextCurrent(null);
    try internal.subErrorCheck(WindowContextError);
    // TODO: Check why this fails, it seems like tls.posix is not set? but it works when it runs the C code?
    // if (self.handle.context.client == @intFromEnum(glfw.Hint.Context.API.Client.Value.NoAPI)) {
    //     return Error.NoWindowContext;
    // }
    //
    // if (_c._glfwPlatformGetTls(&_c._glfw.contextSlot)) |ptr| {
    //     const prev: *_c._GLFWwindow = @ptrCast(@alignCast(ptr));
    //     if (self.handle.context.source != prev.context.source)
    //         prev.context.makeCurrent.?(null);
    // }
    //
    // self.handle.context.makeCurrent.?(self.handle);
}
const WindowContextError = error{ NoWindowContext, PlatformError };

/// Returns the window whose context is current on the calling thread.
///
/// This function returns the window whose OpenGL or OpenGL ES context is current on the calling
/// thread.
///
/// Returns he window whose context is current, or null if no window's context is current.
///
/// @thread_safety This function may be called from any thread.
pub fn getCurrentContext() ?Window {
    internal.requireInit();
    if (c.glfwGetCurrentContext()) |ptr| {
        return .{ .handle = @ptrCast(@alignCast(ptr)) };
    } else return null;
}

/// Sets the swap interval for the current context.
///
/// This function sets the swap interval for the current OpenGL or OpenGL ES context, i.e. the
/// number of screen updates to wait from the time glfw.SwapBuffers was called before swapping the
/// buffers and returning. This is sometimes called _vertical synchronization_, _vertical retrace
/// synchronization_ or just _vsync_.
///
/// A context that supports either of the `WGL_EXT_swap_control_tear` and `GLX_EXT_swap_control_tear`
/// extensions also accepts _negative_ swap intervals, which allows the driver to swap immediately
/// even if a frame arrives a little bit late. You can check for these extensions with glfw.extensionSupported.
///
/// A context must be current on the calling thread. Calling this function without a current context
/// will cause glfw.Error.NoCurrentContext.
///
/// This function does not apply to Vulkan. If you are rendering with Vulkan, see the present mode
/// of your swapchain instead.
///
/// @param[in] interval The minimum number of screen updates to wait for until the buffers are
/// swapped by glfw.swapBuffers.
///
/// This function is not called during context creation, leaving the swap interval set to whatever
/// is the default for that API. This is done because some swap interval extensions used by
/// GLFW do not allow the swap interval to be reset to zero once it has been set to a non-zero
/// value.
///
/// Some GPU drivers do not honor the requested swap interval, either because of a user setting
/// that overrides the application's request or due to bugs in the driver.
///
/// @thread_safety This function may be called from any thread.
pub fn swapInterval(interval: c_int) !void {
    internal.requireInit();
    c.glfwSwapInterval(interval);
    try internal.subErrorCheck(SwapError);
}
const SwapError = error{ NoCurrentContext, PlatformError };
/// Returns whether the specified extension is available.
///
/// This function returns whether the specified API extension (see context_glext) is supported by
/// the current OpenGL or OpenGL ES context. It searches both for client API extension and context
/// creation API extensions.
///
/// A context must be current on the calling thread. Calling this function without a current
/// context will cause glfw.Error.NoCurrentContext.
///
/// As this functions retrieves and searches one or more extension strings each call, it is
/// recommended that you cache its results if it is going to be used frequently. The extension
/// strings will not change during the lifetime of a context, so there is no danger in doing this.
///
/// This function does not apply to Vulkan. If you are using Vulkan, see glfw.getRequiredInstanceExtensions,
/// `vkEnumerateInstanceExtensionProperties` and `vkEnumerateDeviceExtensionProperties` instead.
///
/// @param[in] extension The ASCII encoded name of the extension.
/// @return `true` if the extension is available, or `false` otherwise.
///
/// @thread_safety This function may be called from any thread.
const ExtensionError = error{ NoCurrentContext, InvalidValue, PlatformError };
pub fn extensionSupported(extension: [*:0]const u8) ExtensionError!bool {
    internal.requireInit();
    const res = c.glfwExtensionSupported(extension);
    try internal.subErrorCheck(ExtensionError);
    return res == c.GLFW_TRUE;
}

/// Client API function pointer type.
///
/// Generic function pointer used for returning client API function pointers.
pub const GLProc = *const fn () callconv(if (builtin.os.tag == .windows and builtin.cpu.arch == .x86) .Stdcall else .C) void;

/// Returns the address of the specified function for the current context.
///
/// This function returns the address of the specified OpenGL or OpenGL ES core or extension
/// function (see context_glext), if it is supported by the current context.
///
/// A context must be current on the calling thread. Calling this function without a current
/// context will cause glfw.Error.NoCurrentContext.
///
/// This function does not apply to Vulkan. If you are rendering with Vulkan, see glfw.getInstanceProcAddress,
/// `vkGetInstanceProcAddr` and `vkGetDeviceProcAddr` instead.
///
/// @param[in] procname The ASCII encoded name of the function.
/// @return The address of the function, or null if an error occurred.
///
/// To maintain ABI compatability with the C glfwGetProcAddress, as it is commonly passed into
/// libraries expecting that exact ABI, this function does not return an error. Instead, if
/// glfw.Error.NotInitialized, glfw.Error.NoCurrentContext, or glfw.Error.PlatformError
/// would occur this function will panic. You should ensure a valid OpenGL context exists and the
/// GLFW is initialized before calling this function.
///
/// The address of a given function is not guaranteed to be the same between contexts.
///
/// This function may return a non-null address despite the associated version or extension
/// not being available. Always check the context version or extension string first.
///
/// @pointer_lifetime The returned function pointer is valid until the context is destroyed or the
/// library is terminated.
///
/// @thread_safety This function may be called from any thread.
pub fn getProcAddress(procname: [*:0]const u8) callconv(.C) ?GLProc {
    internal.requireInit();
    if (c.glfwGetProcAddress(procname)) |address| return address;
    return null;
}
