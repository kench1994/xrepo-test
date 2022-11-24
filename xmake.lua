add_rules("mode.debug", "mode.release", "mode.releasedbg")

set_policy("package.install_always", true)

-- 添加本地 package 描述
add_subdirs("packages/zlib", "packages/openssl")

--TODO:定义到其他地方
local zlib_version = "v1.2.10"
local zlib_buildhash = "54e8ae08e1274b7daba559de532d08dd"

--TODO:vs_runtime
add_requires( string.format("zlib %s", zlib_version) , {
        system = false,
        configs = {shared = false, pic = true},
        alias = "zlib"
    }
)

add_requires("openssl 1.1.1-q", {
        system = false, 
        configs = {shared = false, pic = true,
            options = { 
                no_asm = true, no_tests = true
            },
            zlib = {
                buildhash = zlib_buildhash,
                version = zlib_version
            }
        }, 
        alias = "openssl"
    }
)

--add_requires("libcurl 7.82.0", {configs = {shared = false, pic = true, zlib = true}, system = false, alias = "libcurl"})

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib", "openssl")
    -- set_installdir("install")
    -- after_build(function(target)
    --     import("target.action.install")(target)
    -- end)


    -- TODO:直接hook uninstall 清除 package 缓存
    on_uninstall(function(target)
        local deps_dpkgs = target:get("packages")
        for i, v in pairs(deps_dpkgs) do  
            local path = path.join("~", ".xmake", "packages", string.sub(v, 1, 1), v)
            cprint("${bright blue} try removing %s", path)
            os.tryrm(path)
            os.exec("xmake clean --all")
        end          
    end)
target_end()


--
-- If you want to known more usage about xmake, please see https://xmake.io
--
-- ## FAQ
--
-- You can enter the project directory firstly before building project.
--
--   $ cd projectdir
--
-- 1. How to build project?
--
--   $ xmake
--
-- 2. How to configure project?
--
--   $ xmake f -p [macosx|linux|iphoneos ..] -a [x86_64|i386|arm64 ..] -m [debug|release]
--
-- 3. Where is the build output directory?
--
--   The default output directory is `./build` and you can configure the output directory.
--
--   $ xmake f -o outputdir
--   $ xmake
--
-- 4. How to run and debug target after building project?
--
--   $ xmake run [targetname]
--   $ xmake run -d [targetname]
--
-- 5. How to install target to the system directory or other output directory?
--
--   $ xmake install
--   $ xmake install -o installdir
--
-- 6. Add some frequently-used compilation flags in xmake.lua
--
-- @code
--    -- add debug and release modes
--    add_rules("mode.debug", "mode.release")
--
--    -- add macro defination
--    add_defines("NDEBUG", "_GNU_SOURCE=1")
--
--    -- set warning all as error
--    set_warnings("all", "error")
--
--    -- set language: c99, c++11
--    set_languages("c99", "c++11")
--
--    -- set optimization: none, faster, fastest, smallest
--    set_optimize("fastest")
--
--    -- add include search directories
--    add_includedirs("/usr/include", "/usr/local/include")
--
--    -- add link libraries and search directories
--    add_links("tbox")
--    add_linkdirs("/usr/local/lib", "/usr/lib")
--
--    -- add system link libraries
--    add_syslinks("z", "pthread")
--
--    -- add compilation and link flags
--    add_cxflags("-stdnolib", "-fno-strict-aliasing")
--    add_ldflags("-L/usr/local/lib", "-lpthread", {force = true})
--
-- @endcode
--


-- [[-- 支持裁剪 
-- "no_threads": [True, False],
-- "no_zlib": [True, False],
-- "no_asm": [True, False],
-- "enable_weak_ssl_ciphers": [True, False],
-- "386": [True, False],
-- "no_stdio": [True, False],
-- "no_tests": [True, False],
-- "no_sse2": [True, False],
-- "no_bf": [True, False],
-- "no_cast": [True, False],
-- "no_des": [True, False],
-- "no_dh": [True, False],
-- "no_dsa": [True, False],
-- "no_hmac": [True, False],
-- "no_md2": [True, False],
-- "no_md5": [True, False],
-- "no_mdc2": [True, False],
-- "no_rc2": [True, False],
-- "no_rc4": [True, False],
-- "no_rc5": [True, False],
-- "no_rsa": [True, False],
-- "no_sha": [True, False],
-- "no_async": [True, False],
-- "no_dso": [True, False],
-- "no_aria": [True, False],
-- "no_blake2": [True, False],
-- "no_camellia": [True, False],
-- "no_chacha": [True, False],
-- "no_cms": [True, False],
-- "no_comp": [True, False],
-- "no_ct": [True, False],
-- "no_deprecated": [True, False],
-- "no_dgram": [True, False],
-- "no_engine": [True, False],
-- "no_filenames": [True, False],
-- "no_gost": [True, False],
-- "no_idea": [True, False],
-- "no_md4": [True, False],
-- "no_ocsp": [True, False],
-- "no_pinshared": [True, False],
-- "no_rmd160": [True, False],
-- "no_sm2": [True, False],
-- "no_sm3": [True, False],
-- "no_sm4": [True, False],
-- "no_srp": [True, False],
-- "no_srtp": [True, False],
-- "no_ssl": [True, False],
-- "no_ts": [True, False],
-- "no_whirlpool": [True, False],
-- "no_ec": [True, False],
-- "no_ecdh": [True, False],
-- "no_ecdsa": [True, False],
-- "no_rfc3779": [True, False],
-- "no_seed": [True, False],
-- "no_sock": [True, False],
-- "no_ssl3": [True, False],
-- "no_tls1": [True, False],
-- "capieng_dialog": [True, False],
-- "enable_capieng": [True, False]
-- --]]