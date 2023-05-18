#include <sourcemod>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude < updater>    // Comment out this line to remove updater support by force.
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

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

public void OnClientConnected(int client)
{
	if(!LibraryExists("PointSystemAPI") || !LibraryExists("left4dhooks"))
	{
		Updater_ForceUpdate();
	}
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

public void OnPluginStart()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
		Updater_AddPlugin(UPDATE_URL2);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
		Updater_AddPlugin(UPDATE_URL2);
	}
}
