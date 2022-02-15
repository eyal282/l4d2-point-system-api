

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <ps_api>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

char g_sSINames[][]={"","Smoker","Boomer","Hunter","Spitter","Jockey","Charger"};
char g_sSIClassnames[][]={"","smoker","boomer","hunter","spitter", "jockey","charger"};
char g_sBossClassnames[][]={"","smoker","boomer","hunter","spitter","jockey","charger", "","tank"};

public Plugin myinfo = 
{
	name = "Infected Module --> Point System API",
	author = "Eyal282",
	description = "Every infected Item to be bought in Point System",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	CreateInfectedItems();
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "PointSystemAPI"))
	{
		PrintToChatAll("Create items");
		CreateInfectedItems();
	}
}

// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.
public Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, int iCost, float fDelay, float fCooldown)
{
	if(strncmp(sInfo, "Special Infected Spawn - ", 25) == 0)
	{
		char sClassname[64];
		strcopy(sClassname, sizeof(sClassname), sInfo);
		ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - ", "");
		
		SpawnInfectedBossByClassname(target, sClassname, true, true);

		return Plugin_Continue;
	}
	else if (StrEqual(sInfo, "Special Infected Ghost Spawn", false))
	{
		SpawnInfectedBossByClassname(target, g_sSIClassnames[GetRandomInt(0, sizeof(g_sSIClassnames)-1)], true, false);
	}
	else if (StrEqual(sInfo, "infected suicide", false))
	{
		if(L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Charger && (!(GetEntityFlags(target) & FL_ONGROUND)))
		{
			if(L4D_GetVictimCarry(target) != -1 && L4D_GetVictimCharger(target) == -1)
			{
				PrintToChat(target, "\x04[PS]\x03 You cannot kill yourself until you reach the ground as a Charger.");
				return Plugin_Handled;
			}
		}
		
		ForcePlayerSuicide(target);
	}
	
	return Plugin_Continue;
}
public void CreateInfectedItems()
{
	for (int i = 0; i < sizeof(g_sSINames);i++)
	{
		char sDesc[64], sInfo[64];
		FormatEx(sDesc, sizeof(sDesc), "Ghost spawn of a %s", g_sSINames[i]);
		FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %s", g_sSIClassnames[i]);
		PS_CreateProduct(-1, 0, g_sSINames[i], sDesc, g_sSIClassnames[i], sInfo, 0.0, 5.0,
		BUYFLAG_INFECTED | BUYFLAG_DEAD);
	}
	

	PS_CreateProduct(-1, 0, "Ghost", "Instantly revives you to pick any Special Infected", "ghost", "Special Infected Ghost Spawn", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_TEAM);
	
	PS_CreateProduct(-1, 0, "Tank", "Ghost spawn of a Tank", "tank", "Special Infected Spawn - tank", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_DEAD);
	
	PS_CreateProduct(-1, 0, "Suicide", "Instantly kills you", "kill suicide die death", "infected suicide", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_ANY_ALIVE);	
}


stock void ExecuteCheatCommand(int client, const char[] command, any ...)
{
	char formattedCommand[256];
	
	VFormat(formattedCommand, sizeof(formattedCommand), command, 3);
	RemoveFlags();
	
	FakeClientCommand(client, command);
	
	AddFlags();
}
void RemoveFlags()
{
	int flagsgive = GetCommandFlags("give");
	int flagszspawnold = GetCommandFlags("z_spawn_old");
	int flagszspawn = GetCommandFlags("z_spawn");
	int flagsupgradeadd = GetCommandFlags("upgrade_add");
	int flagspanic = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn_old", flagszspawnold & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flagszspawn & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic & ~FCVAR_CHEAT);
}	

void AddFlags()
{
	int flagsgive = GetCommandFlags("give");
	int flagszspawnold = GetCommandFlags("z_spawn_old");
	int flagszspawn = GetCommandFlags("z_spawn");
	int flagsupgradeadd = GetCommandFlags("upgrade_add");
	int flagspanic = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
	SetCommandFlags("z_spawn_old", flagszspawnold|FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flagszspawn|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic|FCVAR_CHEAT);
}


stock void SetPlayerAlive(int client, bool alive)
{
	if (alive) SetEntProp(client, Prop_Data, "m_isAlive", alive);
}

stock bool IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

stock void SetPlayerGhost(int client, bool ghost)
{
	SetEntProp(client, Prop_Send, "m_isGhost", ghost);
}

stock void SetPlayerLifeState(int client, bool ready)
{
	SetEntProp(client, Prop_Send, "m_lifeState", ready);
}

// bNoPick = cannot press mouse2 to change to another SI in a ghost spawn by the plugin l4d2_zcs.smx

stock bool SpawnInfectedBossByClassname(int client, const char[] name, bool bGhost=false, bool bNoPick = false)
{	
	// Regardless of bGhost, we switch to ghost. If not ghost, we materialize.
	
	// Part of sequence to confuse ZCS into thinking we teleported to survivors from the message "You are too far away from survivors"
	if(bNoPick)
		L4D_RespawnPlayer(client);
	
	L4D_State_Transition(client, STATE_GHOST);
		
	
	for (int i = 0; i < sizeof(g_sBossClassnames);i++)
	{
		if(StrEqual(g_sBossClassnames[i], name))
			L4D_SetClass(client, i);
	}
	
	if(!bGhost)
		L4D_MaterializeFromGhost(client);

	// To confuse ZCS into thinking we pressed E to teleport after being far from survivors.
	SetEntProp(client, Prop_Send, "m_isCulling", bNoPick);
	SetEntProp(client, Prop_Send, "m_isRelocating", bNoPick);
	
	// Repeating the process removes the "You are too far away from survivors" message when you have a no pick.
	
	if(bNoPick)
	{
		L4D_State_Transition(client, STATE_GHOST);
			
		
		for (int i = 0; i < sizeof(g_sBossClassnames);i++)
		{
			if(StrEqual(g_sSIClassnames[i], name))
				L4D_SetClass(client, i);
		}
	}
	return true;
}