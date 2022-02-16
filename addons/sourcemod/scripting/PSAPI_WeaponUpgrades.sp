

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
	name = "Weapon Upgrades Module --> Point System API",
	author = "Eyal282",
	description = "Explosive ammo and etc.",
	version = PLUGIN_VERSION,
	url = ""
};


ConVar g_cvExplosiveAmmoCost;
ConVar g_cvIncendiaryAmmoCost;
ConVar g_cvLaserPointerCost;

public void OnPluginStart()
{	
	g_cvExplosiveAmmoCost = CreateConVar("l4d2_points_exammo_cost", "35");
	g_cvIncendiaryAmmoCost = CreateConVar("l4d2_points_incammo_cost", "15");
	g_cvLaserPointerCost = CreateConVar("l4d2_points_laser_pointer_cost", "0");
	
	CreateProducts();
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "PointSystemAPI"))
	{
		CreateProducts();
	}
}

// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.
public Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, int iCost, float fDelay, float fCooldown)
{
	if(strncmp(sInfo, "upgrade_add", 11) == 0)
	{
		PSAPI_ExecuteCheatCommand(target, sInfo);
	}
	
	return Plugin_Continue;
}

public void CreateProducts()
{
	PS_CreateProduct(-1, GetConVarInt(g_cvExplosiveAmmoCost), "Explosive Ammo", "Bullets stagger all Infected but the Tank", "exammo expammo", "upgrade_add EXPLOSIVE_AMMO", 0.0, 0.0,
	BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_TEAM);	
	
	PS_CreateProduct(-1, GetConVarInt(g_cvIncendiaryAmmoCost), "Incendiary Ammo", "Bullets set Infected on fire", "incammo inammo fireammo", "upgrade_add INCENDIARY_AMMO", 0.0, 0.0,
	BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_BOTTEAM);	
	
	PS_CreateProduct(-1, GetConVarInt(g_cvLaserPointerCost), "Laser Sight", "Makes your weapon more accurate", "laser", "upgrade_add LASER_SIGHT", 0.0, 0.0,
	BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_BOTTEAM);	
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