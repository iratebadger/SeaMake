# SeaMake

## Overview

SeaMake is a horrible thing I created years ago to enable some kind of configureable modularity in CMake. I'm pretty sure this has since been resolved in the base system and this monstrosity is no longer needed. However, many of my code bases use this system and will continue to use this system. If you have a TBI and come to the conclusion you wish to use this as well, that's on you mate.

If you have ever heard of a thing called SCube...

## Requirements
CMake 3.5 though don't quote me on that, just use the latest version.

Your sanity.

## Usage

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/SeaMake)
include(SeaModule)

### Target and verion
Usually placed in seperate cmake files to enable automation

set(VERSION_INFO_MAJOR_VERSION 0)

set(VERSION_INFO_API_COMPAT    1)

set(VERSION_INFO_MINOR_VERSION 1)

set(VERSION_INFO_MAINT_VERSION git)

#### SEA_PLATFORM
Used to se the sdk

example

set(SEA_PLATFORM pico-sdk)

#### SEA_ARCH
Used to specify the ABI and specific IC

example

set(SEA_ARCH ARM rp2040)

#### SEA_TARGET
Used to set the target application features

example

set(SEA_TARGET target name and features)


### SEA_MODULE_BUILD
This must exist somewhere in the project to execute the build, I usually use a folder called bin.

SEA_MODULE_BUILD("Project Name")

## Making a simple executable module
Assuming a source tree

module_name/

--src

--include
```
include(SeaModule)

SEA_MODULE("project_name"  static required
                                dep_module
                                go_here)

SEA_MODULE_SOURCES("project_name" src)
SEA_MODULE_INCLUDES("project_name" include)
```