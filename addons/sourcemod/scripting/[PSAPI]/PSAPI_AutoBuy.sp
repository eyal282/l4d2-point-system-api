#include <ps_api>
#include <sdktools>
#include <sourcemod>
#include <clientprefs>

#pragma newdecls required

public Plugin myinfo =
{
	name        = "PS Auto Buy",
	author      = "Eyal282",
	description = "Automatically buys items if you want to.",
	version     = "1.0",
	url         = "<- URL ->"


}

Handle settings;

bool abFHeal[MAXPLAYERS + 1], abExAmmo[MAXPLAYERS + 1], abAdrenaline[MAXPLAYERS + 1], abKit[MAXPLAYERS + 1], abBerserk[MAXPLAYERS + 1];

Handle AutoBuyDelay = INVALID_HANDLE;

public void OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncap);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("weapon_given", Event_WeaponGiven);
	HookEvent("pills_used", Event_MedicineUsed);
	HookEvent("adrenaline_used", Event_MedicineUsed);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("choke_end", Event_TrapEnd);
	HookEvent("pounce_end", Event_TrapEnd);
	HookEvent("charger_pummel_end", Event_TrapEnd);
	HookEvent("charger_carry_end", Event_TrapEnd);
	HookEvent("heal_success", Event_HealSuccess);

	AutoBuyDelay = CreateConVar("ps_autobuy_delay", "1.5", "The delay between each automatic purchase when it's needed.");

	RegConsoleCmd("sm_autobuy", Command_AutoBuy, "Opens the menu to allow automatically buying items as a survivor");
	RegConsoleCmd("sm_ab", Command_AutoBuy, "Opens the menu to allow automatically buying items as a survivor");

	settings = RegClientCookie("autobuy_settings", "Every !autobuy setting seperated by space", CookieAccess_Public);

	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		else if(!AreClientCookiesCached(i))
			continue;

		OnClientCookiesCached(i);
	}
}

public void OnClientConnected(int client)
{
	abFHeal[client]      = false;
	abExAmmo[client]     = false;
	abAdrenaline[client] = false;
	abKit[client]        = false;
	abBerserk[client]    = false;
}

public Action Command_AutoBuy(int client, int args)
{
	Create_AutoBuyMenu(client);

	return Plugin_Handled;
}

void Create_AutoBuyMenu(int client)
{
	char   TempFormat[100];
	Handle hMenu = CreateMenu(AutoBuy_MenuHandler);

	Format(TempFormat, sizeof(TempFormat), "Auto Full Heal: %s", abFHeal[client] ? "ON" : "OFF");
	AddMenuItem(hMenu, "", TempFormat);

	Format(TempFormat, sizeof(TempFormat), "Auto Explosive Ammo: %s", abExAmmo[client] ? "ON" : "OFF");
	AddMenuItem(hMenu, "", TempFormat);

	Format(TempFormat, sizeof(TempFormat), "Auto Adrenaline: %s", abAdrenaline[client] ? "ON" : "OFF");
	AddMenuItem(hMenu, "", TempFormat);

	Format(TempFormat, sizeof(TempFormat), "Auto First-Aid Kit: %s", abKit[client] ? "ON" : "OFF");
	AddMenuItem(hMenu, "", TempFormat);

	float fCost = PSAPI_FetchProductCostByAlias("berserk", client, client);

	if (fCost >= 0.0)
	{
		Format(TempFormat, sizeof(TempFormat), "Auto Berserk: %s", abBerserk[client] ? "ON" : "OFF");
		AddMenuItem(hMenu, "", TempFormat);
	}
	SetMenuTitle(hMenu, "Choose which items to automatically buy when available:");
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int AutoBuy_MenuHandler(Handle hMenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
		CloseHandle(hMenu);

	else if (action == MenuAction_Select)
	{
		switch (item)
		{
			case 0: abFHeal[client] = !abFHeal[client];
			case 1: abExAmmo[client] = !abExAmmo[client];
			case 2: abAdrenaline[client] = !abAdrenaline[client];
			case 3: abKit[client] = !abKit[client];
			case 4: abBerserk[client] = !abBerserk[client];
		}

		SetSettings(client);

		Create_AutoBuyMenu(client);
	}

	hMenu = INVALID_HANDLE;

	return 0;
}

public Action Event_PlayerHurt(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (client == 0)
		return Plugin_Continue;

	else if (!abBerserk[client])
		return Plugin_Continue;

	if (PSAPI_CanProductBeBought("berserk", client, client))
		FakeClientCommand(client, "sm_buy berserk");

	return Plugin_Continue;
}

public Action Event_PlayerIncap(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int userid = GetEventInt(hEvent, "userid");

	int client = GetClientOfUserId(userid);

	CreateTimer(GetConVarFloat(AutoBuyDelay) + 0.1, PurchaseAdren, userid);    // In case the guy has insufficient points for fheal but has enough for adrenaline...

	if (!abFHeal[client])
		return Plugin_Continue;

	else if (!IsClientTrapped(client) && GetClientTeam(client) == 2 && !IsFakeClient(client))
	{
		float fCost = PSAPI_FetchProductCostByAlias("heal", client, client);

		if (PSAPI_GetPoints(client) >= fCost && fCost > 0.0)
		{
			CreateTimer(GetConVarFloat(AutoBuyDelay), PurchaseFHeal, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Continue;
}

public Action Event_WeaponFire(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int userid = GetEventInt(hEvent, "userid");
	int client = GetClientOfUserId(userid);

	if (!abExAmmo[client])
		return Plugin_Continue;

	else if (IsFakeClient(client))
		return Plugin_Continue;

	else if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	char WeaponName[30];
	GetEventString(hEvent, "weapon", WeaponName, sizeof(WeaponName));

	if (StrEqual(WeaponName, "weapon_grenade_launcher", true))
		return Plugin_Continue;

	int weaponid = GetPlayerWeaponSlot(client, 0);

	if (!IsValidEdict(weaponid))
		return Plugin_Continue;

	int uammocount = GetEntProp(weaponid, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
	if (uammocount == 0)
	{
		CreateTimer(GetConVarFloat(AutoBuyDelay), TimerExAmmo, userid, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action TimerExAmmo(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!client || !IsClientInGame(client))
		return Plugin_Continue;

	else if (!abExAmmo[client])
		return Plugin_Continue;

	else if (IsFakeClient(client))
		return Plugin_Continue;

	else if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	int weaponid = GetPlayerWeaponSlot(client, 0);

	if (!IsValidEdict(weaponid))
		return Plugin_Continue;

	int uammocount = GetEntProp(weaponid, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);

	float fCost = PSAPI_FetchProductCostByAlias("exammo", client, client);

	if (uammocount == 0 && PSAPI_GetPoints(client) >= fCost && fCost > 0.0)
		FakeClientCommand(client, "sm_buy exammo");

	return Plugin_Continue;
}

public Action Event_WeaponGiven(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int userid = GetEventInt(hEvent, "giver");
	int client = GetClientOfUserId(userid);

	if (IsFakeClient(client))
		return Plugin_Continue;

	int recipient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (recipient == 0)
		return Plugin_Continue;

	int weaponid = GetEventInt(hEvent, "weaponentid");

	if (!IsValidEntity(weaponid))
		return Plugin_Continue;

	char Classname[50];
	GetEdictClassname(weaponid, Classname, sizeof(Classname));

	if (!StrEqual(Classname, "weapon_adrenaline") && !StrEqual(Classname, "weapon_pain_pills"))
		return Plugin_Continue;

	float fCost = PSAPI_FetchProductCostByAlias("adren", client, client);

	if (abAdrenaline[client] && PSAPI_GetPoints(client) >= fCost && fCost > 0.0)
		CreateTimer(GetConVarFloat(AutoBuyDelay) + 0.1, PurchaseAdren, userid, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action Event_MedicineUsed(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int userid = GetEventInt(hEvent, "userid");
	int client = GetClientOfUserId(userid);

	if (IsFakeClient(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;

	float fCost = PSAPI_FetchProductCostByAlias("adren", client, client);
	if (abAdrenaline[client] && PSAPI_GetPoints(client) >= fCost && fCost > 0.0)
		CreateTimer(GetConVarFloat(AutoBuyDelay) + 0.1, PurchaseAdren, userid, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action Event_ReviveSuccess(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int userid = GetEventInt(hEvent, "subject");

	int client = GetClientOfUserId(userid);

	if (IsFakeClient(client))
		return Plugin_Continue;

	float fCost = PSAPI_FetchProductCostByAlias("adren", client, client);
	if (abAdrenaline[client] && PSAPI_GetPoints(client) >= fCost && fCost > 0.0)
	{
		CreateTimer(GetConVarFloat(AutoBuyDelay) + 0.1, PurchaseAdren, userid, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action Event_TrapEnd(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int userid = GetEventInt(hEvent, "victim");

	int client = GetClientOfUserId(userid);

	if (!abFHeal[client])
		return Plugin_Continue;

	else if (IsFakeClient(client))
		return Plugin_Continue;

	else if (GetClientTeam(client) != 2 || !IsPlayerAlive(client))    // Don't ask, just making sure.
		return Plugin_Continue;

	if (GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0)
	{
		CreateTimer(GetConVarFloat(AutoBuyDelay), PurchaseFHeal, userid, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action Event_HealSuccess(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int client  = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int subject = GetClientOfUserId(GetEventInt(hEvent, "subject"));

	if (client != 0)
	{
		int userid = GetClientUserId(client);
		CreateTimer(GetConVarFloat(AutoBuyDelay), PurchaseKit, userid, TIMER_FLAG_NO_MAPCHANGE);
	}

	else if (subject != 0)
	{
		int subject_userid = GetClientUserId(subject);
		CreateTimer(GetConVarFloat(AutoBuyDelay), PurchaseKit, subject_userid, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action PurchaseKit(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!client || !IsClientInGame(client))
		return Plugin_Continue;

	else if (IsFakeClient(client))
		return Plugin_Continue;

	float fCost = PSAPI_FetchProductCostByAlias("kit", client, client);

	int KitSlot = GetPlayerWeaponSlot(client, 3);

	bool hasKit = true;

	if (!IsValidEdict(KitSlot))
		hasKit = false;

	if (hasKit)    // If hasKit is false, KitSlot is an invalid edict and getting it's classname will throw an evil error.
	{
		char Classname[50];
		GetEntityClassname(KitSlot, Classname, sizeof(Classname));

		if (!StrEqual(Classname, "weapon_first_aid_kit"))
			hasKit = false;
	}
	if (!hasKit && abKit[client] && PSAPI_GetPoints(client) >= fCost && fCost > 0.0 && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		FakeClientCommand(client, "sm_buy kit");
	}

	return Plugin_Continue;
}

public Action PurchaseAdren(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!client || !IsClientInGame(client))
		return Plugin_Continue;

	else if (IsFakeClient(client))
		return Plugin_Continue;

	float fCost = PSAPI_FetchProductCostByAlias("adren", client, client);

	int AdrenSlot = GetPlayerWeaponSlot(client, 4);

	bool hasAdren = true;

	if (!IsValidEdict(AdrenSlot))
		hasAdren = false;

	if (hasAdren)    // If hasAdren is false, AdrenSlot is an invalid edict and getting it's classname will throw an evil error.
	{
		char Classname[50];
		GetEntityClassname(AdrenSlot, Classname, sizeof(Classname));

		if (!StrEqual(Classname, "weapon_adrenaline"))
			hasAdren = false;
	}
	if (!hasAdren && abAdrenaline[client] && PSAPI_GetPoints(client) >= fCost && fCost > 0.0 && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		FakeClientCommand(client, "sm_buy adren");
	}

	return Plugin_Continue;
}

public Action PurchaseFHeal(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!client || !IsClientInGame(client))
		return Plugin_Continue;

	else if (IsFakeClient(client))
		return Plugin_Continue;

	float fCost = PSAPI_FetchProductCostByAlias("heal", client, client);

	if (abFHeal[client] && PSAPI_GetPoints(client) >= fCost && fCost > 0.0 && IsPlayerAlive(client) && GetClientTeam(client) == 2 && GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0)
	{
		FakeClientCommand(client, "sm_buy heal");
	}

	return Plugin_Continue;
}
// This excludes Joe Key
stock bool IsClientTrapped(int client)
{
	if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") != -1 || GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") != -1 || GetEntPropEnt(client, Prop_Send, "m_carryAttacker") != -1 || GetEntPropEnt(client, Prop_Send, "m_tongueOwner") != -1)
		return true;

	return false;
}

public void OnClientCookiesCached(int client)
{
	RestoreSettings(client);
}


stock void SetSettings(int client)
{
	char sValue[64];
	FormatEx(sValue, sizeof(sValue), "%i %i %i %i %i", abFHeal[client], abExAmmo[client], abAdrenaline[client], abKit[client], abBerserk[client])
	SetClientCookie(client, settings, sValue);

	RestoreSettings(client);
}

stock void RestoreSettings(int client)
{
	char sValue[64];
	GetClientCookie(client, settings, sValue, sizeof(sValue));

	if(sValue[0] == EOS)
	{
		SetClientCookie(client, settings, "0 1 1 0 0");

		RestoreSettings(client);

		return;
	}

	int i = 0;

	abFHeal[client] = strlen(sValue) > i && sValue[i] == '1'; i += 2;
	abExAmmo[client] = strlen(sValue) > i && sValue[i] == '1'; i += 2;
	abAdrenaline[client] = strlen(sValue) > i && sValue[i] == '1'; i += 2;
	abKit[client] = strlen(sValue) > i && sValue[i] == '1'; i += 2;
	abBerserk[client] = strlen(sValue) > i && sValue[i] == '1'; i += 2;
}