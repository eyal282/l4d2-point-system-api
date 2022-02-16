

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <ps_api>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

char g_sSIClassnames[][]={"","smoker","boomer","hunter","spitter", "jockey","charger"};
char g_sBossClassnames[][]={"","smoker","boomer","hunter","spitter","jockey","charger", "","tank"};

ConVar g_hCommonLimit;
int ucommonleft;

Handle PointsSuicide = INVALID_HANDLE;
Handle PointsHunter = INVALID_HANDLE;
Handle PointsJockey = INVALID_HANDLE;
Handle PointsSmoker = INVALID_HANDLE;
Handle PointsCharger = INVALID_HANDLE;
Handle PointsBoomer = INVALID_HANDLE;
Handle PointsSpitter = INVALID_HANDLE;
Handle PointsWitch = INVALID_HANDLE;
Handle PointsTank = INVALID_HANDLE;
Handle PointsHorde = INVALID_HANDLE;
Handle PointsUmob = INVALID_HANDLE;

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
	g_hCommonLimit = FindConVar("z_common_limit");
	
	PointsSuicide = CreateConVar("l4d2_points_suicide", "4", "How many points does suicide cost");
	PointsHunter = CreateConVar("l4d2_points_hunter", "4", "How many points does a hunter cost");
	PointsJockey = CreateConVar("l4d2_points_jockey", "6", "How many points does a jockey cost");
	PointsSmoker = CreateConVar("l4d2_points_smoker", "4", "How many points does a smoker cost");
	PointsCharger = CreateConVar("l4d2_points_charger", "6", "How many points does a charger cost");
	PointsBoomer = CreateConVar("l4d2_points_boomer", "5", "How many points does a boomer cost");
	PointsSpitter = CreateConVar("l4d2_points_spitter", "6", "How many points does a spitter cost");
	PointsWitch = CreateConVar("l4d2_points_witch", "20", "How many points does a witch cost");
	PointsTank = CreateConVar("l4d2_points_tank", "30", "How many points does a tank cost");
	PointsHorde = CreateConVar("l4d2_points_horde", "15", "How many points does a horde cost");
	PointsUmob = CreateConVar("l4d2_points_umob", "12", "How many points does an uncommon mob cost");
	
	HookConVarChange(g_hCommonLimit, convarChange_commonLimit);
	
	CreateInfectedItems();
}

public void convarChange_commonLimit(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CreateInfectedItems();
}

public void OnMapStart()
{
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	ucommonleft = 0;
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "PointSystemAPI"))
	{
		PrintToChatAll("Create items");
		CreateInfectedItems();
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{	
	if (ucommonleft <= 0)
		return;
	
	else if(!StrEqual(classname, "infected", false))
		return;
	
	switch(GetRandomInt(1, 6))
	{
		case 1: SetEntityModel(entity, "models/infected/common_male_riot.mdl");
		case 2: SetEntityModel(entity, "models/infected/common_male_ceda.mdl");
		case 3: SetEntityModel(entity, "models/infected/common_male_clown.mdl");
		case 4: SetEntityModel(entity, "models/infected/common_male_mud.mdl");
		case 5: SetEntityModel(entity, "models/infected/common_male_roadcrew.mdl");
		case 6: SetEntityModel(entity, "models/infected/common_male_fallen_survivor.mdl");
	}
	
	ucommonleft--;
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
	else if(StrEqual(sInfo, "Witch"))
	{
		PSAPI_ExecuteCheatCommand(target, "z_spawn_old witch auto");
	}
	else if(StrEqual(sInfo, "Horde"))
	{
		L4D_ForcePanicEvent();
	}
	else if(StrEqual(sInfo, "Uncommon Mob"))
	{
		ucommonleft += GetConVarInt(g_hCommonLimit);
		
		PSAPI_ExecuteCheatCommand(target, "z_spawn_old mob auto");
	}
	else if (StrEqual(sInfo, "Infected Suicide", false))
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
	
	PS_CreateProduct(-1, GetConVarInt(PointsBoomer), "Boomer", "Ghost Spawn of a Boomer", "boomer", "Special Infected Spawn - boomer", 0.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	PS_CreateProduct(-1, GetConVarInt(PointsSpitter), "Spitter", "Ghost Spawn of a Spitter", "spitter", "Special Infected Spawn - spitter", 0.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	PS_CreateProduct(-1, GetConVarInt(PointsSmoker), "Smoker", "Ghost Spawn of a Smoker", "smoker", "Special Infected Spawn - smoker", 0.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	PS_CreateProduct(-1, GetConVarInt(PointsHunter), "Hunter", "Ghost Spawn of a Hunter", "hunter", "Special Infected Spawn - hunter", 0.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	PS_CreateProduct(-1, GetConVarInt(PointsCharger), "Charger", "Ghost Spawn of a Charger", "charger", "Special Infected Spawn - charger", 0.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	PS_CreateProduct(-1, GetConVarInt(PointsJockey), "Jockey", "Ghost Spawn of a Jockey", "jockey", "Special Infected Spawn - jockey", 0.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	
	
	PS_CreateProduct(-1, CalculateGhostPrice(), "Ghost", "Instantly revives you to pick any Special Infected", "ghost", "Special Infected Ghost Spawn", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_HUMANTEAM);
	
	PS_CreateProduct(-1, GetConVarInt(PointsTank), "Tank", "Ghost spawn of a Tank", "tank", "Special Infected Spawn - tank", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_DEAD);
	
	PS_CreateProduct(-1, GetConVarInt(PointsWitch), "Witch", "Spawns a witch", "witch", "Witch", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);
	
	PS_CreateProduct(-1, GetConVarInt(PointsHorde), "Horde", NO_DESCRIPTION, "horde", "Horde", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);
	
	char sDesc[128];
	FormatEx(sDesc, sizeof(sDesc), "Sends a mob that will contain %i uncommon CI", GetConVarInt(g_hCommonLimit));
	PS_CreateProduct(-1, GetConVarInt(PointsUmob), "Uncommon Mob", sDesc, "umob uncommonmob unmob ", "Uncommon Mob", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);
	
	PS_CreateProduct(-1, GetConVarInt(PointsSuicide), "Suicide", "Instantly kills you", "kill suicide die death", "Infected Suicide", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_ANY_ALIVE);	
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

stock int CalculateGhostPrice()
{
	int HighestCost = 0;
	
	if(HighestCost < GetConVarInt(PointsHunter))
		HighestCost = GetConVarInt(PointsHunter);
		
	if(HighestCost < GetConVarInt(PointsJockey))
		HighestCost = GetConVarInt(PointsJockey);
		
	if(HighestCost < GetConVarInt(PointsSmoker))
		HighestCost = GetConVarInt(PointsSmoker);
			
	if(HighestCost < GetConVarInt(PointsCharger))
		HighestCost = GetConVarInt(PointsCharger);
		
	if(HighestCost < GetConVarInt(PointsBoomer))
		HighestCost = GetConVarInt(PointsBoomer);
		
	if(HighestCost < GetConVarInt(PointsSpitter))
		HighestCost = GetConVarInt(PointsSpitter);
		
	return HighestCost;
}