#[[
   Part of the CMakeTargets Project (https://github.com/cpp4ever/CMakeTargets), under the MIT License
   SPDX-License-Identifier: MIT

   Copyright (c) 2024 Mikhail Smirnov

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
]]

function(get_directories_recursive IN_ROOT_DIRECTORY OUT_SUBDIRECTORIES)
   set(SUBDIRECTORIES )
   get_directory_property(ROOT_SUBDIRECTORIES DIRECTORY "${IN_ROOT_DIRECTORY}" SUBDIRECTORIES)
   foreach(ROOT_SUBDIRECTORY IN ITEMS ${ROOT_SUBDIRECTORIES})
      get_directories_recursive("${ROOT_SUBDIRECTORY}" ROOT_SUBDIRECTORY_SUBDIRECTORIES)
      list(APPEND SUBDIRECTORIES "${ROOT_SUBDIRECTORY}" ${ROOT_SUBDIRECTORY_SUBDIRECTORIES})
   endforeach()
   list(REMOVE_DUPLICATES SUBDIRECTORIES)
   set(${OUT_SUBDIRECTORIES} ${SUBDIRECTORIES} PARENT_SCOPE)
endfunction()

function(get_directory_targets IN_ROOT_DIRECTORY OUT_TARGETS)
   get_directories_recursive("${IN_ROOT_DIRECTORY}" SUBDIRECTORIES)
   list(APPEND SUBDIRECTORIES "${IN_ROOT_DIRECTORY}")
   set(TARGETS )
   foreach(SUBDIRECTORY IN ITEMS ${SUBDIRECTORIES})
      get_directory_property(SUBDIRECTORY_BUILDSYSTEM_TARGETS DIRECTORY "${SUBDIRECTORY}" BUILDSYSTEM_TARGETS)
      get_directory_property(SUBDIRECTORY_IMPORTED_TARGETS DIRECTORY "${SUBDIRECTORY}" IMPORTED_TARGETS)
      foreach(SUBDIRECTORY_TARGET IN LISTS SUBDIRECTORY_BUILDSYSTEM_TARGETS SUBDIRECTORY_IMPORTED_TARGETS)
         if(TARGET ${SUBDIRECTORY_TARGET})
            list(APPEND TARGETS ${SUBDIRECTORY_TARGET})
         endif()
      endforeach()
   endforeach()
   list(REMOVE_DUPLICATES TARGETS)
   set(${OUT_TARGETS} ${TARGETS} PARENT_SCOPE)
endfunction()

function(organize_target IN_TARGET_NAME IN_FOLDER)
   get_target_property(TARGET_FOLDER ${IN_TARGET_NAME} FOLDER)
   if(TARGET_FOLDER STREQUAL TARGET_FOLDER-NOTFOUND OR "${TARGET_FOLDER}" STREQUAL "")
      set(TARGET_FOLDER "${IN_FOLDER}")
   else()
      string(REGEX MATCH "^${IN_FOLDER}/?.*" MATCHED_TARGET_FOLDER ${TARGET_FOLDER})
      if(NOT "${MATCHED_TARGET_FOLDER}" STREQUAL "${TARGET_FOLDER}")
         string(PREPEND TARGET_FOLDER "${IN_FOLDER}/")
      endif()
   endif()
   set_target_properties(${IN_TARGET_NAME} PROPERTIES FOLDER "${TARGET_FOLDER}")
endfunction()

function(organize_directory_targets IN_ROOT_DIRECTORY IN_FOLDER)
   set_property(DIRECTORY "${IN_ROOT_DIRECTORY}" PROPERTY EXCLUDE_FROM_ALL ON)
   get_directory_targets("${IN_ROOT_DIRECTORY}" TARGETS)
   foreach(TARGET_NAME IN ITEMS ${TARGETS})
      organize_target(${TARGET_NAME} "${IN_FOLDER}")
   endforeach()
endfunction()
