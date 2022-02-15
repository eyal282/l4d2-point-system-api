

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

ConVar g_cvTankHealAmount;

public void OnPluginStart()
{
	CreateProducts();
	
	g_cvTankHealAmount = CreateConVar("l4d2_points_tank_heal_amount", "3200"); // Amount of HP a tank heals per !buy heal.
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
			
			iCost *= RoundToCeil(float(iMissingHealth) / float(GetConVarInt(g_cvTankHealAmount)));
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
			HealEntity(target, GetConVarInt(g_cvTankHealAmount));
	}
	
	return Plugin_Continue;
}

public void CreateProducts()
{

	
	PS_CreateProduct(-1, 100, "Heal", "Heals you to max health\nTanks gain less health", "heal", "Partial Heal", 0.0, 0.0,
	BUYFLAG_INFECTED | BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_TEAM | BUYFLAG_PINNED);	
	
	PS_CreateProduct(-1, 100, "Full Heal", "Heals you to max health\nTanks buy this over and over until full health", "fheal fullheal", "Full Heal", 0.0, 0.0,
	BUYFLAG_INFECTED | BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_TEAM | BUYFLAG_PINNED);	
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