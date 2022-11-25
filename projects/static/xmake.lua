includes("../../global.lua")

local zlib_version = "v1.2.10"
local zlib_buildhash = "644588e2d3ca448fba28b07c827e2162"
local openssl_version = "1.1.1-q"
local openssl_buildhash = "603295821a4041ac996c35c821688e39"
local libcurl_version = "7.82.0"

add_requires( string.format("zlib %s", zlib_version) , {
        system = false, alias = "zlib",
        configs = {shared = false, pic = true, vs_runtime = "MD"}
    }
)

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

add_requires( string.format("libcurl %s", libcurl_version), {
        system = false, alias = "libcurl",
        configs = {shared = false, pic = true, vs_runtime = "MD",
            zlib = true,
            zlib_ver = zlib_version,
            zlib_hash = zlib_buildhash,
            openssl = true,
            openssl_ver = openssl_version,
            openssl_hash = openssl_buildhash,
        }
    }
)

target("test")
    set_kind("binary")
    add_files("../../src/*.c")
    -- 主要为了 hook install、uninstall 动作
    add_packages("libcurl", "openssl", "zlib")

    -- after_build(function(target)
    --     import("target.action.install")(target)
    -- end)

    set_installdir("$(projectdir)/publish/")
    -- set_rundir("$(projectdir)/publish")

    on_install(function(target)
        --TODO:分析依赖
        local deps_dpkgs = target:get("packages")
        for _, v in pairs(deps_dpkgs) do  
            os.cp(path.join(target:pkg(v):installdir(), "lib", "*.a"), target:installdir())
        end
        os.cp(target:targetfile(), target:installdir())
    end)

    -- 直接hook uninstall 清除 package 缓存
    on_uninstall(function(target)
        local deps_dpkgs = target:get("packages")
        for _, v in pairs(deps_dpkgs) do  
            cprint("${bright blue} try removing %s", target:pkg(v):installdir())
            os.tryrm(target:pkg(v):installdir())
        end          
    end)

    --TODO:package
target_end()
