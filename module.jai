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

#module_parameters()(ENABLED := true);

// Helper function to create an uint32_t color from 3 RGB values. The R, G and B values must be in range [0, 255].
PERFORMANCEAPI_MAKE_COLOR :: inline ( r: u8, g: u8, b: u8 ) -> u32 { return ((cast(u32)r) << 24) | ((cast(u32)g) << 16) | ((cast(u32)b) << 8) | 0xFF; }

// Use this define if you don't care about the color of an event and just want to use the default
PERFORMANCEAPI_DEFAULT_COLOR :: 0xFFFFFFFF;

// Set the name of the current thread to the specified thread name.
ProfileSetCurrentThreadName :: ( name: string )
{
	#if ENABLED then PerformanceAPI_SetCurrentThreadName_N( name.data, cast,trunc(u16) name.length );
}

// Begin an instrumentation event with the specified ID and runtime data
//
// @param id    The ID of this scope as an UTF8 encoded string. The ID for a specific scope must be the same over the lifetime of the program (see docs at the top of this file)
// @param data  [optional] The data for this scope as an UTF8 encoded string. The data can vary for each invocation of this scope and is intended to hold information that is only available at runtime. See docs at the top of this file.
//							 Set to null if not available.
// @param color [optional] The color for this scope. The color for a specific scope is coupled to the ID and must be the same over the lifetime of the program
//							 Set to PERFORMANCEAPI_DEFAULT_COLOR to use default coloring.

BeginProfileEvent :: inline ( id: string, data: string = "", color: u32 = PERFORMANCEAPI_DEFAULT_COLOR )
{
	#if ENABLED then PerformanceAPI_BeginEvent_N( id.data, cast(u16) id.count, data.data, cast(u16) data.count, color );
}

// End an instrumentation event. Must be matched with a call to BeginProfileEvent within the same function
EndProfileEvent :: inline ()
{
	#if ENABLED then PerformanceAPI_EndEvent();
}

// Automatic instrumentation event begin+end for current scope
ProfileEvent :: ( id: string, data: string = "", color: u32 = PERFORMANCEAPI_DEFAULT_COLOR ) #expand
{
	#if ENABLED
	{
		PerformanceAPI_BeginEvent_N( id.data, cast(u16) id.count, data.data, cast(u16) data.count, color );
		`defer PerformanceAPI_EndEvent();
	}
}

// Call this function when a fiber starts running
RegisterFiber :: inline ( inFiberID: u64 )
{
	#if ENABLED then PerformanceAPI_RegisterFiber( inFiberID );
}

// Call this function before a fiber ends
UnregisterFiber :: inline ( inFiberID: u64 )
{
	#if ENABLED then PerformanceAPI_UnregisterFiber( inFiberID );
}

// The call to the Windows SwitchFiber function should be surrounded by BeginFiberSwitch and EndFiberSwitch calls. For example:
//
//	PerformanceAPI_BeginFiberSwitch(currentFiber, otherFiber);
//	SwitchToFiber(otherFiber);
//	PerformanceAPI_EndFiberSwitch(currentFiber);
//
// @param inCurrentFiberID    The currently running fiber
// @param inNewFiberID		  The fiber we're switching to

BeginFiberSwitch :: ( inCurrentFiberID: u64, inNewFiberID: u64 )
{
	#if ENABLED then PerformanceAPI_BeginFiberSwitch( inCurrentFiberID, inNewFiberID );
}

EndFiberSwitch :: ( inFiberID: u64 )
{
	#if ENABLED then PerformanceAPI_EndFiberSwitch( inFiberID );
}

#scope_file

PerformanceAPI_BeginEvent_N :: ( id: *u8, idLength: u16, data: *u8, dataLength: u16, color: u32 ) #foreign superluminal_lib;
PerformanceAPI_SetCurrentThreadName_N :: ( inThreadName: *u8, inThreadNameLength: u16 ) #foreign superluminal_lib;
PerformanceAPI_RegisterFiber :: ( inFiberID: u64 ) #foreign superluminal_lib;
PerformanceAPI_UnregisterFiber :: ( inFiberID: u64 ) #foreign superluminal_lib;
PerformanceAPI_BeginFiberSwitch :: ( inCurrentFiberID: u64, inNewFiberID: u64 ) #foreign superluminal_lib;
PerformanceAPI_EndFiberSwitch :: ( inFiberID: u64 ) #foreign superluminal_lib;

// Helper struct that is used to prevent calls to EndEvent from being optimized to jmp instructions as part of tail call optimization.
// You don't ever need to do anything with this as user of the API.
PerformanceAPI_SuppressTailCallOptimization :: struct
{
	SuppressTailCall: [3]s64;
};

PerformanceAPI_EndEvent :: () -> PerformanceAPI_SuppressTailCallOptimization #foreign superluminal_lib;

#if OS == .WINDOWS {
	#system_library "msvcprt";
	#system_library "advapi32";
	superluminal_lib :: #library,no_dll "win/PerformanceAPI_MD";
}
