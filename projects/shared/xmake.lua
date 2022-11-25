includes("../../global.lua")

local zlib_version = "v1.2.10"
local zlib_buildhash = "39bc6b93326149baad8a4ec21245c122"
local openssl_version = "1.1.1-q"
local openssl_buildhash = "9a19735311074bffa2bd79a235ae479b"
local libcurl_version = "7.82.0"

add_requires( string.format("zlib %s", zlib_version) , {
        system = false, alias = "zlib",
        configs = {shared = true, pic = true}
    }
)

add_requires( string.format("openssl %s", openssl_version), {
        system = false, alias = "openssl",
        configs = {shared = true, pic = true,
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
        configs = {shared = true, pic = true, 
            zlib = true,
            zlib_ver = zlib_version,
            zlib_hash = zlib_buildhash,
            openssl = true,
            openssl_ver = openssl_version,
            openssl_hash = openssl_buildhash,
        }
    }
)

target("shared")
    set_kind("phony")
    --add_files("../../src/*.c")
    -- 主要为了 hook install、uninstall 动作
    add_packages(
        --"libcurl", 
        "zlib",
        "openssl"
    )
    -- after_build(function(target)
    --     import("target.action.install")(target)
    -- end)

    -- set_installdir("publish")
    -- on_install(function(target)

    -- end)

    -- 直接hook uninstall 清除 package 缓存
    on_uninstall(function(target)
        local deps_dpkgs = target:get("packages")
        for i, v in pairs(deps_dpkgs) do  
            local pkgpath
            if is_plat("linux") then pkgpath = path.join("~", ".xmake", "packages", string.sub(v, 1, 1), v) end
            cprint("${bright blue} try removing %s", pkgpath)
            os.tryrm(pkgpath)
            --os.exec("xmake clean --all")
        end          
    end)
target_end()
