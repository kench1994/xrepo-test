include("../libz/libz_cfg.lua")
include("openssl_cfg.lua")

add_requires( string.format("openssl %s", openssl_version), {
    system = false, alias = "openssl",
    configs = {shared = false, pic = true, vs_runtime = "MD",
        -- 这样的写法有待商议, 使用 options 主要是懒得加太多条目
        -- 其实可以直接写到 install 脚本，但是跨平台可能比较差
        -- 或者规范点写，就得加很多条目
        options = { 
            no_asm = true, no_tests = true
        },
        zlib = {
            buildhash = zlib_buildhash,
            version = zlib_version
        }
    }
    }
)


