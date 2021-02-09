# Copyright 2010-2011 Free Software Foundation, Inc.
#
# This file is part of SEAMAKE
#
# SeaMake is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# SeaMake is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with SeaMake; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.

include (SeaMiscUtils)
include(CMakeDependentOption)

if(NOT WIN32)
  string(ASCII 27 Esc)
  set(ColourReset "${Esc}[m")
  set(ColourBold  "${Esc}[1m")
  set(Red         "${Esc}[31m")
  set(Green       "${Esc}[32m")
  set(Yellow      "${Esc}[33m")
  set(Blue        "${Esc}[34m")
  set(Magenta     "${Esc}[35m")
  set(Cyan        "${Esc}[36m")
  set(White       "${Esc}[37m")
  set(BoldRed     "${Esc}[1;31m")
  set(BoldGreen   "${Esc}[1;32m")
  set(BoldYellow  "${Esc}[1;33m")
  set(BoldBlue    "${Esc}[1;34m")
  set(BoldMagenta "${Esc}[1;35m")
  set(BoldCyan    "${Esc}[1;36m")
  set(BoldWhite   "${Esc}[1;37m")
endif()

if(DEFINED __INCLUDED_SEA_MODULE_CMAKE)
	return()
endif()
set(__INCLUDED_SEA_MODULE_CMAKE TRUE)

set(_sea_modules "" CACHE INTERNAL "" FORCE)
set(_sea_modules_resolved "" CACHE INTERNAL "" FORCE)

#Reset the internal "SEA state"
function(SEA_INIT)
	#Reset the internal "SEA state"
	get_cmake_property(_vars VARIABLES)
	string (REGEX MATCHALL "(^|;)_sea_module[A-Za-z0-9_\-]*" _matchedVars "${_vars}")

	foreach (_var IN LISTS _matchedVars)
    	unset(${_var} CACHE)
	endforeach()
endfunction(SEA_INIT)

SEA_INIT()

if(NOT DEFINED ENABLE_DEFAULT)
	set(ENABLE_DEFAULT OFF)
	message(STATUS "")
	message(STATUS "The build system will automatically disable all modules.")
	message(STATUS "Use -DENABLE_DEFAULT=OFF to enable modules by default.")
endif()

function(SEA_LOG_VERBOSE)
	if(SEA_VERBOSE)
		message(${ARGN})
	endif(SEA_VERBOSE)
endfunction(SEA_LOG_VERBOSE)

function(SEA_LOG)
	message(${ARGN})
endfunction(SEA_LOG)

function(SEA_ERROR)
	message(WARNING ${ARGN})
endfunction(SEA_ERROR)

function(SEA_FAIL)
	message(FATAL_ERROR ${ARGN})
endfunction(SEA_FAIL)

function(SEA_ENABLE name)
	SEA_SET_GLOBAL(SeaModule_${name}_enable ON)
endfunction(SEA_ENABLE)

function(SEA_DISABLE name)
	SEA_SET_GLOBAL(SeaModule_${name}_enable OFF)
endfunction(SEA_DISABLE)

function(SEA_SET_GLOBAL_IF_NOT_SET var)
	if(NOT DEFINED ${var})
		SEA_SET_GLOBAL(${var} ${ARGN})
	endif()
endfunction(SEA_SET_GLOBAL_IF_NOT_SET)

########################################################################
# Register a module into the system
# - name: canonical module name
# - type: module type - static shared module test executable external
# - mode: enable mode - optional required request
# - argn: list of dependencies
########################################################################
function(SEA_MODULE name type mode)
	string(TOUPPER "${mode}" mode)
	string(TOUPPER "${type}" type)

	if(NOT "${type}" STREQUAL "EXTERNAL")
		SEA_LOG_VERBOSE(STATUS "")
		SEA_LOG_VERBOSE(STATUS "Configuring ${name} support...")
		SEA_LOG_VERBOSE(STATUS "  Build ${mode} ${type}")
	endif(NOT "${type}" STREQUAL "EXTERNAL")

	#Add the module to the list
	list(APPEND _sea_modules ${name})
	SEA_SET_GLOBAL(_sea_modules ${_sea_modules})

	if(NOT DEFINED SeaModule_${name}_enable)
		#Enable tests by default for the moment, this should be a global option
		if("${mode}" STREQUAL "REQUIRED"
			OR "${type}" STREQUAL "META"
			OR "${type}" STREQUAL "TEST"
			OR "${type}" STREQUAL "EXTERNAL")
			set(SeaModule_${name}_enable ON)
		else()
			set(SeaModule_${name}_enable ${ENABLE_DEFAULT})
		endif()
	endif(NOT DEFINED SeaModule_${name}_enable)

	SEA_SET_ENABLE(SeaModule_${name}_enable ${SeaModule_${name}_enable})

	SEA_SET_GLOBAL(_sea_module_${name}_deps ${ARGN})

	SEA_SET_GLOBAL_IF_NOT_SET(_sea_module_${name}_commands "")
	SEA_SET_GLOBAL_IF_NOT_SET(_sea_module_${name}_sources "")
	SEA_SET_GLOBAL_IF_NOT_SET(_sea_module_${name}_include "")
	SEA_SET_GLOBAL_IF_NOT_SET(_sea_module_${name}_extern "")
	SEA_SET_GLOBAL_IF_NOT_SET(_sea_module_${name}_props "")
	SEA_SET_GLOBAL_IF_NOT_SET(_sea_module_${name}_dep_props "")

	SEA_SET_GLOBAL(_sea_module_${name}_dynamic "")

	SEA_SET_GLOBAL(_sea_module_${name}_target "${type}")

	SEA_SET_GLOBAL(_sea_module_${name}_mode "${mode}")
endfunction(SEA_MODULE)

function(SEA_MODULE_COMMAND module name)
	list(APPEND _sea_module_${module}_commands ${name})
	SEA_SET_GLOBAL(_sea_module_${module}_commands ${_sea_module_${module}_commands})
	SEA_SET_GLOBAL(_sea_module_${module}_command_${name} ${ARGN})
endfunction(SEA_MODULE_COMMAND)

macro(SEA_MODULE_ENABLE name)
	SEA_SET_GLOBAL(SeaModule_${name}_enable ON)
endmacro(SEA_MODULE_ENABLE)

macro(SEA_MODULE_DISABLE name)
	SEA_SET_GLOBAL(SeaModule_${name}_enable OFF)
	endmacro(SEA_MODULE_DISABLE)

macro(SEA_MODULE_IS_ENABLED name result)
	IF(SeaModule_${name}_enable STREQUAL ON)
		SET(${result} TRUE)
	ELSE()
		SET(${result} FALSE)
	ENDIF()
endmacro(SEA_MODULE_IS_ENABLED)

MACRO(SEA_GET_ARCH_DIRS result base)
	IF(IS_DIRECTORY ${base})
		SET(${result} ${${result}} ${base})

		IF(SEA_ARCH)
			find_sub_dirs(${result} ${base} ${SEA_ARCH})
		ENDIF()

		IF(SEA_PLATFORM)
			find_sub_dirs(__platform_dirs ${base} ${SEA_PLATFORM})

			IF(SEA_TARGET)
				FOREACH(dir ${__platform_dirs})
					SET(${result} ${${result}} ${dir})
					find_option_dirs(__option_dirs ${dir} ${SEA_TARGET})
				ENDFOREACH()
			ENDIF()

			IF(SEA_ARCH)
				FOREACH(dir ${__platform_dirs})
					SET(${result} ${${result}} ${dir})
					find_sub_dirs(${result} ${dir} ${SEA_ARCH})
				ENDFOREACH()
			ENDIF()
		ENDIF()

		IF(SEA_TARGET)
			find_option_dirs(__option_dirs ${base} ${SEA_TARGET})

			IF(SEA_ARCH)
				FOREACH(dir ${__option_dirs})
					SET(${result} ${${result}} ${dir})
					find_sub_dirs(${result} ${dir} ${SEA_ARCH})
				ENDFOREACH()
			ENDIF()
		ENDIF()

	ELSEIF(EXISTS ${base})
		SET(${result} ${${result}} ${base})
	ENDIF()
ENDMACRO()

########################################################################
# Attach source resources to the module
# - name: canonical module name
# - argn: list source resources
########################################################################
function(SEA_MODULE_SOURCES name)
	if("${_sea_module_${name}_target}" STREQUAL "EXTERNAL"
		OR "${_sea_module_${name}_target}" STREQUAL "META")
		SEA_ERROR("Can not add sources to meta or external module")
		return()
	endif("${_sea_module_${name}_target}" STREQUAL "EXTERNAL"
		OR "${_sea_module_${name}_target}" STREQUAL "META")

	SEA_LOG_VERBOSE(STATUS "")
	SEA_LOG_VERBOSE(STATUS "Adding ${name} sources...")

	foreach(src ${ARGN})
		list(APPEND _sea_module_${name}_sources ${CMAKE_CURRENT_LIST_DIR}/${src})
	endforeach(src)

	SEA_SET_GLOBAL(_sea_module_${name}_sources ${_sea_module_${name}_sources})
endfunction(SEA_MODULE_SOURCES)

########################################################################
# Attach include directories to the module
# - name: canonical module name
# - argn: list include directories
########################################################################
function(SEA_MODULE_INCLUDES name)
	#if(NOT "${_sea_module_${name}_target}" STREQUAL "EXTERNAL")
		SEA_LOG_VERBOSE(STATUS "")
		SEA_LOG_VERBOSE(STATUS "Adding ${name} include directories...")
	#endif(NOT "${_sea_module_${name}_target}" STREQUAL "EXTERNAL")

	foreach(inc ${ARGN})
		SEA_LOG_VERBOSE(STATUS "Adding " "${CMAKE_CURRENT_LIST_DIR}/${inc}")
		list(APPEND _sea_module_${name}_include "${CMAKE_CURRENT_LIST_DIR}/${inc}")
	endforeach(inc)

	SEA_SET_GLOBAL(_sea_module_${name}_include ${_sea_module_${name}_include})
endfunction(SEA_MODULE_INCLUDES)

########################################################################
# Attach include directories to the module
# - name: canonical module name
# - argn: list of absolute paths to include directories
########################################################################
function(SEA_MODULE_INCLUDE_PATH name)
	#if(NOT "${_sea_module_${name}_target}" STREQUAL "EXTERNAL")
		message(STATUS "")
		message(STATUS "Adding ${name} include directories...")
	#endif(NOT "${_sea_module_${name}_target}" STREQUAL "EXTERNAL")

	foreach(dir ${ARGN})
		message(STATUS "Adding " ${dir})
		list(APPEND _sea_module_${name}_include ${dir})
	endforeach(dir)

	SEA_SET_GLOBAL(_sea_module_${name}_include ${_sea_module_${name}_include})
endfunction(SEA_MODULE_INCLUDE_PATH)

########################################################################
# Inject a module dependency
# - name: canonical module name
# - argn: list of dependency modules
########################################################################
function(SEA_MODULE_DEPENDS name)
	if(NOT "${_sea_module_${name}_target}" STREQUAL "EXTERNAL")
		SEA_LOG_VERBOSE(STATUS "")
		SEA_LOG_VERBOSE(STATUS "Adding ${name} dependent modules...")
	endif(NOT "${_sea_module_${name}_target}" STREQUAL "EXTERNAL")

	foreach(reff ${ARGN})
		SEA_LOG_VERBOSE(STATUS "Adding " ${reff})
		list(APPEND _sea_module_${name}_deps ${reff})
	endforeach(reff)

	SEA_SET_GLOBAL(_sea_module_${name}_deps ${_sea_module_${name}_deps})
endfunction(SEA_MODULE_DEPENDS)

########################################################################
# Attach external libraries to an external mdoule
# - name: canonical module name
# - argn: list of libraries
########################################################################
function(SEA_MODULE_EXTERNALS name)
	list(APPEND _sea_module_${name}_extern ${ARGN})

	SEA_LOG_VERBOSE(STATUS "Adding ${name} externals ${ARGN}")

	SEA_SET_GLOBAL(_sea_module_${name}_extern ${_sea_module_${name}_extern})
endfunction(SEA_MODULE_EXTERNALS)

macro(LIST_REPLACE LIST INDEX NEWVALUE)
    list(INSERT ${LIST} ${INDEX} ${NEWVALUE})
    MATH(EXPR __INDEX "${INDEX} + 1")
    list (REMOVE_AT ${LIST} ${__INDEX})
endmacro(LIST_REPLACE)

########################################################################
# Changes an existing property in a property list.  A property list is
# a normal cmake list where the elements alternate with prop_name and
# prop_value.
# - prop_list:  canonical list name
# - cmd:        if APPEND (and prop exists in list), append prop_value
#               to existing value separated with a space.
# - prop_name:  name of property to set
# - prop_value: value
########################################################################
function(_SEA_MODULE_PROPERTY_SETAPPEND prop_list cmd prop_name prop_value )
	# Check if the property is in the list
	list (FIND ${prop_list} "${prop_name}" prop_idx)
	if (${prop_idx} GREATER -1)
	    # If property is in the list replace it
		math(EXPR val_idx "${prop_idx} + 1")
		list (GET ${prop_list} ${val_idx} old_value)
		if("${cmd}" STREQUAL "APPEND")
			set (prop_value "${old_value} ${prop_value}")
		endif()
		LIST_REPLACE(${prop_list} ${val_idx} ${prop_value})
	else()
		list (APPEND ${prop_list} ${prop_name} ${prop_value})
	endif()
	SEA_SET_GLOBAL(${prop_list} ${${prop_list}})
endfunction(_SEA_MODULE_PROPERTY_SETAPPEND)

########################################################################
# Changes an existing property in a property list.  A property list is
# a normal cmake list where the elements alternate with prop_name and
# prop_value.
# - prop_list:  canonical list name
# - cmd:        if APPEND (and prop exists in list), append prop_value
#               to existing value separated with a space.
# - argn:       name/value pairs
########################################################################
function(_SEA_MODULE_PROPERTY_LIST_CHANGE prop_list cmd)
	list(LENGTH ARGN num_args)

	if(${num_args} EQUAL 0)
		return()
	endif()

	foreach(i RANGE 0 num_args 2)
		math(EXPR _vali "${i} + 1")
		list(GET ARGN ${i} prop_name)
		list(GET ARGN ${_vali} prop_value)
		_SEA_MODULE_PROPERTY_SETAPPEND(${prop_list} ${cmd} ${prop_name} "${prop_value}")
	endforeach()
endfunction(_SEA_MODULE_PROPERTY_LIST_CHANGE)

########################################################################
# Adds properties to a target
# - name: canonical module name
# - argn: name/value pairs
########################################################################
function(SEA_MODULE_PROPERTY name)
	_SEA_MODULE_PROPERTY_LIST_CHANGE(_sea_module_${name}_props "APPEND" ${ARGN})
endfunction(SEA_MODULE_PROPERTY)

########################################################################
# Adds dependant properties to a target, these apply to dependant targets
# - name: canonical module name
# - argn: list of property value pairs
########################################################################
function(SEA_MODULE_DEPENDANT_PROPERTY name)
	_SEA_MODULE_PROPERTY_LIST_CHANGE(_sea_module_${name}_dep_props "APPEND" ${ARGN})
endfunction(SEA_MODULE_DEPENDANT_PROPERTY)

########################################################################
# Adds dependant properties to a target, these apply to dependant targets as well
# - name: canonical module name
# - argn: list of property value pairs
########################################################################
function(SEA_MODULE_STICKY_PROPERTY name)
	SEA_MODULE_DEPENDANT_PROPERTY(${name} ${ARGN})
	SEA_MODULE_PROPERTY(${name} ${ARGN})
endfunction(SEA_MODULE_STICKY_PROPERTY)

########################################################################
# Adds a dynamic target to the module, will apply post module resolution
# - name: canonical module name
# - argn: list of dynamic targets to add
########################################################################
function(SEA_MODULE_DYNAMIC_TARGET name)

	foreach(target ${ARGN})
		if("${target}" IN_LIST "_sea_module_${name}_dynamic")
			continue()
		endif()

		list(APPEND "_sea_module_${name}_dynamic" "${target}")
	endforeach()

	SEA_SET_GLOBAL(_sea_module_${name}_dynamic ${_sea_module_${name}_dynamic})

	message("${_sea_module_${name}_dynamic}")
endfunction(SEA_MODULE_DYNAMIC_TARGET)

function(_SEA_MODULE_RESOLVE_THIS name)
	set(can_resolve TRUE)
	set(is_resolved TRUE)
	set(default_enable ON)

	list(APPEND module_enable "SeaModule_${name}_enable")

	if("${_sea_module_${name}_target}" STREQUAL "META")
		SEA_SET_GLOBAL(SeaModule_${name}_enable ON)
	elseif(NOT SeaModule_${name}_enable)
		set(can_resolve FALSE)

		if("${_sea_module_${name}_mode}" STREQUAL "REQUIRED")
			SEA_ERROR("ERROR : Required module " ${name} " is disabled")
		endif("${_sea_module_${name}_mode}" STREQUAL "REQUIRED")

	else("${_sea_module_${name}_target}" STREQUAL "META")
		foreach(dep ${_sea_module_${name}_deps})
			list(FIND _sea_modules_resolved ${dep} dep_res_index)
			list(FIND _sea_modules ${dep} dep_module_index)

			if(dep_module_index LESS 0)
				SEA_ERROR("	* ${name} Failed to locate dependency ${dep}")
				set(can_resolve FALSE)
				break()
			endif()

			if(NOT SeaModule_${dep}_enable)
				if("${_sea_module_${dep}_mode}" STREQUAL "REQUEST")
					SEA_SET_ENABLE(SeaModule_${dep}_enable ON)
				elseif("${_sea_module_${dep}_mode}" STREQUAL "REQUIRED")
					SEA_ERROR("	* ${name} Dependency ${dep} is disabled")
					set(can_resolve FALSE)
					break()
				endif()
			endif()

			if(dep_res_index LESS 0)
				set(is_resolved FALSE)
			endif()
		endforeach(dep)
	endif("${_sea_module_${name}_target}" STREQUAL "META")

	if(NOT can_resolve)
		set(SeaModule_${name}_enable OFF)
	else(can_resolve)
		if(NOT is_resolved)
			return()
		endif()
	endif()

	CMAKE_DEPENDENT_OPTION(
		SeaModule_${name}_enable
		"enable ${name} support"
		${SeaModule_${name}_enable}
		"${module_enable}"
		OFF)

	SEA_SET_ENABLE(SeaModule_${name}_enable ${SeaModule_${name}_enable})

	list(APPEND _sea_modules_resolved ${name})
	SEA_SET_GLOBAL(_sea_modules_resolved "${_sea_modules_resolved}")

endfunction(_SEA_MODULE_RESOLVE_THIS)

function(_SEA_MODULE_ALL_RESOLVED status)
	set(${status} FALSE PARENT_SCOPE)

	foreach(module ${_sea_modules})
		list(FIND _sea_modules_resolved ${module} module_res_index)

		if(${module_res_index} EQUAL -1)
			return()
		endif()
	endforeach(module)

	set(${status} TRUE PARENT_SCOPE)
endfunction(_SEA_MODULE_ALL_RESOLVED)

function(_SEA_MODULE_RESOLVE)
	set(done FALSE)

	while(NOT ${done})
		set(done TRUE)

		foreach(module ${_sea_modules})
			_SEA_MODULE_RESOLVE_THIS(${module})
			_SEA_MODULE_ALL_RESOLVED(done)
		endforeach(module)
	endwhile()
endfunction(_SEA_MODULE_RESOLVE)

function(_SEA_MERGE_TARGET_PROPERTIES module)
	SEA_LOG_VERBOSE("MERGING PROPS FOR ${module}")
	foreach(dep ${ARGN})
		SEA_LOG_VERBOSE(" -- FROM " ${dep})
		list(LENGTH _sea_module_${dep}_dep_props fromlen)

		if(${fromlen} EQUAL 0)
			continue()
		endif()

		foreach(i RANGE 0 fromlen 2)
			list(GET _sea_module_${dep}_dep_props ${i} prop)
			math(EXPR _vali "${i} + 1")
			list(GET _sea_module_${dep}_dep_props ${_vali} val)
			SEA_LOG_VERBOSE("PROP " ${module} ${prop})
			get_target_property(extend ${module} ${prop})

			if(extend)
				set_target_properties(${module} PROPERTIES ${prop} "${extend} ${val}")
			else()
			set_target_properties(${module} PROPERTIES ${prop} "${val}")
			endif()

		endforeach()
	endforeach()
endfunction(_SEA_MERGE_TARGET_PROPERTIES)

########################################################################
# Print the registered module summary
########################################################################
function(_SEA_PRINT_MODULE_SUMMARY name)
	SEA_LOG(STATUS "")
	SEA_LOG(STATUS "######################################################")
	SEA_LOG(STATUS "# " ${name} " modules")
	SEA_LOG(STATUS "######################################################")
	foreach(name ${_sea_modules})
		if(SeaModule_${name}_enable)
			SEA_LOG(STATUS "  * ${name} ${Green}ENABLED${ColourReset}")
		else(SeaModule_${name}_enable)
			SEA_LOG(STATUS "  * ${name} ${Red}DISABLED${ColourReset}")
		endif(SeaModule_${name}_enable)
	endforeach(name)
	SEA_LOG(STATUS "")
endfunction(_SEA_PRINT_MODULE_SUMMARY)

function(_SEA_MODULE_BUILD_THIS module sources includes deps)
	if(NOT "${${sources}}" STREQUAL "")
		if("${_sea_module_${module}_target}" STREQUAL "STATIC"
			OR "${_sea_module_${module}_target}" STREQUAL "SHARED"
			OR "${_sea_module_${module}_target}" STREQUAL "MODULE")
			SEA_LOG(STATUS "building " ${module} " as "
					"${_sea_module_${module}_target}" " library")
			add_library(
				${module}
				${_sea_module_${module}_target}
				${${sources}})
		elseif("${_sea_module_${module}_target}" STREQUAL "TEST")
			SEA_LOG(STATUS "building " ${module} " as test")
			add_executable(
				${module}
				${${sources}})
			add_test(${module} ${module})
		elseif("${_sea_module_${module}_target}" STREQUAL "EXTERNAL")
			return()
		elseif("${_sea_module_${module}_target}" STREQUAL "COMPONENT")
			SEA_LOG(STATUS "building " ${module} " as component")
			add_library(
				${module}
				OBJECT
				${${sources}})
		else()
			SEA_LOG(STATUS "building " ${module} " as executable")
			add_executable(
				${module}
				${${sources}})
		endif()

		if(NOT "${_sea_module_${module}_props}" STREQUAL "")
			SEA_LOG("Set target props ${module} : " ${_sea_module_${module}_props})
			set_target_properties(${module} PROPERTIES ${_sea_module_${module}_props})
		endif()

#		if("${_sea_module_${module}_target}" STREQUAL "SHARED"
#			OR "${_sea_module_${module}_target}" STREQUAL "TEST"
#			OR "${_sea_module_${module}_target}" STREQUAL "EXECUTABLE")
#			_SEA_MERGE_TARGET_PROPERTIES(${module} ${${deps}})
#		endif()
		_SEA_MERGE_TARGET_PROPERTIES(${module} ${${deps}})

		foreach(inc ${${includes}})
			SEA_LOG_VERBOSE(STATUS "${module} include : ${inc}")
			target_include_directories(${module} PRIVATE ${inc})
		endforeach(inc)
	endif(NOT "${${sources}}" STREQUAL "")
endfunction(_SEA_MODULE_BUILD_THIS)

function(_SEA_MDOULE_COMMANDS module)
	foreach(cmd ${_sea_module_${module}_commands})
		add_custom_command(${_sea_module_${module}_command_${cmd}})
	endforeach(cmd ${_sea_module_${module}_commands})
endfunction(_SEA_MDOULE_COMMANDS)

macro(_SEA_MODULE_FLATTEN_DEPS deps module)
	foreach(dep ${_sea_module_${module}_deps})
		if(NOT SeaModule_${dep}_enable)
			continue()
		endif(NOT SeaModule_${dep}_enable)

		if("${dep}" IN_LIST ${deps})
			continue()
		endif("${dep}" IN_LIST ${deps})

		list(APPEND ${deps} ${dep})

		_SEA_MODULE_FLATTEN_DEPS(${deps} ${dep})
	endforeach(dep ${_sea_module_${module}_deps})
endmacro(_SEA_MODULE_FLATTEN_DEPS)

macro(_SEA_MODULE_GATHER includes sources libs)
	foreach(dep ${ARGN})
		if("${dep}" IN_LIST ${libs})
			continue()
		endif("${dep}" IN_LIST ${libs})

		if(NOT SeaModule_${dep}_enable)
			continue()
		endif(NOT SeaModule_${dep}_enable)

		if("${_sea_module_${dep}_target}" STREQUAL "META")
			continue()
		endif("${_sea_module_${dep}_target}" STREQUAL "META")

		set(${includes} ${${includes}} ${_sea_module_${dep}_include})

		if("${_sea_module_${dep}_target}" STREQUAL "EXTERNAL")
		elseif("${_sea_module_${dep}_target}" STREQUAL "COMPONENT")
		else("${_sea_module_${dep}_target}" STREQUAL "EXTERNAL")
			list(APPEND ${libs} ${dep})
		endif("${_sea_module_${dep}_target}" STREQUAL "EXTERNAL")

		list(APPEND ${libs} ${_sea_module_${dep}_extern})
	endforeach(dep ${ARGN})
endmacro(_SEA_MODULE_GATHER)

function(_SEA_MODULE_RESOLVE_SOURCES sources)
	set("${sources}" "")

	if("${_sea_module_${name}_target}" STREQUAL "EXTERNAL"
		OR "${_sea_module_${name}_target}" STREQUAL "META")
		return()
	endif()

	list(APPEND search "")

	foreach(src ${ARGN})
		SEA_GET_ARCH_DIRS(search ${src})
	endforeach(src)

	list(REMOVE_DUPLICATES search)

	foreach(dir ${search})
		SEA_LOG_VERBOSE(STATUS "Adding " ${dir})
		if(IS_DIRECTORY "${dir}")
			find_sources_dir("${sources}" ${dir})
		else(IS_DIRECTORY "${dir}")
			list(APPEND "${sources}" ${dir})
		endif(IS_DIRECTORY "${dir}")
	endforeach(dir)

	set("${sources}" ${${sources}} PARENT_SCOPE)
endfunction(_SEA_MODULE_RESOLVE_SOURCES)

function(_SEA_MODULE_RESOLVE_INCLUDES includes)
	set("${includes}" "")

	if("${_sea_module_${name}_target}" STREQUAL "EXTERNAL")
		return()
	endif()

	list(APPEND search "")

	foreach(inc ${ARGN})
		SEA_GET_ARCH_DIRS(search ${inc})
	endforeach(inc)

	list(REMOVE_DUPLICATES search)
	list(REVERSE search)

	foreach(dir ${search})
		SEA_LOG_VERBOSE(STATUS "Adding " ${dir})
		list(APPEND "${includes}" ${dir})
	endforeach(dir)

	set("${includes}" ${${includes}} PARENT_SCOPE)
endfunction(_SEA_MODULE_RESOLVE_INCLUDES)

macro(_SEA_MODULE_RESOLVE_DYNAMIC_TARGETS targets)
	foreach(name ${ARGN})
		if(${SeaModule_${name}_enable})
			list(APPEND ${targets} ${_sea_module_${name}_dynamic})
		endif()
	endforeach()

	list(REMOVE_DUPLICATES ${targets})
endmacro()

########################################################################
# Emit the build targets
########################################################################
function(SEA_MODULE_BUILD name)
	_SEA_MODULE_RESOLVE()

	_SEA_MODULE_RESOLVE_DYNAMIC_TARGETS(SEA_TARGET ${_sea_modules})
	SEA_SET_GLOBAL(SEA_TARGET ${SEA_TARGET})

	_SEA_PRINT_MODULE_SUMMARY(${name})

	foreach(module ${_sea_modules})
		set(_module_depends "")
		_SEA_MODULE_RESOLVE_INCLUDES(_module_includes ${_sea_module_${module}_include})
		_SEA_MODULE_RESOLVE_SOURCES(_module_sources ${_sea_module_${module}_sources})
		set(_module_libs "")

		if("${_sea_module_${module}_target}" STREQUAL "META")
			continue()
		endif("${_sea_module_${module}_target}" STREQUAL "META")

		if(NOT SeaModule_${module}_enable)
			continue()
		endif(NOT SeaModule_${module}_enable)

		_SEA_MODULE_FLATTEN_DEPS(_module_depends ${module})
		_SEA_MODULE_GATHER(_module_includes _module_sources _module_libs ${_module_depends})
		SEA_LOG_VERBOSE("GATHERED ${module} ${_module_depends}")

		if(NOT "${_module_includes}" STREQUAL "")
			list(REVERSE _module_includes)
			list(REMOVE_DUPLICATES _module_includes)
			list(REVERSE _module_includes)
		endif(NOT "${_module_includes}" STREQUAL "")

		if(NOT "${_module_sources}" STREQUAL "")
			list(REVERSE _module_sources)
			list(REMOVE_DUPLICATES _module_sources)
			list(REVERSE _module_sources)
			_SEA_MODULE_BUILD_THIS(${module} _module_sources _module_includes _module_depends)
		else(NOT "${_module_sources}" STREQUAL "")
			continue()
		endif(NOT "${_module_sources}" STREQUAL "")

		_SEA_MDOULE_COMMANDS(${module})

		if("${_sea_module_${module}_target}" STREQUAL "COMPONENT")
			continue()
		endif("${_sea_module_${module}_target}" STREQUAL "COMPONENT")

		# Pull in components
		foreach(dep ${_module_depends})
			if(NOT "${_sea_module_${dep}_target}" STREQUAL "COMPONENT")
				continue()
			endif(NOT "${_sea_module_${dep}_target}" STREQUAL "COMPONENT")

			if(NOT SeaModule_${dep}_enable)
				continue()
			endif(NOT SeaModule_${dep}_enable)

			if(TARGET ${dep})
				target_sources(${module} PRIVATE "$<TARGET_OBJECTS:${dep}>")
			endif()
		endforeach(dep)

		if(NOT "${_module_libs}" STREQUAL "")
			#Reverse the libs list then remove dups to ensure the right dep order
			list(REVERSE _module_libs)
			list(REMOVE_DUPLICATES _module_libs)
			list(REVERSE _module_libs)

			if(NOT "${_sea_module_${module}_target}" STREQUAL "EXTERNAL"
				AND NOT "${_sea_module_${module}_target}" STREQUAL "COMPONENT")
				#Ensure no self linking
				list(REMOVE_ITEM _module_libs ${module})
				target_link_libraries(${module} ${_module_libs})
			endif(NOT "${_sea_module_${module}_target}" STREQUAL "EXTERNAL"
				AND NOT "${_sea_module_${module}_target}" STREQUAL "COMPONENT")
		endif(NOT "${_module_libs}" STREQUAL "")

	endforeach(module)
endfunction(SEA_MODULE_BUILD)
