

#include <ps_api>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name        = "Full Heal Module --> Point System API",
	author      = "Eyal282",
	description = "Full Heal Module for the multi team product full heal.",
	version     = PLUGIN_VERSION,
	url         = ""
};

int g_iTankHealsBought[MAXPLAYERS] = { 0, ... };

ConVar g_hHealOriginal;
ConVar g_hHealCost;
ConVar g_hBoomerRatioCost;
ConVar g_hSpitterRatioCost;
ConVar g_hTankHealAmount;
ConVar g_hTankHealPercent;
ConVar g_hTankHealMax;

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawnOrDeath, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerSpawnOrDeath, EventHookMode_Post);

	AutoExecConfig_SetFile("PointSystemAPI_FullHeal");

	g_hHealOriginal         = AutoExecConfig_CreateConVar("l4d2_points_full_heal_original", "1", "0 - Heal to max HP. 1 - Heal to 100 HP");
	g_hHealCost         = AutoExecConfig_CreateConVar("l4d2_points_full_heal", "15", "How many points a complete heal costs");
	g_hBoomerRatioCost  = AutoExecConfig_CreateConVar("l4d2_points_full_heal_boomer_ratio_cost", "0.5", "Ratio of cost for boomers");
	g_hSpitterRatioCost = AutoExecConfig_CreateConVar("l4d2_points_full_heal_spitter_ratio_cost", "0.5", "Ratio of cost for spitters");
	g_hTankHealAmount   = AutoExecConfig_CreateConVar("l4d2_points_tank_heal_amount", "0", "Amount of HP a tank will heal instead of a full heal when buying a heal.");
	g_hTankHealPercent  = AutoExecConfig_CreateConVar("l4d2_points_tank_heal_percent", "20.0", "Percentage of HP a tank will heal instead of a full heal when buying a heal", _, true, 0.0, true, 100.0);
	g_hTankHealMax      = AutoExecConfig_CreateConVar("l4d2_points_tank_heal_max", "15", "Amount of times a Tank can heal", _, true, 0.0, true, 86400.0);

	CreateProducts();

	// This makes an internal call to AutoExecConfig with the given configfile
	AutoExecConfig_ExecuteFile();

	// Cleaning should be done at the end
	AutoExecConfig_CleanFile();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("PSAPI_GetTankHealCount", Native_GetTankHealCount);
	CreateNative("PSAPI_AddTankHealCount", Native_AddTankHealCount);

	RegPluginLibrary("PointSystemAPI_FullHeal");
	return APLRes_Success;
}

public int Native_GetTankHealCount(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	SetNativeCellRef(2, GetConVarInt(g_hTankHealMax));

	return g_iTankHealsBought[client];
}

public any Native_AddTankHealCount(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int amount = GetNativeCell(2);

	g_iTankHealsBought[client] += amount;

	return 0;
}

public Action Event_PlayerSpawnOrDeath(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (client == 0)
		return Plugin_Continue;

	g_iTankHealsBought[client] = 0;

	return Plugin_Continue;
}

public void OnConfigsExecuted()
{
	CreateProducts();
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "PointSystemAPI"))
	{
		CreateProducts();
	}
}

// Called even if you cannot afford the product, and even if you didn't try to buy the product'.
// sAliases contain the original alias list, to compare your own alias as an identifier.
// If the cost drops below 0, the item is disabled!!!
// No return
public Action PointSystemAPI_OnGetParametersProduct(int buyer, const char[] sAliases, char[] sInfo, char[] sName, char[] sDescription, int target, float& fCost, float& fDelay, float& fCooldown)
{
	if (StrEqual(sInfo, "Full Heal") || StrEqual(sInfo, "Partial Heal"))
	{
		if (L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Boomer)
			fCost *= GetConVarFloat(g_hBoomerRatioCost);

		else if (L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Spitter)
			fCost *= GetConVarFloat(g_hSpitterRatioCost);
	}
	if (StrEqual(sInfo, "Full Heal"))
	{
		if (GetClientTeam(target) == view_as<int>(L4DTeam_Infected) && L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Tank)
		{
			int iAmountToHeal = GetConVarInt(g_hTankHealAmount) + RoundFloat(((GetConVarFloat(g_hTankHealPercent) / 100.0) * PSAPI_GetEntityMaxHealth(target)));

			int iMissingHealth = PSAPI_GetEntityMaxHealth(target) - GetEntityHealth(target);

			int purchases = RoundToCeil(float(iMissingHealth) / float(iAmountToHeal));

			if (g_iTankHealsBought[target] + purchases >= GetConVarInt(g_hTankHealMax))
				purchases = GetConVarInt(g_hTankHealMax) - g_iTankHealsBought[target];

			fCost *= purchases;
		}
	}

	return Plugin_Continue;
}

public Action PointSystemAPI_OnTryBuyProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown)
{
	if (StrEqual(sInfo, "Full Heal") || StrEqual(sInfo, "Partial Heal"))
	{
		// Need to fix this with incap, as max health is the same when incapped so 100 hp incap = no heal.
		if (GetEntityHealth(target) == PSAPI_GetEntityMaxHealth(target) && !L4D_IsPlayerIncapacitated(target) && !L4D_IsPlayerPinned(target))
		{
			PSAPI_SetErrorByPriority(50, "\x04[PS]\x03 Error:\x01 You are at max health");
			return Plugin_Handled;
		}

		else if (GetClientTeam(target) == view_as<int>(L4DTeam_Infected) && L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Tank)
		{
			if (buyer != target)
			{
				PSAPI_SetErrorByPriority(50, "\x04[PS]\x03 Error:\x01 Tanks must heal themselves because they are limited in buying health.");
				return Plugin_Handled;
			}
			else if (g_iTankHealsBought[target] >= GetConVarInt(g_hTankHealMax))
			{
				PSAPI_SetErrorByPriority(50, "\x04[PS]\x03 Error:\x01 Max Tank heal limit");
				return Plugin_Handled;
			}
			else if (L4D_IsPlayerIncapacitated(target))
			{
				PSAPI_SetErrorByPriority(50, "\x04[PS-Anti Exploit]\x03 You cannot heal yourself as a dying tank.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.
public Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown)
{
	if (StrEqual(sInfo, "Full Heal"))
	{
		if (GetClientTeam(target) == view_as<int>(L4DTeam_Survivor) || L4D2_GetPlayerZombieClass(target) != L4D2ZombieClass_Tank)
		{
			int oldHP = GetEntityHealth(target);

			if(L4D_IsPlayerIncapacitated(target) || oldHP < 0)
				oldHP = 0;

			PSAPI_FullHeal(target);

			if(g_hHealOriginal.BoolValue && L4D_GetClientTeam(target) == L4DTeam_Survivor)
			{
				if(!L4D_IsPlayerIncapacitated(target))
				{
					SetEntityHealth(target, oldHP + 100);

					if(GetEntityHealth(target) > GetEntityMaxHealth(target))
					{
						SetEntityHealth(target, GetEntityMaxHealth(target));
					}
				}
			}
		}

		else
		{
			int iAmountToHeal = GetConVarInt(g_hTankHealAmount) + RoundFloat(((GetConVarFloat(g_hTankHealPercent) / 100.0) * PSAPI_GetEntityMaxHealth(target)));

			int iMissingHealth = PSAPI_GetEntityMaxHealth(target) - GetEntityHealth(target);

			int purchases = RoundToCeil(float(iMissingHealth) / float(iAmountToHeal));

			if (g_iTankHealsBought[target] + purchases >= GetConVarInt(g_hTankHealMax))
				purchases = GetConVarInt(g_hTankHealMax) - g_iTankHealsBought[target];

			g_iTankHealsBought[target] += purchases;

			HealEntity(target, iAmountToHeal * purchases);
		}

		return Plugin_Continue;
	}
	else if (StrEqual(sInfo, "Partial Heal"))
	{
		if (GetClientTeam(target) == view_as<int>(L4DTeam_Survivor) || L4D2_GetPlayerZombieClass(target) != L4D2ZombieClass_Tank)
		{
			int oldHP = GetEntityHealth(target);

			if(L4D_IsPlayerIncapacitated(target) || oldHP < 0)
				oldHP = 0;

			PSAPI_FullHeal(target);

			if(g_hHealOriginal.BoolValue && L4D_GetClientTeam(target) == L4DTeam_Survivor)
			{
				if(!L4D_IsPlayerIncapacitated(target))
				{
					SetEntityHealth(target, oldHP + 100);

					if(GetEntityHealth(target) > GetEntityMaxHealth(target))
					{
						SetEntityHealth(target, GetEntityMaxHealth(target));
					}
				}
			}
		}

		else
		{
			int iAmountToHeal = GetConVarInt(g_hTankHealAmount) + RoundFloat(((GetConVarFloat(g_hTankHealPercent) / 100.0) * PSAPI_GetEntityMaxHealth(target)));

			g_iTankHealsBought[target]++;

			HealEntity(target, iAmountToHeal);
		}
	}

	return Plugin_Continue;
}

public void CreateProducts()
{
	// Prevents fail state of plugin.
	if(!LibraryExists("PointSystemAPI"))
		return;

	int iCategory = PSAPI_CreateCategory(-1, "health products", "Health Products", BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_PINNED);

	if (GetConVarFloat(g_hBoomerRatioCost) == GetConVarFloat(g_hSpitterRatioCost))
	{
		char sDescription[256];
		FormatEx(sDescription, sizeof(sDescription), "Heals you to max health\nTanks gain less health\nBoomers and Spitters pay %i%% the price", RoundFloat(GetConVarFloat(g_hBoomerRatioCost) * 100.0));

		PSAPI_CreateProduct(iCategory, g_hHealCost.FloatValue, "Heal", sDescription, "heal health", "Partial Heal", 0.0, 0.0,
		                    BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED | BUYFLAG_TEAM);

		FormatEx(sDescription, sizeof(sDescription), "Heals you to max health\nFor tanks, as if they spam !buy heal\nBoomers and Spitters pay %i%% the price", RoundFloat(GetConVarFloat(g_hBoomerRatioCost) * 100.0));

		PSAPI_CreateProduct(iCategory, g_hHealCost.FloatValue, "Full Heal", sDescription, "fheal fullheal full", "Full Heal", 0.0, 0.0,
		                    BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED | BUYFLAG_TEAM);
	}
	else
	{
		char sDescription[256];
		FormatEx(sDescription, sizeof(sDescription), "Heals you to max health\nTanks gain less health\nBoomers pay %i%% the price\nSpitters pay %i%% the price", RoundFloat(GetConVarFloat(g_hBoomerRatioCost) * 100.0), RoundFloat(GetConVarFloat(g_hBoomerRatioCost) * 100.0));
		PSAPI_CreateProduct(iCategory, g_hHealCost.FloatValue, "Heal", sDescription, "heal", "Partial Heal", 0.0, 0.0,
		                    BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED | BUYFLAG_TEAM);

		FormatEx(sDescription, sizeof(sDescription), "Heals you to max health\nFor tanks, as if they spam !buy heal\nBoomers pay %i%% the price\nSpitters pay %i%% the price", RoundFloat(GetConVarFloat(g_hBoomerRatioCost) * 100.0), RoundFloat(GetConVarFloat(g_hBoomerRatioCost) * 100.0));
		PSAPI_CreateProduct(iCategory, g_hHealCost.FloatValue, "Full Heal", sDescription, "fheal fullheal", "Full Heal", 0.0, 0.0,
		                    BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED | BUYFLAG_TEAM);
	}
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

stock int GetEntityHealth(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

stock void HealEntity(int entity, int amount)
{
	SetEntityHealth(entity, GetEntityHealth(entity) + amount);
}

stock bool IsEntityPlayer(int entity)
{
	if (entity <= 0)
		return false;

	else if (entity > MaxClients)
		return false;

	return true;
}

stock int GetEntityMaxHealth(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
}