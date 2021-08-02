cmake_minimum_required(VERSION 3.10)

add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/source-charset:utf-8>")

# add_definitions(-DGL_BGRA_EXT)

project("OpenGLES3DWaifu")
set(PVR_SDK_DIRECTORY "d:/Program Files/Native_SDK-R21.1-v5.7")

add_executable(OpenGLES3DWaifu WIN32 "OpenGLES3DWaifu.cpp")
target_include_directories(OpenGLES3DWaifu PUBLIC
            "${PVR_SDK_DIRECTORY}/framework"
            "${PVR_SDK_DIRECTORY}/include"
            "${PVR_SDK_DIRECTORY}/build/external/glm/src"
            # "${PVR_SDK_DIRECTORY}/include/GLES2/gl2ext.h"
            )
target_link_libraries(OpenGLES3DWaifu PUBLIC
"${PVR_SDK_DIRECTORY}/build/framework/PVRCore/Debug/PVRCore.lib"
"${PVR_SDK_DIRECTORY}/build/framework/PVRShell/Debug/PVRShell.lib"
"${PVR_SDK_DIRECTORY}/build/framework/PVRUtils/OpenGLES/Debug/PVRUtilsGles.lib"
"${PVR_SDK_DIRECTORY}/build/framework/PVRAssets/Debug/PVRAssets.lib"
)

add_custom_command(TARGET OpenGLES3DWaifu
POST_BUILD
COMMAND ${CMAKE_COMMAND} -E copy "${PROJECT_SOURCE_DIR}/DefaultFragShader.fsh" $<TARGET_FILE_DIR:${PROJECT_NAME}>
COMMAND ${CMAKE_COMMAND} -E copy "${PROJECT_SOURCE_DIR}/DefaultVertShader.vsh" $<TARGET_FILE_DIR:${PROJECT_NAME}>
COMMAND ${CMAKE_COMMAND} -E copy "${PROJECT_SOURCE_DIR}/SkinnedFragShader.fsh" $<TARGET_FILE_DIR:${PROJECT_NAME}>
COMMAND ${CMAKE_COMMAND} -E copy "${PROJECT_SOURCE_DIR}/SkinnedVertShader.vsh" $<TARGET_FILE_DIR:${PROJECT_NAME}>
COMMAND ${CMAKE_COMMAND} -E copy "${PROJECT_SOURCE_DIR}/ShadowFragShader.fsh" $<TARGET_FILE_DIR:${PROJECT_NAME}>
)