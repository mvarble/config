cmake_minimum_required(VERSION 3.24)

project(ratswarm VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(GNUInstallDirs)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Qml)
find_package(Python3 REQUIRED COMPONENTS Interpreter)

qt_standard_project_setup(REQUIRES 6.5)

# -------------------------------------------------------------------
# 1. C++ QML Plugin (RatMotion / RatPack)
# -------------------------------------------------------------------
qt_add_qml_module(ratmotion
    URI RatMotion
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/RatMotion
    SOURCES
        plugin/ratmotion.h
        plugin/ratmotion.cpp
        plugin/ratpack.h
        plugin/ratpack.cpp
)

target_include_directories(ratmotion PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/plugin)
target_link_libraries(ratmotion PRIVATE Qt6::Quick Qt6::Qml)

# Set $ORIGIN on both backing library (ratmotion) and plugin (ratmotionplugin)
# so libratmotionplugin.so can locate libratmotion.so in the same folder.
set_target_properties(ratmotion ratmotionplugin PROPERTIES
    INSTALL_RPATH "$ORIGIN"
    BUILD_RPATH "$ORIGIN"
)

# Strip `prefer :/qt/qml/RatMotion/` from generated qmldir
add_custom_command(TARGET ratmotionplugin POST_BUILD
    COMMAND sed -i "/^prefer /d"
            ${CMAKE_CURRENT_BINARY_DIR}/RatMotion/qmldir
    COMMENT "Stripping qrc prefer line from generated qmldir"
)

# -------------------------------------------------------------------
# 2. Asset Generation
# -------------------------------------------------------------------
set(THEME_ASSETS ${CMAKE_CURRENT_SOURCE_DIR}/theme/assets)

add_custom_command(
    OUTPUT ${THEME_ASSETS}/rat_hull.json ${THEME_ASSETS}/rat.glb ${THEME_ASSETS}/tile.png
    COMMAND ${CMAKE_COMMAND} -E make_directory ${THEME_ASSETS}
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/assets/rat.glb
            ${THEME_ASSETS}/rat.glb
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/assets/tile.png
            ${THEME_ASSETS}/tile.png
    COMMAND ${Python3_EXECUTABLE}
            ${CMAKE_CURRENT_SOURCE_DIR}/tools/extract_hull.py
            ${CMAKE_CURRENT_SOURCE_DIR}/assets/rat.glb
            ${THEME_ASSETS}/rat_hull.json
    DEPENDS
            ${CMAKE_CURRENT_SOURCE_DIR}/assets/rat.glb
            ${CMAKE_CURRENT_SOURCE_DIR}/tools/extract_hull.py
    COMMENT "Copying rat.glb and extracting collision hull"
)

add_custom_target(theme_assets ALL DEPENDS ${THEME_ASSETS}/rat_hull.json ${THEME_ASSETS}/rat.glb)

# -------------------------------------------------------------------
# 3. Installation Rules
# -------------------------------------------------------------------

# Install library targets
install(TARGETS ratmotion ratmotionplugin
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/qt6/qml/RatMotion
)

# Install generated qmldir, qmltypes, etc.
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/RatMotion/
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/qt6/qml/RatMotion
)

# Install theme files
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/theme/
    DESTINATION ${CMAKE_INSTALL_DATADIR}/sddm/themes/rat-swarm
    PATTERN "RatMotion" EXCLUDE
)
