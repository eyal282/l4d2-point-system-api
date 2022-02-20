

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <ps_api>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar g_hCommonLimit;
int ucommonleft;
int witchesinqueue;

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
Handle PointsTerrorPerWitch = INVALID_HANDLE;
Handle WitchLimit = INVALID_HANDLE;

char g_sUncommonModels[][] =
{
	"models/infected/common_male_riot.mdl",
	"models/infected/common_male_ceda.mdl",
	"models/infected/common_male_clown.mdl",
	"models/infected/common_male_mud.mdl",
	"models/infected/common_male_roadcrew.mdl",
	"models/infected/common_male_fallen_survivor.mdl",
	"models/infected/common_male_jimmy.mdl"
};

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
	AutoExecConfig_SetFile("PointSystemAPI_Infected");
	
	g_hCommonLimit = FindConVar("z_common_limit");
	
	PointsSuicide = AutoExecConfig_CreateConVar("l4d2_points_suicide", "4", "How many points does suicide cost");
	PointsHunter = AutoExecConfig_CreateConVar("l4d2_points_hunter", "4", "How many points does a hunter cost");
	PointsJockey = AutoExecConfig_CreateConVar("l4d2_points_jockey", "6", "How many points does a jockey cost");
	PointsSmoker = AutoExecConfig_CreateConVar("l4d2_points_smoker", "4", "How many points does a smoker cost");
	PointsCharger = AutoExecConfig_CreateConVar("l4d2_points_charger", "6", "How many points does a charger cost");
	PointsBoomer = AutoExecConfig_CreateConVar("l4d2_points_boomer", "5", "How many points does a boomer cost");
	PointsSpitter = AutoExecConfig_CreateConVar("l4d2_points_spitter", "6", "How many points does a spitter cost");
	PointsWitch = AutoExecConfig_CreateConVar("l4d2_points_witch", "20", "How many points does a witch cost");
	PointsTank = AutoExecConfig_CreateConVar("l4d2_points_tank", "30", "How many points does a tank cost");
	PointsHorde = AutoExecConfig_CreateConVar("l4d2_points_horde", "15", "How many points does a horde cost");
	PointsUmob = AutoExecConfig_CreateConVar("l4d2_points_umob", "12", "How many points does an uncommon mob cost");
	PointsTerrorPerWitch = AutoExecConfig_CreateConVar("l4d2_points_terror_per_witch", "10", "How many points does a terror cost per witch");
	WitchLimit = AutoExecConfig_CreateConVar("l4d2_points_witch_limiter", "10", "Maximum amount of witches");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	
	HookConVarChange(g_hCommonLimit, convarChange_commonLimit);
	
	CreateInfectedProducts();
	
	// This makes an internal call to AutoExecConfig with the given configfile
	AutoExecConfig_ExecuteFile();

	// Cleaning should be done at the end
	AutoExecConfig_CleanFile();
}

public void OnConfigsExecuted()
{
	CreateInfectedProducts();
}

public void convarChange_commonLimit(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CreateInfectedProducts();
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof(g_sUncommonModels);i++)
		PrecacheModel(g_sUncommonModels[i], true);
		
	ucommonleft = 0;
	
	CreateTimer(1.0, Timer_CheckWitchCount, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action Timer_CheckWitchCount(Handle hTimer)
{
	if(witchesinqueue <= 0)
		return Plugin_Continue;
	
	else if(L4D2_GetWitchCount() >= GetConVarInt(WitchLimit))
		return Plugin_Continue;
		
	int client = GetRandomInfected(-1, 0);
	
	if(client == 0)
		return Plugin_Continue;
	
	PSAPI_ExecuteCheatCommand(client, "z_spawn_old witch auto");
	witchesinqueue--;
	
	return Plugin_Continue;
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "PointSystemAPI"))
	{
		CreateInfectedProducts();
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{	
	if (ucommonleft <= 0)
		return;
	
	else if(!StrEqual(classname, "infected", false))
		return;
	
	int iRNG = GetRandomInt(0, sizeof(g_sUncommonModels) - 1);
	
	if(!IsModelPrecached(g_sUncommonModels[iRNG]))
		PrecacheModel(g_sUncommonModels[iRNG]);
		
	
	SetEntityModel(entity, g_sUncommonModels[iRNG]);
	
	ucommonleft--;
}

public Action Event_RoundStart(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	ucommonleft = 0;
	
	return Plugin_Continue;
}

public void PointSystemAPI_OnGetParametersProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, int &iCost, float &fDelay, float &fCooldown)
{
	if(StrEqual(sInfo, "Terror All Witches Attack"))
	{
		iCost = GetConVarInt(PointsTerrorPerWitch) * L4D2_GetWitchCount();
	}
}

public void PointSystemAPI_OnTryBuyProduct(
{
	if(L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Charger)
	{
			
		// Airborne charger running.
		int iVictim = L4D_GetVictimCarry(target);
		
		if(iVictim != -1)
		{
			if((!(GetEntityFlags(target) & FL_ONGROUND)))
			{
				PrintToChat(target, "\x04[PS]\x03 You cannot kill yourself until you reach the ground as a Charger.");
				return Plugin_Handled;
			}
		
		
			// A charger is carrying afar away survivor is before transition.

			float fTargetOrigin[3];
			float fVictimOrigin[3];
			
			GetEntPropVector(target, Prop_Data, "m_vecOrigin", fTargetOrigin);
			GetEntPropVector(iVictim, Prop_Data, "m_vecOrigin", fVictimOrigin);
			
			
			PrintToChat(buyer, "%.2f", GetVectorDistance(fTargetOrigin, fVictimOrigin));
			
				//PrintToChat(target, "\x04[PS]\x03 You cannot kill yourself in transition from carry to pummel as a Charger.");
				//return Plugin_Handled;
			//}
		}
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
		
		// 1 = noPick, 0 = canPick
		
		bool bNoPick = true;
		if(strncmp(sInfo, "Special Infected Spawn - 0", 26) == 0)
			bNoPick = false;
			
		if(ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - 1", "") == -1)
			ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - 0", "");
		
		PSAPI_SpawnInfectedBossByClassname(target, sClassname, true, bNoPick);

		return Plugin_Continue;
	}
	else if (StrEqual(sInfo, "Special Infected Ghost Spawn", false))
	{
		PSAPI_SpawnInfectedBossByClassname(target, g_sSIClassnames[GetRandomInt(0, sizeof(g_sSIClassnames)-1)], true, false);
	}
	else if(StrEqual(sInfo, "Witch"))
	{
		if(L4D2_GetWitchCount() < GetConVarInt(WitchLimit))
		{
			PSAPI_ExecuteCheatCommand(target, "z_spawn_old witch auto");	
		}
		else
		{
			witchesinqueue++;
			
			PrintToChat(buyer, "Witch limit exceeded, but your witch will spawn after a witch dies.");
		}
	}
	else if(StrEqual(sInfo, "Terror All Witches Attack"))
	{
		int iEntity = -1;
		
		while((iEntity = FindEntityByClassname(iEntity, "witch")) != -1)
		{
			int iAttacker = GetRandomSurvivor(1, 0);
			
			if(iAttacker == 0)
			{
				return Plugin_Handled;
			}
			else
			{
				SDKHooks_TakeDamage(iEntity, iAttacker, iAttacker, 1.0, DMG_BULLET);
			}
		}
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
		ForcePlayerSuicide(target);
	}
	
	return Plugin_Continue;
}
public void CreateInfectedProducts()
{
	
	
	char sInfo[256];
	
	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %iboomer", GetConVarInt(PointsBoomer) == CalculateGhostPrice() ? 0 : 1);
	PS_CreateProduct(-1, GetConVarInt(PointsBoomer), "Boomer", "Ghost Spawn of a Boomer", "boomer", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	
	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %ispitter", GetConVarInt(PointsSpitter) == CalculateGhostPrice() ? 0 : 1);
	PS_CreateProduct(-1, GetConVarInt(PointsSpitter), "Spitter", "Ghost Spawn of a Spitter", "spitter", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	
	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %ismoker", GetConVarInt(PointsSmoker) == CalculateGhostPrice() ? 0 : 1);
	PS_CreateProduct(-1, GetConVarInt(PointsSmoker), "Smoker", "Ghost Spawn of a Smoker", "smoker", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	
	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %ihunter", GetConVarInt(PointsHunter) == CalculateGhostPrice() ? 0 : 1);
	PS_CreateProduct(-1, GetConVarInt(PointsHunter), "Hunter", "Ghost Spawn of a Hunter", "hunter", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	
	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %icharger", GetConVarInt(PointsCharger) == CalculateGhostPrice() ? 0 : 1);
	PS_CreateProduct(-1, GetConVarInt(PointsCharger), "Charger", "Ghost Spawn of a Charger", "charger", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	
	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %ijockey", GetConVarInt(PointsJockey) == CalculateGhostPrice() ? 0 : 1);
	PS_CreateProduct(-1, GetConVarInt(PointsJockey), "Jockey", "Ghost Spawn of a Jockey", "jockey", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD);
	
	PS_CreateProduct(-1, CalculateGhostPrice(), "Ghost", "Instantly revives you to pick any Special Infected", "ghost", "Special Infected Ghost Spawn", 3.0, 0.0,
	BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_HUMANTEAM);
	
	PS_CreateProduct(-1, GetConVarInt(PointsTank), "Tank", "Ghost spawn of a Tank", "tank", "Special Infected Spawn - 1tank", 0.0, 0.0,
	BUYFLAG_INFECTED | BUYFLAG_DEAD);
	
	PS_CreateProduct(-1, GetConVarInt(PointsWitch), "Witch", "Spawns a witch", "witch", "Witch", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);
	
	
	FormatEx(sInfo, sizeof(sInfo), "Forces all witches to attack random players\nCosts %i points multiplied by the number of witches", GetConVarInt(PointsTerrorPerWitch));
	
	PS_CreateProduct(-1, GetConVarInt(PointsTerrorPerWitch), "Terror", sInfo, "terror", "Terror All Witches Attack", 0.0, 5.0,
	BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);
	
	PS_CreateProduct(-1, GetConVarInt(PointsHorde), "Horde", NO_DESCRIPTION, "horde", "Horde", 0.0, 10.0,
	BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);
	
	char sDesc[128];
	FormatEx(sDesc, sizeof(sDesc), "Sends a mob that will contain %i uncommon CI", GetConVarInt(g_hCommonLimit));
	PS_CreateProduct(-1, GetConVarInt(PointsUmob), "Uncommon Mob", sDesc, "umob uncommonmob unmob ", "Uncommon Mob", 0.0, 1.0,
	BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);
	
	PS_CreateProduct(-1, GetConVarInt(PointsSuicide), "Suicide", "Instantly kills you", "kill suicide die death", "Infected Suicide", 0.0, 0.0,
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