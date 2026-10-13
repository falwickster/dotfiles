
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

-- Custom palette matching Helix's github_dark_high_contrast (WezTerm only
-- ships the regular "GitHub Dark"). Colors follow GitHub Primer.
config.color_schemes = {
  ["GitHub Dark High Contrast"] = {
    foreground = "#f0f3f6",
    background = "#0a0c10",
    cursor_bg = "#71b7ff",
    cursor_fg = "#0a0c10",
    cursor_border = "#71b7ff",
    selection_bg = "#264f78",
    selection_fg = "#f0f3f6",
    ansi = { "#272b33", "#ff9492", "#26cd4d", "#f0b72f", "#71b7ff", "#cb9eff", "#39c5cf", "#d9dee3" },
    brights = { "#4c5461", "#ffb1af", "#4ae168", "#f7c843", "#91cbff", "#dbb7ff", "#56d4dd", "#ffffff" },
  },
}
config.color_scheme = "GitHub Dark High Contrast"

-- Pinned explicitly (rather than relying on WezTerm's built-in fallback
-- font) for consistently crisp rendering of Nerd Font glyphs (tmux status
-- icons, eza/shell prompt icons, etc.) instead of the fallback.
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 11
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
-- https://wezterm.org/config/default-keys.html for the full list. Tab
-- keybindings (new/close/switch tab, etc.) are kept as-is - useful as an
-- extra layer on top of tmux, and verified not to collide with tmux's own
-- keymap (tmux's root/no-prefix table is mouse-bindings-only, and its
-- prefix-table Ctrl+Arrow resize-pane bindings require the Ctrl+b prefix
-- first, so they never fire on a bare keypress).
--
-- Pane/split keybindings are disabled below, though: tmux is already the
-- single source of truth for multiplexing (panes, splits), so WezTerm's
-- own pane/split defaults would just be redundant/confusing (nested
-- splits, two different "add a pane" gestures, etc.). Each entry below
-- undoes exactly one default assignment (see
-- https://wezterm.org/config/lua/keyassignment/DisableDefaultAssignment.html)
-- and lets the keypress fall through to tmux/the shell instead.
config.keys = {
  { key = "\"", mods = "CTRL|ALT", action = act.DisableDefaultAssignment }, -- SplitVertical
  { key = "\"", mods = "CTRL|SHIFT|ALT", action = act.DisableDefaultAssignment }, -- SplitVertical
  { key = "'", mods = "CTRL|ALT", action = act.DisableDefaultAssignment }, -- SplitVertical (raw apostrophe key)
  { key = "'", mods = "CTRL|SHIFT|ALT", action = act.DisableDefaultAssignment }, -- SplitVertical (raw apostrophe key + shift)
  { key = "%", mods = "CTRL|ALT", action = act.DisableDefaultAssignment }, -- SplitHorizontal
  { key = "%", mods = "CTRL|SHIFT|ALT", action = act.DisableDefaultAssignment }, -- SplitHorizontal
  { key = "5", mods = "CTRL|ALT", action = act.DisableDefaultAssignment }, -- SplitHorizontal (raw 5 key)
  { key = "5", mods = "CTRL|SHIFT|ALT", action = act.DisableDefaultAssignment }, -- SplitHorizontal (raw 5 key + shift)
  { key = "LeftArrow", mods = "CTRL|SHIFT|ALT", action = act.DisableDefaultAssignment }, -- AdjustPaneSize Left
  { key = "RightArrow", mods = "CTRL|SHIFT|ALT", action = act.DisableDefaultAssignment }, -- AdjustPaneSize Right
  { key = "UpArrow", mods = "CTRL|SHIFT|ALT", action = act.DisableDefaultAssignment }, -- AdjustPaneSize Up
  { key = "DownArrow", mods = "CTRL|SHIFT|ALT", action = act.DisableDefaultAssignment }, -- AdjustPaneSize Down
  { key = "LeftArrow", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment }, -- ActivatePaneDirection Left
  { key = "RightArrow", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment }, -- ActivatePaneDirection Right
  { key = "UpArrow", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment }, -- ActivatePaneDirection Up
  { key = "DownArrow", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment }, -- ActivatePaneDirection Down
  { key = "Z", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment }, -- TogglePaneZoomState
}

-- Tab bar
-- I don't like the look of "fancy" tab bar
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = false
config.tab_max_width = 32

-- Colors for the retro tab bar, tuned to sit apart from the GitHub high-contrast
-- pane background so tabs read as distinct "chips" rather than blending in.
config.colors = {
  tab_bar = {
    background = "#010409",
    new_tab = { bg_color = "#010409", fg_color = "#9ea7b3" },
    new_tab_hover = { bg_color = "#272b33", fg_color = "#f0f3f6" },
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
      { Background = { Color = "#010409" } },
      { Foreground = { Color = "#71b7ff" } },
      { Text = SOLID_LEFT_ARROW },
      { Background = { Color = "#71b7ff" } },
      { Foreground = { Color = "#010409" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = " " .. title .. " " },
    }
  end

  return {
    { Background = { Color = "#010409" } },
    { Foreground = { Color = "#4c5461" } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = "#272b33" } },
    { Foreground = { Color = "#d9dee3" } },
    { Text = " " .. title .. " " },
  }
end)

wezterm.on("update-status", function(window, pane)
  -- Workspace name
  local stat = window:active_workspace()
  local stat_color = "#ff9492"

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
    { Foreground = { Color = "#f0b72f" } },
    { Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
    "ResetAttributes",
    { Text = " | " },
    { Text = wezterm.nerdfonts.md_clock .. "  " .. time },
    { Text = "  " },
  }))
end)

return config
