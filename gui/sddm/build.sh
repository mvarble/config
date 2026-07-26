#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

THEME_NAME=rat-swarm
THEMES_DIR=/usr/share/sddm/themes
THEME_DEST=$THEMES_DIR/$THEME_NAME
CONF_DEST=/etc/sddm.conf.d/$THEME_NAME.conf

# Clean out any old/stale installations from previous attempts
sudo rm -rf /usr/local/share/sddm/themes/$THEME_NAME \
            /usr/local/lib*/qt6/qml/RatMotion \
            /usr/lib*/qt6/qml/RatMotion \
            "$THEME_DEST"

# 1. Configure CMake with system prefix (/usr)
cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# 2. Build and Install
cmake --build build -j"$(nproc)"
sudo cmake --install build

# 3. Select Theme
if [[ "${1:-}" != "--no-set" ]]; then
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=%s\n' "$THEME_NAME" | sudo tee "$CONF_DEST" > /dev/null
    echo "Theme '$THEME_NAME' installed and selected (via $CONF_DEST)."
else
    echo "Theme '$THEME_NAME' installed (selection skipped)."
fi

echo "Preview without logging out: sddm-greeter-qt6 --test-mode --theme $THEME_DEST"
