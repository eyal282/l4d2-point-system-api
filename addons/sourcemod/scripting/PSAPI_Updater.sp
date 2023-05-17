#include <sourcemod>
#include <eyal-jailbreak>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude < updater>    // Comment out this line to remove updater support by force.
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#define UPDATE_URL "https://raw.githubusercontent.com/eyal282/csgo-jailbreak-package/master/addons/sourcemod/updatefile.txt"

#pragma semicolon 1
#pragma newdecls  required

public Plugin myinfo =
{
	name        = "JailBreak Updater",
	author      = "Eyal282",
	description = "Enables auto updater support",
	version     = "1.0",
	url         = ""
};

public void OnMapEnd()
{
	RemoveServerTag2("JBPack");
}

public void OnMapStart()
{
	AddServerTag2("JBPack");
}

public void OnClientConnected(int client)
{
	if(!LibraryExists("JB_Core"))
	{
		Updater_ForceUpdate();
	}
}

public void Updater_OnPluginUpdated()
{
	if(!LibraryExists("JB_Core"))
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
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
