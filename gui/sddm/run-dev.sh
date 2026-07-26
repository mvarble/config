#!/usr/bin/env bash
# Build the RatMotion plugin into build/RatMotion, generate theme assets,
# and preview the theme with the Qt6 SDDM greeter.
set -euo pipefail
cd "$(dirname "$0")"

# 1. Build plugin and assets
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build -j"$(nproc)"

# 2. Tell Qt to resolve 'import RatMotion 1.0' from the build directory ($PWD/build/RatMotion)
export QML_IMPORT_PATH="$PWD/build:${QML_IMPORT_PATH:-}"
export QML2_IMPORT_PATH="$PWD/build:${QML2_IMPORT_PATH:-}"

# 3. Preview theme directly from local source directory
exec sddm-greeter-qt6 --test-mode --theme "$PWD/theme"
