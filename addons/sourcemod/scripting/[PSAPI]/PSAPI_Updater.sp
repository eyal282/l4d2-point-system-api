#include <sourcemod>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude < updater>    // Comment out this line to remove updater support by force.
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

// Only one update URL can be active at once. Start with left4dhooks then PointSystemAPI.
#define UPDATE_URL "https://raw.githubusercontent.com/eyal282/l4d2-point-system-api/master/addons/sourcemod/updatefile.txt"
#define UPDATE_URL2 "https://raw.githubusercontent.com/SilvDev/Left4DHooks/main/sourcemod/updater.txt"

#pragma semicolon 1
#pragma newdecls  required

public Plugin myinfo =
{
	name        = "Point System API Updater",
	author      = "Eyal282",
	description = "Enables auto updater support",
	version     = "1.0",
	url         = ""
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public Action Event_PlayerSpawn(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	Func_OnAllPluginsLoaded();

	return Plugin_Continue;
}

public void Updater_OnPluginUpdated()
{
	if(!LibraryExists("PointSystemAPI") || !LibraryExists("left4dhooks"))
	{
		char MapName[64];
		GetCurrentMap(MapName, sizeof(MapName));

		ServerCommand("changelevel %s", MapName);
	}
}

public void OnAllPluginsLoaded()
{
	Func_OnAllPluginsLoaded();
}

public void Func_OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		if(!LibraryExists("left4dhooks"))
		{
			Updater_AddPlugin(UPDATE_URL2);
		}
		else if(!LibraryExists("PointSystemAPI"))
		{
			Updater_AddPlugin(UPDATE_URL);
		}
		else
		{
			Updater_AddPlugin(UPDATE_URL);
			return;
		}

		CreateTimer(5.0, Timer_ForceUpdate);
	}
}

public Action Timer_ForceUpdate(Handle hTimer)
{
	Updater_ForceUpdate();

	return Plugin_Continue;
}
