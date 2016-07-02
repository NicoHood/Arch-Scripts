#!/bin/bash

# Check for root user
if [[ $EUID -eq 0 ]]; then
  echo "You must NOT be a root user" 2>&1
  exit 1
fi

# Get system information
. ./sysinfo.sh

################################################################################
# Settings
################################################################################

BUILD_DIR=~/hackallthethings # TODO

# Disable components
ENV_VARS=1
XORG=1
LIGHTDM=1
XFCE=1
ARC_THEME=1
ARC_ICON_THEME=1
PLANK=1
KEYBOARD_SHORTCUTS=1
DESKTOP=1
XFCE_TWEAKS=1
FILE_MANAGER=1
TERMINAL=1


################################################################################
# General
################################################################################

# Add /opt/vc tools to path
# TODO per user
if [[ ENV_VARS -eq 1 ]];then
    echo "Configuring environment variables..."

    # Add /opt/vc/bin to $PATH for Raspberry Pi
    if [[ -e "/opt/vc/bin" ]]; then
        grep "^export PATH=.*:/opt/vc/bin" /etc/bash.bashrc
        if [[ $? -ne 0 ]]; then
            echo "Adding /opt/vc/bin to global path."
            echo "export PATH=${PATH}:/opt/vc/bin" | sudo tee -a /etc/bash.bashrc
        fi
    fi
fi


if [[ LIGHTDM -eq 1 ]];then
    # TODO this requires arc theme and background as dependency
    # TODO gui config messes up settings
    LIGHTDM_GREETER_CFG=/etc/lightdm/lightdm-gtk-greeter.conf
    #if [[ ! -e "$TERMINAL_CFG" ]]; then
    #    echo "[Configuration]" > $TERMINAL_CFG
    #fi
    #sed -i '/^FontName=.*/d' $TERMINAL_CFG
    #echo "FontName=Monospace 11" >> $TERMINAL_CFG
fi


################################################################################
# Arc theme
################################################################################

if [[ ARC_THEME -eq 1 ]];then
    # Install Arc theme
    # Arc theme and icons have to be installed from AUR or from git
    # See the official build instructions for the most up to date installation instructions

    # Go to `Settings->Appearance`
    # Go to `Style`
    # Enable the theme (Arc-Darker)
    # Go to `Settings->Window Manager`
    # Go to `Style`
    # Enable the theme (Arc-Darker)
    xfconf-query -c xfwm4 -p /general/theme -s "Arc-Darker"
    xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Darker"
fi

################################################################################
# Arc icon theme
################################################################################

if [[ ARC_ICON_THEME -eq 1 ]];then
    # Arc theme and icons have to be installed from AUR or from git
    # See the official build instructions for the most up to date installation instructions
    echo "Configuring/updating Arc icon theme..."
    cd /tmp
    git clone https://github.com/horst3180/arc-icon-theme --depth 1
    cd arc-icon-theme

    # Before you compile add elementary as fallback icon theme
    sed -ie "s/Inherits=.*/Inherits=Moka,elementary,Adwaita,gnome,hicolor/" Arc/index.theme

    # Build and install
    ./autogen.sh --prefix=/usr
    sudo make install

    # Go to `Settings->Appearance`
    # Go to `Icons`
    # Enable the theme (Arc)
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Arc"

    # Update/generate Arc icon cache:
    sudo gtk-update-icon-cache /usr/share/icons/Arc/
fi



################################################################################
# Keyboard shortcuts
################################################################################

if [[ KEYBOARD_SHORTCUTS -eq 1 ]];then
    # Go to `Settings->Keyboard->Application Shortcuts`
    # Add a new shortcut for `xfce4-screenshooter --fullscreen` for the `Print` key
    # Add a new shortcut for `xfce4-popup-whiskermenu` for the `Super/Windows` key
    # Remove the `Alt+F1`, `Alt+F2` and `Alt+F3` shortcuts
    echo "Configuring keyboard shortcuts..."
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Print -s "xfce4-screenshooter --fullscreen"
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Super_L -s "xfce4-popup-whiskermenu"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>F1" -r
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>F2" -r
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>F3" -r
    # TODO keyboard layout + change layout option
fi


################################################################################
# Desktop setup
################################################################################

if [[ DESKTOP -eq 1 ]];then
    # Download wallpaper from `https://pixabay.com/en/glacier-mountain-snow-hillside-869593/`
    # Move the wallpaper to `/usr/share/backgrounds/xfce/`
    # Go to `Settings->Desktop`
    # Go to `Background`
    # Enable the wallpaper
    # Go to `Icons`
    # Set `Icon type` as `None`
    # Also disable all desktop menus in `Settings->Desktop->Menus`
    echo "Configuring desktop..."

    # Check if wallpaper exists. If not show website link
    if [[ ! -e /usr/share/backgrounds/xfce/glacier.jpg ]]; then
        if [[ ! -e glacier.jpg ]]; then
            echo "Error: No desktop background found."
            echo "Please download it from: https://pixabay.com/en/glacier-mountain-snow-hillside-869593/"
            echo "Place it into this folder as 'glacier.jpg' and rerun this script."
            exit 1
        fi
        sudo cp glacier.jpg /usr/share/backgrounds/xfce/glacier.jpg
    fi
    xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "/usr/share/backgrounds/xfce/glacier.jpg"
fi


################################################################################
# Xfce tweaks
################################################################################

if [[ XFCE_TWEAKS -eq 1 ]];then
    # Install several Xfce related tweaks/fixes
    echo "Configuring Xfce tweaks..."

    # Go to `Settings->Window Manager Tweaks`
    # Go to `Cycling`
    # Enable `Cycle through windows on all workspaces`
    # Disable `Draw frame around selected windows while cycling`
    # Go to `Accessibility`
    # Disable `Use mouse wheel on tile bar to roll up the window`
    # Go to `Workspaces`
    # Disable `Use the mouse wheel on the desktop to switch workspaces`
    # Go to `Compositor`
    # Disable `Show shadows under dock windows` to get rid of the sticky horizontal line
    xfconf-query -c xfwm4 -p /general/cycle_workspaces -s true
    xfconf-query -c xfwm4 -p /general/cycle_draw_frame -s false
    xfconf-query -c xfwm4 -p /general/mousewheel_rollup -s false
    xfconf-query -c xfwm4 -p /general/scroll_workspaces -s false
    xfconf-query -c xfwm4 -p /general/show_dock_shadow -s false


    # Go to `Settings->Session and Startup`
    # Go to `General`
    # Disable `Automatically save session on logout`
    # Go to `Session`
    # Hit `Clear saved session`
    xfconf-query -c xfce4-session -p /general/AutoSave -s false
    rm -f ~/.cache/sessions/xfce4-session-*


    # Go to `Settings->Workspaces`
    # Set `Number of workspaces` to `1`
    xfconf-query -c xfwm4 -p /general/workspace_count -s 1
fi


################################################################################
# File Manager
################################################################################

if [[ FILE_MANAGER -eq 1 ]];then
    # Go to `Settings->File Manager`
    # Go to `Side Pane`
    # Set all `Icon Size` to `Very Small`
    # Go to `Behavior`
    # Enable `Middle Click->Open folder in new tab`
    echo "Configuring file manager..."
    xfconf-query -c thunar -p /shortcuts-icon-size -s "THUNAR_ICON_SIZE_SMALLEST"
    xfconf-query -c thunar -p /tree-icon-size -s "THUNAR_ICON_SIZE_SMALLEST"
    xfconf-query -c thunar -p /misc-middle-click-in-tab -s true
fi


################################################################################
# Terminal
################################################################################

if [[ TERMINAL -eq 1 ]];then
    # Open a Terminal and go to `Edit->Preferences`
    # Go to `Appearance`
    # Set `Font` to `Monospace 11`
    # Set the `Background` to `Transparent background` with `Transparency 0.95`
    # Go to `Colors`
    # Set `Background color` to the Arc window color (#2F343F)
    # Set `Cursor color` to the Arc text color (#AAAAAA)
    # Set `Tab activity color` to The Arc close button color (#FF5555)
    # You can also drop the colors from the `Palette`
    echo "Configuring terminal..."
    TERMINAL_CFG=~/.config/xfce4/terminal/terminalrc
    if [[ ! -e "$TERMINAL_CFG" ]]; then
        mkdir -p ~/.config/xfce4/terminal
        echo "[Configuration]" > $TERMINAL_CFG
    fi
    sed -i '/^FontName=.*/d' $TERMINAL_CFG
    echo "FontName=Monospace 11" >> $TERMINAL_CFG
    sed -i '/^BackgroundDarkness=.*/d' $TERMINAL_CFG
    echo "BackgroundDarkness=0.950000" >> $TERMINAL_CFG
    sed -i '/^BackgroundMode=/d' $TERMINAL_CFG
    echo "BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT" >> $TERMINAL_CFG
    sed -i '/^ColorBackground=.*/d' $TERMINAL_CFG
    echo "ColorBackground=#2f2f34343f3f" >> $TERMINAL_CFG
    sed -i '/^ColorCursor=.*/d' $TERMINAL_CFG
    echo "ColorCursor=#aaaaaaaaaaaa" >> $TERMINAL_CFG
    sed -i '/^TabActivityColor=.*/d' $TERMINAL_CFG
    echo "TabActivityColor=#ffff55555555" >> $TERMINAL_CFG
fi


################################################################################
# End
################################################################################

echo "All settings applied. You might need to logout/restart to take effect the changes."
