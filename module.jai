/*
BSD LICENSE

Copyright (c) 2019-2020 Superluminal. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
// Bindings by Ville Ruusutie

PERFORMANCEAPI_MAKE_COLOR :: (r: u32, g: u32, b: u32) -> u32 { return (r << 24) | (g << 16) | (b << 8) | 0xFF; }
PERFORMANCEAPI_DEFAULT_COLOR :: 0xFFFFFFFF;

// Begin an instrumentation event with the specified ID and runtime data
//
// @param id    The ID of this scope as an UTF8 encoded string. The ID for a specific scope must be the same over the lifetime of the program (see docs at the top of this file)
// @param data  [optional] The data for this scope as an UTF8 encoded string. The data can vary for each invocation of this scope and is intended to hold information that is only available at runtime. See docs at the top of this file.
//							 Set to null if not available.
// @param color [optional] The color for this scope. The color for a specific scope is coupled to the ID and must be the same over the lifetime of the program
//							 Set to PERFORMANCEAPI_DEFAULT_COLOR to use default coloring.

BeginProfileEvent :: inline ( id: string, data: string = "", color: u32 = PERFORMANCEAPI_DEFAULT_COLOR )
{
	PerformanceAPI_BeginEvent_N( id.data, cast(u16) id.count, data.data, cast(u16) data.count, color );
}

// End an instrumentation event. Must be matched with a call to BeginProfileEvent within the same function

EndProfileEvent :: inline ()
{
	PerformanceAPI_EndEvent();
}

#scope_file

PerformanceAPI_BeginEvent_N :: ( id: *u8, idLength: u16, data: *u8, dataLength: u16, color: u32 ) #foreign superluminal_lib;

// Helper struct that is used to prevent calls to EndEvent from being optimized to jmp instructions as part of tail call optimization.
// You don't ever need to do anything with this as user of the API.
PerformanceAPI_SuppressTailCallOptimization :: struct
{
	SuppressTailCall: [3]s64;
};

PerformanceAPI_EndEvent :: () -> PerformanceAPI_SuppressTailCallOptimization #foreign superluminal_lib;

#if OS == .WINDOWS {
	#foreign_system_library "msvcprt";
	superluminal_lib :: #foreign_library,no_dll "win/PerformanceAPI_MD";
}
