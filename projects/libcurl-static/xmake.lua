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