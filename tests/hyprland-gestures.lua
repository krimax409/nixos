assert(os.getenv("HYPRLAND_LAPTOP_TEST") == "1", "run with HYPRLAND_LAPTOP_TEST=1 and --verify-config")
local config_dir = assert(os.getenv("HYPRLAND_LAPTOP_CONFIG"), "set HYPRLAND_LAPTOP_CONFIG")
local gestures, messages, dispatched = {}, {}, {}
local register, layout = hl.gesture, hl.dsp.layout

hl.gesture = function(spec)
    register(spec)
    if spec.fingers == 3 and not spec.mods then gestures[spec.direction] = spec.action end
end
hl.dsp.layout = function(message)
    local dispatcher = layout(message)
    messages[dispatcher] = message
    return dispatcher
end
hl.dispatch = function(dispatcher)
    dispatched[#dispatched + 1] = assert(messages[dispatcher], "expected a scrolling layout dispatch")
end

dofile(config_dir .. "/hyprland.lua")
for direction, expected in pairs({ left = "focus l", right = "focus r" }) do
    local action = assert(gestures[direction], "missing three-finger swipe " .. direction)
    local event = { type = "swipe", phase = "end", time_ms = 100, direction = direction, cancelled = true }
    dispatched = {}
    action.finish(event)
    assert(#dispatched == 0, "cancelled swipe moved focus")
    event.cancelled = false
    action.finish(event)
    assert(#dispatched == 1 and dispatched[1] == expected, "swipe " .. direction .. " did not focus the adjacent column")
end
print("PASS: three-finger swipes focus the adjacent column once and ignore cancellations")
