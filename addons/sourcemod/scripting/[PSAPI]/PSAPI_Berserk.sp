#include <left4dhooks>
#include <ps_api>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name        = "Berserk Module --> Point System API",
	author      = "Eyal282",
	description = "A sacrifical product that will give you a desperate final blow on the infected.",
	version     = PLUGIN_VERSION,
	url         = ""
};

ConVar g_hBerserkMinCost;
ConVar g_hBerserkCostPerSecond;
ConVar g_hMaxBerserkDuration;

Handle g_hBerserkTimer[MAXPLAYERS + 1];
Handle g_hTickBerserkTimer[MAXPLAYERS + 1];

public void OnPluginStart()
{
	AutoExecConfig_SetFile("PointSystemAPI_Berserk");

	g_hBerserkMinCost       = AutoExecConfig_CreateConVar("l4d2_points_berserk_min_cost", "100", "Minimum cost of berserk");
	g_hBerserkCostPerSecond = AutoExecConfig_CreateConVar("l4d2_points_berserk_cost_per_second", "20", "Cost per second of berserk, -1 to disable");
	g_hMaxBerserkDuration   = AutoExecConfig_CreateConVar("l4d2_points_berserk_max_duration", "30", "Max duration of berserk");

	RegAdminCmd("sm_cheatberserk", Command_Berserk, ADMFLAG_ROOT);

	CreateProducts();

	// This makes an internal call to AutoExecConfig with the given configfile
	AutoExecConfig_ExecuteFile();

	// Cleaning should be done at the end
	AutoExecConfig_CleanFile();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		Func_OnClientPutInServer(i);
	}

	HookEvent("player_entered_checkpoint", Event_PlayerEnteredCheckpoint);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_bot_replace", Event_PlayerReplacedByBot);
}

public Action Command_Berserk(int client, int args)
{
	PrintToChatAll("%N used cheat command berserk", client);

	SetConVarInt(g_hMaxBerserkDuration, 65535);
	PSAPI_SetPoints(client, 999999.0);
	PointSystemAPI_OnShouldGiveProduct(client, "berserk", "berserk", "Berserk", client, 65535.0, 0.0, 0.0);

	return Plugin_Handled;
}

public Action Event_PlayerEnteredCheckpoint(Handle hEvent, const char[] sName, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (client == 0)
		return Plugin_Continue;

	else if (g_hBerserkTimer[client] == INVALID_HANDLE)
		return Plugin_Continue;

	CloseHandle(g_hBerserkTimer[client]);
	g_hBerserkTimer[client] = INVALID_HANDLE;

	if (g_hTickBerserkTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hTickBerserkTimer[client]);
		g_hTickBerserkTimer[client] = INVALID_HANDLE;
	}

	DataPack DP;

	g_hBerserkTimer[client] = CreateDataTimer(0.1, Timer_CheckBerserk, DP, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

	DP.WriteFloat(GetGameTime());
	DP.WriteFloat(GetGameTime());
	DP.WriteCell(client);

	TriggerTimer(g_hBerserkTimer[client]);

	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle hEvent, const char[] sName, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (client == 0)
		return Plugin_Continue;

	else if (g_hBerserkTimer[client] == INVALID_HANDLE)
		return Plugin_Continue;

	CloseHandle(g_hBerserkTimer[client]);
	g_hBerserkTimer[client] = INVALID_HANDLE;

	if (g_hTickBerserkTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hTickBerserkTimer[client]);
		g_hTickBerserkTimer[client] = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action Event_PlayerReplacedByBot(Handle hEvent, const char[] sName, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "player"));
	int bot    = GetClientOfUserId(GetEventInt(hEvent, "bot"));

	if (client == 0)
		return Plugin_Continue;

	else if (g_hBerserkTimer[client] == INVALID_HANDLE)
		return Plugin_Continue;

	CloseHandle(g_hBerserkTimer[client]);
	g_hBerserkTimer[client] = INVALID_HANDLE;

	if (g_hTickBerserkTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hTickBerserkTimer[client]);
		g_hTickBerserkTimer[client] = INVALID_HANDLE;
	}

	DataPack DP;

	g_hBerserkTimer[bot] = CreateDataTimer(0.1, Timer_CheckBerserk, DP, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

	DP.WriteFloat(GetGameTime());
	DP.WriteFloat(GetGameTime());
	DP.WriteCell(bot);

	TriggerTimer(g_hBerserkTimer[bot]);

	return Plugin_Continue;
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof(g_hBerserkTimer); i++)
	{
		g_hBerserkTimer[i]     = INVALID_HANDLE;
		g_hTickBerserkTimer[i] = INVALID_HANDLE;
	}
}

public void OnClientPutInServer(int client)
{
	Func_OnClientPutInServer(client);
}

public void Func_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDKEvent_OnTakeDamage);
	SDKHook(client, SDKHook_SetTransmit, SDKEvent_SetTransmit);
}

public void OnClientDisconnect(int client)
{
	if (g_hBerserkTimer[client] != INVALID_HANDLE)
	{
		if (g_hTickBerserkTimer[client] != INVALID_HANDLE)
		{
			CloseHandle(g_hTickBerserkTimer[client]);
			g_hTickBerserkTimer[client] = INVALID_HANDLE;
		}
		TriggerTimer(g_hBerserkTimer[client]);
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
	if (g_hBerserkTimer[client] != INVALID_HANDLE)
	{
		buttons &= ~IN_USE;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action SDKEvent_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (g_hBerserkTimer[victim] != INVALID_HANDLE)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	else if (IsPlayer(attacker) && g_hBerserkTimer[attacker])
	{
		if (L4D_GetClientTeam(victim) == L4DTeam_Survivor)
			damage = float(GetEntityMaxHealth(victim)) * 0.01;    // 1% damage + boomer health

		else
			damage = float(GetEntityMaxHealth(victim)) * 0.01 + 100.0;    // 1% damage + boomer health

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action SDKEvent_SetTransmit(int victim, int observer)
{
	if (g_hBerserkTimer[observer] != INVALID_HANDLE && victim != observer && GetClientTeam(victim) == GetClientTeam(observer))
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_TankClaw_OnPlayerHit_Pre(int tank, int claw, int player)
{
	if (g_hBerserkTimer[player] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnPlayerFling(int client, int attacker, float vecDir[3])
{
	if (g_hBerserkTimer[client] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnLedgeGrabbed(int client)
{
	if (g_hBerserkTimer[client] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnStagger(int target, int source)
{
	if (g_hBerserkTimer[target] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

// The survivor that is about to get stumbled as a result of "attacker" capping someone in close proximity
public Action L4D2_OnPounceOrLeapStumble(int victim, int attacker)
{
	if (g_hBerserkTimer[victim] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

// Called when someone is about to be hit by a Tank rock or lunged by a Hunter
public Action L4D_OnKnockedDown(int client, int reason)
{
	if (g_hBerserkTimer[client] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

// Called when a player is about to be flung probably by Charger impact.
public Action L4D2_OnThrowImpactedSurvivor(int attacker, int victim)
{
	if (g_hBerserkTimer[victim] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnPouncedOnSurvivor(int victim, int attacker)
{
	if (g_hBerserkTimer[victim] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnGrabWithTongue(int victim, int attacker)
{
	if (g_hBerserkTimer[victim] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnJockeyRide(int victim, int attacker)
{
	if (g_hBerserkTimer[victim] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnStartCarryingVictim(int victim, int attacker)
{
	if (g_hBerserkTimer[victim] != INVALID_HANDLE)
	{
		int iPinner = 0;
		while ((iPinner = L4D_BruteGetPinnedInfected(victim, iPinner)) != 0)
		{
			if(iPinner == attacker)
			{
				SetEntPropEnt(attacker, Prop_Send, "m_carryVictim", -1);
				SetEntPropEnt(victim, Prop_Send, "m_carryAttacker", -1);
			}
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
/*
// L4D2 only. Called when a player is about to be pummelled by a Charger.
public Action L4D2_OnPummelVictim(int attacker, int victim)
{
	if (g_hBerserkTimer[victim] != INVALID_HANDLE)
	{
		ForcePlayerSuicide(attacker);
		AnimHookEnable(victim, OnAnimPre, INVALID_FUNCTION);
		CreateTimer(0.3, TimerResetAnim, GetClientUserId(victim));

		return Plugin_Handled;
	}

	return Plugin_Continue;
}
*/

public Action L4D_OnVomitedUpon(int victim, int& attacker, bool& boomerExplosion)
{
	if (g_hBerserkTimer[victim] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vecDir[3], bool bIsHighPounce)
{
	char sClassname[64];
	GetEdictClassname(entity, sClassname, sizeof(sClassname));

	if (!StrEqual(sClassname, "player"))
		return Plugin_Continue;

	if (g_hBerserkTimer[client] != INVALID_HANDLE)
	{
		float damage = float(GetEntityMaxHealth(entity)) * 0.1 + 100.0;    // 10% damage + boomer health

		SDKHooks_TakeDamage(entity, client, client, damage, DMG_BURN, -1, NULL_VECTOR, NULL_VECTOR, false);

		L4D_StaggerPlayer(entity, client, NULL_VECTOR);

		return Plugin_Handled;
	}

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

public Action PointSystemAPI_OnGetParametersCategory(int buyer, const char[] sID, char[] sName)
{
	return Plugin_Continue;
}

// Called even if you cannot afford the product, and even if you didn't try to buy the product'.
// sAliases contain the original alias list, to compare your own alias as an identifier.
// If the cost drops below 0, the item is disabled!!!
// No return
public Action PointSystemAPI_OnGetParametersProduct(int buyer, const char[] sAliases, char[] sInfo, char[] sName, char[] sDescription, int target, float& fCost, float& fDelay, float& fCooldown)
{
	if (g_hBerserkTimer[target] != INVALID_HANDLE)
	{
		fCost += 1000000.0;
	}
	if (StrEqual(sInfo, "berserk"))
	{
		float fDuration = PSAPI_GetPoints(target) / GetConVarFloat(g_hBerserkCostPerSecond);

		if (fDuration > GetConVarFloat(g_hMaxBerserkDuration))
			fDuration = GetConVarFloat(g_hMaxBerserkDuration);

		FormatEx(sDescription, sizeof(enProduct::sDescription), "Activate if incapped, pinned and below 100 health to deal 5k damage to everything in your range\nDuration = (pts/%i) = %.1f\nEvery 0.5sec ignite everything in range for up to 5%% HP, damage increases as distance falls\nNothing can pin, fling, hurt, stagger you\nYou get a spas & incendiary ammo\nBurning rage hides everything except infected\nYou cannot be inside safe rooms\nWhen berserk ends, your body disappears", g_hBerserkCostPerSecond.IntValue, fDuration);
	}

	return Plugin_Continue;
}
// return Plugin_Handled to prevent the user from buying anything.
public Action PointSystemAPI_OnCanBuyProducts(int buyer, int target)
{
	if (g_hBerserkTimer[buyer] != INVALID_HANDLE)
	{
		PSAPI_SetErrorByPriority(50, "Error: Buy menu cannot be used during berserk!");
		return Plugin_Handled;
	}
	else if (g_hBerserkTimer[target] != INVALID_HANDLE)
	{
		PSAPI_SetErrorByPriority(50, "Error: Berserked survivors cannot receive products!");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
// sAliases contain the original alias list, to compare your own alias as an identifier.
// You should print an error because blocking purchase prints nothing
// Return Plugin_Handled to block purchase
public Action PointSystemAPI_OnTryBuyProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown)
{
	if (StrEqual(sInfo, "berserk"))
	{
		if (L4D_IsInLastCheckpoint(target))
		{
			PSAPI_SetErrorByPriority(50, "Error: You cannot berserk in a safe room!");
			return Plugin_Handled;
		}
		else if (GetEntityHealth(target) > 100)
		{
			PSAPI_SetErrorByPriority(50, "Error: Your HP must be lower than 100!");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action PointSystemAPI_OnBuyProductPost(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown)
{
	if (g_hBerserkTimer[target] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.
public Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown)
{
	if (StrEqual(sInfo, "berserk"))
	{
		if (g_hBerserkTimer[target] != INVALID_HANDLE)
		{
			CloseHandle(g_hBerserkTimer[target]);
			g_hBerserkTimer[target] = INVALID_HANDLE;
		}

		// Must account for lost points in the purchase itself for the min cost
		float fDuration = (PSAPI_GetPoints(target) + float(g_hBerserkMinCost.IntValue)) / GetConVarFloat(g_hBerserkCostPerSecond);

		if (fDuration > GetConVarFloat(g_hMaxBerserkDuration))
			fDuration = GetConVarFloat(g_hMaxBerserkDuration);

		DataPack DP;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (i == target)
				continue;

			if (!IsClientInGame(i))
				continue;

			else if (IsFakeClient(i))
				continue;

			PrintHintText(i, "%N berserked!!!\nThe berserk will last for %.1f seconds.", target, fDuration);
		}

		PrintHintText(target, "a");
		g_hBerserkTimer[target] = CreateDataTimer(0.1, Timer_CheckBerserk, DP, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

		DP.WriteFloat(GetGameTime());
		DP.WriteFloat(GetGameTime() + fDuration);
		DP.WriteCell(target);

		g_hTickBerserkTimer[target] = CreateTimer(0.5, Timer_TickBerserk, target, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

		TriggerTimer(g_hTickBerserkTimer[target], true);

		PSAPI_FullHeal(target);
		L4D2_UseAdrenaline(target, fDuration);

		L4D_RemoveAllWeapons(target);

		int iWeapon = GivePlayerItem(target, "weapon_shotgun_spas");

		L4D2_SetWeaponUpgrades(iWeapon, L4D2_WEPUPGFLAG_INCENDIARY);
		L4D2_SetWeaponUpgradeAmmoCount(iWeapon, 9999);

		L4D_OnITExpired(target);

		float fTargetOrigin[3];
		GetEntPropVector(target, Prop_Data, "m_vecOrigin", fTargetOrigin);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (i == target)
				continue;

			if (!IsClientInGame(i))
				continue;

			else if (!IsPlayerAlive(i))
				continue;

			float fOrigin[3];
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", fOrigin);

			if (GetVectorDistance(fOrigin, fTargetOrigin, false) < 512.0)
			{
				if (GetClientTeam(i) == GetClientTeam(target))
					SDKHooks_TakeDamage(i, i, i, 1000.0, DMG_BURN, -1, NULL_VECTOR, NULL_VECTOR, false);

				else
					SDKHooks_TakeDamage(i, target, target, 1000.0, DMG_BURN, -1, NULL_VECTOR, NULL_VECTOR, false);
			}
		}
	}

	return Plugin_Continue;
}

public Action Timer_CheckBerserk(Handle hTimer, DataPack DP)
{
	DP.Reset();

	float fStartTime = DP.ReadFloat();
	float fEndTime   = DP.ReadFloat();
	int   target     = DP.ReadCell();

	int iWeapon = GetPlayerWeaponSlot(target, view_as<int>(L4DWeaponSlot_Primary));

	L4D2_SetWeaponUpgrades(iWeapon, L4D2_WEPUPGFLAG_INCENDIARY);
	L4D2_SetWeaponUpgradeAmmoCount(iWeapon, 9999);

	L4D2Direct_SetNextShoveTime(target, 0.0);

	if (GetGameTime() > fStartTime + 0.5 && GetGameTime() < fEndTime)
	{
		char sText[2048];
		Format(sText, sizeof(sText), "Berserk ends in %.1f seconds!!!", fEndTime - GetGameTime());

		PrintHintText(target, sText);

		return Plugin_Continue;
	}
	else if (GetGameTime() >= fEndTime)
	{
		g_hBerserkTimer[target] = INVALID_HANDLE;

		PSAPI_SetPoints(target, 0.0);

		L4D_RemoveAllWeapons(target);

		L4D2_SetEntityGlow(target, L4D2Glow_None, 0, 0, { 0, 0, 0 }, false);
		L4D2_SetPlayerSurvivorGlowState(target, true);

		TeleportEntity(target, view_as<float>({ 32000, 32000, 32000 }), NULL_VECTOR, NULL_VECTOR);
		SetEntProp(target, Prop_Send, "m_isFallingFromLedge", 1);    // Makes his body impossible to defib.

		ForcePlayerSuicide(target);

		L4D_State_Transition(target, STATE_DEATH_WAIT_FOR_KEY);

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

// Timer_CheckBerserk is also used as a faster ticker.
public Action Timer_TickBerserk(Handle hTimer, int target)
{
	if (g_hBerserkTimer[target] == INVALID_HANDLE || !IsPlayerAlive(target))
	{
		L4D2_SetEntityGlow(target, L4D2Glow_None, 0, 0, { 0, 0, 0 }, false);
		L4D2_SetPlayerSurvivorGlowState(target, true);

		return Plugin_Stop;
	}

	int iPinner = 0;
	int bFound = false;

	while ((iPinner = L4D_BruteGetPinnedInfected(target, iPinner)) != 0)
	{
		SDKHooks_TakeDamage(iPinner, target, target, 65535.0, DMG_BURN);
		SDKHooks_TakeDamage(iPinner, target, target, 65535.0, DMG_BULLET);
		SDKHooks_TakeDamage(iPinner, target, target, 65535.0, DMG_GENERIC);

		ForcePlayerSuicide(iPinner);

		bFound = true;
	}

	if(bFound)
	{
		char TempFormat[128];
		FormatEx(TempFormat, sizeof(TempFormat), "GetPlayerFromUserID(%i).SetModel(GetPlayerFromUserID(%i).GetModelName())", GetClientUserId(target), GetClientUserId(target));
		L4D2_ExecVScriptCode(TempFormat);
	}

	PSAPI_FullHeal(target);

	L4D_RemoveWeaponSlot(target, L4DWeaponSlot_Secondary);
	L4D_RemoveWeaponSlot(target, L4DWeaponSlot_Grenade);
	L4D_RemoveWeaponSlot(target, L4DWeaponSlot_FirstAid);

	L4D2_SetEntityGlow(target, L4D2Glow_Constant, 4096, 22, { 255, 0, 0 }, true);
	L4D2_SetPlayerSurvivorGlowState(target, false);

	int iWeapon = GetPlayerWeaponSlot(target, view_as<int>(L4DWeaponSlot_Primary));

	PSAPI_SetPoints(target, 0.0);

	if (iWeapon == -1)
		iWeapon = GivePlayerItem(target, "weapon_shotgun_spas");

	char sClassname[64];
	GetEdictClassname(iWeapon, sClassname, sizeof(sClassname));

	if (!StrEqual(sClassname, "weapon_shotgun_spas"))
	{
		L4D_RemoveAllWeapons(target);

		iWeapon = GivePlayerItem(target, "weapon_shotgun_spas");
	}

	L4D2_SetWeaponUpgrades(iWeapon, L4D2_WEPUPGFLAG_INCENDIARY);
	L4D2_SetWeaponUpgradeAmmoCount(iWeapon, 9999);

	float fTargetOrigin[3];

	GetEntPropVector(target, Prop_Data, "m_vecOrigin", fTargetOrigin);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == target)
			continue;

		else if (!IsClientInGame(i))
			continue;

		else if (!IsPlayerAlive(i))
			continue;

		float fOrigin[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", fOrigin);

		if (GetVectorDistance(fOrigin, fTargetOrigin, false) < 512.0)
		{
			// Linear formula. 256.0 distance = 0.025% damage.
			float fDamage = (GetVectorDistance(fOrigin, fTargetOrigin, false) / 512.0) * float(GetEntityMaxHealth(i)) * 0.05;

			if (GetClientTeam(i) == GetClientTeam(target))
				SDKHooks_TakeDamage(i, i, i, fDamage, DMG_BURN, -1, NULL_VECTOR, NULL_VECTOR, false);

			else    // We need to make the 100 damage also decrease along with the radius
				SDKHooks_TakeDamage(i, target, target, fDamage + ((GetVectorDistance(fOrigin, fTargetOrigin, false) / 512.0) * 100.0), DMG_BURN, -1, NULL_VECTOR, NULL_VECTOR, false);
		}
	}

	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "infected")) != -1)
	{
		float fOrigin[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOrigin);

		if (GetVectorDistance(fOrigin, fTargetOrigin, false) < 512.0)
		{
			SDKHooks_TakeDamage(iEntity, target, target, 65535.0, DMG_BURN);
			SDKHooks_TakeDamage(iEntity, target, target, 65535.0, DMG_BULLET);
			SDKHooks_TakeDamage(iEntity, target, target, 65535.0, DMG_GENERIC);
		}
	}

	iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "witch")) != -1)
	{
		float fOrigin[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOrigin);

		if (GetVectorDistance(fOrigin, fTargetOrigin, false) < 512.0)
		{
			SDKHooks_TakeDamage(iEntity, target, target, 65535.0, DMG_BURN);
			SDKHooks_TakeDamage(iEntity, target, target, 65535.0, DMG_BULLET);
			SDKHooks_TakeDamage(iEntity, target, target, 65535.0, DMG_GENERIC);
		}
	}

	iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "weapon_gascan")) != -1)
	{
		float fOrigin[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOrigin);

		if (GetVectorDistance(fOrigin, fTargetOrigin, false) < 512.0)
		{
			AcceptEntityInput(iEntity, "Ignite", target, target);
		}
	}

	iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "prop_physics*")) != -1)
	{
		float fOrigin[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOrigin);

		if (GetVectorDistance(fOrigin, fTargetOrigin, false) < 512.0 && GetEntProp(iEntity, Prop_Send, "m_hasTankGlow"))
		{
			AcceptEntityInput(iEntity, "Kill");
		}
	}

	iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "prop_car_alarm")) != -1)
	{
		float fOrigin[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOrigin);

		if (GetVectorDistance(fOrigin, fTargetOrigin, false) < 512.0)
		{
			AcceptEntityInput(iEntity, "Kill");
		}
	}

	PSAPI_FullHeal(target);

	return Plugin_Continue;
}

public void CreateProducts()
{
	// Prevents fail state of plugin.
	if(!LibraryExists("PointSystemAPI"))
		return;
		
	if (GetConVarInt(g_hBerserkCostPerSecond) < 0.0)
		PSAPI_CreateProduct(-1, -1.0, "Berserk ( Last Chance )", NO_DESCRIPTION, "berserk", "berserk", 0.0, 0.0, BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_ONLY_PINNED | BUYFLAG_PINNED | BUYFLAG_ONLY_INCAP | BUYFLAG_INCAP);

	else
	{
		PSAPI_CreateProduct(-1, float(g_hBerserkMinCost.IntValue), "Berserk ( Last Chance )", NO_DESCRIPTION, "lc berserk last lastchance chance", "berserk", 0.0, 0.0, BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_ONLY_PINNED | BUYFLAG_PINNED | BUYFLAG_ONLY_INCAP | BUYFLAG_INCAP);
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
stock int GetEntityMaxHealth(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iMaxHealth");
}

stock void HealEntity(int entity, int amount)
{
	SetEntityHealth(entity, GetEntityHealth(entity) + amount);

	if (GetEntityHealth(entity) > GetEntityMaxHealth(entity))
		SetEntityHealth(entity, GetEntityMaxHealth(entity));
}

stock bool IsPlayer(int client)
{
	if (client == 0)
		return false;

	else if (client > MaxClients)
		return false;

	return true;
}

stock int L4D_BruteGetPinnedInfected(int victim, int startEnt = 0)
{
	for (int i = startEnt + 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (!IsPlayerAlive(i))
			continue;

		else if (L4D_GetClientTeam(i) != L4DTeam_Infected)
			continue;

		if (L4D_GetVictimHunter(i) == victim || L4D_GetVictimSmoker(i) == victim || L4D_GetVictimCharger(i) == victim || L4D_GetVictimCarry(i) == victim || L4D_GetVictimJockey(i) == victim)
			return i;
	}

	return 0;
}