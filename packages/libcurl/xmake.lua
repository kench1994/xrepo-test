includes("../openssl")
includes(path.join(os.scriptdir(), "versions.lua"))

package("libcurl")

    set_homepage("https://curl.haxx.se/")
    set_description("The multiprotocol file transfer library.")
    set_license("MIT")

    set_urls("https://curl.haxx.se/download/curl-$(version).tar.bz2",
             "http://curl.mirror.anstey.ca/curl-$(version).tar.bz2")
    add_urls("https://github.com/curl/curl/releases/download/curl-$(version).tar.bz2",
             {version = function (version) return (version:gsub("%.", "_")) .. "/curl-" .. version end})
    add_versions_list()

    add_deps("openssl")

    if is_plat("macosx", "iphoneos") then
        add_frameworks("Security", "CoreFoundation", "SystemConfiguration")
    elseif is_plat("linux") then
        add_syslinks("pthread")
    elseif is_plat("windows", "mingw") then
        add_deps("cmake")
        add_syslinks("advapi32", "crypt32", "wldap32", "winmm", "ws2_32", "user32")
    end

    add_configs("cares",    {description = "Enable c-ares support.", default = false, type = "boolean"})
    add_configs("openssl",  {description = "Enable OpenSSL for SSL/TLS.", default = is_plat("linux", "cross"), type = "boolean"})
    add_configs("mbedtls",  {description = "Enable mbedTLS for SSL/TLS.", default = false, type = "boolean"})
    add_configs("nghttp2",  {description = "Use Nghttp2 library.", default = false, type = "boolean"})
    add_configs("openldap", {description = "Use OpenLDAP library.", default = false, type = "boolean"})
    add_configs("libidn2",  {description = "Use Libidn2 for IDN support.", default = false, type = "boolean"})
    add_configs("zlib",     {description = "Enable zlib support.", default = false, type = "boolean"})
    add_configs("zstd",     {description = "Enable zstd support.", default = false, type = "boolean"})
    add_configs("brotli",   {description = "Enable brotli support.", default = false, type = "boolean"})
    add_configs("libssh2",  {description = "Use libSSH2 library.", default = false, type = "boolean"})

    if not is_plat("windows", "mingw@windows") then
        add_configs("libpsl",   {description = "Use libpsl for Public Suffix List.", default = false, type = "boolean"})
    end
    -- 设置 zlib 相关
    add_configs("zlib_ver", {description = "zlib version", default = "", type = "string"})
    add_configs("zlib_hash", {description = "zlib buildhash", default = "", type = "string"})
    -- 设置 openssl 相关
    add_configs("openssl_ver", {description = "openssl version", default = "", type = "string"})
    add_configs("openssl_hash", {description = "openssl buildhash", default = "", type = "string"})
    
    on_load(function (package)
        if package:is_plat("windows", "mingw") then
            if not package:config("shared") then
                package:add("defines", "CURL_STATICLIB")
            end
        end

        package:add("links", "ssl")
        package:add("links", "crypto")
        package:add("links", "zlib")
        -- local configdeps = {cares    = "c-ares",
        --                     openssl  = "openssl",
        --                     mbedtls  = "mbedtls",
        --                     nghttp2  = "nghttp2",
        --                     openldap = "openldap",
        --                     libidn2  = "libidn2",
        --                     libpsl   = "libpsl",
        --                     zlib     = "zlib",
        --                     zstd     = "zstd",
        --                     brotli   = "brotli",
        --                     libssh2  = "libssh2"}
        -- local has_deps = false
        -- for name, dep in pairs(configdeps) do
        --     if package:config(name) then
        --         package:add("deps", dep)
        --         has_deps = true
        --     end
        -- end

        -- pkg-config 这个插件好像会自动寻找依赖
        -- 目前希望完全有我们自己掌控
        -- if has_deps and package:is_plat("linux", "macosx") then
        --     package:add("deps", "pkg-config")
        -- end
    end)

    on_install("macosx", "linux", "iphoneos", "cross", function (package)
        local configs = {"--disable-silent-rules",
                         "--disable-dependency-tracking",
                         "--without-hyper",
                         "--without-libgsasl",
                         "--without-librtmp",
                         "--without-quiche",
                         "--without-ngtcp2",
                         "--without-nghttp3"}
        table.insert(configs, "--enable-shared=" .. (package:config("shared") and "yes" or "no"))
        table.insert(configs, "--enable-static=" .. (package:config("shared") and "no" or "yes"))
        if package:debug() then
            table.insert(configs, "--enable-debug")
        end
        if package:is_plat("macosx", "iphoneos") then
            table.insert(configs, (package:version():ge("7.77") and "--with-secure-transport" or "--with-darwinssl"))
        end

        table.insert(configs, "--with-openssl=" .. 
            path.join("~", ".xmake", "packages", "o", "openssl", package:config("openssl_ver"), package:config("openssl_hash"))
        )

        table.insert(configs, "--with-zlib=" .. 
            path.join("~", ".xmake", "packages", "z", "zlib", package:config("zlib_ver"), package:config("zlib_hash"))
        )
        
        table.insert(configs, package:config("cares") and "--enable-ares" or "--disable-ares")
        table.insert(configs, package:config("openldap") and "--enable-ldap" or "--disable-ldap")

        if package:is_plat("macosx") then
            local cares = package:dep("c-ares")
            if cares and not cares:config("shared") then
                -- we need fix missing `-lresolv` when checking c-ares
                io.replace("./configure", "PKGCONFIG --libs-only-l libcares", "PKGCONFIG --libs-only-l --static libcares", {plain = true})
            end
        end
        import("package.tools.autoconf").install(package, configs)
    end)

    -- on_test(function (package)
    --     assert(package:has_cfuncs("curl_version", {includes = "curl/curl.h"}))
    -- end)
