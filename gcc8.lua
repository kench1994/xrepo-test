--更换编译链工具
toolchain("gcc-8.5.0")
    set_kind("standalone")
    set_sdkdir("/usr/local/gcc-8.5.0")
toolchain_end()
set_toolchains("gcc-8.5.0")