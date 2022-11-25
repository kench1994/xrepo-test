
package("openssl")

add_urls("https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_$(version).zip", {version = function (version)
    return version:gsub("^(%d+)%.(%d+)%.(%d+)-?(%a*)$", "%1_%2_%3%4")
end, excludes = "*/fuzz/*"})
add_versions("1.1.1-q", "df86e6adcff1c91a85cef139dd061ea40b7e49005e8be16522cf4864bfcf5eb8")
add_patches("1.1.1-q", path.join(os.scriptdir(), "patches", "1.1.1q.diff"), "cfe6929f9db2719e695be0b61f8c38fe8132544c5c58ca8d07383bfa6c675b7b")

on_fetch("fetch")

-- 设置基础数据类型
add_configs("options", {description = "option features switch", default = {}, type = "table"})
-- 设置zlib相关
add_configs("zlib", {description = "zlib configuration", default = {}, type = "table"})


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


on_install("linux", "macosx", "bsd", function (package, opts)
    local nilval
    -- https://wiki.openssl.org/index.php/Compilation_and_Installation#PREFIX_and_OPENSSLDIR
    local buildenvs = import("package.tools.autoconf").buildenvs(package)
    local configs = {"--openssldir=" .. package:installdir(),
                     "--prefix=" .. package:installdir()}
    table.insert(configs, package:config("shared") and "shared" or "no-shared")
    if package:debug() then
        table.insert(configs, "--debug")
    end

    -- 设定其他fearture
    local option_features = package:config("options")
    if option_features then
        for k, v in pairs(option_features) do
            if v then table.insert(configs, string.format("%s", string.gsub(k, "_", "-"))) end
        end
    end
    
    -- 通过外部参数找到我们编译的zlib
    local zlib_cfg = package:config("zlib")
    -- 强制使用 zlib,以避免编译指令未如预期
    local zlib_ctx = find_package("xmake::zlib", {
            buildhash = string.format("%s", zlib_cfg["buildhash"]),
            require_version = string.format("%s", zlib_cfg["version"]), version = true,
            packagedirs = {path.join("~", ".xmake", "packages")}            
        }
    )
    -- 指定zlib
    table.insert(configs, "--with-zlib-lib=" .. zlib_ctx["linkdirs"][1])
    table.insert(configs, "--with-zlib-include=" .. zlib_ctx["includedirs"][1])

    -- TODO: pass compile flags
    os.vrunv("./config", configs, {envs = buildenvs})
    local makeconfigs = {
        CFLAGS = string.format("-fvisibility=hidden %s", buildenvs.CFLAGS),
        ASFLAGS = buildenvs.ASFLAGS
    }
    import("package.tools.make").build(package, makeconfigs)
    import("package.tools.make").make(package, {"install_sw"})
    if package:config("shared") then
        os.tryrm(path.join(package:installdir("lib"), "*.a"))
    end
end)


on_test(function (package)
    assert(package:has_cfuncs("SSL_new", {includes = "openssl/ssl.h"}))
end)

package_end()
