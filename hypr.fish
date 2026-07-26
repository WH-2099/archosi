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
    fcitx5-im \
    fcitx5-rime \
    rime-ice-pinyin-git \
    waybar \
    power-profiles-daemon \
    mako \
    hypridle \
    hyprlock \
    fprintd \
    playerctl \
    firefox \
    ghostty \
    dolphin \
    hyprlauncher \
    hyprpaper \
    hyprshutdown \
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
    breeze \
    kconfig \
    qt6ct \
    qt5-wayland \
    qt6-wayland \
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
    sd \
    visual-studio-code-bin

paru -S --needed $packages

set -l rime_dir ~/.local/share/fcitx5/rime
mkdir -p ~/.config/uwsm
mkdir -p ~/.config/fcitx5
mkdir -p $rime_dir
mkdir -p ~/.vscode

set -l vscode_argv ~/.vscode/argv.json
if not test -f $vscode_argv
    printf '%s\n' '{' '    "password-store": "gnome-libsecret"' '}' >$vscode_argv
else if rg -q '^\s*"password-store"\s*:' $vscode_argv
    sd '^(\s*)"password-store"\s*:\s*"[^"]*"' '$1"password-store": "gnome-libsecret"' $vscode_argv
else
    sd -n 1 '^\{' '{\n    "password-store": "gnome-libsecret",' $vscode_argv
end

rg -q '^\s*"password-store"\s*:\s*"gnome-libsecret"' $vscode_argv
or begin
    echo "Failed to configure VS Code password store."
    exit 1
end

set -l uwsm_env_body \
    'export XMODIFIERS=@im=fcitx' \
    "export QT_IM_MODULES='wayland;fcitx'"
printf '%s\n' $uwsm_env_body >~/.config/uwsm/env

set -l fcitx_profile_body \
    '[Groups/0]' \
    'Name=Default' \
    'Default Layout=us' \
    'DefaultIM=rime' \
    '' \
    '[Groups/0/Items/0]' \
    'Name=keyboard-us' \
    'Layout=' \
    '' \
    '[Groups/0/Items/1]' \
    'Name=rime' \
    'Layout=' \
    '' \
    '[GroupOrder]' \
    '0=Default'
printf '%s\n' $fcitx_profile_body >~/.config/fcitx5/profile

set -l default_custom_body \
    'patch:' \
    '  __include: rime_ice_suggestion:/' \
    '  __patch:' \
    '    ascii_composer/switch_key/Shift_R: inline_ascii' \
    '' \
    '    menu/page_size: 9' \
    '' \
    '    switcher/hotkeys:' \
    '      - "Control+backslash"' \
    '' \
    '    key_binder/select_first_character: comma' \
    '    key_binder/select_last_character: period' \
    '    key_binder/bindings/+:' \
    '      - { when: paging, accept: bracketleft, send: Page_Up }' \
    '      - { when: has_menu, accept: bracketright, send: Page_Down }' \
    '      - { when: composing, accept: Control+bracketleft, send: Escape }'
printf '%s\n' $default_custom_body >$rime_dir/default.custom.yaml

set -l wanxiang_model $rime_dir/wanxiang-lts-zh-hans.gram
if not test -s $wanxiang_model
    curl --fail --location --retry 3 --remove-on-error \
        --output $wanxiang_model.part \
        https://github.com/amzxyz/RIME-LMDG/releases/download/LTS/wanxiang-lts-zh-hans.gram
    and mv $wanxiang_model.part $wanxiang_model
    or exit 1
end

set -l rime_ice_custom_body \
    'patch:' \
    '  grammar:' \
    '    language: wanxiang-lts-zh-hans' \
    '    collocation_max_length: 6' \
    '    collocation_min_length: 3' \
    '    collocation_penalty: -14' \
    '    non_collocation_penalty: -6' \
    '    weak_collocation_penalty: -100' \
    '    rear_penalty: -20' \
    '  translator/contextual_suggestions: false' \
    '  translator/max_homophones: 8'
printf '%s\n' $rime_ice_custom_body >$rime_dir/rime_ice.custom.yaml

set -l system_fontconfig (mktemp /tmp/60-cascadia-noto-fallback.XXXXXX.conf)
set -l system_fontconfig_body '<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family"><string>sans-serif</string></test>
    <test name="lang" compare="eq"><string>zh-tw</string></test>
    <edit name="family" mode="prepend"><string>Noto Sans CJK TC</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>serif</string></test>
    <test name="lang" compare="eq"><string>zh-tw</string></test>
    <edit name="family" mode="prepend"><string>Noto Serif CJK TC</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>monospace</string></test>
    <test name="lang" compare="eq"><string>zh-tw</string></test>
    <edit name="family" mode="prepend"><string>Noto Sans Mono CJK TC</string></edit>
  </match>

  <match target="pattern">
    <test name="family"><string>sans-serif</string></test>
    <test name="lang" compare="eq"><string>zh-hk</string></test>
    <edit name="family" mode="prepend"><string>Noto Sans CJK HK</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>serif</string></test>
    <test name="lang" compare="eq"><string>zh-hk</string></test>
    <edit name="family" mode="prepend"><string>Noto Serif CJK HK</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>monospace</string></test>
    <test name="lang" compare="eq"><string>zh-hk</string></test>
    <edit name="family" mode="prepend"><string>Noto Sans Mono CJK HK</string></edit>
  </match>

  <match target="pattern">
    <test name="family"><string>sans-serif</string></test>
    <test name="lang" compare="eq"><string>zh-mo</string></test>
    <edit name="family" mode="prepend"><string>Noto Sans CJK TC</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>serif</string></test>
    <test name="lang" compare="eq"><string>zh-mo</string></test>
    <edit name="family" mode="prepend"><string>Noto Serif CJK TC</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>monospace</string></test>
    <test name="lang" compare="eq"><string>zh-mo</string></test>
    <edit name="family" mode="prepend"><string>Noto Sans Mono CJK TC</string></edit>
  </match>

  <match target="pattern">
    <test name="family"><string>sans-serif</string></test>
    <test name="lang" compare="contains"><string>ja</string></test>
    <edit name="family" mode="prepend"><string>Noto Sans CJK JP</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>serif</string></test>
    <test name="lang" compare="contains"><string>ja</string></test>
    <edit name="family" mode="prepend"><string>Noto Serif CJK JP</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>monospace</string></test>
    <test name="lang" compare="contains"><string>ja</string></test>
    <edit name="family" mode="prepend"><string>Noto Sans Mono CJK JP</string></edit>
  </match>

  <match target="pattern">
    <test name="family"><string>sans-serif</string></test>
    <test name="lang" compare="contains"><string>ko</string></test>
    <edit name="family" mode="prepend"><string>Noto Sans CJK KR</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>serif</string></test>
    <test name="lang" compare="contains"><string>ko</string></test>
    <edit name="family" mode="prepend"><string>Noto Serif CJK KR</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>monospace</string></test>
    <test name="lang" compare="contains"><string>ko</string></test>
    <edit name="family" mode="prepend"><string>Noto Sans Mono CJK KR</string></edit>
  </match>

  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans</family>
      <family>Noto Sans CJK SC</family>
    </prefer>
  </alias>
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif</family>
      <family>Noto Serif CJK SC</family>
    </prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>Cascadia Code NF</family>
      <family>Noto Sans Mono CJK SC</family>
    </prefer>
  </alias>
</fontconfig>'
printf '%s\n' "$system_fontconfig_body" >$system_fontconfig
sudo install -Dm644 $system_fontconfig /etc/fonts/conf.d/60-cascadia-noto-fallback.conf
rm -f $system_fontconfig

mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0
mkdir -p ~/.config/mako
mkdir -p ~/.config/qt6ct

set -l gtk_settings_body \
    '[Settings]' \
    'gtk-theme-name=Adwaita-dark' \
    'gtk-icon-theme-name=breeze-dark' \
    'gtk-font-name=Noto Sans 11' \
    'gtk-cursor-theme-name=Adwaita' \
    'gtk-cursor-theme-size=24' \
    'gtk-im-module=fcitx' \
    'gtk-application-prefer-dark-theme=1'
printf '%s\n' $gtk_settings_body >~/.config/gtk-3.0/settings.ini
printf '%s\n' $gtk_settings_body >~/.config/gtk-4.0/settings.ini

set -l gtk2_settings_body \
    'gtk-theme-name="Adwaita-dark"' \
    'gtk-icon-theme-name="breeze-dark"' \
    'gtk-font-name="Noto Sans 11"' \
    'gtk-cursor-theme-name="Adwaita"' \
    'gtk-cursor-theme-size=24'
printf '%s\n' $gtk2_settings_body >~/.gtkrc-2.0

set -l qt6ct_body \
    '[Appearance]' \
    'color_scheme_path=/usr/share/qt6ct/colors/darker.conf' \
    'custom_palette=true' \
    'icon_theme=breeze-dark' \
    'standard_dialogs=default' \
    'style=Breeze' \
    '' \
    '[Fonts]' \
    'fixed="Cascadia Mono,11,-1,5,50,0,0,0,0,0"' \
    'general="Noto Sans,11,-1,5,50,0,0,0,0,0"' \
    '' \
    '[Interface]' \
    'activate_item_on_single_click=1' \
    'buttonbox_layout=0' \
    'cursor_flash_time=1000' \
    'dialog_buttons_have_icons=1' \
    'double_click_interval=400' \
    'gui_effects=@Invalid()' \
    'keyboard_scheme=2' \
    'menus_have_icons=true' \
    'show_shortcuts_in_context_menus=true' \
    'stylesheets=@Invalid()' \
    'toolbutton_style=4' \
    'underline_shortcut=1' \
    'wheel_scroll_lines=3'
printf '%s\n' $qt6ct_body >~/.config/qt6ct/qt6ct.conf

set -l mako_config_body \
    'border-radius=0' \
    'default-timeout=90000' \
    'max-visible=9' \
    'max-history=99' \
    '' \
    '[urgency=critical]' \
    'default-timeout=0'
printf '%s\n' $mako_config_body >~/.config/mako/config

kwriteconfig6 --file kdeglobals --group General --key ColorScheme 'Breeze Dark'
kwriteconfig6 --file kdeglobals --group Icons --key Theme breeze-dark
kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop
kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme 'Breeze Dark'
kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme 'Breeze Dark'

gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null; or true
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark 2>/dev/null; or true
gsettings set org.gnome.desktop.interface icon-theme breeze-dark 2>/dev/null; or true
gsettings set org.gnome.desktop.interface cursor-theme Adwaita 2>/dev/null; or true
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11' 2>/dev/null; or true

sudo usermod -aG realtime (id -un)

set -l greetd_command_pattern '(^# command = .*\n)?^command = .*$'
set -l greetd_command_replacement "# command = 'tuigreet --time --remember --cmd Hyprland'\ncommand = 'tuigreet --time --remember --cmd \"uwsm start -e -D Hyprland hyprland.desktop\"'"
sudo sd -A -f m -n 1 $greetd_command_pattern $greetd_command_replacement /etc/greetd/config.toml

set -l greetd_pam /etc/pam.d/greetd
set -l greetd_pam_auth 'auth       include      system-local-login
auth       optional     pam_gnome_keyring.so'
set -l greetd_pam_session 'session    include      system-local-login
session    optional     pam_gnome_keyring.so auto_start'

if not rg -q '^auth\s+optional\s+pam_gnome_keyring\.so\s*$' $greetd_pam
    sudo sd '^auth\s+include\s+system-local-login$' $greetd_pam_auth $greetd_pam
    or exit 1
end

if not rg -q '^session\s+optional\s+pam_gnome_keyring\.so\s+auto_start\s*$' $greetd_pam
    sudo sd '^session\s+include\s+system-local-login$' $greetd_pam_session $greetd_pam
    or exit 1
end

rg -q '^auth\s+optional\s+pam_gnome_keyring\.so\s*$' $greetd_pam
and rg -q '^session\s+optional\s+pam_gnome_keyring\.so\s+auto_start\s*$' $greetd_pam
or begin
    echo "Failed to configure GNOME Keyring PAM hooks in $greetd_pam" >&2
    exit 1
end

mkdir -p ~/.config/hypr
mkdir -p ~/.local/bin

set -l hypr_record_region_body \
    '#!/usr/bin/env fish' \
    '' \
    'if pkill -INT -x wf-recorder' \
    '    notify-send -a system -e -h string:x-canonical-private-synchronous:recording "Recording stopped"' \
    '    exit 0' \
    'end' \
    '' \
    'set -l dir "$HOME/Videos"' \
    'mkdir -p $dir' \
    '' \
    'set -l geometry (slurp)' \
    'or exit 1' \
    '' \
    'set -l file "$dir/recording-"(date +%Y%m%d-%H%M%S)".mp4"' \
    'notify-send -a system -e -h string:x-canonical-private-synchronous:recording "Recording started" "$file"' \
    'wf-recorder -g "$geometry" -f "$file"'
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
    'local home = os.getenv("HOME") or "/home/wh2099"' \
    'local localBin = home .. "/.local/bin"' \
    'local path = os.getenv("PATH") or "/usr/local/sbin:/usr/local/bin:/usr/bin"' \
    '' \
    'if not string.find(":" .. path .. ":", ":" .. localBin .. ":", 1, true) then' \
    '    hl.env("PATH", path .. ":" .. localBin)' \
    'end' \
    '' \
    'hl.env("XCURSOR_SIZE", "24")' \
    'hl.env("HYPRCURSOR_SIZE", "24")' \
    'hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")' \
    '' \
    'hl.config({' \
    '    general = {' \
    '        border_size = 1,' \
    '        gaps_in = 0,' \
    '        gaps_out = 0,' \
    '' \
    '        col = {' \
    '            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },' \
    '            inactive_border = "rgba(595959aa)",' \
    '        },' \
    '    },' \
    '' \
    '    decoration = {' \
    '        rounding = 0,' \
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
    '})' \
    '' \
    'hl.gesture({' \
    '    fingers        = 3,' \
    '    direction      = "vertical",' \
    '    action         = "special",' \
    '    workspace_name = "magic",' \
    '})' \
    '' \
    'hl.gesture({' \
    '    fingers   = 3,' \
    '    direction = "pinch",' \
    '    action    = "cursor_zoom",' \
    '    mode      = "live",' \
    '})' \
    '' \
    'hl.gesture({' \
    '    fingers   = 4,' \
    '    direction = "swipe",' \
    '    action    = "move",' \
    '})' \
    '' \
    'hl.gesture({' \
    '    fingers   = 4,' \
    '    direction = "swipe",' \
    '    mods      = "SUPER",' \
    '    action    = "resize",' \
    '})' \
    '' \
    'hl.gesture({' \
    '    fingers   = 4,' \
    '    direction = "pinch",' \
    '    action    = "fullscreen",' \
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
    '    hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))' \
    '    hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprshutdown"))' \
    '    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))' \
    '    hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("firefox"))' \
    '    hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))' \
    '    hl.bind("ALT + space", hl.dsp.exec_cmd(menu))' \
    '    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))' \
    '    hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())' \
    '    hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))' \
    '' \
    '    hl.bind("Print",                             hl.dsp.exec_cmd("hyprshot -m output --raw | satty --filename -"))' \
    '    hl.bind("XF86SelectiveScreenshot",           hl.dsp.exec_cmd("hyprshot -m region --raw | satty --filename -"))' \
    '    hl.bind(mainMod .. " + Print",               hl.dsp.exec_cmd("hyprshot -m output"))' \
    '    hl.bind(mainMod .. " + XF86SelectiveScreenshot", hl.dsp.exec_cmd("hyprshot -m region"))' \
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
    '    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })' \
    '    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })' \
    '    hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })' \
    '    hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })' \
    '    hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })' \
    '    hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })' \
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
set -l hyprlock_config_body \
    '$font = Monospace' \
    '' \
    'general {' \
    '    hide_cursor = true' \
    '}' \
    '' \
    'auth {' \
    '    fingerprint {' \
    '        enabled = true' \
    '        ready_message = Touch the power-button sensor' \
    '        present_message = Scanning...' \
    '        retry_delay = 250' \
    '    }' \
    '}' \
    '' \
    'animations {' \
    '    enabled = true' \
    '    bezier = linear, 1, 1, 0, 0' \
    '    animation = fadeIn, 1, 5, linear' \
    '    animation = fadeOut, 1, 5, linear' \
    '    animation = inputFieldDots, 1, 2, linear' \
    '}' \
    '' \
    'background {' \
    '    monitor =' \
    '    path =' \
    '    color = rgb(000000)' \
    '    blur_passes = 0' \
    '}' \
    '' \
    'input-field {' \
    '    monitor =' \
    '    size = 32%, 7%' \
    '    outline_thickness = 4' \
    '    inner_color = rgba(0, 0, 0, 0.0)' \
    '    outer_color = rgba(33ccffee) rgba(00ff99ee) 45deg' \
    '    check_color = rgba(00ff99ee) rgba(ff6633ee) 120deg' \
    '    fail_color = rgba(ff6633ee) rgba(ff0066ee) 40deg' \
    '    font_color = rgb(143, 143, 143)' \
    '    fade_on_empty = false' \
    '    rounding = 0' \
    '    font_family = $font' \
    '    placeholder_text = $PAMPROMPT<br/>$FPRINTPROMPT' \
    '    fail_text = $FAIL' \
    '    hide_input = true' \
    '    position = 0, 35' \
    '    halign = center' \
    '    valign = center' \
    '}' \
    '' \
    'label {' \
    '    monitor =' \
    '    text = cmd[update:60000] date +%F' \
    '    font_size = 144' \
    '    font_family = $font' \
    '    position = 0, -130' \
    '    halign = center' \
    '    valign = top' \
    '}' \
    '' \
    'label {' \
    '    monitor =' \
    '    text = cmd[update:1000] date +%T' \
    '    font_size = 88' \
    '    font_family = $font' \
    '    position = 0, -360' \
    '    halign = center' \
    '    valign = top' \
    '}' \
    ''
printf '%s\n' $hyprlock_config_body >$hyprlock_config

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
