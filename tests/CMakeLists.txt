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

cmake_minimum_required(VERSION 3.20)

project(CMakeTargetsTest LANGUAGES C)

include(CMakeTargetCompiler)

set(
   TEST_COMPILE_FLAGS
   test_compile_flag_0
   test_compile_flag_1 test_compile_flag_2 test_compile_flag_3
   test_compile_flag_4 test_compile_flag_5 test_compile_flag_6
   test_compile_flag_7 test_compile_flag_8 test_compile_flag_9
   test_compile_flag_10 test_compile_flag_11
)

add_library(test_check_compile_flags_positive main.c)
target_compile_options(
   test_check_compile_flags_positive
   PRIVATE
   test_compile_flag_0
   "test_compile_flag_1 test_compile_flag_2 test_compile_flag_3"
   $<$<BOOL:TRUE>:test_compile_flag_4 test_compile_flag_5 test_compile_flag_6>
   "$<$<BOOL:TRUE>:test_compile_flag_7 test_compile_flag_8 test_compile_flag_9>"
   $<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>
)
foreach(TEST_COMPILE_FLAG IN LISTS TEST_COMPILE_FLAGS)
   check_target_compile_flag("C" test_check_compile_flags_positive ${TEST_COMPILE_FLAG} ${TEST_COMPILE_FLAG}_FOUND)
   if(NOT ${TEST_COMPILE_FLAG}_FOUND)
      message(FATAL_ERROR "expected `${TEST_COMPILE_FLAG}` found")
   endif()
   check_target_compile_flag("C" test_check_compile_flags_positive ${TEST_COMPILE_FLAG}- ${TEST_COMPILE_FLAG}_FOUND)
   if(${TEST_COMPILE_FLAG}_FOUND)
      message(FATAL_ERROR "expected `${TEST_COMPILE_FLAG}-` not found")
   endif()
endforeach()

add_library(test_check_compile_flags_negative main.c)
target_compile_options(
   test_check_compile_flags_negative
   PRIVATE
   test_compile_flag_0-
   "test_compile_flag_1- test_compile_flag_2- test_compile_flag_3-"
   $<$<BOOL:TRUE>:test_compile_flag_4- test_compile_flag_5- test_compile_flag_6->
   "$<$<BOOL:TRUE>:test_compile_flag_7- test_compile_flag_8- test_compile_flag_9->"
   $<IF:$<BOOL:TRUE>,test_compile_flag_10-,test_compile_flag_11->
)
foreach(TEST_COMPILE_FLAG IN LISTS TEST_COMPILE_FLAGS)
   check_target_compile_flag("C" test_check_compile_flags_negative ${TEST_COMPILE_FLAG}- ${TEST_COMPILE_FLAG}_FOUND)
   if(NOT ${TEST_COMPILE_FLAG}_FOUND)
      message(FATAL_ERROR "expected `${TEST_COMPILE_FLAG}-` found")
   endif()
   check_target_compile_flag("C" test_check_compile_flags_negative ${TEST_COMPILE_FLAG} ${TEST_COMPILE_FLAG}_FOUND)
   if(${TEST_COMPILE_FLAG}_FOUND)
      message(FATAL_ERROR "expected `${TEST_COMPILE_FLAG}` not found")
   endif()
endforeach()

get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "test_compile_flag_0|\
test_compile_flag_1 test_compile_flag_2 test_compile_flag_3|\
$<$<BOOL:TRUE>:test_compile_flag_4|test_compile_flag_5|test_compile_flag_6>|\
$<$<BOOL:TRUE>:test_compile_flag_7 test_compile_flag_8 test_compile_flag_9>|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_0)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
test_compile_flag_1 test_compile_flag_2 test_compile_flag_3|\
$<$<BOOL:TRUE>:test_compile_flag_4|test_compile_flag_5|test_compile_flag_6>|\
$<$<BOOL:TRUE>:test_compile_flag_7 test_compile_flag_8 test_compile_flag_9>|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_1)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
test_compile_flag_2 test_compile_flag_3|\
$<$<BOOL:TRUE>:test_compile_flag_4|test_compile_flag_5|test_compile_flag_6>|\
$<$<BOOL:TRUE>:test_compile_flag_7 test_compile_flag_8 test_compile_flag_9>|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_2)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
test_compile_flag_3|\
$<$<BOOL:TRUE>:test_compile_flag_4|test_compile_flag_5|test_compile_flag_6>|\
$<$<BOOL:TRUE>:test_compile_flag_7 test_compile_flag_8 test_compile_flag_9>|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_3)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
\
$<$<BOOL:TRUE>:test_compile_flag_4|test_compile_flag_5|test_compile_flag_6>|\
$<$<BOOL:TRUE>:test_compile_flag_7 test_compile_flag_8 test_compile_flag_9>|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_4)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
\
$<$<BOOL:TRUE>:|test_compile_flag_5|test_compile_flag_6>|\
$<$<BOOL:TRUE>:test_compile_flag_7 test_compile_flag_8 test_compile_flag_9>|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_5)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
\
$<$<BOOL:TRUE>:|test_compile_flag_6>|\
$<$<BOOL:TRUE>:test_compile_flag_7 test_compile_flag_8 test_compile_flag_9>|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_6)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
\
$<$<BOOL:TRUE>:|>|\
$<$<BOOL:TRUE>:test_compile_flag_7 test_compile_flag_8 test_compile_flag_9>|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_7)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
\
$<$<BOOL:TRUE>:|>|\
$<$<BOOL:TRUE>: test_compile_flag_8 test_compile_flag_9>|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_8)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
\
$<$<BOOL:TRUE>:|>|\
$<$<BOOL:TRUE>:  test_compile_flag_9>|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_9)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
\
$<$<BOOL:TRUE>:|>|\
$<$<BOOL:TRUE>:  >|\
$<IF:$<BOOL:TRUE>,test_compile_flag_10,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_10)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
\
$<$<BOOL:TRUE>:|>|\
$<$<BOOL:TRUE>:  >|\
$<IF:$<BOOL:TRUE>,,test_compile_flag_11>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()

remove_target_compile_flag(test_check_compile_flags_positive test_compile_flag_11)
get_target_property(TEST_TARGET_COMPILE_OPTIONS test_check_compile_flags_positive COMPILE_OPTIONS)
list(JOIN TEST_TARGET_COMPILE_OPTIONS "|" TEST_TARGET_COMPILE_OPTIONS)
if(NOT TEST_TARGET_COMPILE_OPTIONS STREQUAL "\
\
$<$<BOOL:TRUE>:|>|\
$<$<BOOL:TRUE>:  >|\
$<IF:$<BOOL:TRUE>,,>")
   message(FATAL_ERROR "unexpected `${TEST_TARGET_COMPILE_OPTIONS}`")
endif()
