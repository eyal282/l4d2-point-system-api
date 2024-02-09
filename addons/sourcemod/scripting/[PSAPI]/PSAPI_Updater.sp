
#include <sourcemod>

#include <updater>

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

Handle g_Timer;

public void OnLibraryAdded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public void OnMapStart()
{
	g_Timer = INVALID_HANDLE;
}
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

public void Func_OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		if(!LibraryExists("left4dhooks"))
		{
			Updater_RemovePlugin();
			Updater_AddPlugin(UPDATE_URL2);
		}
		else if(!LibraryExists("PointSystemAPI"))
		{
			Updater_RemovePlugin();
			Updater_AddPlugin(UPDATE_URL);
		}
		else
		{		
			return;
		}

		if(g_Timer != INVALID_HANDLE)
		{
			delete g_Timer;
		}

		g_Timer = CreateTimer(5.0, Timer_ForceUpdate, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_ForceUpdate(Handle hTimer)
{

	Updater_ForceUpdate();

	g_Timer = INVALID_HANDLE;
	return Plugin_Stop;
}
