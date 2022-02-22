

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <ps_api>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "Full Heal Module --> Point System API",
	author = "Eyal282",
	description = "Full Heal Module for the multi team product full heal.",
	version = PLUGIN_VERSION,
	url = ""
};

int g_iTankHealsBought[MAXPLAYERS] = { 0, ... };

ConVar g_hHealCost;
ConVar g_hTankHealAmount;
ConVar g_hTankHealPercent;
ConVar g_hTankHealMax;

public void OnPluginStart()
{	
	HookEvent("player_spawn", Event_PlayerSpawnOrDeath, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerSpawnOrDeath, EventHookMode_Post);
	
	AutoExecConfig_SetFile("PointSystemAPI_FullHeal");
	
	g_hHealCost = AutoExecConfig_CreateConVar("l4d2_points_full_heal", "15", "How many points a complete heal costs");
	g_hTankHealAmount = AutoExecConfig_CreateConVar("l4d2_points_tank_heal_amount", "0", "Amount of HP a tank will heal instead of a full heal when buying a heal.");
	g_hTankHealPercent = AutoExecConfig_CreateConVar("l4d2_points_tank_heal_percent", "20.0", "Percentage of HP a tank will heal instead of a full heal when buying a heal", _, true, 0.0, true, 100.0);
	g_hTankHealMax = AutoExecConfig_CreateConVar("l4d2_points_tank_heal_max", "15", "Amount of times a Tank can heal", _, true, 0.0, true, 86400.0);
	
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
	
	if(client == 0)
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
	if(StrEqual(name, "PointSystemAPI"))
	{
		CreateProducts();
	}
}

// Called even if you cannot afford the product, and even if you didn't try to buy the product'.
// sAliases contain the original alias list, to compare your own alias as an identifier.
// If the cost drops below 0, the item is disabled!!!
// No return
public void PointSystemAPI_OnGetParametersProduct(int buyer, const char[] sAliases, char[] sInfo, char[] sName, char[] sDescription, int target, float &fCost, float &fDelay, float &fCooldown)
{
	if(StrEqual(sInfo, "Full Heal"))
	{
		if(GetClientTeam(target) == view_as<int>(L4DTeam_Infected) && L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Tank)
		{
			int iAmountToHeal = GetConVarInt(g_hTankHealAmount) + RoundFloat(((GetConVarFloat(g_hTankHealPercent) / 100.0) * GetEntityMaxHealth(target)));
			
			int iMissingHealth = GetEntityMaxHealth(target) - GetEntityHealth(target);
			
			int purchases = RoundToCeil(float(iMissingHealth) / float(iAmountToHeal));
			
			if(g_iTankHealsBought[target] + purchases >= GetConVarInt(g_hTankHealMax))
				purchases = GetConVarInt(g_hTankHealMax) - g_iTankHealsBought[target];
				
			fCost *= purchases;
		}
	}
}

public Action PointSystemAPI_OnTryBuyProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown)
{
	
	if(StrEqual(sInfo, "Full Heal") || StrEqual(sInfo, "Partial Heal"))
	{
		if(GetEntityHealth(target) == GetEntityMaxHealth(target))
		{
			PrintToChat(buyer, "Error: Max Health");
			return Plugin_Handled;
		}
		
		else if(GetClientTeam(target) == view_as<int>(L4DTeam_Infected) && L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Tank && buyer != target)
		{
			PrintToChat(buyer, "Error: Tanks must heal themselves because they are limited in buying health.");
			return Plugin_Handled;
		}
		else if(GetClientTeam(target) == view_as<int>(L4DTeam_Infected) && L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Tank && g_iTankHealsBought[target] >= GetConVarInt(g_hTankHealMax))
		{
			PrintToChat(buyer, "Error: Max Tank heal limit");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.
public Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown)
{
	if(StrEqual(sInfo, "Full Heal"))
	{
		if(GetClientTeam(target) == view_as<int>(L4DTeam_Survivor) || L4D2_GetPlayerZombieClass(target) != L4D2ZombieClass_Tank)
			PSAPI_FullHeal(target);
			
		else
		{
			int iAmountToHeal = GetConVarInt(g_hTankHealAmount) + RoundFloat(((GetConVarFloat(g_hTankHealPercent) / 100.0) * GetEntityMaxHealth(target)));
			
			int iMissingHealth = GetEntityMaxHealth(target) - GetEntityHealth(target);
			
			int purchases = RoundToCeil(float(iMissingHealth) / float(iAmountToHeal));
			
			if(g_iTankHealsBought[target] + purchases >= GetConVarInt(g_hTankHealMax))
				purchases = GetConVarInt(g_hTankHealMax) - g_iTankHealsBought[target];
			
			g_iTankHealsBought[target] += purchases;
			
			HealEntity(target, iAmountToHeal * purchases);
		}
		
		return Plugin_Continue;
	}
	else if(StrEqual(sInfo, "Partial Heal"))
	{
		if(GetClientTeam(target) == view_as<int>(L4DTeam_Survivor) || L4D2_GetPlayerZombieClass(target) != L4D2ZombieClass_Tank)
			PSAPI_FullHeal(target);
			
		else
		{
			int iAmountToHeal = GetConVarInt(g_hTankHealAmount) + RoundFloat(((GetConVarFloat(g_hTankHealPercent) / 100.0) * GetEntityMaxHealth(target)));
			
			g_iTankHealsBought[target]++;
			
			HealEntity(target, iAmountToHeal);
		}
	}
	
	return Plugin_Continue;
}

public void CreateProducts()
{

	int iCategory = PSAPI_CreateCategory(-1, "health products", "Health Products", BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, g_hHealCost.FloatValue, "Heal", "Heals you to max health\nTanks gain less health", "heal", "Partial Heal", 0.0, 0.0,
	BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_PINNED | BUYFLAG_TEAM);	
	
	PSAPI_CreateProduct(iCategory, g_hHealCost.FloatValue, "Full Heal", "Heals you to max health\nFor tanks, as if they spam !buy heal", "fheal fullheal", "Full Heal", 0.0, 0.0,
	BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_PINNED | BUYFLAG_TEAM);	
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
stock int GetEntityMaxHealth(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iMaxHealth");
}

stock void HealEntity(int entity, int amount)
{
	SetEntityHealth(entity, GetEntityHealth(entity) + amount);
	
	if(GetEntityHealth(entity) > GetEntityMaxHealth(entity))
		SetEntityHealth(entity, GetEntityMaxHealth(entity));
}