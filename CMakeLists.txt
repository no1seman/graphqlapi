cmake_minimum_required(VERSION 2.8 FATAL_ERROR)

project(graphqlapi NONE)

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})
set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY TRUE)

# Find Tarantool and Lua dependecies
set(TARANTOOL_FIND_REQUIRED ON)
find_package(Tarantool)
include_directories(${TARANTOOL_INCLUDE_DIRS})

file(GLOB_RECURSE LUA_FILES
  "${CMAKE_CURRENT_SOURCE_DIR}/graphqlapi/*.lua"
  "${CMAKE_CURRENT_SOURCE_DIR}/cartridge/roles/*.lua"
)

install(CODE "")