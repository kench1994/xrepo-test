includes("libz_cfg.lua")

add_requires( string.format("zlib %s", zlib_version) , {
    system = false, alias = "zlib",
    configs = {shared = false, pic = true, vs_runtime = "MD"}
    }
)