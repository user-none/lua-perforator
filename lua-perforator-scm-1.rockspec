package = "lua-perforator"
version = "scm-1"

source = {
    url = "git://github.com/user-none/lua-perforator.git"
}

description = {
    summary    = "Lua profiling module",
    homepage   = "https://github.com/user-none/lua-perforator.git",
    license    = "MIT/X11",
    maintainer = "John Schember <john@nachtimwald.com>"
}

dependencies = {
    "lua >= 5.3"
}

build = {
    type    = "builtin",
    modules = {
        ["perforator"]            = "perforator/init.lua",
        ["perforator.perforator"] = "perforator/perforator.lua",
    }
}
