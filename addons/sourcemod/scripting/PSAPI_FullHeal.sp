

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
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

ConVar g_hHealCost
ConVar g_hTankHealAmount;

public void OnPluginStart()
{
	CreateProducts();
	
	g_hTankHealAmount = CreateConVar("l4d2_points_tank_heal_amount", "3200"); // Amount of HP a tank heals per !buy heal.
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
			int iMissingHealth = GetEntityMaxHealth(target) - GetEntityHealth(target);
			
			iCost *= RoundToCeil(float(iMissingHealth) / float(GetConVarInt(g_hTankHealAmount)));
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
			HealEntity(target, GetConVarInt(g_hTankHealAmount));
	}
	
	return Plugin_Continue;
}

public void CreateProducts()
{

	int iCategory = PS_CreateCategory("health items", "Health Items", BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE)
	PS_CreateProduct(-1, g_hHealCost.IntValue, "Heal", "Heals you to max health\nTanks gain less health", "heal", "Partial Heal", 0.0, 0.0,
	BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_TEAM | BUYFLAG_PINNED);	
	
	PS_CreateProduct(-1, g_hHealCost.IntValue, "Full Heal", "Heals you to max health\nFor tanks, as if they spam !buy heal", "fheal fullheal", "Full Heal", 0.0, 0.0,
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