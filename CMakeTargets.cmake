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

function(get_subdirectories_recursive SUBDIRECTORY SUBDIRECTORIES)
   set(RESULT_SUBDIRECTORIES "")
   get_directory_property(CURRENT_DIRECTORIES DIRECTORY "${SUBDIRECTORY}" SUBDIRECTORIES)
   foreach(CURRENT_DIRECTORY IN ITEMS ${CURRENT_DIRECTORIES})
      list(APPEND RESULT_SUBDIRECTORIES ${CURRENT_DIRECTORY})
      get_subdirectories_recursive(${CURRENT_DIRECTORY} CURRENT_SUBDIRECTORIES)
      foreach(CURRENT_SUBDIRECTORY IN ITEMS ${CURRENT_SUBDIRECTORIES})
         list(APPEND RESULT_SUBDIRECTORIES ${CURRENT_SUBDIRECTORY})
      endforeach()
   endforeach()
   list(REMOVE_DUPLICATES RESULT_SUBDIRECTORIES)
   set(${SUBDIRECTORIES} ${RESULT_SUBDIRECTORIES} PARENT_SCOPE)
endfunction()

function(get_subdirectory_targets SUBDIRECTORY TARGET_TYPES TARGETS)
   get_subdirectories_recursive(${SUBDIRECTORY} SUBDIRECTORIES)
   list(APPEND SUBDIRECTORIES ${SUBDIRECTORY})
   set(RESULT_TARGETS "")
   foreach(SUBDIRECTORY IN ITEMS ${SUBDIRECTORIES})
      get_directory_property(SUBDIRECTORY_BUILDSYSTEM_TARGETS DIRECTORY "${SUBDIRECTORY}" BUILDSYSTEM_TARGETS)
      get_directory_property(SUBDIRECTORY_IMPORTED_TARGETS DIRECTORY "${SUBDIRECTORY}" IMPORTED_TARGETS)
      foreach(SUBDIRECTORY_TARGET IN LISTS SUBDIRECTORY_BUILDSYSTEM_TARGETS SUBDIRECTORY_IMPORTED_TARGETS)
         if(TARGET ${SUBDIRECTORY_TARGET})
            get_target_property(SUBDIRECTORY_TARGET_TYPE ${SUBDIRECTORY_TARGET} TYPE)
            if(SUBDIRECTORY_TARGET_TYPE IN_LIST ${TARGET_TYPES})
               list(APPEND RESULT_TARGETS ${SUBDIRECTORY_TARGET})
            endif()
         endif()
      endforeach()
   endforeach()
   list(REMOVE_DUPLICATES RESULT_TARGETS)
   set(${TARGETS} ${RESULT_TARGETS} PARENT_SCOPE)
endfunction()

function(organize_target TARGET_NAME ROOT_FOLDER)
   get_target_property(TARGET_FOLDER ${TARGET_NAME} FOLDER)
   if(TARGET_FOLDER STREQUAL TARGET_FOLDER-NOTFOUND)
      set(TARGET_FOLDER "")
   endif()
   set_target_properties(${TARGET_NAME} PROPERTIES FOLDER "${ROOT_FOLDER}/${TARGET_FOLDER}")
endfunction()

set(DEFAULT_TARGET_TYPES INTERFACE_LIBRARY EXECUTABLE OBJECT_LIBRARY MODULE_LIBRARY SHARED_LIBRARY STATIC_LIBRARY PARENT_SCOPE)

function(organize_targets TARGET_DIR TARGET_TYPES ROOT_FOLDER)
   set_property(DIRECTORY ${TARGET_DIR} PROPERTY EXCLUDE_FROM_ALL ON)
   get_subdirectory_targets(${TARGET_DIR} ${TARGET_TYPES} TARGET_NAMES)
   foreach(TARGET_NAME IN ITEMS ${TARGET_NAMES})
      organize_target(${TARGET_NAME} ${ROOT_FOLDER})
   endforeach()
endfunction()

function(organize_thirdparty_target TARGET_NAME ROOT_FOLDER)
   organize_target(${TARGET_NAME} ${ROOT_FOLDER})
   set_target_properties(
      ${TARGET_NAME}
      PROPERTIES
         EXCLUDE_FROM_ALL ON
         VS_GLOBAL_RunCodeAnalysis false
         VS_GLOBAL_EnableMicrosoftCodeAnalysis false
         VS_GLOBAL_EnableClangTidyCodeAnalysis false
   )
   if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.25.0")
      set_target_properties(${TARGET_NAME} PROPERTIES SYSTEM ON)
   endif()
   get_target_property(TARGET_TYPE ${TARGET_NAME} TYPE)
   if (NOT TARGET_TYPE STREQUAL INTERFACE_LIBRARY)
      target_compile_options(
         ${TARGET_NAME}
         PRIVATE
            $<$<AND:$<COMPILE_LANGUAGE:C>,$<C_COMPILER_ID:MSVC>>:/analyze- /analyze:external- /external:anglebrackets /external:templates- /external:W0 /GF /MP /W0 /WX->
            $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/analyze- /analyze:external- /external:anglebrackets /external:templates- /external:W0 /GF /MP /W0 /WX->
            $<$<AND:$<COMPILE_LANGUAGE:C>,$<C_COMPILER_ID:GNU,Clang,AppleClang>>:-w>
            $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:GNU,Clang,AppleClang>>:-w>
      )
   endif()
endfunction()

function(organize_thirdparty_targets THIRDPARTY_DIR THIRDPARTY_TARGET_TYPES ROOT_FOLDER)
   set_property(DIRECTORY ${THIRDPARTY_DIR} PROPERTY EXCLUDE_FROM_ALL ON)
   if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.25.0")
      set_property(DIRECTORY ${THIRDPARTY_DIR} PROPERTY SYSTEM ON)
   endif()
   get_subdirectory_targets(${THIRDPARTY_DIR} ${THIRDPARTY_TARGET_TYPES} THIRDPARTY_TARGETS)
   foreach(THIRDPARTY_TARGET IN ITEMS ${THIRDPARTY_TARGETS})
      organize_thirdparty_target(${THIRDPARTY_TARGET} ${ROOT_FOLDER})
   endforeach()
endfunction()
