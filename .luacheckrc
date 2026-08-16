-- .luacheckrc
-- Configuration for luacheck
--
-- The CI lint step aborts on any warning, so both the project's own globals
-- and the TIC-80 API functions this game calls have to be declared here.

globals = {
  -- the game's own globals
  "Context",
  "init_game",

  -- TIC-80 callbacks and API
  "TIC",
  "btn",
  "btnp",
  "cls",
  "exit",
  "keyp",
  "mget",
  "mset",
  "rect",
  "rectb",
  "spr",
}

-- The INPUT_KEY_* constants are a coherent set (LEFT/RIGHT/A/B/X/Y); some are
-- not bound yet, and dropping them would leave gaps in the mapping.
ignore = { "211/INPUT_KEY_.*" }

std = "lua51" -- TIC-80 runs Lua 5.1
