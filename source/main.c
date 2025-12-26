// --------------------------------------------------------------------------@/
// main.c
// Runs a script 'workdata/main.lua', passing it an API written in C.
// --------------------------------------------------------------------------@/
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <unistd.h>
#include <time.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// type/enum ----------------------------------------------------------------@/
typedef struct CProgramWork {
	lua_State* lua_state;
	int luafn_stageupdate;
	int timer_frame;
} CProgramWork;

// var ----------------------------------------------------------------------@/
CProgramWork* gProgramWork;

// function -----------------------------------------------------------------@/
void program_init();
void program_close();
void program_exec();
void program_lua_fileExec(const char* filename);
void program_lua_fileRequireBuiltin(const char* filename, const char* modulename);
void program_lua_pushRegFn(int fn_idx);
int program_luaFn_continue(lua_State *L, int status, lua_KContext ctx);
int program_luaAPI_test(lua_State* lu);
int program_luaAPI_add(lua_State* lu);
int program_luaAPI_assign_fnUpdate(lua_State* lu);
int program_luaAPI_timer_getFrame(lua_State* lu);

static inline CProgramWork* program_workGet() {
	return gProgramWork;
}

int main(int argc,const char* argv[]) {
	program_init();
	program_exec();
	program_close();

	return 0;
}

void program_init() {
	gProgramWork = calloc(1,sizeof(CProgramWork));

	// initialize lua --------------------------------------@/
	auto workarea = program_workGet();
	auto lua_state = luaL_newstate();
	if(!lua_state) {
		puts("unable to make state..");
		exit(-1);
	}
	printf("created lua state: %p\n",lua_state);
	workarea->lua_state = lua_state;
	luaL_openlibs(lua_state);

	// initialize api --------------------------------------@/
	const luaL_Reg api_fntable[] = {
		{               "test", program_luaAPI_test },
		{                "add", program_luaAPI_add },
		{    "assign_fnUpdate", program_luaAPI_assign_fnUpdate },
		{     "timer_getFrame", program_luaAPI_timer_getFrame },
		{ NULL,NULL }
	};
	luaL_newlib(lua_state,api_fntable);
	lua_setglobal(lua_state,"api");
}
void program_close() {
	free(gProgramWork);
	gProgramWork = NULL;
}

void program_exec() {
	auto workarea = program_workGet();
	auto lu = workarea->lua_state;

	// load libraries --------------------------------------@/
	program_lua_fileRequireBuiltin("workdata/libtask.lua","libtask");
	printf("stack top: %d\n",lua_gettop(lu));

	// run lua function..? ---------------------------------@/
	program_lua_fileExec("workdata/main.lua");
	for(int i=0; i<500; i++) {
		program_lua_pushRegFn(workarea->luafn_stageupdate);
		if(!lua_isfunction(lu,1)) {
			puts("NOT a function");
			exit(-1);
		}
		lua_call(lu,0,0);

		struct timespec ts = {
			.tv_nsec = 16666667
		};
		nanosleep(&ts,NULL);
		// time to sleep shld be 16666666.7ns
		workarea->timer_frame++;
	}
	puts("succeeded");
}
void program_lua_fileExec(const char* filename) {
	auto workarea = program_workGet();
	auto lua_state = workarea->lua_state;
	
	// run file, show errors -------------------------------@/
	auto status = luaL_dofile(lua_state,filename);
	if(status != LUA_OK) {
		int num_args = lua_gettop(lua_state);
		for( int i=1; i <= num_args; i++ ) {
			if(lua_isstring(lua_state,i)) {
				auto str = lua_tostring(lua_state,i);
				printf("failed to run file! (%s)",str);
			}
		}
		exit(-1);
	}
}
void program_lua_fileRequireBuiltin(const char* filename, const char* modulename) {
	auto workarea = program_workGet();
	auto lu = workarea->lua_state;

	if(luaL_dofile(lu,filename) != LUA_OK) {
		printf("error: failed to execute builtin %s\n",filename);
		exit(-1);
	}

	// set global
	lua_pushvalue(lu,-1);
	lua_setglobal(lu,modulename);

	// get package.loaded, then set it
	lua_getglobal(lu,"package");
	lua_getfield(lu,-1,"loaded");
	lua_pushvalue(lu,-3);
	lua_setfield(lu,-2,modulename);

	lua_pop(lu,-2); // pop package.loaded
	lua_pop(lu,-1); // pop module
}
void program_lua_pushRegFn(int fn_idx) {
	auto workarea = program_workGet();
	auto lu = workarea->lua_state;
	lua_rawgeti(lu,LUA_REGISTRYINDEX, fn_idx);
}

int program_luaAPI_test(lua_State* lu) {
	lua_pushstring(lu,"hello");
	return 1; // number of results
}
int program_luaAPI_add(lua_State* lu) {
	int num_args = lua_gettop(lu);
	lua_Integer sum = 0;
	for (int i = 1; i <= num_args; i++) {
		if (!lua_isinteger(lu, i)) {
			lua_pushstring(lu, "incorrect argument; must be an integer");
			lua_error(lu);
		}
		sum += lua_tointeger(lu, i);
	}

	lua_pushinteger(lu,sum);
	return 1;
}
int program_luaAPI_assign_fnUpdate(lua_State* lu) {
	if(!lua_isfunction(lu,1)) {
		lua_pushstring(lu, "incorrect argument, must be a function");
		lua_error(lu);
	}
	auto workarea = program_workGet();
	lua_pushvalue(lu,1);
	workarea->luafn_stageupdate = luaL_ref(lu, LUA_REGISTRYINDEX);
	
	return 0;
}
int program_luaAPI_timer_getFrame(lua_State* lu) {
	auto workarea = program_workGet();
	lua_pushinteger(lu,workarea->timer_frame);
	
	return 1;
}

