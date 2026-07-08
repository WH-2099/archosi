#!/usr/bin/env fish

if test (id -u) -eq 0
    echo "Run this script as the desktop user, not root."
    exit 1
end

set -l packages \
    hyprland \
    uwsm \
    xorg-xwayland \
    greetd \
    greetd-tuigreet \
    dbus-broker \
    polkit \
    waybar \
    mako \
    hypridle \
    hyprlock \
    playerctl \
    firefox \
    ghostty \
    dolphin \
    hyprlauncher \
    hyprpaper \
    nwg-look \
    xdg-desktop-portal \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    pipewire \
    pipewire-audio \
    wireplumber \
    pipewire-pulse \
    pipewire-alsa \
    gst-plugin-pipewire \
    sof-firmware \
    realtime-privileges \
    gnome-keyring \
    bluez \
    bluez-utils \
    blueman \
    iwd \
    iwgtk \
    pavucontrol \
    hyprpolkitagent \
    qt6ct \
    qt6-wayland \
    otf-atkinsonhyperlegiblemono-nerd \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-cascadia-code \
    grim \
    slurp \
    wl-clipboard \
    cliphist \
    brightnessctl \
    hyprshot \
    wf-recorder \
    satty \
    libnotify \
    ripgrep \
    sd

paru -S --needed $packages

sudo usermod -aG realtime (id -un)

set -l greetd_command_pattern '(^# command = .*\n)?^command = .*$'
set -l greetd_command_replacement "# command = 'tuigreet --time --remember --cmd Hyprland'\ncommand = 'tuigreet --time --remember --cmd \"uwsm start -e -D Hyprland hyprland.desktop\"'"
sudo sd -A -f m -n 1 $greetd_command_pattern $greetd_command_replacement /etc/greetd/config.toml

mkdir -p ~/.config/hypr
mkdir -p ~/.local/bin

set -l hypr_volume_body \
    '#!/usr/bin/env fish' \
    '' \
    'set -l sink @DEFAULT_AUDIO_SINK@' \
    '' \
    'switch $argv[1]' \
    '    case up' \
    '        wpctl set-volume -l 1 $sink 5%+' \
    '    case down' \
    '        wpctl set-volume $sink 5%-' \
    '    case mute' \
    '        wpctl set-mute $sink toggle' \
    '    case "*"' \
    '        echo "usage: hypr-volume up|down|mute" >&2' \
    '        exit 2' \
    'end' \
    '' \
    'set -l status (wpctl get-volume $sink)' \
    'set -l volume (string match -r "[0-9.]+" -- $status | tail -n 1)' \
    'set -l percent (math -s0 "$volume * 100")' \
    '' \
    'if string match -q "*MUTED*" -- $status' \
    '    notify-send -a system -e -h string:x-canonical-private-synchronous:volume "Volume muted"' \
    'else' \
    '    notify-send -a system -e -h string:x-canonical-private-synchronous:volume "Volume $percent%"' \
    'end'
printf '%s\n' $hypr_volume_body >~/.local/bin/hypr-volume
chmod 755 ~/.local/bin/hypr-volume

set -l hypr_brightness_body \
    '#!/usr/bin/env fish' \
    '' \
    'switch $argv[1]' \
    '    case up' \
    '        brightnessctl -e4 -n2 set 5%+' \
    '    case down' \
    '        brightnessctl -e4 -n2 set 5%-' \
    '    case "*"' \
    '        echo "usage: hypr-brightness up|down" >&2' \
    '        exit 2' \
    'end' \
    '' \
    'set -l current (brightnessctl get)' \
    'set -l max (brightnessctl max)' \
    'set -l percent (math -s0 "$current * 100 / $max")' \
    '' \
    'notify-send -a system -e -h string:x-canonical-private-synchronous:brightness "Brightness $percent%"'
printf '%s\n' $hypr_brightness_body >~/.local/bin/hypr-brightness
chmod 755 ~/.local/bin/hypr-brightness

set -l hypr_record_region_body \
    '#!/usr/bin/env fish' \
    '' \
    'set -l pidfile "$XDG_RUNTIME_DIR/hypr-record-region.pid"' \
    '' \
    'if test -f $pidfile' \
    '    set -l pid (cat $pidfile)' \
    '    if kill -0 $pid 2>/dev/null' \
    '        kill -INT $pid' \
    '        rm -f $pidfile' \
    '        notify-send -a system -e -h string:x-canonical-private-synchronous:recording "Recording stopped"' \
    '        exit 0' \
    '    end' \
    '    rm -f $pidfile' \
    'end' \
    '' \
    'set -l dir "$HOME/Videos"' \
    'mkdir -p $dir' \
    '' \
    'set -l geometry (slurp)' \
    'or exit 1' \
    '' \
    'set -l file "$dir/recording-"(date +%Y%m%d-%H%M%S)".mp4"' \
    'wf-recorder -g "$geometry" -f "$file" &' \
    'set -l pid $last_pid' \
    'echo $pid >$pidfile' \
    '' \
    'notify-send -a system -e -h string:x-canonical-private-synchronous:recording "Recording started" "$file"'
printf '%s\n' $hypr_record_region_body >~/.local/bin/hypr-record-region
chmod 755 ~/.local/bin/hypr-record-region

set -l hyprland_dir ~/.config/hypr
set -l hyprland_config $hyprland_dir/hyprland.lua
set -l hypr_programs_config $hyprland_dir/programs.lua
set -l hypr_settings_config $hyprland_dir/settings.lua
set -l hypr_binds_config $hyprland_dir/binds.lua
set -l hypr_rules_config $hyprland_dir/rules.lua

set -l hyprland_body \
    'local programs = require("programs")' \
    '' \
    'require("settings")' \
    'require("binds")(programs)' \
    'require("rules")'
printf '%s\n' $hyprland_body >$hyprland_config

set -l hypr_programs_body \
    'return {' \
    '    terminal     = "ghostty",' \
    '    file_manager = "dolphin",' \
    '    menu         = "hyprlauncher",' \
    '    main_mod     = "SUPER",' \
    '}'
printf '%s\n' $hypr_programs_body >$hypr_programs_config

set -l hypr_settings_body \
    'hl.monitor({' \
    '    output   = "",' \
    '    mode     = "preferred",' \
    '    position = "auto",' \
    '    scale    = "auto",' \
    '})' \
    '' \
    'hl.env("XCURSOR_SIZE", "24")' \
    'hl.env("HYPRCURSOR_SIZE", "24")' \
    'hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")' \
    '' \
    'hl.config({' \
    '    general = {' \
    '        border_size = 2,' \
    '' \
    '        col = {' \
    '            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },' \
    '            inactive_border = "rgba(595959aa)",' \
    '        },' \
    '    },' \
    '' \
    '    decoration = {' \
    '        rounding = 10,' \
    '' \
    '        blur = {' \
    '            size = 3,' \
    '        },' \
    '    },' \
    '})' \
    '' \
    'hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })' \
    'hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })' \
    'hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })' \
    'hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })' \
    'hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })' \
    'hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })' \
    '' \
    'hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })' \
    'hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })' \
    'hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })' \
    'hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 87%" })' \
    'hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })' \
    'hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })' \
    'hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })' \
    'hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })' \
    'hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })' \
    'hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })' \
    'hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })' \
    'hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })' \
    'hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })' \
    'hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })' \
    'hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })' \
    'hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })' \
    'hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })' \
    '' \
    'hl.config({' \
    '    dwindle = {' \
    '        preserve_split = true,' \
    '    },' \
    '})' \
    '' \
    'hl.config({' \
    '    master = {' \
    '        new_status = "master",' \
    '    },' \
    '})' \
    '' \
    'hl.gesture({' \
    '    fingers   = 3,' \
    '    direction = "horizontal",' \
    '    action    = "workspace",' \
    '})'
printf '%s\n' $hypr_settings_body >$hypr_settings_config

set -l hypr_binds_body \
    'return function(programs)' \
    '    local mainMod     = programs.main_mod' \
    '    local terminal    = programs.terminal' \
    '    local fileManager = programs.file_manager' \
    '    local menu        = programs.menu' \
    '' \
    '    hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))' \
    '    hl.bind(mainMod .. " + C", hl.dsp.window.close())' \
    "    hl.bind(mainMod .. \" + M\", hl.dsp.exec_cmd(\"command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'\"))" \
    '    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))' \
    '    hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))' \
    '    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))' \
    '    hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())' \
    '    hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))' \
    '' \
    '    hl.bind("Print",                   hl.dsp.exec_cmd("hyprshot -m region"))' \
    '    hl.bind(mainMod .. " + Print",     hl.dsp.exec_cmd("hyprshot -m output"))' \
    '    hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprshot -m region --raw | satty --filename -"))' \
    '    hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hypr-record-region"))' \
    '' \
    '    hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))' \
    '    hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))' \
    '    hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))' \
    '    hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))' \
    '' \
    '    for i = 1, 10 do' \
    '        local key = i % 10' \
    '        hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))' \
    '        hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))' \
    '    end' \
    '' \
    '    hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))' \
    '    hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))' \
    '' \
    '    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))' \
    '    hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))' \
    '' \
    '    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })' \
    '    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })' \
    '' \
    '    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("hypr-volume up"),                               { locked = true, repeating = true })' \
    '    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("hypr-volume down"),                             { locked = true, repeating = true })' \
    '    hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("hypr-volume mute"),                             { locked = true, repeating = true })' \
    '    hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })' \
    '    hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("hypr-brightness up"),                           { locked = true, repeating = true })' \
    '    hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("hypr-brightness down"),                         { locked = true, repeating = true })' \
    '' \
    '    hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })' \
    '    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })' \
    '    hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })' \
    '    hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })' \
    'end'
printf '%s\n' $hypr_binds_body >$hypr_binds_config

set -l hypr_rules_body \
    'hl.window_rule({' \
    '    name  = "suppress-maximize-events",' \
    '    match = { class = ".*" },' \
    '' \
    '    suppress_event = "maximize",' \
    '})' \
    '' \
    'hl.window_rule({' \
    '    name  = "fix-xwayland-drags",' \
    '    match = {' \
    '        class      = "^$",' \
    '        title      = "^$",' \
    '        xwayland   = true,' \
    '        float      = true,' \
    '        fullscreen = false,' \
    '        pin        = false,' \
    '    },' \
    '' \
    '    no_focus = true,' \
    '})'
printf '%s\n' $hypr_rules_body >$hypr_rules_config

set -l hyprpaper_config ~/.config/hypr/hyprpaper.conf
set -l hyprpaper_wallpaper /usr/share/hypr/wall0.png
touch $hyprpaper_config

if rg -q '^preload\s*=' $hyprpaper_config
    sd -A -f m -n 1 '(^# preload =.*\n)?^preload\s*=.*$' "# preload =\npreload = $hyprpaper_wallpaper" $hyprpaper_config
else
    printf '%s\n' '# preload =' "preload = $hyprpaper_wallpaper" >>$hyprpaper_config
end

if rg -q '^wallpaper\s*=' $hyprpaper_config
    sd -A -f m -n 1 '(^# wallpaper =.*\n)?^wallpaper\s*=.*$' "# wallpaper =\nwallpaper = ,$hyprpaper_wallpaper" $hyprpaper_config
else
    printf '%s\n' '# wallpaper =' "wallpaper = ,$hyprpaper_wallpaper" >>$hyprpaper_config
end

set -l hypridle_config ~/.config/hypr/hypridle.conf
set -l hypridle_config_body \
    'general {' \
    '    lock_cmd = pidof hyprlock || hyprlock' \
    '    before_sleep_cmd = loginctl lock-session' \
    '    after_sleep_cmd = hyprctl dispatch dpms on' \
    '}' \
    '' \
    'listener {' \
    '    timeout = 300' \
    '    on-timeout = brightnessctl -s set 10' \
    '    on-resume = brightnessctl -r' \
    '}' \
    '' \
    'listener {' \
    '    timeout = 600' \
    '    on-timeout = loginctl lock-session' \
    '}' \
    '' \
    'listener {' \
    '    timeout = 660' \
    '    on-timeout = hyprctl dispatch dpms off' \
    '    on-resume = hyprctl dispatch dpms on' \
    '}' \
    ''
printf '%s\n' $hypridle_config_body >$hypridle_config

set -l hyprlock_config ~/.config/hypr/hyprlock.conf
cp /usr/share/hypr/hyprlock.conf $hyprlock_config

set -l graphical_session_wants ~/.config/systemd/user/graphical-session.target.wants
mkdir -p $graphical_session_wants

function enable_graphical_user_service
    set -l unit $argv[1]
    set -l source /usr/lib/systemd/user/$unit

    if not test -e $source
        echo "Missing user unit: $source" >&2
        return 1
    end

    ln -sf $source $graphical_session_wants/$unit
end

enable_graphical_user_service hyprpolkitagent.service
enable_graphical_user_service waybar.service
enable_graphical_user_service mako.service
enable_graphical_user_service hyprpaper.service
enable_graphical_user_service cliphist.service
enable_graphical_user_service hypridle.service

sudo systemctl enable greetd.service
sudo systemctl enable bluetooth.service
sudo systemctl enable iwd.service
sudo systemctl enable systemd-networkd.service
sudo systemctl enable systemd-resolved.service
