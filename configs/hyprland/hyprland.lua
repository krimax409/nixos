local home = os.getenv("HOME")
local config_dir = os.getenv("HYPRLAND_LAPTOP_CONFIG") or home .. "/nixos/configs/hyprland"
local state_home = os.getenv("XDG_STATE_HOME") or home .. "/.local/state"
local data_home = os.getenv("XDG_DATA_HOME") or home .. "/.local/share"
local testing = os.getenv("HYPRLAND_LAPTOP_TEST") == "1"
local dsp = hl.dsp
local run = hl.dispatch

local function quote(path)
    return "'" .. path:gsub("'", "'\\''") .. "'"
end

local function action(name)
    return dsp.exec_cmd("bash " .. quote(config_dir .. "/actions.sh") .. " " .. name)
end

hl.env("NOCTALIA_CONFIG_HOME", config_dir)
hl.env("NOCTALIA_STATE_HOME", state_home .. "/hyprland-laptop")
hl.env("NOCTALIA_DATA_HOME", data_home .. "/hyprland-laptop")
hl.env("XCURSOR_THEME", "Posy_Cursor")
hl.env("XCURSOR_SIZE", "24")

hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = testing and 1 or "auto" })

hl.config({
    general = {
        layout = "scrolling",
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        resize_on_border = true,
        col = { active_border = "rgb(60cdff)", inactive_border = "rgb(383d44)" },
    },
    scrolling = {
        column_width = 0.75,
        explicit_column_widths = "0.333, 0.5, 0.667",
        fullscreen_on_one_column = true,
        focus_fit_method = 1,
        wrap_focus = false,
        wrap_swapcol = false,
    },
    decoration = {
        rounding = 9,
        shadow = { enabled = true, range = 12, render_power = 3, color = "rgba(00000066)" },
        blur = { enabled = false },
    },
    animations = { enabled = true },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true, background_color = "rgb(17191d)" },
    cursor = { enable_hyprcursor = false, no_warps = true },
    binds = { scroll_event_delay = 150, movefocus_cycles_fullscreen = true },
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle",
        repeat_rate = 40,
        repeat_delay = 250,
        follow_mouse = 1,
        accel_profile = "flat",
        touchpad = { tap_to_click = true, natural_scroll = true },
    },
})
hl.device({ name = "elan0678:00-04f3:3195-touchpad", accel_profile = "adaptive", sensitivity = 0.15 })

hl.curve("quietOut", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.animation({ leaf = "global", enabled = true, speed = 1.6, bezier = "quietOut" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1.4, bezier = "quietOut", style = "popin 97%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "quietOut", style = "popin 97%" })
hl.animation({ leaf = "windowsMove", enabled = false })
hl.animation({ leaf = "workspaces", enabled = false })
hl.animation({ leaf = "border", enabled = false })
hl.layer_rule({ name = "noctalia-motion", match = { namespace = "noctalia-.*" }, no_anim = true })

local function float_rule(name, class, title, placement)
    local rule = { name = name, match = { class = class, title = title }, float = true }
    if placement then rule.move = placement end
    hl.window_rule(rule)
end

float_rule("firefox-pip", ".*firefox$", "^Picture-in-Picture$")
float_rule("bitwarden", "(?i)^bitwarden$")
float_rule("bitwarden-browser", "(.*firefox|google-chrome)", "^Bitwarden$")
float_rule("bitwarden-extension", "chrome-nngceckbapebfimnlniiiahkandclblb.*")
float_rule("steam", "(?i)^steam$")
float_rule("steam-toast", "notificationtoasts.*", nil, "monitor_w-window_w-16 monitor_h-window_h-58")
float_rule("discord-updater", "(?i)^discord$", "(?i)^(discord )?updat.*")
float_rule("volume-mixer", "(org\\.pulseaudio\\.pavucontrol|pavucontrol)")
hl.window_rule({ name = "noctalia-settings", match = { class = "dev\\.noctalia\\.Noctalia" },
    float = true, center = true, size = {1080, 920} })

hl.on("hyprland.start", function()
    if not testing then
        local shell = "env http_proxy=http://127.0.0.1:2080 https_proxy=http://127.0.0.1:2080 no_proxy=localhost,127.0.0.1,::1 noctalia --daemon"
        if os.getenv("HYPRLAND_LAPTOP_UWSM") == "1" then shell = "uwsm finalize && " .. shell end
        hl.exec_cmd(shell)
        hl.exec_cmd("sleep 3 && exec keepassxc-unlocked")
    end
end)

local function get_column(win)
    local layout = win and win.layout
    return layout and layout.column
end

local function edge_of_strip(to_end, move)
    local ws = hl.get_active_workspace()
    local active = hl.get_active_window()
    if not ws then return end
    local target, extreme
    for _, win in ipairs(ws:get_windows()) do
        local col = get_column(win)
        if col and (not extreme or (to_end and col.index > extreme) or (not to_end and col.index < extreme)) then
            target, extreme = win, col.index
        end
    end
    if not target then return end
    if not move then
        run(dsp.focus({ window = target }))
        return
    end
    local col = get_column(active)
    if not col then return end
    local direction = to_end and "r" or "l"
    for _ = 1, math.abs(extreme - col.index) do run(dsp.layout("swapcol " .. direction)) end
end

local function float_focus()
    local ws = hl.get_active_workspace()
    local active = hl.get_active_window()
    if not ws or not active then return end
    local best
    for _, win in ipairs(ws:get_windows()) do
        if win.mapped and not win.hidden and win.floating ~= active.floating
            and (not best or win.focus_history_id < best.focus_history_id) then
            best = win
        end
    end
    if best then run(dsp.focus({ window = best })) end
end

local function adjacent_workspace(delta)
    local ws = hl.get_active_workspace()
    if not ws or ws.id < 1 then return end
    local nearest
    for _, other in ipairs(hl.get_workspaces()) do
        local distance = (other.id - ws.id) * delta
        if other.id > 0 and other.monitor == ws.monitor and distance > 0
            and (not nearest or distance < (nearest - ws.id) * delta) then
            nearest = other.id
        end
    end
    if nearest then return nearest end
    if delta < 0 or ws.is_empty then return end
    local id = ws.id + 1
    while hl.get_workspace(id) do id = id + 1 end
    return id
end

local function focus_adjacent(delta)
    local destination = adjacent_workspace(delta)
    if destination then run(dsp.focus({ workspace = destination })) end
end

local function move_column(destination)
    local active = hl.get_active_window()
    if not active or not destination or (active.workspace and active.workspace.id == destination) then return end
    local col = get_column(active)
    local prev
    for _, win in ipairs(col and col.windows or {active}) do
        run(dsp.window.move({ window = win, workspace = destination }))
        if prev and win.workspace == prev.workspace then
            local left, right = get_column(prev), get_column(win)
            if left and right and math.abs(left.index - right.index) == 1 then
                run(dsp.focus({ window = win }))
                run(dsp.layout("consume_or_expel " .. (right.index > left.index and "prev" or "next")))
            end
        end
        prev = win
    end
    run(dsp.focus({ window = active }))
    if col and get_column(active) then run(dsp.layout("colresize " .. col.width)) end
end

local function move_to_monitor(direction)
    local monitor = hl.get_monitor(direction)
    if monitor and monitor.active_workspace then move_column(monitor.active_workspace.id) end
end

local function reorder_workspace(delta)
    local ws = hl.get_active_workspace()
    if not ws or ws.id <= 0 or ws.id + delta < 1 then return end
    local old, dst = ws.id, ws.id + delta
    local other = hl.get_workspace(dst)
    if other and other.monitor ~= ws.monitor then return end
    local function change(before, after) run(dsp.workspace.change_id({ workspace = before, id = after })) end
    if other then
        local spare = 1000
        while hl.get_workspace(spare) do spare = spare + 1 end
        change(dst, spare)
        change(old, dst)
        change(spare, old)
    else
        change(old, dst)
    end
end

local function adjust_height(delta)
    local active = hl.get_active_window()
    if not active or not active.monitor then return end
    local mon = active.monitor
    run(dsp.window.resize({ x = 0, y = math.floor(mon.height / mon.scale * delta), relative = true }))
end

local super = "SUPER + "
local repeatable, locked = { repeating = true }, { locked = true }
local locked_repeat = { locked = true, repeating = true }
local bind, exec = hl.bind, dsp.exec_cmd
local function key(chord, handler, opts) bind(super .. chord, handler, opts) end

key("Return", exec("kitty"))
key("Q", dsp.window.close())
bind("ALT + F4", dsp.window.close())
key("Space", function()
    for _, layer in ipairs(hl.get_layers({ namespace = "noctalia-window-switcher" })) do
        if layer.mapped then
            hl.exec_cmd("noctalia msg window-switcher close")
            return
        end
    end
    hl.exec_cmd("noctalia msg window-switcher")
end)
key("D", exec("qs ipc -n -c win11-start-menu call start-menu toggle"))
key("SHIFT + D", exec("noctalia msg panel-toggle launcher"))
key("SHIFT + W", action("wallpaper"))
key("S", exec("noctalia msg settings-toggle"))
key("V", exec("noctalia msg panel-toggle clipboard"))
bind("CTRL + ALT + Delete", exec("noctalia msg panel-toggle session"))
key("Escape", exec("noctalia msg session lock"), locked)

key("F", dsp.window.fullscreen({ mode = "maximized" }))
key("G", dsp.window.fullscreen({ mode = "fullscreen" }))
key("SHIFT + F", dsp.window.float({ action = "toggle" }))
key("SHIFT + V", float_focus)
key("C", dsp.layout("center"))
key("Left", dsp.layout("focus l"), repeatable)
key("Right", dsp.layout("focus r"), repeatable)
key("Up", function() focus_adjacent(-1) end, repeatable)
key("Down", function() focus_adjacent(1) end, repeatable)
key("SHIFT + Left", dsp.layout("swapcol l"), repeatable)
key("SHIFT + Right", dsp.layout("swapcol r"), repeatable)
key("SHIFT + Up", dsp.window.swap({ direction = "up" }), repeatable)
key("SHIFT + Down", dsp.window.swap({ direction = "down" }), repeatable)
key("Home", function() edge_of_strip(false, false) end)
key("End", function() edge_of_strip(true, false) end)
key("CTRL + Home", function() edge_of_strip(false, true) end)
key("CTRL + End", function() edge_of_strip(true, true) end)
key("Page_Down", function() move_column(adjacent_workspace(1)) end, repeatable)
key("Page_Up", function() move_column(adjacent_workspace(-1)) end, repeatable)
key("SHIFT + Page_Down", function() reorder_workspace(1) end, repeatable)
key("SHIFT + Page_Up", function() reorder_workspace(-1) end, repeatable)

for _, direction in ipairs({"Left", "Right", "Up", "Down"}) do
    key("CTRL + SHIFT + " .. direction, function() move_to_monitor(direction:lower()) end, repeatable)
end
for i = 1, 9 do
    key(tostring(i), dsp.focus({ workspace = i }))
    key("SHIFT + " .. i, function() move_column(i) end)
end
key("CTRL + Left", dsp.layout("colresize -0.05"), repeatable)
key("CTRL + Right", dsp.layout("colresize +0.05"), repeatable)
key("CTRL + Up", function() adjust_height(-0.05) end, repeatable)
key("CTRL + Down", function() adjust_height(0.05) end, repeatable)
key("mouse_down", dsp.layout("focus r"))
key("mouse_up", dsp.layout("focus l"))
key("CTRL + mouse_down", function() focus_adjacent(1) end)
key("CTRL + mouse_up", function() focus_adjacent(-1) end)

bind("Print", action("capture-region"))
key("SHIFT + S", action("capture-region"))
bind("CTRL + Print", action("capture-output"))
bind("ALT + Print", action("capture-window"))
bind("XF86AudioRaiseVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0"), locked_repeat)
bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), locked_repeat)
bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked)
bind("XF86AudioMicMute", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked)
bind("XF86AudioPlay", exec("playerctl play-pause"), locked)
bind("XF86AudioStop", exec("playerctl stop"), locked)
bind("XF86AudioPrev", exec("playerctl previous"), locked)
bind("XF86AudioNext", exec("playerctl next"), locked)
bind("XF86MonBrightnessUp", exec("brightnessctl --class=backlight set +5%"), locked_repeat)
bind("XF86MonBrightnessDown", exec("brightnessctl --class=backlight set 5%-"), locked_repeat)
key("SHIFT + Escape", action("logout"))
