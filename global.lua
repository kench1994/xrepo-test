add_rules("mode.debug", "mode.release", "mode.releasedbg")
set_policy("package.install_always", true)
-- 添加本地 package 描述
includes("packages/zlib/xmake.lua", "packages/openssl/xmake.lua", "packages/libcurl/xmake.lua")
