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

include(CheckCXXCompilerFlag)
include(CMakeTargetDependencies)

function(check_compiler_flags IN_LANGUAGE IN_FLAGS OUT_RESULT)
   if(IN_LANGUAGE STREQUAL "C")
      include(CheckCCompilerFlag)
      set(CMAKE_REQUIRED_FLAGS ${IN_FLAGS})
      check_c_compiler_flag(${CMAKE_REQUIRED_FLAGS} ${OUT_RESULT})
   elseif(IN_LANGUAGE STREQUAL "CXX")
      include(CheckCXXCompilerFlag)
      set(CMAKE_REQUIRED_FLAGS ${IN_FLAGS})
      check_cxx_compiler_flag(${CMAKE_REQUIRED_FLAGS} ${OUT_RESULT})
   else()
      message(FATAL_ERROR "Unknown language: ${IN_LANGUAGE}")
   endif()
endfunction()

function(check_target_compile_flag IN_COMPILE_LANGUAGE IN_TARGET IN_COMPILE_FLAG OUT_RESULT)
   set(TARGET_${IN_COMPILE_LANGUAGE}_COMPILE_FLAGS ${CMAKE_${IN_COMPILE_LANGUAGE}_FLAGS})
   foreach(CONFIGURATION_TYPE IN LISTS CMAKE_CONFIGURATION_TYPES)
      list(APPEND TARGET_${IN_COMPILE_LANGUAGE}_COMPILE_FLAGS ${CMAKE_${IN_COMPILE_LANGUAGE}_FLAGS_${CONFIGURATION_TYPE}})
   endforeach()
   get_target_property(TARGET_COMPILE_OPTIONS ${IN_TARGET} COMPILE_OPTIONS)
   if(NOT TARGET_COMPILE_OPTIONS STREQUAL TARGET_COMPILE_OPTIONS-NOTFOUND)
      list(APPEND TARGET_${IN_COMPILE_LANGUAGE}_COMPILE_FLAGS ${TARGET_COMPILE_OPTIONS})
   endif()
   get_target_property(TARGET_COMPILE_FLAGS ${IN_TARGET} COMPILE_FLAGS)
   if(NOT TARGET_COMPILE_FLAGS STREQUAL TARGET_COMPILE_FLAGS-NOTFOUND)
      list(APPEND TARGET_${IN_COMPILE_LANGUAGE}_COMPILE_FLAGS ${TARGET_COMPILE_FLAGS})
   endif()
   set(RESULT FALSE)
   foreach(TARGET_COMPILE_FLAG IN LISTS TARGET_${IN_COMPILE_LANGUAGE}_COMPILE_FLAGS)
      if(TARGET_COMPILE_FLAG MATCHES "(^|[ \t\r\n,:])(${IN_COMPILE_FLAG})([ \t\r\n,>]|$)")
         set(RESULT TRUE)
         break()
      endif()
   endforeach()
   set(${OUT_RESULT} ${RESULT} PARENT_SCOPE)
endfunction()

function(set_target_compile_flag IN_COMPILE_LANGUAGE IN_TARGET IN_SCOPE IN_COMPILE_FLAG)
   check_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_COMPILE_FLAG} TARGET_COMPILE_FLAG_FOUND)
   if(NOT TARGET_COMPILE_FLAG_FOUND)
      if(IN_COMPILE_LANGUAGE STREQUAL "CXX")
         set(COMPILE_LANGUAGE "C,CXX")
      else()
         set(COMPILE_LANGUAGE ${IN_COMPILE_LANGUAGE})
      endif()
      target_compile_options(${IN_TARGET} ${IN_SCOPE} $<$<COMPILE_LANGUAGE:${COMPILE_LANGUAGE}>:${IN_COMPILE_FLAG}>)
   endif()
endfunction()

function(set_target_c_compile_flag IN_TARGET IN_SCOPE IN_COMPILE_FLAG)
   set_target_compile_flag("C" ${IN_TARGET} ${IN_SCOPE} ${IN_COMPILE_FLAG})
   get_target_property(TARGET_COMPILE_OPTIONS ${IN_TARGET} COMPILE_OPTIONS)
endfunction()

function(set_target_cxx_compile_flag IN_TARGET IN_SCOPE IN_COMPILE_FLAG)
   set_target_compile_flag("CXX" ${IN_TARGET} ${IN_SCOPE} ${IN_COMPILE_FLAG})
endfunction()

function(set_target_compile_flag_exclusive IN_COMPILE_LANGUAGE IN_TARGET IN_SCOPE IN_EXCLUDING_COMPILE_FLAG IN_COMPILE_FLAG)
   check_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_EXCLUDING_COMPILE_FLAG} TARGET_EXCLUDING_COMPILE_FLAG_SET)
   if(NOT TARGET_EXCLUDING_COMPILE_FLAG_SET)
      set_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} ${IN_COMPILE_FLAG})
   endif()
endfunction()

function(enforce_msvc_target_standard_conformance IN_COMPILE_LANGUAGE IN_TARGET IN_SCOPE)
   get_target_property(TARGET_C_EXTENSIONS_ENABLED ${IN_TARGET} C_EXTENSIONS)
   get_target_property(TARGET_C_STANDARD ${IN_TARGET} C_STANDARD)
   get_target_property(TARGET_CXX_EXTENSIONS_ENABLED ${IN_TARGET} CXX_EXTENSIONS)
   if(TARGET_C_EXTENSIONS_ENABLED OR TARGET_CXX_EXTENSIONS_ENABLED)
      set(MSVC_EXTENSIONS_ENABLED TRUE)
   else()
      set(MSVC_EXTENSIONS_ENABLED FALSE)
   endif()
   get_target_property(TARGET_CXX_STANDARD ${IN_TARGET} CXX_STANDARD)
   # /permissive- (Standards conformance) https://learn.microsoft.com/en-us/cpp/build/reference/permissive-standards-conformance
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /permissive- MSVC_FLAG_STANDARDS_CONFORMANCE_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_CONFORMANCE_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /permissive /permissive-)
   endif()
   # /Za (Disable Language Extensions) https://learn.microsoft.com/en-us/cpp/build/reference/za-ze-disable-language-extensions
   if(TARGET_C_STANDARD STREQUAL TARGET_C_STANDARD-NOTFOUND OR TARGET_C_STANDARD LESS 11)
      if(NOT MSVC_EXTENSIONS_ENABLED)
         check_compiler_flags(${IN_COMPILE_LANGUAGE} /Za MSVC_FLAG_DISABLE_LANGUAGE_EXTENSIONS_AVAILABLE)
         if(MSVC_FLAG_DISABLE_LANGUAGE_EXTENSIONS_AVAILABLE)
            set_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Za)
         endif()
      endif()
   endif()
   # /Zc:__cplusplus (Enable updated __cplusplus macro) https://learn.microsoft.com/en-us/cpp/build/reference/zc-cplusplus
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:__cplusplus MSVC_FLAG_STANDARDS_COMPLIANT__cplusplus_MACRO_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_COMPLIANT__cplusplus_MACRO_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:__cplusplus- /Zc:__cplusplus)
   endif()
   # /Zc:__STDC__ (Enable __STDC__ macro) https://learn.microsoft.com/en-us/cpp/build/reference/zc-stdc
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC" AND NOT MSVC_EXTENSIONS_ENABLED)
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:__STDC__ MSVC_FLAG_STANDARDS_COMPLIANT__STDC__MACRO_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT__STDC__MACRO_AVAILABLE)
         set_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:__STDC__)
      endif()
   endif()
   # /Zc:alignedNew (C++17 over-aligned allocation) https://learn.microsoft.com/en-us/cpp/build/reference/zc-alignednew
   if(TARGET_CXX_STANDARD GREATER_EQUAL 17)
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:alignedNew MSVC_FLAG_STANDARDS_COMPLIANT_OVER_ALIGNED_NEW_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_OVER_ALIGNED_NEW_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:alignedNew- /Zc:alignedNew)
      endif()
   endif()
   # /Zc:auto (Deduce Variable Type) https://learn.microsoft.com/en-us/cpp/build/reference/zc-auto-deduce-variable-type
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:auto MSVC_FLAG_STANDARDS_COMPLIANT_DEDUCE_VARIABLE_TYPE_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_COMPLIANT_DEDUCE_VARIABLE_TYPE_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:auto- /Zc:auto)
   endif()
   # /Zc:char8_t (Enable C++20 char8_t type) https://learn.microsoft.com/en-us/cpp/build/reference/zc-char8-t
   if(TARGET_CXX_STANDARD GREATER_EQUAL 20)
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:char8_t MSVC_FLAG_STANDARDS_COMPLIANT_char8_t_TYPE_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_char8_t_TYPE_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:char8_t- /Zc:char8_t)
      endif()
   endif()
   # /Zc:checkGwOdr (Enforce Standard C++ ODR violations under /Gw) https://learn.microsoft.com/en-us/cpp/build/reference/zc-check-gwodr
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:checkGwOdr MSVC_FLAG_STANDARDS_COMPLIANT_ODR_VIOLATIONS_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_ODR_VIOLATIONS_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:checkGwOdr- /Zc:checkGwOdr)
      endif()
   endif()
   # /Zc:enumTypes (Enable enum type deduction) https://learn.microsoft.com/en-us/cpp/build/reference/zc-enumtypes
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:enumTypes MSVC_FLAG_STANDARDS_COMPLIANT_ENUM_TYPE_DEDUCTION_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_ENUM_TYPE_DEDUCTION_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:enumTypes- /Zc:enumTypes)
      endif()
   endif()
   # /Zc:externC (Use Standard C++ extern "C" rules) https://learn.microsoft.com/en-us/cpp/build/reference/zc-externc
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:externC MSVC_FLAG_STANDARDS_COMPLIANT_EXTERN_C_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_EXTERN_C_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:externC- /Zc:externC)
      endif()
   endif()
   # /Zc:externConstexpr (Enable extern constexpr variables) https://learn.microsoft.com/en-us/cpp/build/reference/zc-externconstexpr
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:externConstexpr MSVC_FLAG_STANDARDS_COMPLIANT_EXTERN_CONSTEXPR_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_EXTERN_CONSTEXPR_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:externConstexpr- /Zc:externConstexpr)
      endif()
   endif()
   # /Zc:forScope (Force Conformance in for Loop Scope) https://learn.microsoft.com/en-us/cpp/build/reference/zc-forscope-force-conformance-in-for-loop-scope
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:forScope MSVC_FLAG_STANDARDS_COMPLIANT_FOR_LOOP_SCOPE_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_COMPLIANT_FOR_LOOP_SCOPE_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:forScope- /Zc:forScope)
   endif()
   # /Zc:gotoScope (Enforce conformance in goto scope) https://learn.microsoft.com/en-us/cpp/build/reference/zc-gotoscope
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:gotoScope MSVC_FLAG_STANDARDS_COMPLIANT_GOTO_SCOPE_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_GOTO_SCOPE_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:gotoScope- /Zc:gotoScope)
      endif()
   endif()
   # /Zc:hiddenFriend (Enforce Standard C++ hidden friend rules) https://learn.microsoft.com/en-us/cpp/build/reference/zc-hiddenfriend
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:hiddenFriend MSVC_FLAG_STANDARDS_COMPLIANT_HIDDEN_FRIEND_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_HIDDEN_FRIEND_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:hiddenFriend- /Zc:hiddenFriend)
      endif()
   endif()
   # /Zc:implicitNoexcept (Implicit Exception Specifiers) https://learn.microsoft.com/en-us/cpp/build/reference/zc-implicitnoexcept-implicit-exception-specifiers
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:implicitNoexcept MSVC_FLAG_STANDARDS_COMPLIANT_IMPLICIT_EXCEPTION_SPECIFIERS_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_IMPLICIT_EXCEPTION_SPECIFIERS_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:implicitNoexcept- /Zc:implicitNoexcept)
      endif()
   endif()
   # /Zc:inline (Remove unreferenced COMDAT) https://learn.microsoft.com/en-us/cpp/build/reference/zc-inline-remove-unreferenced-comdat
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:inline MSVC_FLAG_STANDARDS_COMPLIANT_INLINING_RULES_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_COMPLIANT_INLINING_RULES_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:inline- /Zc:inline)
   endif()
   # /Zc:lambda (Enable updated lambda processor) https://learn.microsoft.com/en-us/cpp/build/reference/zc-lambda
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:lambda MSVC_FLAG_STANDARDS_COMPLIANT_LAMBDA_PROCESSOR_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_LAMBDA_PROCESSOR_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:lambda- /Zc:lambda)
      endif()
   endif()
   # /Zc:noexceptTypes (C++17 noexcept rules) https://learn.microsoft.com/en-us/cpp/build/reference/zc-noexcepttypes
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC" AND TARGET_CXX_STANDARD GREATER_EQUAL 17)
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:noexceptTypes MSVC_FLAG_STANDARDS_COMPLIANT_NOEXCEPT_RULES_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_NOEXCEPT_RULES_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:noexceptTypes- /Zc:noexceptTypes)
      endif()
   endif()
   # /Zc:nrvo (Control optional NRVO) https://learn.microsoft.com/en-us/cpp/build/reference/zc-nrvo
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:nrvo MSVC_FLAG_STANDARDS_COMPLIANT_NRVO_RULES_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_NRVO_RULES_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:nrvo- /Zc:nrvo)
      endif()
   endif()
   # /Zc:preprocessor (Enable preprocessor conformance mode) https://learn.microsoft.com/en-us/cpp/build/reference/zc-preprocessor
   if(CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION VERSION_GREATER_EQUAL 10.0.20348)
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:preprocessor MSVC_FLAG_STANDARDS_COMPLIANT_PREPROCESSOR_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_PREPROCESSOR_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:preprocessor- /Zc:preprocessor)
      endif()
   endif()
   # /Zc:referenceBinding (Enforce reference binding rules) https://learn.microsoft.com/en-us/cpp/build/reference/zc-referencebinding-enforce-reference-binding-rules
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:referenceBinding MSVC_FLAG_STANDARDS_COMPLIANT_REFERENCE_BINDING_RULES_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_REFERENCE_BINDING_RULES_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:referenceBinding- /Zc:referenceBinding)
      endif()
   endif()
   # /Zc:rvalueCast (Enforce type conversion rules) https://learn.microsoft.com/en-us/cpp/build/reference/zc-rvaluecast-enforce-type-conversion-rules
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:rvalueCast MSVC_FLAG_STANDARDS_COMPLIANT_RVALUE_CAST_RULES_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_COMPLIANT_RVALUE_CAST_RULES_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:rvalueCast- /Zc:rvalueCast)
   endif()
   # /Zc:sizedDealloc (Enable Global Sized Deallocation Functions) https://learn.microsoft.com/en-us/cpp/build/reference/zc-sizeddealloc-enable-global-sized-dealloc-functions
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:sizedDealloc MSVC_FLAG_STANDARDS_COMPLIANT_GLOBAL_SIZED_DEALLOCATION_FUNCTIONS_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_COMPLIANT_GLOBAL_SIZED_DEALLOCATION_FUNCTIONS_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:sizedDealloc- /Zc:sizedDealloc)
   endif()
   # /Zc:static_assert (Strict static_assert handling) https://learn.microsoft.com/en-us/cpp/build/reference/zc-static-assert
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:static_assert MSVC_FLAG_STANDARDS_COMPLIANT_static_assert_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_static_assert_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:static_assert- /Zc:static_assert)
      endif()
   endif()
   # /Zc:strictStrings (Disable string literal type conversion) https://learn.microsoft.com/en-us/cpp/build/reference/zc-strictstrings-disable-string-literal-type-conversion
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:strictStrings MSVC_FLAG_STANDARDS_COMPLIANT_STRING_LITERAL_TYPE_CONVERSION_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_COMPLIANT_STRING_LITERAL_TYPE_CONVERSION_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:strictStrings- /Zc:strictStrings)
   endif()
   # /Zc:templateScope (Check template parameter shadowing) https://learn.microsoft.com/en-us/cpp/build/reference/zc-templatescope
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:templateScope MSVC_FLAG_STANDARDS_COMPLIANT_TEMPLATE_PARAMETER_SHADOWING_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_TEMPLATE_PARAMETER_SHADOWING_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:templateScope- /Zc:templateScope)
      endif()
   endif()
   # /Zc:ternary (Enforce conditional operator rules) https://learn.microsoft.com/en-us/cpp/build/reference/zc-ternary
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:ternary MSVC_FLAG_STANDARDS_COMPLIANT_CONDITIOAL_OPERATOR_RULES_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_COMPLIANT_CONDITIOAL_OPERATOR_RULES_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:ternary- /Zc:ternary)
   endif()
   # /Zc:threadSafeInit (Thread-safe Local Static Initialization) https://learn.microsoft.com/en-us/cpp/build/reference/zc-threadsafeinit-thread-safe-local-static-initialization
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:threadSafeInit MSVC_FLAG_STANDARDS_COMPLIANT_THREAD_SAFE_STATIC_INITIALIZATION_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_COMPLIANT_THREAD_SAFE_STATIC_INITIALIZATION_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:threadSafeInit- /Zc:threadSafeInit)
   endif()
   # /Zc:throwingNew (Assume operator new throws) https://learn.microsoft.com/en-us/cpp/build/reference/zc-throwingnew-assume-operator-new-throws
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:throwingNew MSVC_FLAG_STANDARDS_COMPLIANT_THROWING_NEW_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_THROWING_NEW_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:throwingNew- /Zc:throwingNew)
      endif()
   endif()
   # /Zc:tlsGuards (Check TLS initialization) https://learn.microsoft.com/en-us/cpp/build/reference/zc-tlsguards
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:tlsGuards MSVC_FLAG_STANDARDS_COMPLIANT_TLS_INITIALIZATION_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_TLS_INITIALIZATION_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:tlsGuards- /Zc:tlsGuards)
      endif()
   endif()
   # /Zc:trigraphs (Trigraphs Substitution) https://learn.microsoft.com/en-us/cpp/build/reference/zc-trigraphs-trigraphs-substitution
   # /Zc:twoPhase- (disable two-phase name lookup) https://learn.microsoft.com/en-us/cpp/build/reference/zc-twophase
   # /Zc:wchar_t (wchar_t Is Native Type) https://learn.microsoft.com/en-us/cpp/build/reference/zc-wchar-t-wchar-t-is-native-type
   check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:wchar_t MSVC_FLAG_STANDARDS_COMPLIANT_NATIVE_wchar_t_AVAILABLE)
   if(MSVC_FLAG_STANDARDS_COMPLIANT_NATIVE_wchar_t_AVAILABLE)
      set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:wchar_t- /Zc:wchar_t)
   endif()
   # /Zc:zeroSizeArrayNew (Call member new/delete on arrays) https://learn.microsoft.com/en-us/cpp/build/reference/zc-zerosizearraynew
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_ID STREQUAL "MSVC")
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zc:zeroSizeArrayNew MSVC_FLAG_STANDARDS_COMPLIANT_NEW_DELETE_FOR_ZERO_LENGTH_ARRAY_AVAILABLE)
      if(MSVC_FLAG_STANDARDS_COMPLIANT_NEW_DELETE_FOR_ZERO_LENGTH_ARRAY_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:zeroSizeArrayNew- /Zc:zeroSizeArrayNew)
      endif()
   endif()
endfunction()

function(set_target_default_compile_flags IN_COMPILE_LANGUAGE IN_TARGET IN_SCOPE)
   if(CMAKE_${IN_COMPILE_LANGUAGE}_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
      enforce_msvc_target_standard_conformance(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE})
      # /analyze:external- (Skip analysis of external header files) https://learn.microsoft.com/en-us/cpp/build/reference/analyze-code-analysis
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /analyze:external- MSVC_FLAG_SKIP_ANALYSIS_OF_EXTERNAL_HEADERS_AVAILABLE)
      if(MSVC_FLAG_SKIP_ANALYSIS_OF_EXTERNAL_HEADERS_AVAILABLE)
         set_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /analyze:external-)
      endif()
      # /external (External headers diagnostics) https://learn.microsoft.com/en-us/cpp/build/reference/external-external-headers-diagnostics
      #    Treats all headers included by #include <header> as external headers
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /external:anglebrackets MSVC_FLAG_EXTERNAL_ANGLEBRACKETS_AVAILABLE)
      if(MSVC_FLAG_EXTERNAL_ANGLEBRACKETS_AVAILABLE)
         set_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /external:anglebrackets)
      endif()
      #    Turn off warnings for external headers
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /external:W0 MSVC_FLAG_EXTERNAL_NO_WARNINGS_AVAILABLE)
      if(MSVC_FLAG_EXTERNAL_NO_WARNINGS_AVAILABLE)
         set_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /external:W0)
      endif()
      # /GF (Eliminate Duplicate Strings) https://learn.microsoft.com/en-us/cpp/build/reference/gf-eliminate-duplicate-strings
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /GF MSVC_FLAG_ELIMINATE_DUPLICATE_STRINGS_AVAILABLE)
      if(MSVC_FLAG_ELIMINATE_DUPLICATE_STRINGS_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zc:strictStrings- /GF)
      endif()
      # /GR (Enable Run-Time Type Information) https://learn.microsoft.com/en-us/cpp/build/reference/gr-enable-run-time-type-information
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /GR- MSVC_FLAG_DISABLE_RTTI_AVAILABLE)
      if(MSVC_FLAG_DISABLE_RTTI_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /GR /GR-)
      endif()
      # /GS (Buffer Security Check) https://learn.microsoft.com/en-us/cpp/build/reference/gs-buffer-security-check
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /GS MSVC_FLAG_BUFFER_SECURITY_CHECK_AVAILABLE)
      if(MSVC_FLAG_BUFFER_SECURITY_CHECK_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /GS- /GS)
      endif()
      # /jumptablerdata (put switch case jump tables in .rdata) https://learn.microsoft.com/en-us/cpp/build/reference/jump-table-rdata
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /jumptablerdata MSVC_FLAG_PUT_SWITCH_CASE_JUMP_TABLES_TO_RDATA_AVAILABLE)
      if(MSVC_FLAG_PUT_SWITCH_CASE_JUMP_TABLES_TO_RDATA_AVAILABLE)
         set_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /jumptablerdata)
      endif()
      # /MP (Build with multiple processes) https://learn.microsoft.com/en-us/cpp/build/reference/mp-build-with-multiple-processes
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /MP MSVC_FLAG_MULTIPLE_PROCESSES_BUILD_AVAILABLE)
      if(MSVC_FLAG_MULTIPLE_PROCESSES_BUILD_AVAILABLE)
         set_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /MP)
      endif()
      # /Oi (Generate Intrinsic Functions) https://learn.microsoft.com/en-us/cpp/build/reference/oi-generate-intrinsic-functions
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Oi MSVC_FLAG_GENERATE_INTRINSIC_FUNCTIONS_AVAILABLE)
      if(MSVC_FLAG_GENERATE_INTRINSIC_FUNCTIONS_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Oi- /Oi)
      endif()
      # /sdl (Enable Additional Security Checks) https://learn.microsoft.com/en-us/cpp/build/reference/sdl-enable-additional-security-checks
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /sdl MSVC_FLAG_ADDITIONAL_SECURITY_CHECKS_AVAILABLE)
      if(MSVC_FLAG_ADDITIONAL_SECURITY_CHECKS_AVAILABLE)
         set_target_compile_flag_exclusive(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /sdl- /sdl)
      endif()
      # /Zf (Faster PDB generation) https://learn.microsoft.com/en-us/cpp/build/reference/zf
      check_compiler_flags(${IN_COMPILE_LANGUAGE} /Zf MSVC_FLAG_FASTER_PDB_GENERATION_AVAILABLE)
      if(MSVC_FLAG_FASTER_PDB_GENERATION_AVAILABLE)
         set_target_compile_flag(${IN_COMPILE_LANGUAGE} ${IN_TARGET} ${IN_SCOPE} /Zf)
      endif()
   endif()
endfunction()

function(set_target_default_c_compile_flags IN_TARGET IN_SCOPE)
   set_target_default_compile_flags("C" ${IN_TARGET} ${IN_SCOPE})
endfunction()

function(set_target_default_cxx_compile_flags IN_TARGET IN_SCOPE)
   set_target_default_compile_flags("CXX" ${IN_TARGET} ${IN_SCOPE})
endfunction()

function(remove_target_compile_flag IN_TARGET IN_COMPILE_FLAG)
   set(TARGET_PROPERTIES COMPILE_FLAGS COMPILE_OPTIONS INTERFACE_COMPILE_OPTIONS)
   foreach(TARGET_PROPERTY IN LISTS TARGET_PROPERTIES)
      get_target_property(IN_TARGET_COMPILE_FLAGS ${IN_TARGET} ${TARGET_PROPERTY})
      if(NOT IN_TARGET_COMPILE_FLAGS STREQUAL IN_TARGET_COMPILE_FLAGS-NOTFOUND AND NOT "${IN_TARGET_COMPILE_FLAGS}" STREQUAL "")
         set(OUT_TARGET_COMPILE_FLAGS )
         foreach(TARGET_COMPILE_FLAG IN LISTS IN_TARGET_COMPILE_FLAGS)
            if(NOT TARGET_COMPILE_FLAG MATCHES "^(${IN_COMPILE_FLAG})$")
               string(
                  REGEX REPLACE
                  "(^|[ \t\r\n,:])(${IN_COMPILE_FLAG})([ \t\r\n,>]|$)"
                  "\\1\\3"
                  TARGET_COMPILE_FLAG
                  ${TARGET_COMPILE_FLAG}
               )
               string(STRIP "${TARGET_COMPILE_FLAG}" TARGET_COMPILE_FLAG)
               list(APPEND OUT_TARGET_COMPILE_FLAGS ${TARGET_COMPILE_FLAG})
            endif()
         endforeach()
         set_target_properties(${IN_TARGET} PROPERTIES ${TARGET_PROPERTY} "${OUT_TARGET_COMPILE_FLAGS}")
      endif()
   endforeach()
endfunction()

function(disable_target_compile_warnings IN_TARGET)
   get_target_property(TARGET_TYPE ${IN_TARGET} TYPE)
   set(SKIP_TARGET_TYPES INTERFACE_LIBRARY UTILITY)
   if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
      remove_target_compile_flag(${IN_TARGET} "[/-]analyse-?|[/-]W[0-9]+|[/-]Wall|[/-]Wv:?[0-9]*|[/-]WX-?|[/-]w[deo]?[0-9]*")
      if(NOT TARGET_TYPE IN_LIST SKIP_TARGET_TYPES)
         target_compile_options(${IN_TARGET} PRIVATE /analyze- /W0)
      endif()
   else()
      remove_target_compile_flag(${IN_TARGET} "-w|-W[0-9a-zA-Z-]*|-pedantic[0-9a-zA-Z-]*")
      if(NOT TARGET_TYPE IN_LIST SKIP_TARGET_TYPES)
         target_compile_options(${IN_TARGET} PRIVATE -w)
      endif()
   endif()
endfunction()
