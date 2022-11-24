add_rules("mode.debug", "mode.release")

-- if is_os("windows") then
--     if(is_mode("release")) then
--         set_config("vs_runtime", "MD")
--     else
--         set_config("vs_runtime", "MDd")
--     end
-- else
--     add_cxflags("-MD")
-- end

package("zlib")
    set_homepage("http://www.zlib.net")
    set_description("A Massively Spiffy Yet Delicately Unobtrusive Compression Library")

    add_urls("https://github.com/madler/zlib/archive/$(version).tar.gz",
             "https://github.com/madler/zlib.git")
    add_versions("v1.2.10", "42cd7b2bdaf1c4570e0877e61f2fdc0bce8019492431d054d3d86925e5058dc5")
    add_versions("v1.2.11", "629380c90a77b964d896ed37163f5c3a34f6e6d897311f1df2a7016355c45eff")
    add_versions("v1.2.12", "d8688496ea40fb61787500e863cc63c9afcbc524468cedeb478068924eb54932")

    if is_plat("mingw") and is_subhost("msys") then
        add_extsources("pacman::zlib")
    elseif is_plat("linux") then
        add_extsources("pacman::zlib", "apt::zlib1g-dev")
    elseif is_plat("macosx") then
        add_extsources("brew::zlib")
    end

    on_install(function (package)
        io.writefile("xmake.lua", [[
            includes("check_cincludes.lua")
            add_rules("mode.debug", "mode.release")
            target("zlib")
                set_kind("$(kind)")
                if not is_plat("windows") then
                    set_basename("z")
                end
                add_files("adler32.c")
                add_files("compress.c")
                add_files("crc32.c")
                add_files("deflate.c")
                add_files("gzclose.c")
                add_files("gzlib.c")
                add_files("gzread.c")
                add_files("gzwrite.c")
                add_files("inflate.c")
                add_files("infback.c")
                add_files("inftrees.c")
                add_files("inffast.c")
                add_files("trees.c")
                add_files("uncompr.c")
                add_files("zutil.c")
                add_headerfiles("zlib.h", "zconf.h")
                check_cincludes("Z_HAVE_UNISTD_H", "unistd.h")
                check_cincludes("HAVE_SYS_TYPES_H", "sys/types.h")
                check_cincludes("HAVE_STDINT_H", "stdint.h")
                check_cincludes("HAVE_STDDEF_H", "stddef.h")
                if is_plat("windows") then
                    add_defines("_CRT_SECURE_NO_DEPRECATE")
                    add_defines("_CRT_NONSTDC_NO_DEPRECATE")
                    if is_kind("shared") then
                        add_files("win32/zlib1.rc")
                        add_defines("ZLIB_DLL")
                    end
                else
                    add_defines("ZEXPORT=__attribute__((visibility(\"default\")))")
                    add_defines("_LARGEFILE64_SOURCE=1")
                end
        ]])
        local configs = {}
        if package:config("shared") then
            configs.kind = "shared"
        elseif not package:is_plat("windows", "mingw") and package:config("pic") ~= false then
            configs.cxflags = "-fPIC"
        end
        import("package.tools.xmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("inflate", {includes = "zlib.h"}))
    end)
package_end()

package("openssl")

    set_homepage("https://www.openssl.org/")
    set_description("A robust, commercial-grade, and full-featured toolkit for TLS and SSL.")

    add_urls("https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_$(version).zip", {version = function (version)
        return version:gsub("^(%d+)%.(%d+)%.(%d+)-?(%a*)$", "%1_%2_%3%4")
    end, excludes = "*/fuzz/*"})
    add_versions("1.1.1-q", "df86e6adcff1c91a85cef139dd061ea40b7e49005e8be16522cf4864bfcf5eb8")
    add_patches("1.1.1-q", path.join(os.scriptdir(), "patches", "1.1.1q.diff"), "cfe6929f9db2719e695be0b61f8c38fe8132544c5c58ca8d07383bfa6c675b7b")

    on_fetch("fetch")

    on_load(function (package)
        if package:is_plat("windows") and (not package.is_built or package:is_built()) then
            package:add("deps", "nasm")
            -- the perl executable found in GitForWindows will fail to build OpenSSL
            -- see https://github.com/openssl/openssl/blob/master/NOTES-PERL.md#perl-on-windows
            package:add("deps", "strawberry-perl", { system = false })
        end

        -- @note we must use package:is_plat() instead of is_plat in description for supporting add_deps("openssl", {host = true}) in python
        if package:is_plat("windows") then
            package:add("links", "libssl", "libcrypto")
        else
            package:add("links", "ssl", "crypto")
        end
        if package:is_plat("windows", "mingw") then
            package:add("syslinks", "ws2_32", "user32", "crypt32", "advapi32")
        elseif package:is_plat("linux", "cross") then
            package:add("syslinks", "pthread", "dl")
        end
        if package:is_plat("linux") then
            package:add("extsources", "apt::libssl-dev")
        end
    end)

    on_install("windows", function (package)
        local configs = {"Configure"}
        local target
        if package:is_arch("x86", "i386") then
            target = "VC-WIN32"
        elseif package:is_arch("arm64") then
            target = "VC-WIN64-ARM"
        elseif package:is_arch("arm.*") then
            target = "VC-WIN32-ARM"
        else
            target = "VC-WIN64A"
        end
        table.insert(configs, target)
        table.insert(configs, package:config("shared") and "shared" or "no-shared")
        table.insert(configs, "--prefix=" .. package:installdir())
        table.insert(configs, "--openssldir=" .. package:installdir())
        os.vrunv("perl", configs)
        import("package.tools.nmake").install(package)
    end)

    on_install("mingw", function (package)
        local configs = {"Configure", "no-tests"}
        table.insert(configs, package:is_arch("i386", "x86") and "mingw" or "mingw64")
        table.insert(configs, package:config("shared") and "shared" or "no-shared")
        local installdir = package:installdir()
        -- Use MSYS2 paths instead of Windows paths
        if is_subhost("msys") then
            installdir = installdir:gsub("(%a):[/\\](.+)", "/%1/%2"):gsub("\\", "/")
        end
        table.insert(configs, "--prefix=" .. installdir)
        table.insert(configs, "--openssldir=" .. installdir)
        local buildenvs = import("package.tools.autoconf").buildenvs(package)
        buildenvs.RC = package:build_getenv("mrc")
        if is_subhost("msys") then
            local rc = buildenvs.RC
            if rc then
                rc = rc:gsub("(%a):[/\\](.+)", "/%1/%2"):gsub("\\", "/")
                buildenvs.RC = rc
            end
        end
        -- fix 'cp: directory fuzz does not exist'
        if package:config("shared") then
            os.mkdir("fuzz")
        end
        os.vrunv("perl", configs, {envs = buildenvs})
        import("package.tools.make").build(package)
        import("package.tools.make").make(package, {"install_sw"})
    end)

    on_install("linux", "macosx", "bsd", function (package)
        -- https://wiki.openssl.org/index.php/Compilation_and_Installation#PREFIX_and_OPENSSLDIR
        local buildenvs = import("package.tools.autoconf").buildenvs(package)
        local configs = {"--openssldir=" .. package:installdir(),
                         "--prefix=" .. package:installdir()}
        table.insert(configs, package:config("shared") and "shared" or "no-shared")
        if package:debug() then
            table.insert(configs, "--debug")
        end
        os.vrunv("./config", configs, {envs = buildenvs})
        local makeconfigs = {CFLAGS = buildenvs.CFLAGS, ASFLAGS = buildenvs.ASFLAGS}
        import("package.tools.make").build(package, makeconfigs)
        import("package.tools.make").make(package, {"install_sw"})
        if package:config("shared") then
            os.tryrm(path.join(package:installdir("lib"), "*.a"))
        end
    end)

    on_install("cross", "android", function (package)

        local target_arch = "generic32"
        if package:is_arch("x86_64") then
            target_arch = "x86_64"
        elseif package:is_arch("i386", "x86") then
            target_arch = "x86"
        elseif package:is_arch("arm64", "arm64-v8a") then
            target_arch = "aarch64"
        elseif package:is_arch("arm.*") then
            target_arch = "armv4"
        elseif package:is_arch(".*64") then
            target_arch = "generic64"
        end

        local target_plat = "linux"
        if package:is_plat("macosx") then
            target_plat = "darwin64"
            target_arch = "x86_64-cc"
        end

        local target = target_plat .. "-" .. target_arch
        local configs = {target,
                         "-DOPENSSL_NO_HEARTBEATS",
                         "no-shared",
                         "no-threads",
                         "--openssldir=" .. package:installdir(),
                         "--prefix=" .. package:installdir()}
        local buildenvs = import("package.tools.autoconf").buildenvs(package)
        os.vrunv("./Configure", configs, {envs = buildenvs})
        local makeconfigs = {CFLAGS = buildenvs.CFLAGS, ASFLAGS = buildenvs.ASFLAGS}
        import("package.tools.make").build(package, makeconfigs)
        import("package.tools.make").make(package, {"install_sw"})
    end)

    on_test(function (package)
        assert(package:has_cfuncs("SSL_new", {includes = "openssl/ssl.h"}))
    end)
package_end()

--
--{configs = {toolchains = "gcc-11"}})
add_requires("zlib v1.2.10", {configs = {shared = false, pic = true}, system = false, alias = "myzlib"})
add_requires("openssl 1.1.1-q", {configs = {shared = false, pic = true}, system = false, alias = "myopenssl"})

--add_requires("libcurl 7.82.0", {configs = {shared = false, pic = true, zlib = true}, system = false, alias = "libcurl"})

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("myzlib", "myopenssl")--, "libcurl")



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

