# Copyright 2010-2011 Free Software Foundation, Inc.
#
# This file is part of SEAMAKE
#
# SEAMAKE is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# SEAMAKE is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with SEAMAKE; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.

if(DEFINED __INCLUDED_SEAMAKE_FIND_MODULES_CMAKE)
    return()
endif()
SET(__INCLUDED_SEAMAKE_FIND_MODULES_CMAKE TRUE)

MACRO(find_modules_in_dir result dir)
	FILE(GLOB children RELATIVE ${dir} ${dir}/*)
	SET(dlist "")
	FOREACH(child ${children})
		IF(IS_DIRECTORY ${dir}/${child} AND EXISTS ${dir}/${child}/CMakeLists.txt)
			SET(dlist ${dlist} ${child})
		ENDIF()
	ENDFOREACH()
	SET(${result} ${dlist})
ENDMACRO()

MACRO(include_modules_dir dir)
	find_modules_in_dir(modules ${dir})

	FOREACH(module ${modules})
		IF(NOT ${module} STREQUAL cmake
			AND NOT ${module} STREQUAL bin
			AND NOT ${module} STREQUAL tools)
			ADD_SUBDIRECTORY(${module})
		ENDIF()
	ENDFOREACH()
ENDMACRO()

MACRO(include_modules)
	include_modules_dir(${CMAKE_CURRENT_LIST_DIR})
ENDMACRO()

MACRO(find_sub_dirs result base)
SET(extent "")
FOREACH(part ${ARGN})
	IF(IS_DIRECTORY ${base}/${extent}${part})
		SET(${result} ${${result}} ${base}/${extent}${part})
	ELSE()
		BREAK()
	ENDIF()
	SET(extent ${extent}${part}/)
ENDFOREACH()
ENDMACRO()

MACRO(find_option_dirs result base)
SET(extent "")
FOREACH(part ${ARGN})
	IF(IS_DIRECTORY ${base}/${part})
		SET(${result} ${${result}} ${base}/${part})
	ENDIF()
ENDFOREACH()
ENDMACRO()

MACRO(find_sources_dir result dir)
	SET(sfiles "")
	FILE(GLOB children ${dir}/*.c)
	SET(sfiles ${sfiles} ${children})
	FILE(GLOB children ${dir}/*.cc)
	SET(sfiles ${sfiles} ${children})
	FILE(GLOB children ${dir}/*.C)
	SET(sfiles ${sfiles} ${children})
	FILE(GLOB children ${dir}/*.cpp)
	SET(sfiles ${sfiles} ${children})
	FILE(GLOB children ${dir}/*.s)
	SET(sfiles ${sfiles} ${children})
	FILE(GLOB children ${dir}/*.S)
	SET(sfiles ${sfiles} ${children})
	SET(${result} ${${result}} ${sfiles})
ENDMACRO()

MACRO(find_sources_rel_dir result rel dir)
	get_filename_component(base ${rel} REALPATH)
	SET(sfiles "")
	FILE(GLOB children RELATIVE ${base} ${dir}/*.c)
	SET(sfiles ${sfiles} ${children})
	FILE(GLOB children RELATIVE ${base} ${dir}/*.cc)
	SET(sfiles ${sfiles} ${children})
	FILE(GLOB children RELATIVE ${base} ${dir}/*.C)
	SET(sfiles ${sfiles} ${children})
	FILE(GLOB children RELATIVE ${base} ${dir}/*.cpp)
	SET(sfiles ${sfiles} ${children})
	FILE(GLOB children RELATIVE ${base} ${dir}/*.s)
	SET(sfiles ${sfiles} ${children})
	FILE(GLOB children RELATIVE ${base} ${dir}/*.S)
	SET(sfiles ${sfiles} ${children})
	SET(${result} ${${result}} ${sfiles})
ENDMACRO()

MACRO(find_sources result)
	find_sources_rel_dir(${result} ${CMAKE_CURRENT_LIST_DIR} ${CMAKE_CURRENT_LIST_DIR})
ENDMACRO()

MACRO(find_sources_rel result)
	find_sources_rel_dir(${result} ${CMAKE_CURRENT_LIST_DIR}/${_sea_rel_dir} ${CMAKE_CURRENT_LIST_DIR})
ENDMACRO()
