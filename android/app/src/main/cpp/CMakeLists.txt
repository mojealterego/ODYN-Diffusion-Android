cmake_minimum_required(VERSION 3.22.1)
project(odyn_native LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Download source in CI before configuring this project.
set(SDCPP_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../../../third_party/stable-diffusion.cpp" CACHE PATH "stable-diffusion.cpp checkout")
if(NOT EXISTS "${SDCPP_SOURCE_DIR}/CMakeLists.txt")
  message(FATAL_ERROR "stable-diffusion.cpp checkout missing: ${SDCPP_SOURCE_DIR}")
endif()

set(SD_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(SD_BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(GGML_VULKAN OFF CACHE BOOL "" FORCE)
add_subdirectory("${SDCPP_SOURCE_DIR}" "${CMAKE_BINARY_DIR}/sdcpp")

add_library(odyn_native SHARED odyn_native.cpp)
target_include_directories(odyn_native PRIVATE "${SDCPP_SOURCE_DIR}")
target_link_libraries(odyn_native PRIVATE stable-diffusion log)
