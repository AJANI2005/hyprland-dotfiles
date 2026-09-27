#!/usr/bin/env bash

word="${*,,}"

word="${word//-/ }"
word="${word//_/ }"
word="${word//./ }"

declare -a icons=(
    # Browsers
    '(firefox|firefox esr|mozilla firefox|librewolf):󰈹'
    '(zen|zen browser):󰈹'
    '(chrome|google chrome|chromium):󰊯'
    '(brave|brave browser):󰖟'
    '(microsoft edge|edge):󰇩'
    '(opera):󰀹'
    '(vivaldi):󰖟'
    '(qutebrowser):󰖟'
    '(tor browser|tor):󰖟'

    # Terminals
    '(foot):󰆍'
    '(kitty|alacritty|ghostty|wezterm|konsole|gnome terminal|xfce4 terminal):󰆍'
    '(terminal|terminal emulator):󰆍'

    # Editors
    '(neovim|nvim):'
    '(vim):'
    '(emacs):'
    '(visual studio code|vscode|code oss|code):󰨞'
    '(cursor):󰅲'
    '(zed):'
    '(sublime|sublime text):'
    '(atom):'
    '(gedit|kate|mousepad|helix|micro):󰈔'
    '(geany):'

    # JetBrains
    '(intellij|idea|intellij idea):'
    '(pycharm):'
    '(webstorm):'
    '(phpstorm):'
    '(clion):'
    '(goland):󰟓'
    '(rustrover):'
    '(datagrip):'
    '(rubymine):'
    '(rider):󰌛'
    '(fleet):'

    # File managers
    '(thunar|nautilus|gnome files|dolphin|nemo|caja|pcmanfm):󰉋'
    '(yazi|ranger|nnn|lf):󰉋'
    
    # XFCE
    '(xfce|xfce4|xfce desktop|xfce desktop environment):󰣆'

    # Communication
    '(discord):󰙯'
    '(telegram):󰚩'
    '(signal):󰭻'
    '(slack):󰒱'
    '(microsoft teams|teams):󰊻'
    '(zoom):󰖐'
    '(whatsapp):󰖣'
    '(element|matrix):󰭻'
    '(skype):󰒊'

    # Music
    '(spotify|rhythmbox):󰓇'
    '(clementine|audacious|deadbeef|ncmpcpp|cmus|elisa|lollypop|amberol):󰎆'
    '(tidal):󰝚'

    # Video
    '(vlc|totem):󰕼'
    '(mpv|celluloid|haruna):󰐹'
    '(kodi):󰖔'
    '(plex):󰚺'
    '(obs studio):󰑋'
    '(youtube):󰗃'

    # Graphics
    '(gimp):'
    '(inkscape):'
    '(krita):󰉏'
    '(blender):󰂫'
    '(darktable|digikam|rawtherapee):󰄀'
    '(photoshop):󰈀'
    '(illustrator):'
    '(figma):'
    '(pinta):󰏘'

    # Office
    '(libreoffice|libre office|writer):󰈬'
    '(calc|microsoft excel|excel):󰈛'
    '(impress|powerpoint):󰐻'
    '(onlyoffice|only office):󰈬'
    '(microsoft word|word):󰈬'
    '(onenote|notion|obsidian|logseq|joplin):󰎚'

    # Documents
    '(pdf|evince|okular|zathura):󰈦'
    '(calibre|ebook|epub):󰂾'
    '(document|documents):󰈙'

    # Git
    '(github|github desktop):󰊤'
    '(gitlab):󰮠'
    '(gitea):󰊤'
    '(lazygit):󰊢'
    '(git):󰊢'

    # Containers / DevOps
    '(docker|podman):󰡨'
    '(kubernetes|kubectl):󱃾'
    '(helm):󰠳'
    '(terraform):󱁢'
    '(ansible):󰠨'
    '(vagrant):󰚗'


    # Databases
    '(postgres|postgresql):'
    '(mysql|mariadb):'
    '(mongodb):'
    '(redis):󰆼'
    '(sqlite):'
    '(dbeaver):'
    '(database):󰆼'

    # Cloud
    '(aws):󰸏'
    '(azure):󰠅'
    '(google cloud|gcp):󰊭'
    '(cloud):󰅟'
    '(dropbox):󰇣'
    '(onedrive):󰉓'
    '(google drive|drive):󰊶'

    # System
    '(settings|preferences|system settings):󰒓'
    '(system monitor|task manager|btop|htop):󰍛'
    '(file manager|files):󰉋'
    '(system information|fastfetch):󰍛'
    '(asusctl|rog control center|asus):󰒓'
    '(hyprland):󰖯'
    '(quickshell):󰒓'
    '(wayland):󰇧'
    '(linux|kernel):󰌽'

    # Networking
    '(wifi|wireless):󰖩'
    '(bluetooth|bluetui):󰂯'
    '(vpn):󰒃'
    '(network|network manager|nmcli):󰖩'
    '(ethernet):󰈀'
    '(ssh):󰣀'
    '(browser|internet|web):󰖟'

    # Power
    '(battery|upower):󰁹'
    '(shutdown|power off):󰐥'
    '(restart|reboot):󰜉'
    '(sleep|suspend):󰒲'
    '(lock|lock screen|hyprlock):󰌾'
    '(logout|log out):󰍃'

    # Audio
    '(volume|speaker|audio|sound):󰕾'
    '(microphone|mic):󰍬'
    '(headphones):󰋋'
    '(pipewire|wireplumber):󰕾'
    '(pwvucontrol|pavucontrol):󰕾'
    '(playerctl):󰎆'

    # Utilities
    '(calculator|bc):󰃬'
    '(calendar):󰃭'
    '(clock):󰥔'
    '(alarm):󰀠'
    '(timer):󰔛'
    '(search|ripgrep|rg):󰍉'
    '(help):󰋖'
    '(information|info):󰋼'
    '(clipboard|wl clipboard):󰅍'
    '(password|password manager|keepass|bitwarden):󰌋'
    '(qr code|qr):󰜴'
    '(chafa):󰋩'
    '(fzf|fuzzel):󰍉'
    '(mime tui):󰈙'
    '(unzip|zip|archive):󰀼'

    # Files
    '(home):󰋜'
    '(desktop):󰇄'
    '(downloads|download):󰇚'
    '(upload):󰕒'
    '(trash|recycle bin):󰩺'
    '(archive|zip):󰀼'
    '(usb):󰕓'
    '(disk|hard drive):󰋊'
    '(folder|directory):󰉋'
    '(file):󰈙'

    # Games
    '(steam):󰓓'
    '(lutris|heroic):󰺵'
    '(minecraft):󰍳'
    '(wine):󰡯'
    '(game|games):󰊗'
    '(controller):󰖺'

    # Virtualization
    '(qemu|virtual machine|virt manager|virtualbox|vmware):󰇧'

    # Package managers
    '(pacman|paru|yay|apt|dnf|brew|homebrew|flatpak|snap):󰏖'
    '(package|packages|software):󰏖'

    # Math / science
    '(mathcad):󰪚'
    '(matlab):'
    '(jupyter):󰠮'
    '(wolfram|mathematica):󰪚'
    '(octave):󰪚'

    # Screenshots / desktop
    '(screenshot|screen capture|grim|slurp|swappy):󰹑'
    '(wallpaper|awww):󰸉'
    '(notification|notifications|mako):󰂚'
    '(brightness|brightnessctl):󰃠'

    # Fonts / appearance
    '(font|fonts|noto|jetbrains mono|nerd font):󰛖'
    '(cursor|cursors|breeze cursor):󰇀'
    '(theme|gtk|adw|qt):󰉼'

    # Virtual / boot / system
    '(efi|efibootmgr|boot):󰌽'
    '(firmware):󰒓'
    '(nvidia|gpu|graphics):󰢮'
    '(timeshift|backup|restore):󰁯'
    '(zram|swap):󰆧'

    # Generic
    '(camera|webcam):󰄀'
    '(printer):󰐪'
    '(mail|email):󰇮'
    '(contacts):󰀉'
    '(maps|map):󰆧'
    '(weather):󰖕'
    '(news):󰎕'
    '(rss):󰑩'
    '(book|books|reading):󰂾'
    '(school|education|university):󰑴'
)

for entry in "${icons[@]}"; do
    pattern="${entry%%:*}"
    icon="${entry#*:}"

    if [[ "$word" =~ $pattern ]]; then
        printf '%s\n' "$icon"
        exit 0
    fi
done

printf '%s\n' '󰀻'
