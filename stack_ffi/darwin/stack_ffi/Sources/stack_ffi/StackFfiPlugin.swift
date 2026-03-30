#if os(macOS)
  @_exported import stack_ffi_macos
#elseif os(iOS)
  @_exported import stack_ffi_ios
#endif
