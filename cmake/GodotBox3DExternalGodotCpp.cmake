include_guard()

# Fetches godot-cpp via ExternalProject_Add (not FetchContent, not a submodule) at
# configure time, pinned to the godot-4.3-stable tag (matching this extension's
# compatibility_minimum). Builds a single Debug/Release pair rather than godot-jolt's
# six-way Debug/Development/Distribution/EditorDebug/EditorDevelopment/EditorDistribution
# matrix -- v1 doesn't need per-editor-build configs yet.

include(ExternalProject)

set(GODOT_CPP_GIT_REPOSITORY "https://github.com/godotengine/godot-cpp.git")
set(GODOT_CPP_GIT_TAG "godot-4.3-stable")

set(GODOT_CPP_PREFIX "${CMAKE_BINARY_DIR}/_deps/godot-cpp")
set(GODOT_CPP_SOURCE_DIR "${GODOT_CPP_PREFIX}/src/godot-cpp")
set(GODOT_CPP_BINARY_DIR "${GODOT_CPP_PREFIX}/src/godot-cpp-build")

# godot-cpp's own build only distinguishes Debug from non-Debug via `CMAKE_BUILD_TYPE`, so
# for single-config generators (Ninja/Makefiles) we simply forward our own build type; for
# multi-config generators the external project always builds in Debug and Release side by
# side isn't necessary for a GDExtension consumed by a single active configuration, so we
# forward $<CONFIG> at build time.
if(CMAKE_CONFIGURATION_TYPES)
	set(GODOT_CPP_BUILD_TYPE_ARG "")
	set(GODOT_CPP_BUILD_CONFIG_ARG --config $<CONFIG>)
else()
	if(NOT CMAKE_BUILD_TYPE)
		set(GODOT_CPP_EFFECTIVE_BUILD_TYPE "Release")
	else()
		set(GODOT_CPP_EFFECTIVE_BUILD_TYPE "${CMAKE_BUILD_TYPE}")
	endif()
	set(GODOT_CPP_BUILD_TYPE_ARG "-DCMAKE_BUILD_TYPE=${GODOT_CPP_EFFECTIVE_BUILD_TYPE}")
	set(GODOT_CPP_BUILD_CONFIG_ARG "")
endif()

# godot-cpp's own CMakeLists.txt names its output library
# "godot-cpp.<system_name>.<build_type>.<bits>" (see its OUTPUT_NAME logic), placed under
# <binary_dir>/bin -- not a plain "libgodot-cpp.a" at the binary dir root. Mirror that
# naming exactly rather than guessing a fixed name.
string(TOLOWER "${CMAKE_SYSTEM_NAME}" GODOT_CPP_SYSTEM_NAME_LOWER)
string(TOLOWER "${GODOT_CPP_EFFECTIVE_BUILD_TYPE}" GODOT_CPP_BUILD_TYPE_LOWER)
math(EXPR GODOT_CPP_BITS "${CMAKE_SIZEOF_VOID_P} * 8")

set(GODOT_CPP_LIB_NAME
	"${CMAKE_STATIC_LIBRARY_PREFIX}godot-cpp.${GODOT_CPP_SYSTEM_NAME_LOWER}.${GODOT_CPP_BUILD_TYPE_LOWER}.${GODOT_CPP_BITS}${CMAKE_STATIC_LIBRARY_SUFFIX}"
)
set(GODOT_CPP_LIB_PATH "${GODOT_CPP_BINARY_DIR}/bin/${GODOT_CPP_LIB_NAME}")

ExternalProject_Add(godot-cpp-external
	PREFIX "${GODOT_CPP_PREFIX}"
	GIT_REPOSITORY "${GODOT_CPP_GIT_REPOSITORY}"
	GIT_TAG "${GODOT_CPP_GIT_TAG}"
	GIT_SHALLOW TRUE
	SOURCE_DIR "${GODOT_CPP_SOURCE_DIR}"
	BINARY_DIR "${GODOT_CPP_BINARY_DIR}"
	CMAKE_ARGS
		-G ${CMAKE_GENERATOR}
		-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
		-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON
		${GODOT_CPP_BUILD_TYPE_ARG}
	BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> ${GODOT_CPP_BUILD_CONFIG_ARG} --target godot-cpp
	INSTALL_COMMAND ""
	BUILD_BYPRODUCTS "${GODOT_CPP_LIB_PATH}"
	UPDATE_DISCONNECTED TRUE
)

file(MAKE_DIRECTORY "${GODOT_CPP_SOURCE_DIR}/include")
file(MAKE_DIRECTORY "${GODOT_CPP_SOURCE_DIR}/gdextension")
file(MAKE_DIRECTORY "${GODOT_CPP_BINARY_DIR}/gen/include")

add_library(godot-cpp STATIC IMPORTED GLOBAL)
add_dependencies(godot-cpp godot-cpp-external)

set_target_properties(godot-cpp PROPERTIES
	IMPORTED_LOCATION "${GODOT_CPP_LIB_PATH}"
	INTERFACE_INCLUDE_DIRECTORIES
		"${GODOT_CPP_SOURCE_DIR}/include;${GODOT_CPP_SOURCE_DIR}/gdextension;${GODOT_CPP_BINARY_DIR}/gen/include"
)
