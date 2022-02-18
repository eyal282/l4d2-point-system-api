

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <ps_api>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "Infected Module --> Point System API",
	author = "Eyal282",
	description = "Every infected Item to be bought in Point System",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar g_hHealCost;
ConVar g_hTankHealAmount;
ConVar g_hTankHealPercent;

public void OnPluginStart()
{	
	AutoExecConfig_SetFile("PointSystemAPI");
	
	g_hHealCost = AutoExecConfig_CreateConVar("l4d2_points_full_heal", "15", "How many points a complete heal costs");
	g_hTankHealAmount = AutoExecConfig_CreateConVar("l4d2_points_tank_heal_amount", "0", "Amount of HP a tank will heal instead of a full heal when buying a heal.");
	g_hTankHealPercent = AutoExecConfig_CreateConVar("l4d2_points_tank_heal_percent", "20.0", "Percentage of HP a tank will heal instead of a full heal when buying a heal", _, true, 0.0, true, 100.0);
	
	CreateProducts();
	
	// This makes an internal call to AutoExecConfig with the given configfile
	AutoExecConfig_ExecuteFile();

	// Cleaning should be done at the end
	AutoExecConfig_CleanFile();
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

public Action PointSystemAPI_OnTryBuyProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int &target, int &iCost, float &fDelay, float &fCooldown)
{
	
	if(StrEqual(sInfo, "Full Heal") || StrEqual(sInfo, "Partial Heal"))
	{
		if(GetEntityHealth(target) == GetEntityMaxHealth(target))
		{
			PrintToChat(buyer, "Error: Max Health");
			return Plugin_Handled;
		}
	}
	
	if(StrEqual(sInfo, "Full Heal"))
	{
		if(GetClientTeam(target) == view_as<int>(L4DTeam_Infected) && L4D2_GetPlayerZombieClass(target) == L4D2ZombieClass_Tank)
		{
			int iAmountToHeal = GetConVarInt(g_hTankHealAmount) + RoundFloat(((GetConVarFloat(g_hTankHealPercent) / 100.0) * GetEntityMaxHealth(target)));
			
			int iMissingHealth = GetEntityMaxHealth(target) - GetEntityHealth(target);
			
			iCost *= RoundToCeil(float(iMissingHealth) / float(iAmountToHeal));
		}
	}
	
	return Plugin_Continue;
}

// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.
public Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, int iCost, float fDelay, float fCooldown)
{
	if(StrEqual(sInfo, "Full Heal"))
	{
		PS_FullHeal(target);
		
		return Plugin_Continue;
	}
	else if(StrEqual(sInfo, "Partial Heal"))
	{
		if(GetClientTeam(target) == view_as<int>(L4DTeam_Survivor) || L4D2_GetPlayerZombieClass(target) != L4D2ZombieClass_Tank)
			PS_FullHeal(target);
			
		else
		{
			int iAmountToHeal = GetConVarInt(g_hTankHealAmount) + RoundFloat(((GetConVarFloat(g_hTankHealPercent) / 100.0) * GetEntityMaxHealth(target)));
			
			HealEntity(target, iAmountToHeal);
		}
	}
	
	return Plugin_Continue;
}

public void CreateProducts()
{

	int iCategory = PS_CreateCategory(-1, "health products", "Health Products", BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE);
	PS_CreateProduct(iCategory, g_hHealCost.IntValue, "Heal", "Heals you to max health\nTanks gain less health", "heal", "Partial Heal", 0.0, 0.0,
	BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_TEAM | BUYFLAG_PINNED);	
	
	PS_CreateProduct(iCategory, g_hHealCost.IntValue, "Full Heal", "Heals you to max health\nFor tanks, as if they spam !buy heal", "fheal fullheal", "Full Heal", 0.0, 0.0,
	BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_TEAM | BUYFLAG_PINNED);	
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