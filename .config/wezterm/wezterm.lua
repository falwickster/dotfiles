
--- wezterm.lua
--- $ figlet -f small Wezterm
--- __      __      _
--- \ \    / /__ __| |_ ___ _ _ _ __
---  \ \/\/ / -_)_ /  _/ -_) '_| '  \
---   \_/\_/\___/__|\__\___|_| |_|_|_|
---
--- My Wezterm config file

local wezterm = require("wezterm")
local act = wezterm.action

local config = {}
-- Use config builder object if possible
if wezterm.config_builder then config = wezterm.config_builder() end

-- Settings
config.default_prog = { "pwsh" }

config.color_scheme = "tokyonight_storm"
config.window_background_opacity = 0.9
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.scrollback_lines = 3000
config.default_workspace = "main"

-- Dim inactive panes
config.inactive_pane_hsb = {
  saturation = 0.24,
  brightness = 0.5
}

-- Copy selected text straight to the system clipboard (in addition to the
-- primary selection) as soon as the mouse button is released.
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = "Left" } }, mods = "NONE", action = act.CompleteSelection("ClipboardAndPrimarySelection") },
  { event = { Up = { streak = 2, button = "Left" } }, mods = "NONE", action = act.CompleteSelection("ClipboardAndPrimarySelection") },
  { event = { Up = { streak = 3, button = "Left" } }, mods = "NONE", action = act.CompleteSelection("ClipboardAndPrimarySelection") },
}

-- Keys
-- Leaning on WezTerm's default keybindings (no custom LEADER prefix); see
-- https://wezfurlong.org/wezterm/config/default-keys.html for the full list.

-- Tab bar
-- I don't like the look of "fancy" tab bar
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = false
config.tab_max_width = 32

-- Colors for the retro tab bar, tuned to sit apart from the tokyonight-storm
-- pane background so tabs read as distinct "chips" rather than blending in.
config.colors = {
  tab_bar = {
    background = "#1f2335",
    new_tab = { bg_color = "#1f2335", fg_color = "#565f89" },
    new_tab_hover = { bg_color = "#292e42", fg_color = "#c0caf5" },
  },
}

-- Powerline-style separators between tabs, with the active tab rendered in
-- bold to make it visually distinct without needing the fancy tab bar.
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
  local title = tab.tab_index + 1 .. ": " .. (tab.active_pane.title or "")
  if #title > max_width - 4 then
    title = title:sub(1, max_width - 5) .. "…"
  end

  if tab.is_active then
    return {
      { Background = { Color = "#1f2335" } },
      { Foreground = { Color = "#bb9af7" } },
      { Text = SOLID_LEFT_ARROW },
      { Background = { Color = "#bb9af7" } },
      { Foreground = { Color = "#1f2335" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = " " .. title .. " " },
    }
  end

  return {
    { Background = { Color = "#1f2335" } },
    { Foreground = { Color = "#414868" } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = "#292e42" } },
    { Foreground = { Color = "#a9b1d6" } },
    { Text = " " .. title .. " " },
  }
end)

wezterm.on("update-status", function(window, pane)
  -- Workspace name
  local stat = window:active_workspace()
  local stat_color = "#f7768e"

  local basename = function(s)
    -- Nothing a little regex can't fix
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end

  -- Current working directory
  local cwd = pane:get_current_working_dir()
  if cwd then
    if type(cwd) == "userdata" then
      -- Wezterm introduced the URL object in 20240127-113634-bbcac864
      cwd = basename(cwd.file_path)
    else
      -- 20230712-072601-f4abf8fd or earlier version
      cwd = basename(cwd)
    end
  else
    cwd = ""
  end

  -- Current command
  local cmd = pane:get_foreground_process_name()
  -- CWD and CMD could be nil (e.g. viewing log using Ctrl-Alt-l)
  cmd = cmd and basename(cmd) or ""

  -- Time
  local time = wezterm.strftime("%H:%M")

  -- Left status (left of the tab line)
  window:set_left_status(wezterm.format({
    { Foreground = { Color = stat_color } },
    { Text = "  " },
    { Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
    { Text = " |" },
  }))

  -- Right status
  window:set_right_status(wezterm.format({
    -- Wezterm has a built-in nerd fonts
    -- https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
    { Text = wezterm.nerdfonts.md_folder .. "  " .. cwd },
    { Text = " | " },
    { Foreground = { Color = "#e0af68" } },
    { Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
    "ResetAttributes",
    { Text = " | " },
    { Text = wezterm.nerdfonts.md_clock .. "  " .. time },
    { Text = "  " },
  }))
end)

return config
