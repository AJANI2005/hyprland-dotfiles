local notified = {}

hl.on("window.urgent", function(w)
  local u = hl.get_urgent_window() or w
  if u == nil then return end

  local ws  = u.workspace
  local cur = hl.get_active_workspace()

  -- unknown workspace, or same as current: stay silent
  if ws == nil or cur == nil or ws.id == cur.id then return end

  local key = tostring(u.address or u.class)
  if notified[key] then return end
  notified[key] = true

  local sel = u.address and ("address:" .. u.address)
              or ("class:^(" .. tostring(u.class) .. ")$")

  hl.exec_cmd(string.format(
    "a=$(notify-send -u critical --action=default=Go --wait 'Go to workspace %s' 'to view %s'); "
    .. "[ \"$a\" = default ] && hyprctl dispatch 'hl.dsp.focus({ window = \"%s\" })'",
    tostring(ws.name), tostring(u.class), sel))
end)

-- allow a new notification after you switch workspaces
hl.on("workspace.active", function() notified = {} end)
