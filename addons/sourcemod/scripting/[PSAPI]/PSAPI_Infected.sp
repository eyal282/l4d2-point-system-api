#include <ps_api>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar g_hCommonLimit;
ArrayList g_aWitchQueue;
int    ucommonleft;
int    jimmiesleft;
float g_fPermanentUmobInvested;

ConVar SuicideTankReplace;
ConVar DisableGhostSpawn;
ConVar PointsSuicide;
ConVar PointsExtinguish;
ConVar PointsExtinguishTank;
ConVar PointsMinInstantRespawn;
ConVar PointsHunter;
ConVar PointsJockey;
ConVar PointsSmoker;
ConVar PointsCharger;
ConVar PointsBoomer;
ConVar PointsSpitter;
ConVar PointsWitch;
ConVar PointsTank;
ConVar PointsHorde;
ConVar PointsUmob;
ConVar PointsJmob;
ConVar PointsPermanentUmob;
ConVar PointsTerrorPerWitch;
ConVar WitchLimit;
ConVar TankLimit;

char g_sUncommonModels[][] = {
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
	name        = "Infected Module --> Point System API",
	author      = "Eyal282",
	description = "Every infected Item to be bought in Point System",
	version     = PLUGIN_VERSION,
	url         = ""
};

public void OnPluginStart()
{
	g_aWitchQueue = new ArrayList(3);

	AutoExecConfig_SetFile("PointSystemAPI_Infected");

	g_hCommonLimit = FindConVar("z_common_limit");

	SuicideTankReplace       = AutoExecConfig_CreateConVar("l4d2_points_suicide_tank_replace_with_bot", "1", "0 - Buying kill as Tank kills you. 1 - Buying kill as Tank replaces you with a bot.");
	DisableGhostSpawn       = AutoExecConfig_CreateConVar("l4d2_points_ghost_spawn_disabled", "0", "0 - Ghost Spawn Enbaled. 1 - Ghost Spawn Disabled.");
	PointsSuicide           = AutoExecConfig_CreateConVar("l4d2_points_suicide", "4", "How many points does suicide cost");
	PointsExtinguish        = AutoExecConfig_CreateConVar("l4d2_points_extinguish", "-1", "How many points does extinguish cost");
	PointsExtinguishTank    = AutoExecConfig_CreateConVar("l4d2_points_extinguish_tank", "-1", "How many points does tank extinguish cost? Or -1 to disable");
	PointsMinInstantRespawn = AutoExecConfig_CreateConVar("l4d2_points_min_players_instant_respawn", "4", "If there are x or less human infected players, you instantly respawn by buying Ghost Spawn.", _, true, 0.0, true, float(MAXPLAYERS));
	PointsHunter            = AutoExecConfig_CreateConVar("l4d2_points_hunter", "4", "How many points does a hunter cost");
	PointsJockey            = AutoExecConfig_CreateConVar("l4d2_points_jockey", "6", "How many points does a jockey cost");
	PointsSmoker            = AutoExecConfig_CreateConVar("l4d2_points_smoker", "4", "How many points does a smoker cost");
	PointsCharger           = AutoExecConfig_CreateConVar("l4d2_points_charger", "6", "How many points does a charger cost");
	PointsBoomer            = AutoExecConfig_CreateConVar("l4d2_points_boomer", "5", "How many points does a boomer cost");
	PointsSpitter           = AutoExecConfig_CreateConVar("l4d2_points_spitter", "6", "How many points does a spitter cost");
	PointsWitch             = AutoExecConfig_CreateConVar("l4d2_points_witch", "20", "How many points does a witch cost");
	PointsTank              = AutoExecConfig_CreateConVar("l4d2_points_tank", "30", "How many points does a tank cost");
	PointsHorde             = AutoExecConfig_CreateConVar("l4d2_points_horde", "15", "How many points does a horde cost");
	PointsUmob              = AutoExecConfig_CreateConVar("l4d2_points_umob", "12", "How many points does an uncommon mob cost");
	PointsJmob              = AutoExecConfig_CreateConVar("l4d2_points_jmob", "-1", "How many points does a jimmy mob cost ( this can crash your server )");
	PointsPermanentUmob     = AutoExecConfig_CreateConVar("l4d2_points_permanent_umob", "-1", "How many points does a permanent uncommon mob cost");
	PointsTerrorPerWitch    = AutoExecConfig_CreateConVar("l4d2_points_terror_per_witch", "10", "How many points does a terror cost per witch");
	WitchLimit              = AutoExecConfig_CreateConVar("l4d2_points_witch_limiter", "10", "Maximum amount of alive witches");
	TankLimit              = AutoExecConfig_CreateConVar("l4d2_points_tank_limiter", "1", "Maximum amount of alive tanks");

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
	for (int i = 0; i < sizeof(g_sUncommonModels); i++)
		PrecacheModel(g_sUncommonModels[i], true);

	ucommonleft = 0;
	jimmiesleft = 0;
	g_fPermanentUmobInvested = 0.0;

	CreateTimer(1.0, Timer_CheckWitchCount, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action Timer_CheckWitchCount(Handle hTimer)
{
	if (g_aWitchQueue.Length == 0)
		return Plugin_Continue;

	else if (L4D2_GetWitchCount() >= GetConVarInt(WitchLimit))
		return Plugin_Continue;

	float fOrigin[3];
	g_aWitchQueue.GetArray(0, fOrigin, sizeof(fOrigin));
	g_aWitchQueue.Erase(0);

	L4D2_SpawnWitch(fOrigin, view_as<float>({0.0, 0.0, 0.0}));

	return Plugin_Continue;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "PointSystemAPI"))
	{
		CreateInfectedProducts();
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "infected", false))
		return;

	if(jimmiesleft > 0)
	{
		if (!IsModelPrecached("models/infected/common_male_jimmy.mdl"))
			PrecacheModel("models/infected/common_male_jimmy.mdl");

		SetEntityModel(entity, "models/infected/common_male_jimmy.mdl");

		jimmiesleft--;

		return;
	}
	else if (ucommonleft <= 0)
		return;

	int iRNG = GetRandomInt(0, sizeof(g_sUncommonModels) - 1);

	if (!IsModelPrecached(g_sUncommonModels[iRNG]))
		PrecacheModel(g_sUncommonModels[iRNG]);

	SetEntityModel(entity, g_sUncommonModels[iRNG]);

	ucommonleft--;
}

public Action Event_RoundStart(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	ucommonleft = 0;

	return Plugin_Continue;
}

public Action PointSystemAPI_OnGetParametersProduct(int buyer, const char[] sAliases, char[] sInfo, char[] sName, char[] sDescription, int target, float& fCost, float& fDelay, float& fCooldown)
{
	if (StrEqual(sInfo, "Infected Extinguish"))
	{
		float tankCost = GetConVarFloat(PointsExtinguishTank);

		if (GetConVarFloat(PointsExtinguish) == tankCost)
			FormatEx(sDescription, sizeof(enProduct::sDescription), "Extinguishes your fire.");

		else if (tankCost == -1.0)
		{
			FormatEx(sDescription, sizeof(enProduct::sDescription), "Extinguishes your fire. Doesn't work for tanks.");
		}
		else
		{
			FormatEx(sDescription, sizeof(enProduct::sDescription), "Extinguishes your fire. Costs %i points for tanks.", RoundToFloor(GetConVarFloat(PointsExtinguishTank)));
		}

		if (L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Tank)
			fCost = tankCost;
	}
	else if (StrEqual(sInfo, "Terror All Witches Attack"))
	{
		fCost = GetConVarFloat(PointsTerrorPerWitch) * L4D2_GetWitchCount();
	}
	else if (StrEqual(sInfo, "Special Infected Ghost Spawn", false))
	{
		int infectedCount = PSAPI_GetTeamHumansCount(L4DTeam_Infected, false);

		int minCountForRespawn = GetConVarInt(PointsMinInstantRespawn);

		if (infectedCount <= minCountForRespawn)
		{
			fDelay = 0.0;
		}

		if (minCountForRespawn >= MAXPLAYERS)
		{
			FormatEx(sDescription, sizeof(enProduct::sDescription), "Identical to other infected respawn products.\nEnables zombie class selector.\nCosts the same as the highest priced SI respawn.");
		}
		else
		{
			FormatEx(sDescription, sizeof(enProduct::sDescription), "Identical to other infected respawn products.\nEnables zombie class selector.\nCosts the same as the highest priced SI respawn.\nInstant spawn if infected count is <= %i", minCountForRespawn);
		}
	}
	else if (strncmp(sInfo, "Special Infected Spawn - ", 25) == 0)
	{
		int infectedCount = PSAPI_GetTeamHumansCount(L4DTeam_Infected, false);

		int minCountForRespawn = GetConVarInt(PointsMinInstantRespawn);

		if (infectedCount <= minCountForRespawn)
		{
			fDelay = 0.0;
		}

		char sClassname[64];
		strcopy(sClassname, sizeof(sClassname), sInfo);

		// 1 = noPick, 0 = canPick

		bool bNoPick = true;
		if (strncmp(sInfo, "Special Infected Spawn - 0", 26) == 0)
			bNoPick = false;

		if (ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - 1", "") == -1)
			ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - 0", "");


		if(DisableGhostSpawn.BoolValue)
		{
			if (minCountForRespawn >= MAXPLAYERS)
			{
				FormatEx(sDescription, sizeof(enProduct::sDescription), "Respawn as a %s", sClassname);
			}
			else
			{
				FormatEx(sDescription, sizeof(enProduct::sDescription), "Respawn as a %s\nInstant spawn if infected count is <= %i", sClassname, minCountForRespawn);
			}
		}
		else
		{
			if (bNoPick)
			{
				if (minCountForRespawn >= MAXPLAYERS)
				{
					FormatEx(sDescription, sizeof(enProduct::sDescription), "Respawn as a ghost %s.\nDisables zombie class selector.", sClassname);
				}
				else
				{
					FormatEx(sDescription, sizeof(enProduct::sDescription), "Respawn as a ghost %s.\nDisables zombie class selector.\nInstant spawn if infected count is <= %i", sClassname, minCountForRespawn);
				}
			}
			else
			{
				if (minCountForRespawn >= MAXPLAYERS)
				{
					FormatEx(sDescription, sizeof(enProduct::sDescription), "Respawn as a ghost %s.\nEnables zombie class selector by identical cost to !buy ghost.", sClassname);
				}
				else
				{
					FormatEx(sDescription, sizeof(enProduct::sDescription), "Respawn as a ghost %s.\nEnables zombie class selector by identical cost to !buy ghost.\nInstant spawn if infected count is <= %i", sClassname, minCountForRespawn);
				}
			}
		}
	}

	return Plugin_Continue;
}

// sAliases contain the original alias list, to compare your own alias as an identifier.
// You should print an error because blocking purchase prints nothing
// Return Plugin_Handled to block purchase
public Action PointSystemAPI_OnTryBuyProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown)
{
	if (StrEqual(sInfo, "Infected Extinguish"))
	{
		if (!(GetEntityFlags(target) & FL_ONFIRE))
		{
			PSAPI_SetErrorByPriority(50, "Error:\x05 You are not on fire!");
			return Plugin_Handled;
		}
	}
	else if (StrEqual(sInfo, "Infected Suicide", false))
	{
		if (L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Charger)
		{
			// Airborne charger running.
			int iVictim = L4D_GetVictimCarry(target);

			if (iVictim != 0)
			{
				if ((!(GetEntityFlags(target) & FL_ONGROUND)))
				{
					PSAPI_SetErrorByPriority(50, "You cannot kill yourself until you reach the ground as a Charger.");
					return Plugin_Handled;
				}
			}

			int iAnyVictim = iVictim;

			if (iVictim == 0)
				iAnyVictim = L4D_GetVictimCharger(target);

			if (iAnyVictim != 0)
			{
				if (IsDoubleCharged(iAnyVictim))
				{
					PSAPI_SetErrorByPriority(50, "You cannot kill yourself when pinning a double-charged survivor.");
					return Plugin_Handled;
				}
			}
		}
	}

	char sClassname[64];
	strcopy(sClassname, sizeof(sClassname), sInfo);

	if (ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - 1", "") == -1)
		ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - 0", "");

	if(StrEqual(sClassname, "Tank", false))
	{
		int tankCount = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			else if (GetClientTeam(i) != view_as<int>(L4DTeam_Infected))
				continue;

			else if(!IsPlayerAlive(i))
				continue;

			else if(L4D2_GetPlayerZombieClass(i) != L4D2ZombieClass_Tank)
				continue;

			tankCount++;
		}

		if(tankCount >= GetConVarInt(TankLimit))
		{
			PSAPI_SetErrorByPriority(50, "Maximum living Tank limit reached\x04 (\x03%i\x04)", GetConVarInt(TankLimit));
			return Plugin_Handled;
		}
	}
	if (strncmp(sInfo, "Special Infected Spawn - ", 25) == 0 || StrEqual(sInfo, "Special Infected Ghost Spawn", false))
	{
		PSAPI_RefundProducts("boomer spitter smoker hunter charger jockey ghost", buyer, target);
	}
	return Plugin_Continue;
}

// sAliases contain the original alias list, to compare your own alias as an identifier.

// You should reconsider printing an error because blocking purchase prints a refund point gain.
// Return Plugin_Handled to refund.
public Action PointSystemAPI_OnRealTimeRefundProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fTimeleft)
{
	char sClassname[64];
	strcopy(sClassname, sizeof(sClassname), sInfo);

	if (ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - 1", "") == -1)
		ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - 0", "");

	if(StrEqual(sClassname, "Tank", false))
	{
		int tankCount = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			else if (GetClientTeam(i) != view_as<int>(L4DTeam_Infected))
				continue;

			else if(!IsPlayerAlive(i))
				continue;

			else if(L4D2_GetPlayerZombieClass(i) != L4D2ZombieClass_Tank)
				continue;

			tankCount++;
		}

		if(tankCount >= GetConVarInt(TankLimit))
		{
			return Plugin_Handled;
		}
	}

	if (strncmp(sInfo, "Special Infected Spawn - ", 25) == 0 || StrEqual(sInfo, "Special Infected Ghost Spawn", false))
	{
		if (IsPlayerAlive(buyer))
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}
// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.
public Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown)
{
	bool bFoundTeleport = false;
	float fOrigin[3];

	bFoundTeleport = UC_GetAimPositionBySize(buyer, GetRandomSurvivor(1), fOrigin);

	if (strncmp(sInfo, "Special Infected Spawn - ", 25) == 0)
	{
		char sClassname[64];
		strcopy(sClassname, sizeof(sClassname), sInfo);

		// 1 = noPick, 0 = canPick

		bool bNoPick = true;
		if (strncmp(sInfo, "Special Infected Spawn - 0", 26) == 0)
			bNoPick = false;

		if (ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - 1", "") == -1)
			ReplaceStringEx(sClassname, sizeof(sClassname), "Special Infected Spawn - 0", "");

		PSAPI_SpawnInfectedBossByClassname(target, sClassname, !DisableGhostSpawn.BoolValue, bNoPick);
		
		if(bFoundTeleport)
			TeleportEntity(target, fOrigin, NULL_VECTOR, NULL_VECTOR);

		return Plugin_Continue;
	}
	else if (StrEqual(sInfo, "Special Infected Ghost Spawn", false))
	{
		PSAPI_SpawnInfectedBossByClassname(target, g_sSIClassnames[GetRandomInt(0, sizeof(g_sSIClassnames) - 1)], true, false);

		if(bFoundTeleport)
			TeleportEntity(target, fOrigin, NULL_VECTOR, NULL_VECTOR);
	}
	else if (StrEqual(sInfo, "Witch"))
	{
		if(!bFoundTeleport)
		{
			return Plugin_Handled;
		}

		g_aWitchQueue.PushArray(fOrigin);

		if (L4D2_GetWitchCount() >= GetConVarInt(WitchLimit))
		{
			UC_PrintToChat(buyer, "Witch limit exceeded, but your witch will spawn after a witch dies.");
		}

		CreateTimer(0.0, Timer_CheckWitchCount, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(sInfo, "Terror All Witches Attack"))
	{
		int iEntity = -1;

		while ((iEntity = FindEntityByClassname(iEntity, "witch")) != -1)
		{
			int iAttacker = GetRandomSurvivor(1, 0);

			if (iAttacker == 0)
			{
				return Plugin_Handled;
			}
			else
			{
				SDKHooks_TakeDamage(iEntity, iAttacker, iAttacker, 1.0, DMG_BULLET);
			}
		}
	}
	else if (StrEqual(sInfo, "Horde"))
	{
		L4D_ForcePanicEvent();
	}
	else if (StrEqual(sInfo, "Uncommon Mob"))
	{
		ucommonleft += GetConVarInt(g_hCommonLimit);

		PSAPI_ExecuteCheatCommand(target, "z_spawn_old mob auto");
		
		g_fPermanentUmobInvested += fCost;
		
		if(GetConVarInt(PointsPermanentUmob) >= 0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i))
					continue;

				else if (GetClientTeam(i) != view_as<int>(L4DTeam_Infected))
					continue;

				UC_PrintToChat(i, "%N\x01 invested \x05%d\x03 points to Permanent Uncommon Mob! (\x05%d\x01 / \x05%d \x03)", buyer, RoundToFloor(fCost), RoundToFloor(g_fPermanentUmobInvested), GetConVarInt(PointsPermanentUmob));
			}

			if(g_fPermanentUmobInvested >= GetConVarFloat(PointsPermanentUmob))
			{
				ucommonleft = 2000000000;
			}
		}
	
	}
	else if (StrEqual(sInfo, "Jimmy Mob"))
	{
		jimmiesleft += GetConVarInt(g_hCommonLimit);

		PSAPI_ExecuteCheatCommand(target, "z_spawn_old mob auto");
	}
	else if (StrEqual(sInfo, "Infected Suicide", false))
	{
		if (L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Tank && SuicideTankReplace.BoolValue)
			L4D_ReplaceWithBot(target);

		else
			ForcePlayerSuicide(target);
	}
	else if (StrEqual(sInfo, "Infected Extinguish"))
	{
		ExtinguishEntity(target);
	}

	return Plugin_Continue;
}

public void CreateInfectedProducts()
{
	// Prevents fail state of plugin.
	if(!LibraryExists("PointSystemAPI"))
		return;

	char sInfo[256];

	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %iboomer", GetConVarInt(PointsBoomer) == CalculateGhostPrice() ? 0 : 1);

	PSAPI_CreateProduct(-1, GetConVarFloat(PointsBoomer), "Boomer", NO_DESCRIPTION, "boomer", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_REALTIME_REFUNDS);

	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %ispitter", GetConVarFloat(PointsSpitter) == CalculateGhostPrice() ? 0 : 1);
	PSAPI_CreateProduct(-1, GetConVarFloat(PointsSpitter), "Spitter", NO_DESCRIPTION, "spitter", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_REALTIME_REFUNDS);

	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %ismoker", GetConVarFloat(PointsSmoker) == CalculateGhostPrice() ? 0 : 1);
	PSAPI_CreateProduct(-1, GetConVarFloat(PointsSmoker), "Smoker", NO_DESCRIPTION, "smoker", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_REALTIME_REFUNDS);

	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %ihunter", GetConVarFloat(PointsHunter) == CalculateGhostPrice() ? 0 : 1);
	PSAPI_CreateProduct(-1, GetConVarFloat(PointsHunter), "Hunter", NO_DESCRIPTION, "hunter", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_REALTIME_REFUNDS);

	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %icharger", GetConVarFloat(PointsCharger) == CalculateGhostPrice() ? 0 : 1);
	PSAPI_CreateProduct(-1, GetConVarFloat(PointsCharger), "Charger", NO_DESCRIPTION, "charger", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_REALTIME_REFUNDS);

	FormatEx(sInfo, sizeof(sInfo), "Special Infected Spawn - %ijockey", GetConVarFloat(PointsJockey) == CalculateGhostPrice() ? 0 : 1);
	PSAPI_CreateProduct(-1, GetConVarFloat(PointsJockey), "Jockey", NO_DESCRIPTION, "jockey", sInfo, 3.0, 0.0, BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_REALTIME_REFUNDS);

	PSAPI_CreateProduct(-1, CalculateGhostPrice(), "Ghost", NO_DESCRIPTION, "ghost", "Special Infected Ghost Spawn", 3.0, 0.0,
	                    BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_REALTIME_REFUNDS | BUYFLAG_HUMANTEAM);

	PSAPI_CreateProduct(-1, GetConVarFloat(PointsTank), "Tank", "Ghost spawn of a Tank", "tank", "Special Infected Spawn - 1tank", 0.0, 0.0,
	                    BUYFLAG_INFECTED | BUYFLAG_DEAD | BUYFLAG_REALTIME_REFUNDS);

	PSAPI_CreateProduct(-1, GetConVarFloat(PointsWitch), "Witch", "Spawns a witch", "witch", "Witch", 0.0, 5.0,
	                    BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);

	FormatEx(sInfo, sizeof(sInfo), "Forces all witches to attack random players\nCosts %.0f points multiplied by the number of witches", GetConVarFloat(PointsTerrorPerWitch));

	PSAPI_CreateProduct(-1, GetConVarFloat(PointsTerrorPerWitch), "Terror", sInfo, "terror", "Terror All Witches Attack", 0.0, 5.0,
	                    BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);

	PSAPI_CreateProduct(-1, GetConVarFloat(PointsHorde), "Horde", NO_DESCRIPTION, "horde", "Horde", 0.0, 10.0,
	                    BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);

	char sDesc[128];
	FormatEx(sDesc, sizeof(sDesc), "Sends a mob that will contain %i uncommon CI", GetConVarInt(g_hCommonLimit));
	PSAPI_CreateProduct(-1, GetConVarFloat(PointsUmob), "Uncommon Mob", sDesc, "umob uncommonmob unmob ", "Uncommon Mob", 0.0, 1.0,
	                    BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);

	FormatEx(sDesc, sizeof(sDesc), "Sends a mob that will contain %i Jimmy Gibbs CI", GetConVarInt(g_hCommonLimit));

	PSAPI_CreateProduct(-1, GetConVarFloat(PointsJmob), "Jimmy Mob", sDesc, "jim jimmy jmob jimmies jimy jimi jym", "Jimmy Mob", 0.0, 1.0,
	                    BUYFLAG_INFECTED | BUYFLAG_ALL_LIFESTATES);

	PSAPI_CreateProduct(-1, GetConVarFloat(PointsSuicide), "Suicide", "Instantly kills you", "kill suicide die death", "Infected Suicide", 0.0, 0.0,
	                    BUYFLAG_INFECTED | BUYFLAG_ALIVE | BUYFLAG_GHOST);

	PSAPI_CreateProduct(-1, GetConVarFloat(PointsExtinguish), "Extinguish", NO_DESCRIPTION, "ext extinguish water", "Infected Extinguish", 0.0, 0.0,
	                    BUYFLAG_INFECTED | BUYFLAG_ALIVE);
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

stock float CalculateGhostPrice()
{
	if(DisableGhostSpawn.BoolValue)
		return -1.0;

	float HighestCost = 0.0;

	if (HighestCost < GetConVarFloat(PointsHunter))
		HighestCost = GetConVarFloat(PointsHunter);

	if (HighestCost < GetConVarFloat(PointsJockey))
		HighestCost = GetConVarFloat(PointsJockey);

	if (HighestCost < GetConVarFloat(PointsSmoker))
		HighestCost = GetConVarFloat(PointsSmoker);

	if (HighestCost < GetConVarFloat(PointsCharger))
		HighestCost = GetConVarFloat(PointsCharger);

	if (HighestCost < GetConVarFloat(PointsBoomer))
		HighestCost = GetConVarFloat(PointsBoomer);

	if (HighestCost < GetConVarFloat(PointsSpitter))
		HighestCost = GetConVarFloat(PointsSpitter);

	return HighestCost;
}

stock bool IsDoubleCharged(int victim)
{
	int count;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (GetClientTeam(i) != view_as<int>(L4DTeam_Infected))
			continue;

		else if (L4D2_GetPlayerZombieClass(i) != L4D2ZombieClass_Charger)
			continue;

		if (L4D_GetVictimCarry(i) == victim || L4D_GetVictimCharger(i) == victim)
			count++;
	}

	return count >= 2;
}