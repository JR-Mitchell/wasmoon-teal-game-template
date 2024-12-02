return {
    include_dir = {
        "teal"
    },
    source_dir = "teal/",
    build_dir = "src/assets",
    global_env_def = "teal/global-defs",
    dont_prune = {
        "src/assets/*.png"
    }
}