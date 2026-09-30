-- Programs
local terminal="foot"
local browser="librewolf"
local files="thunar"
local screenshot_region=[[grim -g "$(slurp)" - | swappy -f -]];
local screenshot_full="grim - | swappy -f -";
local mainMod="SUPER"
local tui="$HOME/dotfiles/menus/launch.sh"

-- Permissions
hl.permission({
  binary = "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland",
  type = "screencopy",
  mode = "allow",
})


-- Monitors
hl.monitor({output="",mode="preferred",position="auto",scale="auto"})
hl.monitor({output="DP-1",mode="preferred",position="auto",scale="1"})
hl.monitor({output="eDP-1",mode="1920x1080@144",position="0x0",scale="1"})

-- Environment
hl.env("LIBVA_DRIVER_NAME","nvidia");
hl.env("__GLX_VENDOR_LIBRARY_NAME","nvidia");
hl.env("XCURSOR_THEME","Breeze_Light");
hl.env("XCURSOR_SIZE","24")
hl.env("QT_QPA_PLATFORMTHEME","qt6ct")

-- Autostart
hl.on("hyprland.start",function()
  hl.exec_cmd("hypridle");
  hl.exec_cmd("mako")
  hl.exec_cmd("qs")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("systemctl start hyprpolkitagent --user")

  -- Apps
  hl.exec_cmd("morgen &")
end)

-- Look & Feel
hl.config({
  general={gaps_in=5,gaps_out=8,
  border_size=2,col={
    active_border="rgba(666666cc)",
    inactive_border="rgba(33333388)"},
    resize_on_border=true,allow_tearing=false,float_gaps=-1,layout="dwindle"},
    decoration={rounding=4,rounding_power=2,
    shadow={enabled=true,range=3,render_power=2,color=0x55000000},blur={enabled=false}},
    dwindle={preserve_split=true},
    master={new_status="master"},
    scrolling={fullscreen_on_one_column=true},
    input={kb_layout="us",repeat_rate=25,repeat_delay=300,
    follow_mouse=1,sensitivity=0,touchpad={natural_scroll=true}},
    misc={disable_splash_rendering = true,force_default_wallpaper=1,disable_hyprland_logo=true,
    mouse_move_enables_dpms=true, key_press_enables_dpms=true
  },
})

hl.gesture({fingers=3,direction="horizontal",action="workspace"})

-- Programs
hl.bind(mainMod.." + Return",hl.dsp.exec_cmd(terminal))
hl.bind(mainMod.." + B",hl.dsp.exec_cmd(browser))
hl.bind(mainMod.." + E",hl.dsp.exec_cmd(files))
hl.bind(mainMod.." + SHIFT + C",hl.dsp.exec_cmd(browser .. " --new-window https://www.chatgpt.com"))


-- Menus
hl.bind(mainMod.." + Space",hl.dsp.exec_cmd(tui .. " apps.sh"))
hl.bind(mainMod.." + SHIFT + P",hl.dsp.exec_cmd(tui .. " power.sh"))
hl.bind(mainMod.." + SHIFT + W",hl.dsp.exec_cmd("qs ipc call wallpapers toggle"))



-- System
hl.bind(mainMod.." + SHIFT + M",hl.dsp.exit())
hl.bind(mainMod.." + SHIFT + Escape",hl.dsp.exec_cmd("hyprlock"))

-- ASUS 
--
local asus_profile_cmd='asusctl profile next && notify-send "ASUS Profile" "$(asusctl profile get | head -n1)"'

hl.bind(mainMod.." + F5",hl.dsp.exec_cmd(asus_profile_cmd))
hl.bind( mainMod .. " + F6",
hl.dsp.exec_cmd("sleep 1 && hyprctl dispatch 'hl.dsp.dpms({ action = \"off\", monitor = \"\" })' "),
{ description = "Turn Off Monitor", locked = true, repeating = false })

hl.bind(mainMod.." + F9",hl.dsp.exec_cmd("setsid -f gtk-launch hyprmoncfg &>/dev/null"))


-- Screenshots
hl.bind(mainMod.." + S",hl.dsp.exec_cmd(screenshot_region))
hl.bind(mainMod.." + SHIFT + S",hl.dsp.exec_cmd(screenshot_full))

-- Windows
hl.bind(mainMod.." + Q",hl.dsp.window.close())
hl.bind(mainMod.." + F",hl.dsp.window.fullscreen({mode="maximized",action="toggle"}))
hl.bind(mainMod.." + SHIFT + F",hl.dsp.window.fullscreen({mode="fullscreen",action="toggle"}))
hl.bind(mainMod.." + W",hl.dsp.window.float({action="toggle"}))
hl.bind(mainMod.." + TAB",hl.dsp.window.cycle_next(),{description="Cycle windows"})

-- Focus
hl.bind(mainMod.." + left",hl.dsp.focus({direction="left"})); hl.bind(mainMod.." + right",hl.dsp.focus({direction="right"}))
hl.bind(mainMod.." + up",hl.dsp.focus({direction="up"})); hl.bind(mainMod.." + down",hl.dsp.focus({direction="down"}))
hl.bind(mainMod.." + h",hl.dsp.focus({direction="left"})); hl.bind(mainMod.." + l",hl.dsp.focus({direction="right"}))
hl.bind(mainMod.." + k",hl.dsp.focus({direction="up"})); hl.bind(mainMod.." + j",hl.dsp.focus({direction="down"}))

-- Move windows
hl.bind(mainMod.." + SHIFT + h",hl.dsp.window.move({direction="left"})); hl.bind(mainMod.." + SHIFT + l",hl.dsp.window.move({direction="right"}))
hl.bind(mainMod.." + SHIFT + j",hl.dsp.window.move({direction="down"})); hl.bind(mainMod.." + SHIFT + k",hl.dsp.window.move({direction="up"}))

-- Layout
hl.bind(mainMod.." + T",function()
  local ws=hl.get_active_workspace()
  if not ws then return end
  hl.workspace_rule({workspace=ws.id,layout=ws.tiled_layout=="scrolling" and "dwindle" or "scrolling"})
end,{description="Toggle tiling / scrolling layout"})

-- Workspaces
for i=1,10 do local key=i%10; hl.bind(mainMod.." + "..key,hl.dsp.focus({workspace=i})); hl.bind(mainMod.." + SHIFT + "..key,hl.dsp.window.move({workspace=i})) end
hl.bind(mainMod.." + mouse_down",hl.dsp.focus({workspace="e+1"})); hl.bind(mainMod.." + mouse_up",hl.dsp.focus({workspace="e-1"}))
hl.bind(mainMod.." + mouse:272",hl.dsp.window.drag(),{mouse=true}); hl.bind(mainMod.." + mouse:273",hl.dsp.window.resize(),{mouse=true})

-- Multimedia
hl.bind("XF86AudioRaiseVolume",hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),{locked=true,repeating=true})
hl.bind("XF86AudioLowerVolume",hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),{locked=true,repeating=true})
hl.bind("XF86AudioMute",hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),{locked=true,repeating=true})
hl.bind("XF86AudioMicMute",hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),{locked=true,repeating=true})
hl.bind("XF86MonBrightnessUp",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),{locked=true,repeating=true})
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),{locked=true,repeating=true})
hl.bind("XF86AudioNext",hl.dsp.exec_cmd("playerctl next"),{locked=true})
hl.bind("XF86AudioPlay",hl.dsp.exec_cmd("playerctl play-pause"),{locked=true})
hl.bind("XF86AudioPrev",hl.dsp.exec_cmd("playerctl previous"),{locked=true})

-- Window Rules
hl.window_rule({name="suppress-maximize-events",match={class=".*"},suppress_event="maximize"})
hl.window_rule({name="fix-xwayland-drags",match={class="^$",title="^$",xwayland=true,float=true,fullscreen=false,pin=false},no_focus=true})
hl.window_rule({name="floating-utilities",match={class="^(org.gnome.Calculator|thunar|mpv|blueman-manager|com.saivert.pwvucontrol)$"},float=true,pin=true})
hl.window_rule({name="picture-in-picture",match={title="^(Picture-in-Picture)$"},float=true,pin=true,size={400,400}})
hl.window_rule({ match={class="^(btop|hyprmon)$"},float=true,pin=true,size={1440,900}})


hl.window_rule({ match={class="^(tui-package.sh)$"},float=true,pin=true,size={1200,600}})
hl.window_rule({ match={class="^(tui-apps.sh)$"},float=true,pin=true,size={500,800}})

-- Match bluetui,mimetui etc
hl.window_rule({name="floating-tuis",match={class="^(.*tui.*)$"},float=true,pin=true})




-- Curves
hl.curve("md3_decel", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })
hl.curve("md3_accel", { type = "bezier", points = { {0.3, 0}, {0.8, 0.15} } })
hl.curve("hyprnostretch", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })
hl.curve("menu_decel", { type = "bezier", points = { {0.1, 1}, {0, 1} } })
hl.curve("menu_accel", { type = "bezier", points = { {0.38, 0.04}, {1, 0.07} } })
hl.curve("linear", { type = "bezier", points = { {0, 0}, {1, 1} } })

-- Windows
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "hyprnostretch", style = "popin 80%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "md3_decel", style = "popin 75%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "md3_accel", style = "popin 75%" })
hl.animation({ leaf = "windowsMove", enabled = false })

-- Fade
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "md3_decel" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "md3_decel" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.5, bezier = "md3_accel" })

-- Layers
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "md3_decel" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.5, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.6, bezier = "menu_accel" })

-- Layer fades
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.5, bezier = "menu_accel" })

-- Workspaces
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "menu_decel", style = "slidefade 10%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 3, bezier = "menu_decel", style = "slidefade 10%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2, bezier = "menu_accel", style = "slidefade 10%" })

-- Border
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "md3_decel" })

-- Zoom
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 5, bezier = "md3_decel" })
