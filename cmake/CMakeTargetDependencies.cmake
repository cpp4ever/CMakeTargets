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

function(get_target_link_libraries_recursive IN_TARGET OUT_LINK_LIBRARIES)
   set(LINK_LIBRARIES )
   get_target_property(TARGET_LINK_LIBRARIES ${IN_TARGET} LINK_LIBRARIES)
   if(NOT TARGET_LINK_LIBRARIES STREQUAL TARGET_LINK_LIBRARIES-NOTFOUND)
      foreach(SUBTARGET IN LISTS TARGET_LINK_LIBRARIES)
         if(TARGET ${SUBTARGET})
            get_target_property(ALIASED_SUBTARGET ${SUBTARGET} ALIASED_TARGET)
            if(NOT ALIASED_SUBTARGET STREQUAL ALIASED_SUBTARGET-NOTFOUND)
               set(SUBTARGET ${ALIASED_SUBTARGET})
            endif()
            get_target_link_libraries_recursive(${SUBTARGET} SUBTARGET_LINK_LIBRARIES)
            list(APPEND LINK_LIBRARIES ${SUBTARGET} ${SUBTARGET_LINK_LIBRARIES})
         endif()
      endforeach()
   endif()
   list(REMOVE_DUPLICATES LINK_LIBRARIES)
   set(${OUT_LINK_LIBRARIES} ${LINK_LIBRARIES} PARENT_SCOPE)
endfunction()
