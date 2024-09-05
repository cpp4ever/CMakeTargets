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

include(CMakeDirectoryTargets)
include(CMakeTargetCompiler)

function(organize_thirdparty_target IN_TARGET IN_FOLDER)
   organize_target(${IN_TARGET} "${IN_FOLDER}")
   set_target_properties(
      ${IN_TARGET}
      PROPERTIES
         EXCLUDE_FROM_ALL ON
         VS_GLOBAL_RunCodeAnalysis false
         VS_GLOBAL_EnableMicrosoftCodeAnalysis false
         VS_GLOBAL_EnableClangTidyCodeAnalysis false
   )
   if(${CMAKE_VERSION} VERSION_GREATER_EQUAL 3.25)
      set_target_properties(${IN_TARGET} PROPERTIES SYSTEM ON)
   endif()
   disable_target_compile_warnings(${IN_TARGET})
   get_target_property(TARGET_TYPE ${IN_TARGET} TYPE)
   set(SKIP_TARGET_TYPES INTERFACE_LIBRARY UTILITY)
   if(NOT TARGET_TYPE IN_LIST SKIP_TARGET_TYPES)
      if(CMAKE_CXX_COMPILER_LOADED)
         set_target_default_cxx_compile_flags(${IN_TARGET} PRIVATE)
      elseif(CMAKE_C_COMPILER_LOADED)
         set_target_default_c_compile_flags(${IN_TARGET} PRIVATE)
      endif()
   endif()
endfunction()

function(organize_thirdparty_directory_targets IN_ROOT_DIRECTORY IN_FOLDER)
   set_property(DIRECTORY "${IN_ROOT_DIRECTORY}" PROPERTY EXCLUDE_FROM_ALL ON)
   if(${CMAKE_VERSION} VERSION_GREATER_EQUAL 3.25)
      set_property(DIRECTORY "${IN_ROOT_DIRECTORY}" PROPERTY SYSTEM ON)
   endif()
   get_directory_targets("${IN_ROOT_DIRECTORY}" THIRDPARTY_TARGETS)
   foreach(THIRDPARTY_TARGET IN ITEMS ${THIRDPARTY_TARGETS})
      organize_thirdparty_target(${THIRDPARTY_TARGET} "${IN_FOLDER}")
   endforeach()
endfunction()
