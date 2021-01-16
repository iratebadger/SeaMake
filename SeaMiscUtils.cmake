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

if(DEFINED __INCLUDED_SEA_MISC_UTILS_CMAKE)
    return()
endif()
set(__INCLUDED_SEA_MISC_UTILS_CMAKE TRUE)
set(_sea_rel_dir "./")

########################################################################
# Set global variable macro.
# Used for subdirectories to export settings.
# Example: include and library paths.
########################################################################
function(SEA_SET_GLOBAL var)
    set(${var} ${ARGN} CACHE INTERNAL "" FORCE)
endfunction(SEA_SET_GLOBAL)

function(SEA_SET_ENABLE var)
    set(${var} ${ARGN} CACHE INTERNAL "" FORCE)
endfunction(SEA_SET_ENABLE)

########################################################################
# Set the pre-processor definition if the condition is true.
#  - def the pre-processor definition to set and condition name
########################################################################
function(SEA_ADD_COND_DEF def)
    if(${def})
        add_definitions(-D${def})
    endif(${def})
endfunction(SEA_ADD_COND_DEF)

########################################################################
# Check for a header and conditionally set a compile define.
#  - hdr the relative path to the header file
#  - def the pre-processor definition to set
########################################################################
function(SEA_CHECK_HDR_N_DEF hdr def)
    include(CheckIncludeFileCXX)
    CHECK_INCLUDE_FILE_CXX(${hdr} ${def})
    SEA_ADD_COND_DEF(${def})
endfunction(SEA_CHECK_HDR_N_DEF)

########################################################################
# Include subdirectory macro.
# Sets the CMake directory variables,
# includes the subdirectory CMakeLists.txt,
# resets the CMake directory variables.
#
# This macro includes subdirectories rather than adding them
# so that the subdirectory can affect variables in the level above.
# This provides a work-around for the lack of convenience libraries.
# This way a subdirectory can append to the list of library sources.
########################################################################
macro(SEA_INCLUDE_SUBDIRECTORY subdir)
    #insert the current directories on the front of the list
    list(INSERT _cmake_source_dirs 0 ${CMAKE_CURRENT_SOURCE_DIR})
    list(INSERT _cmake_binary_dirs 0 ${CMAKE_CURRENT_BINARY_DIR})
    list(INSERT _cmake_rel_stack 0 ${_sea_rel_dir})

    #set the current directories to the names of the subdirs
    set(CMAKE_CURRENT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/${subdir})
    set(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${subdir})
    set(_sea_rel_dir ${_sea_rel_dir}../)

    #include the subdirectory CMakeLists to run it
    file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    include(${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt)

    #reset the value of the current directories
    list(GET _cmake_source_dirs 0 CMAKE_CURRENT_SOURCE_DIR)
    list(GET _cmake_binary_dirs 0 CMAKE_CURRENT_BINARY_DIR)
    list(GET _cmake_rel_stack 0 _sea_rel_dir)

    #pop the subdir names of the front of the list
    list(REMOVE_AT _cmake_source_dirs 0)
    list(REMOVE_AT _cmake_binary_dirs 0)
    list(REMOVE_AT _cmake_rel_stack 0)
endmacro(SEA_INCLUDE_SUBDIRECTORY)

########################################################################
# Check if a compiler flag works and conditionally set a compile define.
#  - flag the compiler flag to check for
#  - have the variable to set with result
########################################################################
macro(SEA_ADD_CXX_COMPILER_FLAG_IF_AVAILABLE flag have)
    include(CheckCXXCompilerFlag)
    CHECK_CXX_COMPILER_FLAG(${flag} ${have})
    if(${have})
        add_definitions(${flag})
    endif(${have})
endmacro(SEA_ADD_CXX_COMPILER_FLAG_IF_AVAILABLE)

macro(SEA_ADD_CXX_COMPILDER_DEBUG_FLAG_IF_AVAILABLE flag, have)
	if(CMAKE_BUILD_TYPE EQUAL "DEBUG")
    	include(CheckCXXCompilerFlag)
    	CHECK_CXX_COMPILER_FLAG(${flag} ${have})
    	if(${have})
    	    add_definitions(${flag})
    	endif(${have})
	endif(CMAKE_BUILD_TYPE EQUAL "DEBUG")
endmacro(SEA_ADD_CXX_COMPILDER_DEBUG_FLAG_IF_AVAILABLE)

########################################################################
# Check if HAVE_PTHREAD_SETSCHEDPARAM and HAVE_SCHED_SETSCHEDULER
#  should be defined
########################################################################
macro(SEA_CHECK_LINUX_SCHED_AVAIL)
set(CMAKE_REQUIRED_LIBRARIES -lpthread)
    CHECK_CXX_SOURCE_COMPILES("
        #include <pthread.h>
        int main(){
            pthread_t pthread;
            pthread_setschedparam(pthread,  0, 0);
            return 0;
        } " HAVE_PTHREAD_SETSCHEDPARAM
    )
    SEA_ADD_COND_DEF(HAVE_PTHREAD_SETSCHEDPARAM)

    CHECK_CXX_SOURCE_COMPILES("
        #include <sched.h>
        int main(){
            pid_t pid;
            sched_setscheduler(pid, 0, 0);
            return 0;
        } " HAVE_SCHED_SETSCHEDULER
    )
    SEA_ADD_COND_DEF(HAVE_SCHED_SETSCHEDULER)
endmacro(SEA_CHECK_LINUX_SCHED_AVAIL)

