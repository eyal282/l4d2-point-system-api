#pragma semicolon 1
#include <ps_api>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#pragma newdecls required
#define PLUGIN_TITLE "Point System API"
float version = 1.0;

// Primitive constant. Feel free to make a better method. Derived from the fact acid stays for 5 seconds and deals 28/29 ticks of damage, so 28 / 5 = 5.6, therefore  1 / 5.6 = delay.
// But due to inaccuracies, I decrement slightly.
float SPIT_DELAY = 0.17;

ArrayList g_aCategories, g_aProducts, g_aDelayedProducts;

GlobalForward g_fwOnProductCreated;
GlobalForward g_fwOnCanBuyProducts;
GlobalForward g_fwOnGetParametersCategory;
GlobalForward g_fwOnGetParametersProduct;
GlobalForward g_fwOnTryBuyProduct;
GlobalForward g_fwOnRealTimeRefundProduct;
GlobalForward g_fwOnBuyProductPost;
GlobalForward g_fwOnShouldGiveProduct;    // We should now give the product to the user, because the delay has passed and not refunded.

char  g_error[256];
int   g_errorPriority;
float g_fPoints[MAXPLAYERS + 1] = { 0.0, ... };
float g_fSavedSurvivorPoints[MAXPLAYERS + 1], g_fSavedInfectedPoints[MAXPLAYERS + 1] = { 0.0, ... };

// MultipleDamageStack is not attack count, it's point count accumulated.
int   MultipleDamageStack[MAXPLAYERS + 1];
float NextMultipleDamage[MAXPLAYERS + 1];

// SpitterDamageStack is seconds of damage.
float SpitterDamageStack[MAXPLAYERS + 1];
float NextSpitterDamage[MAXPLAYERS + 1];

char g_sLastBoughtAlias[MAXPLAYERS + 1][32];
char g_sLastBoughtTargetArg[MAXPLAYERS + 1][64];

char MapName[30];
int  hurtcount[MAXPLAYERS + 1]     = { 0, ... };
int  protectcount[MAXPLAYERS + 1]  = { 0, ... };
int  tankburning[MAXPLAYERS + 1]   = { 0, ... };
int  tankbiled[MAXPLAYERS + 1]     = { 0, ... };
int  witchburning[MAXPLAYERS + 1]  = { 0, ... };
int  killcount[MAXPLAYERS + 1]     = { 0, ... };
int  headshotcount[MAXPLAYERS + 1] = { 0, ... };
// Definitions to save space
#define ATTACKER int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
#define CLIENT   int client = GetClientOfUserId(GetEventInt(event, "userid"));
#define ACHECK2  if (attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define CCHECK2  if (client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define ACHECK3  if (attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define CCHECK3  if (client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 3 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
// Other
Handle Enable             = INVALID_HANDLE;
Handle Modes              = INVALID_HANDLE;
Handle Notifications      = INVALID_HANDLE;
// Item buyables
/*

Handle PointsHeal = INVALID_HANDLE;
*/
// Survivor point earning things
Handle SValueKillingSpree = INVALID_HANDLE;
Handle SNumberKill        = INVALID_HANDLE;
Handle SValueHeadSpree    = INVALID_HANDLE;
Handle SNumberHead        = INVALID_HANDLE;
Handle SSIKill            = INVALID_HANDLE;
Handle STankKill          = INVALID_HANDLE;
Handle SWitchKill         = INVALID_HANDLE;
Handle SWitchCrown        = INVALID_HANDLE;
Handle SHeal              = INVALID_HANDLE;
Handle SHealWarning       = INVALID_HANDLE;
Handle SProtect           = INVALID_HANDLE;
Handle SRevive            = INVALID_HANDLE;
Handle SLedge             = INVALID_HANDLE;
Handle SDefib             = INVALID_HANDLE;
Handle STBurn             = INVALID_HANDLE;
Handle STSolo             = INVALID_HANDLE;
Handle SWBurn             = INVALID_HANDLE;
Handle STag               = INVALID_HANDLE;
// Infected point earning things
Handle IChoke             = INVALID_HANDLE;
Handle IPounce            = INVALID_HANDLE;
Handle ICarry             = INVALID_HANDLE;
Handle IImpact            = INVALID_HANDLE;
Handle IRide              = INVALID_HANDLE;
Handle ITag               = INVALID_HANDLE;
Handle IIncap             = INVALID_HANDLE;
Handle IHurt              = INVALID_HANDLE;
Handle ISpit              = INVALID_HANDLE;
Handle IKill              = INVALID_HANDLE;
Handle IKarma             = INVALID_HANDLE;

Handle ResetPoints = INVALID_HANDLE;
Handle StartPoints = INVALID_HANDLE;
Handle DeadBuy     = INVALID_HANDLE;

public Plugin myinfo =
{
	name        = "[L4D2] Points System API",
	author      = "Eyal282 [Complete remake of McFlurry's script]",
	description = "Points system to buy products on the fly.",
	version     = PLUGIN_TITLE,
	url         = "N/A"

};

// While this is fired after OnPluginStart, everybody should see sm_b is created when they CTRL + F "OnPluginStart"
public void OnAllPluginsLoaded()
{
	if (!CommandExists("sm_b"))
		RegConsoleCmd("sm_b", BuyMenu);
}

public void OnPluginEnd()
{
	RemoveServerTag2("buy");
	RemoveServerTag2("psapi");
	RemoveServerTag2("!buy");
}

public void OnPluginStart()
{
	AddServerTag2("buy");
	AddServerTag2("psapi");
	AddServerTag2("!buy");

	g_aCategories      = new ArrayList(sizeof(enCategory));
	g_aProducts        = new ArrayList(sizeof(enProduct));
	g_aDelayedProducts = new ArrayList(sizeof(enDelayedProduct));

	g_fwOnProductCreated = CreateGlobalForward("PointSystemAPI_OnProductCreated", ET_Event, Param_Array);

	g_fwOnCanBuyProducts = CreateGlobalForward("PointSystemAPI_OnCanBuyProducts", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell);

	g_fwOnGetParametersCategory = CreateGlobalForward("PointSystemAPI_OnGetParametersCategory", ET_Event, Param_Cell, Param_String, Param_String);

	g_fwOnGetParametersProduct = CreateGlobalForward("PointSystemAPI_OnGetParametersProduct", ET_Ignore, Param_Cell, Param_String, Param_String, Param_String, Param_String, Param_Cell, Param_CellByRef, Param_FloatByRef, Param_FloatByRef);

	g_fwOnTryBuyProduct = CreateGlobalForward("PointSystemAPI_OnTryBuyProduct", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_String, Param_Cell);

	g_fwOnBuyProductPost = CreateGlobalForward("PointSystemAPI_OnBuyProductPost", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Float, Param_Float);

	g_fwOnRealTimeRefundProduct = CreateGlobalForward("PointSystemAPI_OnRealTimeRefundProduct", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Float);

	g_fwOnShouldGiveProduct = CreateGlobalForward("PointSystemAPI_OnShouldGiveProduct", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Float, Param_Float);

	char game_name[128];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("This plugin only supports Left 4 Dead 2");
	}
	LoadTranslations("common.phrases");

	AutoExecConfig_SetFile("PointSystemAPI");

	StartPoints        = AutoExecConfig_CreateConVar("l4d2_points_start", "0", "Points to start each round/map with.");
	DeadBuy            = AutoExecConfig_CreateConVar("l4d2_points_dead_buy", "1", "0 - You can't buy products as a dead survivor. 1 - You cannot buy products for other survivors as a dead survivor. 2 - You can buy products as a dead survivor.");
	Notifications      = AutoExecConfig_CreateConVar("l4d2_points_notify", "1", "Show messages when points are earned?");
	Enable             = AutoExecConfig_CreateConVar("l4d2_points_enable", "1", "Enable Point System?");
	Modes              = AutoExecConfig_CreateConVar("l4d2_points_modes", "coop,realism,versus,teamversus", "Which game modes to use Point System");
	ResetPoints        = AutoExecConfig_CreateConVar("l4d2_points_reset_mapchange", "versus,teamversus", "Which game modes to reset point count on round end and round start");
	SValueKillingSpree = AutoExecConfig_CreateConVar("l4d2_points_cikill_value", "2", "How many points does killing a certain amount of infected earn");
	SNumberKill        = AutoExecConfig_CreateConVar("l4d2_points_cikills", "25", "How many kills you need to earn a killing spree bounty");
	SValueHeadSpree    = AutoExecConfig_CreateConVar("l4d2_points_headshots_value", "4", "How many points does killing a certain amount of infected with headshots earn");
	SNumberHead        = AutoExecConfig_CreateConVar("l4d2_points_headshots", "20", "How many kills you need to earn a killing spree bounty");
	SSIKill            = AutoExecConfig_CreateConVar("l4d2_points_sikill", "1", "How many points does killing a special infected earn");
	STankKill          = AutoExecConfig_CreateConVar("l4d2_points_tankkill", "2", "How many points does killing a tank earn");
	SWitchKill         = AutoExecConfig_CreateConVar("l4d2_points_witchkill", "4", "How many points does killing a witch earn");
	SWitchCrown        = AutoExecConfig_CreateConVar("l4d2_points_witchcrown", "2", "How many points does crowning a witch earn");
	SHeal              = AutoExecConfig_CreateConVar("l4d2_points_heal", "5", "How many points does healing a team mate earn");
	SProtect           = AutoExecConfig_CreateConVar("l4d2_points_protect", "1", "How many points does protecting a team mate earn");
	SHealWarning       = AutoExecConfig_CreateConVar("l4d2_points_heal_warning", "1", "How many points does healing a team mate who did not need healing earn");
	SRevive            = AutoExecConfig_CreateConVar("l4d2_points_revive", "3", "How many points does reviving a team mate earn");
	SLedge             = AutoExecConfig_CreateConVar("l4d2_points_ledge", "1", "How many points does reviving a hanging team mate earn");
	SDefib             = AutoExecConfig_CreateConVar("l4d2_points_defib_action", "5", "How many points does defibbing a team mate earn");
	STBurn             = AutoExecConfig_CreateConVar("l4d2_points_tankburn", "2", "How many points does burning a tank earn");
	STSolo             = AutoExecConfig_CreateConVar("l4d2_points_tanksolo", "8", "How many points does killing a tank single-handedly earn");
	SWBurn             = AutoExecConfig_CreateConVar("l4d2_points_witchburn", "1", "How many points does burning a witch earn");
	STag               = AutoExecConfig_CreateConVar("l4d2_points_bile_tank", "2", "How many points does biling a tank earn");
	IChoke             = AutoExecConfig_CreateConVar("l4d2_points_smoke", "2", "How many points does smoking a survivor earn");
	IPounce            = AutoExecConfig_CreateConVar("l4d2_points_pounce", "1", "How many points does pouncing a survivor earn");
	ICarry             = AutoExecConfig_CreateConVar("l4d2_points_charge", "2", "How many points does charging a survivor earn");
	IImpact            = AutoExecConfig_CreateConVar("l4d2_points_impact", "1", "How many points does impacting a survivor earn");
	IRide              = AutoExecConfig_CreateConVar("l4d2_points_ride", "2", "How many points does riding a survivor earn");
	ITag               = AutoExecConfig_CreateConVar("l4d2_points_boom", "1", "How many points does booming a survivor earn");
	IIncap             = AutoExecConfig_CreateConVar("l4d2_points_incap", "3", "How many points does incapping a survivor earn");
	IHurt              = AutoExecConfig_CreateConVar("l4d2_points_damage", "2", "How many points does doing damage earn");
	ISpit              = AutoExecConfig_CreateConVar("l4d2_points_spit", "1.0", "Points gained per second of standing on spit. If set to 0, spitter uses multiple damage.");
	IKill              = AutoExecConfig_CreateConVar("l4d2_points_kill", "5", "How many points does killing a survivor earn");
	IKarma             = AutoExecConfig_CreateConVar("l4d2_points_karma", "5", "How many points does registering a karma event earn");

	// This makes an internal call to AutoExecConfig with the given configfile
	AutoExecConfig_ExecuteFile();

	// Cleaning should be done at the end
	AutoExecConfig_CleanFile();

	RegConsoleCmd("sm_ps", Command_PointSystem);
	RegConsoleCmd("sm_rebuy", Command_Rebuy);
	RegConsoleCmd("sm_shortcuts", Command_Aliases);
	RegConsoleCmd("sm_shortcut", Command_Aliases);
	RegConsoleCmd("sm_alias", Command_Aliases);
	RegConsoleCmd("sm_aliases", Command_Aliases);
	RegConsoleCmd("sm_buystuff", BuyMenu);
	RegConsoleCmd("sm_buy", BuyMenu);
	RegConsoleCmd("sm_usepoints", BuyMenu);
	RegConsoleCmd("sm_blist", Command_BuyList);
	RegConsoleCmd("sm_buylist", Command_BuyList);
	RegConsoleCmd("sm_points", ShowPoints);
	RegConsoleCmd("sm_teampoints", ShowTeamPoints);
	RegConsoleCmd("sm_send", Command_SendPoints, "sm_sendpoints <target> [amount/all]");
	RegConsoleCmd("sm_sendpoints", Command_SendPoints, "sm_sendpoints <target> [amount/all]");
	RegConsoleCmd("sm_sp", Command_SendPoints, "sm_sendpoints <target> [amount/all]");
	RegConsoleCmd("sm_splist", Command_SendPointsList, "sm_sendpointslist [amount/all]");
	RegAdminCmd("sm_heal", Command_Heal, ADMFLAG_SLAY, "sm_heal <target> [amount] - Won't reset incaps if you select amount.");
	RegAdminCmd("sm_incap", Command_Incap, ADMFLAG_SLAY, "sm_incap <target>");
	RegAdminCmd("sm_setincap", Command_SetIncap, ADMFLAG_SLAY, "sm_setincap <target> <amount left>");
	RegAdminCmd("sm_setincaps", Command_SetIncap, ADMFLAG_ROOT, "sm_setincap <target> <amount left>");
	RegAdminCmd("sm_givepoints", Command_Points, ADMFLAG_SLAY, "sm_givepoints <target> [amount]");
	RegAdminCmd("sm_setpoints", Command_SPoints, ADMFLAG_SLAY, "sm_setpoints <target> [amount]");
	RegAdminCmd("sm_exec", Command_Exec, ADMFLAG_SLAY, "sm_exec <target> <command>");
	RegAdminCmd("sm_fakeexec", Command_FakeExec, ADMFLAG_SLAY, "sm_fakeexec <target> <command>");
	HookEvent("infected_death", Event_Kill, EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_death", Event_Death);
	HookEvent("tank_killed", Event_TankDeath, EventHookMode_Pre);
	HookEvent("witch_killed", Event_WitchDeath);
	HookEvent("heal_success", Event_Heal);
	HookEvent("award_earned", Event_Protect);
	HookEvent("revive_success", Event_Revive);
	HookEvent("defibrillator_used", Event_Shock);
	HookEvent("choke_start", Event_Choke);
	HookEvent("player_now_it", Event_Boom);
	HookEvent("lunge_pounce", Event_Pounce);
	HookEvent("jockey_ride", Event_Ride);
	HookEvent("charger_carry_start", Event_Carry);
	HookEvent("charger_impact", Event_Impact);
	HookEvent("player_hurt", Event_Hurt);
	HookEvent("zombie_ignited", Event_Burn);
	HookEvent("round_end", Event_REnd);
	HookEvent("round_start", Event_RStart);
	HookEvent("finale_win", Event_Finale);
	HookEvent("player_team", Event_ChangeTeam, EventHookMode_Pre);
}

// return Plugin_Handled or above to prevent the user from buying anything.
public Action PointSystemAPI_OnCanBuyProducts(int buyer, int target)
{
	if (GetClientTeam(buyer) != view_as<int>(L4DTeam_Survivor))
		return Plugin_Continue;

	else if (IsPlayerAlive(buyer))
		return Plugin_Continue;

	switch (GetConVarInt(DeadBuy))
	{
		// Cannot buy as dead survivor
		case 0:
		{
			return PSAPI_SetErrorByPriority(50, "\x04[PS]\x03 Error: Buy menu cannot be accessed when you're dead!");
		}
		case 1:
		{
			if (buyer != target)
			{
				return PSAPI_SetErrorByPriority(50, "\x04[PS]\x03 Error: You can only buy products for yourself when dead!");
			}

			return Plugin_Continue;
		}
		default:
		{
			return Plugin_Continue;
		}
	}
}

public void L4D_OnServerHibernationUpdate(bool hibernating)
{
	if (!hibernating)
		RegPluginLibrary("PointSystemAPI");
}

/**
 * Description
 *
 * @param victim             Muse that was honored to model a karma event
 * @param attacker           Artist that crafted the karma event. The only way to check if attacker is valid is: if(attacker > 0)
 * @param KarmaName          Name of karma: "Charge", "Impact", "Jockey", "Slap", "Punch", "Smoke"
 * @param bBird              true if a bird charge event occured, false if a karma kill was detected or performed.
 * @param bKillConfirmed     Whether or not this indicates the complete death of the player. This is NOT just !IsPlayerAlive(victim)
 * @param bOnlyConfirmed     Whether or not only kill confirmed are allowed.

 * @noreturn
 * @note					This can be called more than once. One for the announcement, one for the kill confirmed.
                            If you want to reward both killconfirmed and killunconfirmed you should reward when killconfirmed is false.
                            If you want to reward if killconfirmed you should reward when killconfirmed is true.

 * @note					If the plugin makes a kill confirmed without a previous announcement without kill confirmed,
                            it compensates by sending two consecutive events, one without kill confirmed, one with kill confirmed.



 */
public void KarmaKillSystem_OnKarmaEventPost(int victim, int attacker, const char[] KarmaName, bool bBird, bool bKillConfirmed, bool bOnlyConfirmed)
{
	if (attacker <= 0)
		return;

	if ((bOnlyConfirmed && bKillConfirmed) || (!bOnlyConfirmed && !bKillConfirmed))
	{
		int Points = GetConVarInt(IKarma);

		g_fPoints[attacker] += float(Points);

		PrintToChat(attacker, "\x04[PS]\x01 %s %s'd!!! + \x05%d\x03 points (??: \x05%d\x03)", bBird ? "Bird" : "Karma", KarmaName, Points, GetClientPoints(attacker));
	}
}

public Action CheckMultipleDamage(Handle hTimer, any number)
{
	if (!L4D_HasAnySurvivorLeftSafeAreaStock())
		return Plugin_Continue;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i))
			continue;

		else if (!IsTeamInfected(i))
			continue;

		if (GetConVarBool(Notifications) && NextMultipleDamage[i] <= GetEngineTime() && MultipleDamageStack[i] != 0)
		{
			NextMultipleDamage[i] = GetEngineTime() + 10.0;
			PrintToChat(i, "\x04[PS]\x03 Multiple Damage + \x05%d\x03 points *\x05 %dx\x03 =\x05 %d\x03 (??: \x05%d\x03)", GetConVarInt(IHurt), MultipleDamageStack[i] / GetConVarInt(IHurt), MultipleDamageStack[i], GetClientPoints(i));
			MultipleDamageStack[i] = 0;
		}

		if (GetConVarBool(Notifications) && NextSpitterDamage[i] <= GetEngineTime() && SpitterDamageStack[i] >= 1.0 && RoundToFloor(GetConVarFloat(ISpit) * SpitterDamageStack[i]) > 0)
		{
			NextSpitterDamage[i] = GetEngineTime() + 10.0;
			PrintToChat(i, "\x04[PS]\x03 Acid Damage + \x05%d\x03 points *\x05 %.1fsec\x03 =\x05 %d\x03 (??: \x05%d\x03)", GetConVarInt(ISpit), SpitterDamageStack[i], RoundToFloor(GetConVarFloat(ISpit) * SpitterDamageStack[i]), GetClientPoints(i));
			SpitterDamageStack[i] = 0.0;
		}
	}

	return Plugin_Continue;
}

public void OnMapStart()
{
	CreateTimer(0.1, CheckMultipleDamage, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(1.0, Timer_Cleanup, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

	GetCurrentMap(MapName, sizeof(MapName));
}

public Action Timer_Cleanup(Handle hTimer)
{
	int iEntity = -1;

	while ((iEntity = FindEntityByTargetname(iEntity, "PointSystemAPI", false, true)) != -1)
	{
		if (!HasEntProp(iEntity, Prop_Data, "m_hOwnerEntity") || GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity") != -1)
			continue;

		char sTargetname[64];
		GetEntPropString(iEntity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

		ReplaceStringEx(sTargetname, sizeof(sTargetname), "PointSystemAPI ", "");

		int iSecondsLeft = StringToInt(sTargetname);

		if (iSecondsLeft <= 0)
		{
			AcceptEntityInput(iEntity, "Kill");
		}
		else
		{
			FormatEx(sTargetname, sizeof(sTargetname), "PointSystemAPI %i", iSecondsLeft - 1);

			SetEntPropString(iEntity, Prop_Data, "m_iName", sTargetname);
		}
	}

	return Plugin_Continue;
}

public void OnMapEnd()
{
	WipeAllInfected();
}

void WipeAllInfected()
{
	int MaxEntities = GetEntityCount();

	char Classname[11];
	for (int i = 0; i < MaxEntities; i++)
	{
		if (!IsValidEdict(i))
			continue;

		GetEdictClassname(i, Classname, sizeof(Classname));

		if (StrEqual(Classname, "infected", true))
			AcceptEntityInput(i, "Kill");
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("PSAPI_SetErrorByPriority", Native_SetErrorByPriority);
	CreateNative("PSAPI_CreateCategory", Native_CreateCategory);
	CreateNative("PSAPI_CreateProduct", Native_CreateProduct);
	CreateNative("PSAPI_FindCategoryByIdentifier", Native_FindCategory);
	CreateNative("PSAPI_CanProductBeBought", Native_CanProductBeBought);
	CreateNative("PSAPI_RefundProducts", Native_RefundProducts);
	CreateNative("PSAPI_FindProductByAlias", Native_FindProduct);
	CreateNative("PSAPI_FetchProductCostByAlias", Native_FetchProductCostByAlias);
	CreateNative("PSAPI_GetVersion", Native_GetVersion);
	CreateNative("PSAPI_SetPoints", Native_SetPoints);
	CreateNative("PSAPI_HardSetPoints", Native_HardSetPoints);
	CreateNative("PSAPI_GetPoints", Native_GetPoints);
	CreateNative("PSAPI_FullHeal", Native_FullHeal);

	RegPluginLibrary("PointSystemAPI");

	return APLRes_Success;
}

public any Native_SetErrorByPriority(Handle plugin, int numParams)
{
	int priority = GetNativeCell(1);

	if (priority >= g_errorPriority)
	{
		FormatNativeString(0, 2, 3, sizeof(g_error), _, g_error);

		g_errorPriority = priority;
	}
	return Plugin_Handled;
}

public any Native_CreateCategory(Handle plugin, int numParams)
{
	enCategory cat;

	cat.iCategory = GetNativeCell(1);
	GetNativeString(2, cat.sID, sizeof(enCategory::sID));
	GetNativeString(3, cat.sName, sizeof(enCategory::sName));
	cat.iBuyFlags = GetNativeCell(4);

	int iCategory = FindCategoryByIdentifier(cat.sID);

	if (iCategory == -1)
		return PushArrayArray(g_aCategories, cat);

	else
	{
		SetArrayArray(g_aCategories, iCategory, cat);
		return iCategory;
	}
}

public any Native_CreateProduct(Handle plugin, int numParams)
{
	enProduct product;

	product.iCategory = GetNativeCell(1);
	product.fCost     = float(RoundToFloor(GetNativeCell(2)));

	GetNativeString(3, product.sName, sizeof(enProduct::sName));
	GetNativeString(4, product.sDescription, sizeof(enProduct::sDescription));
	GetNativeString(5, product.sAliases, sizeof(enProduct::sAliases));
	GetNativeString(6, product.sInfo, sizeof(enProduct::sInfo));

	product.fDelay    = GetNativeCell(7);
	product.fCooldown = GetNativeCell(8);

	product.iBuyFlags = GetNativeCell(9);

	bool bNoHooks = GetNativeCell(10);

	DeleteProductsByAliases(product.sAliases);

	if (!bNoHooks)
	{
		Call_StartForward(g_fwOnProductCreated);

		Call_PushArrayEx(product, sizeof(enProduct), SM_PARAM_COPYBACK);

		Action result;
		Call_Finish(result);

		if (result >= Plugin_Handled)
			return false;
	}

	PushArrayArray(g_aProducts, product);

	return true;
}

public any Native_FindCategory(Handle plugin, int numParams)
{
	enCategory cat;

	char[] sID = new char[sizeof(enCategory::sID)];
	GetNativeString(1, sID, sizeof(enCategory::sID));

	int iCategory = FindCategoryByIdentifier(sID);

	if (iCategory == -1)
		return false;

	else
	{
		GetArrayArray(g_aCategories, iCategory, cat);

		SetNativeArray(2, cat, sizeof(enCategory));
		return true;
	}
}

public any Native_CanProductBeBought(Handle plugin, int numParams)
{
	enProduct product;

	char sAlias[32];
	GetNativeString(1, sAlias, sizeof(sAlias));

	int client       = GetNativeCell(2);
	int targetclient = GetNativeCell(3);

	if (LookupProductByAlias(sAlias, product) == -1)
		return false;

	Call_StartForward(g_fwOnCanBuyProducts);

	Call_PushCell(client);
	Call_PushCell(targetclient);

	Action result;
	Call_Finish(result);

	if (result >= Plugin_Handled)
		return false;

	bool bShouldReturn;
	char sError[1];

	if (PSAPI_GetErrorFromBuyflags(client, sAlias, product, targetclient, sError, sizeof(sError), bShouldReturn))
		return false;

	Call_StartForward(g_fwOnGetParametersProduct);

	enProduct alteredProduct;
	alteredProduct = product;

	Call_PushCell(client);
	Call_PushString(alteredProduct.sAliases);
	Call_PushStringEx(alteredProduct.sInfo, sizeof(enProduct::sInfo), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(alteredProduct.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(alteredProduct.sDescription, sizeof(enProduct::sDescription), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(targetclient);
	Call_PushCellRef(alteredProduct.fCost);
	Call_PushFloatRef(alteredProduct.fDelay);
	Call_PushFloatRef(alteredProduct.fCooldown);

	Call_Finish();

	alteredProduct.fCost = float(RoundToFloor(alteredProduct.fCost));

	if (g_fPoints[client] < alteredProduct.fCost)
		return false;

	Call_StartForward(g_fwOnTryBuyProduct);

	Call_PushCell(client);
	Call_PushString(alteredProduct.sInfo);
	Call_PushString(alteredProduct.sAliases);
	Call_PushString(alteredProduct.sName);
	Call_PushCell(targetclient);
	Call_PushCell(alteredProduct.fCost);
	Call_PushFloat(alteredProduct.fDelay);
	Call_PushFloat(alteredProduct.fCooldown);

	result = Plugin_Continue;
	Call_Finish(result);

	if (result >= Plugin_Handled)
		return false;

	if (alteredProduct.iBuyFlags & BUYFLAG_REALTIME_REFUNDS)
	{
		Call_StartForward(g_fwOnRealTimeRefundProduct);

		Call_PushCell(client);
		Call_PushString(alteredProduct.sInfo);
		Call_PushString(alteredProduct.sAliases);
		Call_PushString(alteredProduct.sName);
		Call_PushCell(targetclient);
		Call_PushCell(alteredProduct.fCost);
		Call_PushFloat(0.0);

		result = Plugin_Continue;
		Call_Finish(result);

		if (result >= Plugin_Handled)
			return false;
	}

	Call_StartForward(g_fwOnBuyProductPost);

	Call_PushCell(client);
	Call_PushString(alteredProduct.sInfo);
	Call_PushString(alteredProduct.sAliases);
	Call_PushString(alteredProduct.sName);
	Call_PushCell(targetclient);
	Call_PushCell(alteredProduct.fCost);
	Call_PushFloat(alteredProduct.fDelay);
	Call_PushFloat(alteredProduct.fCooldown);

	result = Plugin_Continue;
	Call_Finish(result);

	if (result >= Plugin_Handled)
		return false;

	return true;
}

public any Native_RefundProducts(Handle plugin, int numParams)
{
	char sAliases[1024];
	GetNativeString(1, sAliases, sizeof(sAliases));

	int client       = GetNativeCell(2);
	int targetclient = GetNativeCell(3);

	for (int i = 0; i < GetArraySize(g_aDelayedProducts); i++)
	{
		enDelayedProduct dProduct;

		GetArrayArray(g_aDelayedProducts, i, dProduct);

		int buyer      = GetClientOfUserId(dProduct.buyerUserId);
		int targetUser = GetClientOfUserId(dProduct.targetUserId);

		if (buyer == 0 || targetUser == 0)
			continue;

		if (buyer != client || targetUser != targetclient)
			continue;

		char sAliasArray[32][32];
		int  iAliasSize = ExplodeString(sAliases, " ", sAliasArray, sizeof(sAliasArray), sizeof(sAliasArray[]));

		for (int a = 0; a < iAliasSize; a++)
		{
			if (StrEqual(dProduct.sAlias, sAliasArray[a], false))
			{
				enProduct product;
				int       productPos = LookupProductByAlias(dProduct.sAlias, product);

				g_fPoints[client] += dProduct.fCost;

				if (productPos != -1)
					PrintToChat(client, "\x04[PS]\x03 Refunded %s\x05 + %d\x03 points(??: \x05%d\x03)", product.sName, RoundToFloor(dProduct.fCost), GetClientPoints(client));

				RemoveDelayedProductByTimer(dProduct.timer);

				CloseHandle(dProduct.timer);

				break;
			}
		}
	}

	return 0;
}

public any Native_FindProduct(Handle plugin, int numParams)
{
	enProduct product;

	char sAlias[32];
	GetNativeString(1, sAlias, sizeof(sAlias));

	if (LookupProductByAlias(sAlias, product) == -1)
		return false;

	SetNativeArray(2, product, sizeof(enProduct));

	return true;
}

public any Native_FetchProductCostByAlias(Handle plugin, int numParams)
{
	char sAlias[64];

	GetNativeString(1, sAlias, sizeof(sAlias));

	int buyer        = GetNativeCell(2);
	int targetclient = GetNativeCell(3);

	enProduct product;
	if (LookupProductByAlias(sAlias, product) == -1)
	{
		return -1.0;
	}

	Call_StartForward(g_fwOnGetParametersProduct);

	enProduct alteredProduct;
	alteredProduct = product;

	Call_PushCell(buyer);
	Call_PushString(alteredProduct.sAliases);
	Call_PushStringEx(alteredProduct.sInfo, sizeof(enProduct::sInfo), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(alteredProduct.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(alteredProduct.sDescription, sizeof(enProduct::sDescription), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(targetclient);
	Call_PushCellRef(alteredProduct.fCost);
	Call_PushFloatRef(alteredProduct.fDelay);
	Call_PushFloatRef(alteredProduct.fCooldown);

	Call_Finish();

	return float(RoundToFloor(alteredProduct.fCost));
}

public any Native_GetVersion(Handle plugin, int numParams)
{
	return version;
}

public int Native_SetPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	float newval = GetNativeCell(2);

	g_fPoints[client] = newval;

	return true;
}

public int Native_HardSetPoints(Handle plugin, int numParams)
{
	int   client                   = GetNativeCell(1);
	float newval                   = GetNativeCell(2);
	g_fPoints[client]              = newval;
	g_fSavedInfectedPoints[client] = newval;
	g_fSavedSurvivorPoints[client] = newval;

	return true;
}

public any Native_GetPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return g_fPoints[client];
}

public any Native_FullHeal(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	ExecuteFullHeal(client);

	return true;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	NextMultipleDamage[client]    = 0.0;
	NextSpitterDamage[client]     = 0.0;
	MultipleDamageStack[client]   = 0;
	SpitterDamageStack[client]    = 0.0;
	g_sLastBoughtAlias[client][0] = EOS;

	if (g_fPoints[client] > GetConVarFloat(StartPoints)) return;
	g_fPoints[client]              = GetConVarFloat(StartPoints);
	g_fSavedSurvivorPoints[client] = GetConVarFloat(StartPoints);
	g_fSavedInfectedPoints[client] = GetConVarFloat(StartPoints);
	if (killcount[client] > 0) return;
	killcount[client]     = 0;
	hurtcount[client]     = 0;
	protectcount[client]  = 0;
	headshotcount[client] = 0;
}

public Action Event_ChangeTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	int team    = GetEventInt(event, "team");
	int oldteam = GetEventInt(event, "oldteam");

	if (oldteam == 2)
		g_fSavedSurvivorPoints[client] = g_fPoints[client];

	else if (oldteam == 3)
		g_fSavedInfectedPoints[client] = g_fPoints[client];

	if (team == 2 || team == 3)
	{
		if (team == 2)
			g_fPoints[client] = g_fSavedSurvivorPoints[client];

		else if (team == 3)
			g_fPoints[client] = g_fSavedInfectedPoints[client];

		hurtcount[client]           = 0;
		protectcount[client]        = 0;
		headshotcount[client]       = 0;
		killcount[client]           = 0;
		NextMultipleDamage[client]  = 0.0;
		MultipleDamageStack[client] = 0;
		NextSpitterDamage[client]   = 0.0;
		SpitterDamageStack[client]  = 0.0;
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client)) return;
	CreateTimer(3.0, Check, client);
	if (g_fPoints[client] > GetConVarFloat(StartPoints)) return;
	g_fPoints[client]     = GetConVarFloat(StartPoints);
	killcount[client]     = 0;
	hurtcount[client]     = 0;
	protectcount[client]  = 0;
	headshotcount[client] = 0;
}

public Action Check(Handle Timer, any client)
{
	if (!IsClientConnected(client))
	{
		g_fPoints[client]     = GetConVarFloat(StartPoints);
		killcount[client]     = 0;
		hurtcount[client]     = 0;
		protectcount[client]  = 0;
		headshotcount[client] = 0;
	}

	return Plugin_Continue;
}

stock bool IsAllowedGameMode()
{
	char gamemode[24], gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(Modes, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}

stock bool IsAllowedReset()
{
	char gamemode[24], gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(ResetPoints, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}

public Action Event_REnd(Handle event, char[] event_name, bool dontBroadcast)
{
	if (IsAllowedReset())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			g_fPoints[i]              = GetConVarFloat(StartPoints);
			g_fSavedSurvivorPoints[i] = GetConVarFloat(StartPoints);
			g_fSavedInfectedPoints[i] = GetConVarFloat(StartPoints);
			hurtcount[i]              = 0;
			protectcount[i]           = 0;
			headshotcount[i]          = 0;
			killcount[i]              = 0;
		}
	}

	int  EntityCount = GetEntityCount();
	char sTemp[16];

	for (int i = MaxClients; i < EntityCount; i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			GetEdictClassname(i, sTemp, sizeof(sTemp));

			if (strcmp(sTemp, "infected") == 0 || strcmp(sTemp, "witch") == 0)
			{
				AcceptEntityInput(i, "Kill");
			}
		}
	}

	return Plugin_Continue;
}

public Action Event_RStart(Handle event, char[] event_name, bool dontBroadcast)
{
	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl")) PrecacheModel("models/w_models/weapons/w_m60.mdl");
	if (!IsModelPrecached("models/v_models/v_m60.mdl")) PrecacheModel("models/v_models/v_m60.mdl");
	float fStartPoints = GetConVarFloat(StartPoints);

	if (IsAllowedReset())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			g_fPoints[i]              = fStartPoints;
			g_fSavedSurvivorPoints[i] = fStartPoints;
			g_fSavedInfectedPoints[i] = fStartPoints;
			hurtcount[i]              = 0;
			protectcount[i]           = 0;
			headshotcount[i]          = 0;
			killcount[i]              = 0;
		}
	}
	PrintToChatAll("\x04[PS]\x03 Your Start Points: \x05%.0f", fStartPoints);

	ResetProductCooldowns();

	return Plugin_Continue;
}

public Action Event_Finale(Handle event, char[] event_name, bool dontBroadcast)
{
	char gamemode[40];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if (StrEqual(gamemode, "versus", false) || StrEqual(gamemode, "teamversus", false)) return Plugin_Continue;
	for (int i = 1; i <= MaxClients; i++)
	{
		g_fPoints[i]     = GetConVarFloat(StartPoints);
		killcount[i]     = 0;
		hurtcount[i]     = 0;
		protectcount[i]  = 0;
		headshotcount[i] = 0;
	}

	return Plugin_Continue;
}

public Action Event_Kill(Handle event, const char[] name, bool dontBroadcast)
{
	bool headshot = GetEventBool(event, "headshot");

	int infected_id = GetEventInt(event, "infected_id");
	int R           = 0;
	int G           = 0;
	int B           = 0;

	if (infected_id > 0)
	{
		SetEntProp(infected_id, Prop_Send, "m_glowColorOverride", R + (G * 256) + (B * 65536));
		SetEntProp(infected_id, Prop_Send, "m_iGlowType", 0);
		SetEntPropFloat(infected_id, Prop_Data, "m_flModelScale", 1.0);
		AcceptEntityInput(GetEntPropEnt(infected_id, Prop_Send, "m_hRagdoll"), "Kill");
	}
	ATTACKER
	ACHECK2
	{
		if (headshot)
		{
			headshotcount[attacker]++;
		}
		if (headshotcount[attacker] == GetConVarInt(SNumberHead) && GetConVarInt(SValueHeadSpree) > 0)
		{
			g_fPoints[attacker] += GetConVarFloat(SValueHeadSpree);
			headshotcount[attacker] = 0;
			if (GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Head Hunter \x05+ %d\x03 points (??: \x05%d\x03)", GetConVarInt(SValueHeadSpree), GetClientPoints(attacker));
		}
		killcount[attacker]++;
		if (killcount[attacker] == GetConVarInt(SNumberKill) && GetConVarInt(SValueKillingSpree) > 0)
		{
			g_fPoints[attacker] += GetConVarFloat(SValueKillingSpree);
			killcount[attacker] = 0;
			if (GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Killing Spree \x05+ %d\x03 points (??: \x05%d\x03)", GetConVarInt(SValueKillingSpree), GetClientPoints(attacker));
		}
	}

	return Plugin_Continue;
}

public Action Event_Incap(Handle event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(GetEventInt(event, "userid"));
	ATTACKER
	ACHECK3
	{
		if (GetConVarInt(IIncap) == -1) return Plugin_Continue;
		g_fPoints[attacker] += GetConVarFloat(IIncap);
		if (GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Incapped \x01%N\x05 + %d\x03 points (??: \x05%d\x03)", userid, GetConVarInt(IIncap), GetClientPoints(attacker));
	}

	return Plugin_Continue;
}

public Action Event_Death(Handle event, const char[] name, bool dontBroadcast)
{
	ATTACKER
	CLIENT
	if (attacker > 0 && client > 0 && !IsFakeClient(attacker) && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if (GetClientTeam(attacker) == 2)
		{
			if (GetConVarInt(SSIKill) <= 0 || GetClientTeam(client) == 2) return Plugin_Continue;
			if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8) return Plugin_Continue;
			g_fPoints[attacker] += GetConVarFloat(SSIKill);
			if (GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Killed \x01%N\x05 + %d\x03 points (??: \x05%d\x03)", client, GetConVarInt(SSIKill), GetClientPoints(attacker));
		}
		// If headshot == 2 ( which is a boolean usually ) then a karma kill occured.
		if (GetClientTeam(attacker) == 3 && GetEventInt(event, "headshot") != 2)
		{
			if (GetConVarInt(IKill) <= 0 || GetClientTeam(client) == 3) return Plugin_Continue;
			g_fPoints[attacker] += GetConVarFloat(IKill);
			if (GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Killed \x01%N\x05 + %d\x03 points (??: \x05%d\x03)", client, GetConVarInt(IKill), GetClientPoints(attacker));
		}
	}

	return Plugin_Continue;
}

public Action Event_TankDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int solo = GetEventBool(event, "solo");
	ATTACKER
	ACHECK2
	{
		if (solo && GetConVarInt(STSolo) > 0)
		{
			g_fPoints[attacker] += GetConVarFloat(STSolo);
			if (GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 TANK SOLO! \x05+ %d\x03 points (??: \x05%d\x03)", GetConVarInt(STSolo), GetClientPoints(attacker));
		}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && GetConVarInt(STankKill) > 0 && GetConVarInt(Enable) == 1 && IsAllowedGameMode())
		{
			g_fPoints[i] += GetConVarFloat(STankKill);
			if (GetConVarBool(Notifications)) PrintToChat(i, "\x04[PS]\x03 Killed Tank \x05+ %d\x03 points (??: \x05%d\x03)", GetConVarInt(STankKill), GetClientPoints(i));
		}
	}
	tankburning[attacker] = 0;
	tankbiled[attacker]   = 0;

	return Plugin_Continue;
}

public Action Event_WitchDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int oneshot = GetEventBool(event, "oneshot");
	CLIENT
	CCHECK2
	{
		if (GetConVarInt(SWitchKill) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(SWitchKill);
		if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Killed Witch + \x05%d\x03 points", GetConVarInt(SWitchKill), GetClientPoints(client));
		if (oneshot && GetConVarInt(SWitchCrown) > 0)
		{
			g_fPoints[client] += GetConVarFloat(SWitchCrown);
			if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Crowned The Witch + \x05%d\x03 points (??: \x05%d\x03)", GetConVarInt(SWitchCrown), GetClientPoints(client));
		}
	}
	witchburning[client] = 0;

	return Plugin_Continue;
}

public Action Event_Heal(Handle event, const char[] name, bool dontBroadcast)
{
	int restored = GetEventInt(event, "health_restored");
	CLIENT
	int subject = GetClientOfUserId(GetEventInt(event, "subject"));
	if (subject > 0 && client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if (client == subject) return Plugin_Continue;
		if (restored > 39)
		{
			if (GetConVarInt(SHeal) <= 0) return Plugin_Continue;
			g_fPoints[client] += GetConVarFloat(SHeal);
			if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Healed \x01%N\x05 + %d\x03 points (??: \x05%d\x03)", subject, GetConVarInt(SHeal), GetClientPoints(client));
		}
		else
		{
			if (GetConVarInt(SHealWarning) <= 0) return Plugin_Continue;
			g_fPoints[client] += GetConVarFloat(SHealWarning);
			if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Don't Harvest Heal Points\x05 + %d\x03 points (??: \x05%d\x03)", GetConVarInt(SHealWarning), GetClientPoints(client));
		}
	}

	return Plugin_Continue;
}

public Action Event_Protect(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	int award = GetEventInt(event, "award");
	if (client > 0 && award == 67 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && !IsFakeClient(client) && IsAllowedGameMode())
	{
		if (GetConVarInt(SProtect) <= 0) return Plugin_Continue;
		protectcount[client]++;
		if (protectcount[client] == 6)
		{
			g_fPoints[client] += GetConVarFloat(SProtect);
			protectcount[client] = 0;
		}
		if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Protected Teammate\x05 + %d\x03 points (??: \x05%d\x03)", GetConVarInt(SProtect), GetClientPoints(client));
	}

	return Plugin_Continue;
}

public Action Event_Revive(Handle event, const char[] name, bool dontBroadcast)
{
	bool ledge = GetEventBool(event, "ledge_hang");
	CLIENT
	int subject = GetClientOfUserId(GetEventInt(event, "subject"));
	CCHECK2
	{
		if (subject == client) return Plugin_Continue;
		if (!ledge && GetConVarInt(SRevive) > 0)
		{
			g_fPoints[client] += GetConVarFloat(SRevive);
			if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Revived \x01%N\x05 + %d\x03 points (??: \x05%d\x03)", subject, GetConVarInt(SRevive), GetClientPoints(client));
		}
		if (ledge && GetConVarInt(SLedge) > 0)
		{
			g_fPoints[client] += GetConVarFloat(SLedge);
			if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Revived \x01%N\x03 From Ledge\x05 + %d\x03 points (??: \x05%d\x03)", subject, GetConVarInt(SLedge), GetClientPoints(client));
		}
	}

	return Plugin_Continue;
}

public Action Event_Shock(Handle event, const char[] name, bool dontBroadcast)
{
	int subject = GetClientOfUserId(GetEventInt(event, "subject"));
	CLIENT
	CCHECK2
	{
		if (GetConVarInt(SDefib) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(SDefib);
		if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Defibbed \x01%N\x05 + %d\x03 points (??: \x05%d\x03)", subject, GetConVarInt(SDefib), GetClientPoints(client));
	}

	return Plugin_Continue;
}

public Action Event_Choke(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if (GetConVarInt(IChoke) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(IChoke);
		if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Choked Survivor\x05 + %d\x03 points (??: \x05%d\x03)", GetConVarInt(IChoke), GetClientPoints(client));
	}

	return Plugin_Continue;
}

public Action Event_Boom(Handle event, const char[] name, bool dontBroadcast)
{
	ATTACKER
	CLIENT
	if (attacker > 0 && !IsFakeClient(attacker) && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if (GetClientTeam(attacker) == 3 && GetConVarInt(ITag) > 0)
		{
			g_fPoints[attacker] += GetConVarFloat(ITag);
			if (GetClientTeam(client) == 2 && GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Boomed \x01%N\x05 + %d\x03 points (??: \x05%d\x03)", client, GetConVarInt(ITag), GetClientPoints(attacker));
		}
		if (GetClientTeam(attacker) == 2 && GetConVarInt(STag) > 0)
		{
			g_fPoints[attacker] += GetConVarFloat(STag);
			if (GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Biled Tank + \x05%d\x03 points (??: \x05%d\x03)", GetConVarInt(STag), GetClientPoints(attacker));
			tankbiled[attacker] = 1;
		}
	}

	return Plugin_Continue;
}

public Action Event_Pounce(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if (GetConVarInt(IPounce) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(IPounce);
		if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Pounced Survivor \x05+ %d\x03 points (??: \x05%d\x03)", GetConVarInt(IPounce), GetClientPoints(client));
	}

	return Plugin_Continue;
}

public Action Event_Ride(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if (GetConVarInt(IRide) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(IRide);
		if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Jockeyed Survivor \x05+ %d\x03 points (??: \x05%d\x03)", GetConVarInt(IRide), GetClientPoints(client));
	}

	return Plugin_Continue;
}

public Action Event_Carry(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if (GetConVarInt(ICarry) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(ICarry);
		if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Charged Survivor \x05+ %d\x03 points (??: \x05%d\x03)", GetConVarInt(ICarry), GetClientPoints(client));
	}

	return Plugin_Continue;
}

public Action Event_Impact(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if (GetConVarInt(IImpact) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(IImpact);
		if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Impacted Survivor \x05+ %d\x03 points(??: \x05%d\x03)", GetConVarInt(IImpact), GetClientPoints(client));
	}

	return Plugin_Continue;
}

public Action Event_Burn(Handle event, const char[] name, bool dontBroadcast)
{
	char victim[30];
	GetEventString(event, "victimname", victim, sizeof(victim));
	CLIENT
	CCHECK2
	{
		if (StrEqual(victim, "Tank", false) && tankburning[client] == 0 && GetConVarInt(STBurn) > 0)
		{
			g_fPoints[client] += GetConVarFloat(STBurn);
			if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Burned The Tank \x05+ %d\x03 points (??: \x05%d\x03)", GetConVarInt(STBurn), GetClientPoints(client));
			tankburning[client] = 1;
		}
		if (StrEqual(victim, "Witch", false) && witchburning[client] == 0 && GetConVarInt(SWBurn) > 0)
		{
			g_fPoints[client] += GetConVarFloat(SWBurn);
			if (GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Burned The Witch \x05+ %d\x03 points (??: \x05%d\x03)", GetConVarInt(SWBurn), GetClientPoints(client));
			witchburning[client] = 1;
		}
	}

	return Plugin_Continue;
}

public Action Event_Hurt(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	ATTACKER
	int dmg_type = GetEventInt(event, "type");

	if (dmg_type & DMG_BURN) return Plugin_Continue;    // Blocks a nasty bug where a survivor joins infected after setting up a molotov to earn lots of points from damaging his team with fire.

	if (attacker != 0 && client != 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == view_as<int>(L4DTeam_Infected) && GetClientTeam(client) == view_as<int>(L4DTeam_Survivor) && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		// Spitter appears to deal both DMG_RADIATION and DMG_ENERGYBEAM.
		if (dmg_type & DMG_RADIATION && GetConVarFloat(ISpit) > 0.0)
		{
			if (SpitterDamageStack[attacker] == 0)
				NextSpitterDamage[attacker] = GetEngineTime() + 10.0;

			g_fPoints[attacker] += GetConVarFloat(ISpit) * SPIT_DELAY;

			SpitterDamageStack[attacker] += SPIT_DELAY;
		}
		else if (GetConVarInt(IHurt) > 0)
		{
			if (MultipleDamageStack[attacker] == 0)
				NextMultipleDamage[attacker] = GetEngineTime() + 10.0;

			hurtcount[attacker]++;

			if (hurtcount[attacker] >= 3)
			{
				g_fPoints[attacker] += GetConVarFloat(IHurt);

				MultipleDamageStack[attacker] += GetConVarInt(IHurt);
				hurtcount[attacker] = 0;
			}
		}
	}

	return Plugin_Continue;
}

public Action Command_PointSystem(int client, int args)
{
	PrintToChat(client, "\x04[PS]\x03 Use\x04 sm_buy <alias> [target]\x03 to buy products.");

	if (CommandExists("sm_autobuy"))
		PrintToChat(client, "\x04[PS]\x03 Use\x04 sm_autobuy\x03 to buy certain survivor products automatically");

	PrintToChat(client, "\x04[PS]\x03 Use\x04 sm_sp\x03 to send points for your teammates");
	PrintToChat(client, "\x04[PS]\x03 Use\x04 sm_splist / sm_buylist\x03 if your teammates have weird names");
	PrintToChat(client, "\x04[PS]\x03 Use\x04 sm_alias\x03 if you want to find a better alias for a product");

	return Plugin_Handled;
}

public Action Command_Rebuy(int client, int args)
{
	// No target, so let's make the target the buyer's userid?
	if (g_sLastBoughtTargetArg[client][0] == EOS)
		FormatEx(g_sLastBoughtTargetArg[client], sizeof(g_sLastBoughtTargetArg[]), "#%i", GetClientUserId(client));

	PerformPurchaseOnAlias(client, g_sLastBoughtAlias[client], g_sLastBoughtTargetArg[client]);

	return Plugin_Handled;
}

public Action Command_Aliases(int client, int args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_alias <alias>");
		return Plugin_Handled;
	}

	char sFirstArg[32];

	GetCmdArg(1, sFirstArg, sizeof(sFirstArg));

	enProduct product;

	int productPos = LookupProductByAlias(sFirstArg, product);

	if (productPos == -1)
	{
		PrintToChat(client, "\x04[PS]\x03 Error: Product could not be found!");
		return Plugin_Handled;
	}

	PrintToChat(client, "\x04[PS]\x03 List of aliases for %s seperated by spaces:\n\x05%s", product.sName, product.sAliases);
	return Plugin_Handled;
}

public Action BuyMenu(int client, int args)
{
	if (!L4D_HasAnySurvivorLeftSafeAreaStock() && GetClientTeam(client) == view_as<int>(L4DTeam_Infected))
	{
		PrintToChat(client, "\x04[PS]\x03 Waiting for Survivors ...");
		return Plugin_Handled;
	}
	if (IsAllowedGameMode() && GetConVarInt(Enable) == 1 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && args == 0)
	{
		BuildBuyMenu(client);
		return Plugin_Handled;
	}
	else    // Alias buy.
	{
		char sFirstArg[32];

		char sArgString[128];

		GetCmdArg(1, sFirstArg, sizeof(sFirstArg));
		TrimString(sFirstArg);

		if (sFirstArg[0] == EOS)
			return Plugin_Handled;

		GetCmdArgString(sArgString, sizeof(sArgString));

		// 2 and beyond are the target's name
		ReplaceStringEx(sArgString, sizeof(sArgString), sFirstArg, "");

		TrimString(sArgString);

		strcopy(g_sLastBoughtAlias[client], sizeof(g_sLastBoughtAlias[]), sFirstArg);

		strcopy(g_sLastBoughtTargetArg[client], sizeof(g_sLastBoughtTargetArg[]), sArgString);

		// No target, so let's make the target the buyer's userid?
		if (sArgString[0] == EOS)
			FormatEx(sArgString, sizeof(sArgString), "#%i", GetClientUserId(client));

		PerformPurchaseOnAlias(client, sFirstArg, sArgString);
	}
	return Plugin_Handled;
}

public Action ShowPoints(int client, int args)
{
	if (IsAllowedGameMode() && GetConVarInt(Enable) == 1 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && args == 0)
	{
		PrintToChat(client, "\x04[PS]\x03 You have \x05%d\x03 points", GetClientPoints(client));
	}
	return Plugin_Handled;
}

public Action ShowTeamPoints(int client, int args)
{
	if (IsAllowedGameMode() && GetConVarInt(Enable) == 1 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && args == 0)
	{
		int count = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			else if (IsFakeClient(i))
				continue;

			else if (GetClientTeam(i) != GetClientTeam(client))
				continue;

			count += GetClientPoints(i);

			if (client == i)
				PrintToChat(client, "\x04[PS]\x03 You have \x05%d\x03 points", GetClientPoints(i));

			else
				PrintToChat(client, "\x04[PS]\x03 %N has \x05%d\x03 points", i, GetClientPoints(i));
		}

		PrintToChat(client, "\x04[PS]\x03 Total Team Points: %i", count);
	}
	return Plugin_Handled;
}

public Action Command_Heal(int client, int args)
{
	if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_heal <target> [amount]");
		return Plugin_Handled;
	}

	char arg[65], arg2[65];
	GetCmdArg(1, arg, sizeof(arg));
	int Amount;
	if (args == 2)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		Amount = StringToInt(arg2);
	}
	char Path[256], LogFormat[100];
	BuildPath(Path_SM, Path, sizeof(Path), "logs/pointsystem.txt");

	if (args == 2)
		Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has set %s's health to %i", client, arg, Amount);
	else if (args != 0)
		Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has fully healed %s", client, arg);

	else
		Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has fully healed himself", client);

	LogToFile(Path, LogFormat);
	if (args == 0)
	{
		ExecuteFullHeal(client);

		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH];
	int  target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			 arg,
			 client,
			 target_list,
			 MAXPLAYERS,
			 COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY,
			 target_name,
			 sizeof(target_name),
			 tn_is_ml))
	    <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		int targetclient;
		targetclient = target_list[i];
		if (args == 2)
		{
			SetEntityHealth(targetclient, Amount);
		}
		else
		{
			ExecuteFullHeal(targetclient);
		}
	}
	return Plugin_Handled;
}

public Action Command_Incap(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_incap <target>");
		return Plugin_Handled;
	}
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	char target_name[MAX_TARGET_LENGTH];
	int  target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			 arg,
			 client,
			 target_list,
			 MAXPLAYERS,
			 COMMAND_FILTER_ALIVE,
			 target_name,
			 sizeof(target_name),
			 tn_is_ml))
	    <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	char Path[256], LogFormat[100];
	BuildPath(Path_SM, Path, sizeof(Path), "logs/pointsystem.txt");

	Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has incapped %s", client, arg);
	LogToFile(Path, LogFormat);

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];

		if (GetClientTeam(target) == 1)
			continue;

		else if (GetClientTeam(target) == 3 && GetEntProp(target, Prop_Send, "m_zombieClass") != 8)
			continue;

		else if (GetClientTeam(target) == 2 && GetEntProp(target, Prop_Send, "m_isIncapacitated") == 1)
			continue;

		if (IsValidEntity(target))
		{
			int iDmgEntity = CreateEntityByName("point_hurt");
			SetEntityHealth(target, 1);
			DispatchKeyValue(target, "targetname", "bm_target");
			DispatchKeyValue(iDmgEntity, "DamageTarget", "bm_target");
			DispatchKeyValue(iDmgEntity, "Damage", "100");
			DispatchKeyValue(iDmgEntity, "DamageType", "0");
			DispatchSpawn(iDmgEntity);
			AcceptEntityInput(iDmgEntity, "Hurt", target);
			DispatchKeyValue(target, "targetname", "bm_targetoff");
			RemoveEdict(iDmgEntity);
		}
	}

	return Plugin_Handled;
}

public Action Command_SetIncap(int client, int args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setincaps <target> <amount left>");
		return Plugin_Handled;
	}
	char arg[65], arg2[65];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	char target_name[MAX_TARGET_LENGTH];
	int  target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			 arg,
			 client,
			 target_list,
			 MAXPLAYERS,
			 COMMAND_FILTER_ALIVE,
			 target_name,
			 sizeof(target_name),
			 tn_is_ml))
	    <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int MAX_INCAPS = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	int Amount     = (MAX_INCAPS - StringToInt(arg2));

	char Path[256], LogFormat[100];
	BuildPath(Path_SM, Path, sizeof(Path), "logs/pointsystem.txt");

	Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has set %s's incaps left to %i", client, arg, Amount);
	LogToFile(Path, LogFormat);

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];

		if (GetClientTeam(target) != 2)
			continue;

		SetEntProp(target, Prop_Send, "m_currentReviveCount", Amount);

		if (Amount >= MAX_INCAPS)
			SetEntProp(target, Prop_Send, "m_isGoingToDie", 1);
	}

	return Plugin_Handled;
}

public Action Command_Points(int client, int args)
{
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givepoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}
	char arg[MAX_NAME_LENGTH], arg2[10];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	char target_name[MAX_TARGET_LENGTH];
	int  target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;

	int targetclient;

	if ((target_count = ProcessTargetString(
			 arg,
			 client,
			 target_list,
			 MAXPLAYERS,
			 0,
			 target_name,
			 sizeof(target_name),
			 tn_is_ml))
	    > 0)
	{
		char Path[256], LogFormat[100];
		BuildPath(Path_SM, Path, sizeof(Path), "logs/pointsystem.txt");

		Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has given %i points to %s", client, StringToInt(arg2), arg);
		LogToFile(Path, LogFormat);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || i == client)
				continue;

			if (CheckCommandAccess(i, "sm_setincaps", ADMFLAG_ROOT))
				PrintToChat(i, LogFormat);
		}

		for (int i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			g_fPoints[targetclient] += StringToFloat(arg2);
			char name[33];
			GetClientName(targetclient, name, sizeof(name));
			ReplyToCommand(client, "\x04[PS]\x03 You gave %i points to %s.", StringToInt(arg2), arg);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action Command_SPoints(int client, int args)
{
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setpoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}
	char arg[MAX_NAME_LENGTH], arg2[10];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	char target_name[MAX_TARGET_LENGTH];
	int  target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;

	int targetclient;

	if ((target_count = ProcessTargetString(
			 arg,
			 client,
			 target_list,
			 MAXPLAYERS,
			 0,
			 target_name,
			 sizeof(target_name),
			 tn_is_ml))
	    > 0)
	{
		char Path[256], LogFormat[100];
		BuildPath(Path_SM, Path, sizeof(Path), "logs/pointsystem.txt");

		Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has set %s's points to %i", client, arg, StringToInt(arg2));
		LogToFile(Path, LogFormat);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || i == client)
				continue;

			if (CheckCommandAccess(i, "sm_setincaps", ADMFLAG_ROOT))
				PrintToChat(i, LogFormat);
		}

		for (int i = 0; i < target_count; i++)
		{
			targetclient            = target_list[i];
			g_fPoints[targetclient] = float(StringToInt(arg2));
			char name[33];
			GetClientName(targetclient, name, sizeof(name));
			ReplyToCommand(client, "\x04[PS]\x03 %s's points have been set to: %s", name, arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action Command_Exec(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_exec <target> <command>");
		return Plugin_Handled;
	}
	char command[200], targetarg[MAX_NAME_LENGTH], targetargsubstract[MAX_NAME_LENGTH + 1];
	GetCmdArgString(command, sizeof(command));

	GetCmdArg(1, targetarg, sizeof(targetarg));

	Format(targetargsubstract, sizeof(targetargsubstract), "%s ", targetarg);
	ReplaceString(command, sizeof(command), targetargsubstract, "");

	char target_name[MAX_TARGET_LENGTH];
	int  target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;

	int targetclient;

	if ((target_count = ProcessTargetString(
			 targetarg,
			 client,
			 target_list,
			 MAXPLAYERS,
			 0,
			 target_name,
			 sizeof(target_name),
			 tn_is_ml))
	    > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || i == client)
				continue;

			if (CheckCommandAccess(i, "sm_setincaps", ADMFLAG_ROOT))
				PrintToChat(i, "\x04[PS]\x03 Admin %N has executed %s on %s", client, command, targetarg);
		}

		char flaggedcommand[200];

		for (int i; i < strlen(command); i++)
		{
			if (IsCharSpace(command[i]) || command[i] == EOS)
				Format(flaggedcommand, i + 1, command);
		}

		int flags = GetCommandFlags(flaggedcommand);

		SetCommandFlags(flaggedcommand, flags & ~FCVAR_CHEAT);
		for (int i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];

			ClientCommand(targetclient, command);
			ReplyToCommand(client, "\x04[PS]\x03 Command %s was executed on %N", command, targetclient);
		}

		SetCommandFlags(flaggedcommand, flags);
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action Command_FakeExec(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakeexec <target> <command>");
		return Plugin_Handled;
	}
	char command[200], targetarg[MAX_NAME_LENGTH], targetargsubstract[MAX_NAME_LENGTH + 1];
	GetCmdArgString(command, sizeof(command));

	GetCmdArg(1, targetarg, sizeof(targetarg));

	Format(targetargsubstract, sizeof(targetargsubstract), "%s ", targetarg);
	ReplaceString(command, sizeof(command), targetargsubstract, "");

	char target_name[MAX_TARGET_LENGTH];
	int  target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;

	int targetclient;

	if ((target_count = ProcessTargetString(
			 targetarg,
			 client,
			 target_list,
			 MAXPLAYERS,
			 0,
			 target_name,
			 sizeof(target_name),
			 tn_is_ml))
	    > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || i == client)
				continue;

			if (CheckCommandAccess(i, "sm_setincaps", ADMFLAG_ROOT))
				PrintToChat(i, "\x04[PS]\x03 Admin %N has executed %s on %s", client, command, targetarg);
		}

		char flaggedcommand[200];

		for (int i; i < strlen(command); i++)
		{
			if (IsCharSpace(command[i]) || command[i] == EOS)
				Format(flaggedcommand, i + 1, command);
		}

		int flags = GetCommandFlags(flaggedcommand);

		SetCommandFlags(flaggedcommand, flags & ~FCVAR_CHEAT);

		for (int i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];

			FakeClientCommand(targetclient, command);
			ReplyToCommand(client, "\x04[PS]\x03 Command %s was executed on %N", command, targetclient);
		}

		SetCommandFlags(flaggedcommand, flags);
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action Command_SendPoints(int client, int args)
{
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sendpoints <#userid|name> <points to send>");
		return Plugin_Handled;
	}

	char arg[MAX_NAME_LENGTH], arg2[10];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}

	float pointsToSend = float(RoundToFloor(StringToFloat(arg2)));

	if (StrContains(arg2, "all", false) != -1)
		pointsToSend = float(GetClientPoints(client));

	if (pointsToSend <= 0.0)
	{
		PrintToChat(client, "\x04[PS]\x03 Error: Invalid value to send!");
		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH];
	int  target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;

	int targetclient;

	if ((target_count = ProcessTargetString(
			 arg,
			 client,
			 target_list,
			 MAXPLAYERS,
			 COMMAND_FILTER_NO_IMMUNITY,
			 target_name,
			 sizeof(target_name),
			 tn_is_ml))
	    > 0)
	{
		for (int i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];

			if (GetClientTeam(targetclient) != GetClientTeam(client) || targetclient == client || IsFakeClient(targetclient))
				continue;

			else if (!IsPlayerAlive(targetclient) && IsTeamSurvivor(targetclient))
			{
				PrintToChat(client, "\x04[PS]\x03 Error:\x05 %N\x03 is dead.", targetclient);
				continue;
			}

			else if (pointsToSend > g_fPoints[client])
			{
				PrintToChat(client, "\x04[PS]\x03 Error: Not enough points to send! (??: \x05%d\x03)", GetClientPoints(client));
				return Plugin_Handled;
			}

			ResetGlobalError();

			Call_StartForward(g_fwOnCanBuyProducts);

			Call_PushCell(client);
			Call_PushCell(targetclient);

			Action result;
			Call_Finish(result);

			if (result >= Plugin_Handled)
			{
				if (g_error[0] != EOS)
					PrintToChat(client, g_error);

				continue;
			}

			g_fPoints[targetclient] += pointsToSend;
			g_fPoints[client] -= pointsToSend;

			char name[33], sendername[33];
			GetClientName(targetclient, name, sizeof(name));
			GetClientName(client, sendername, sizeof(sendername));
			PrintToChat(client, "\x04[PS]\x03 You gave \x05%d\x03 points to %s. (??: \x05%d\x03)", RoundToFloor(pointsToSend), name, GetClientPoints(client));
			PrintToChat(targetclient, "\x04[PS]\x03 %s gave you \x05%d\x03 points. (??: \x05%d\x03)", sendername, RoundToFloor(pointsToSend), GetClientPoints(targetclient));
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}

	return Plugin_Handled;
}

public Action Command_SendPointsList(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_splist <points to send>");
		return Plugin_Handled;
	}

	char arg[MAX_NAME_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));

	float pointsToSend = float(RoundToFloor(StringToFloat(arg)));

	if (StrContains(arg, "all", false) != -1)
		pointsToSend = float(GetClientPoints(client));

	if (pointsToSend <= 0.0)
	{
		PrintToChat(client, "\x04[PS]\x03 Error: Invalid value to send!");
		return Plugin_Handled;
	}

	bool bAnyPlayers;

	Handle hMenu = CreateMenu(SPListMenu_Handler);

	SetMenuTitle(hMenu, "Choose a player to send %.0f points to\nYour Points: %i", pointsToSend, GetClientPoints(client));

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (GetClientTeam(i) != GetClientTeam(client) || i == client || IsFakeClient(i))
			continue;

		Call_StartForward(g_fwOnCanBuyProducts);

		Call_PushCell(client);
		Call_PushCell(i);

		Action result;
		Call_Finish(result);

		if (result >= Plugin_Handled)
			continue;

		char sInfo[24], sName[64];
		FormatEx(sInfo, sizeof(sInfo), "%i %.0f", GetClientUserId(i), pointsToSend);    // c for category, p for product

		GetClientName(i, sName, sizeof(sName));
		AddMenuItem(hMenu, sInfo, sName);
		bAnyPlayers = true;
	}

	if (bAnyPlayers)
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	else
		CloseHandle(hMenu);

	return Plugin_Handled;
}

public int SPListMenu_Handler(Handle hMenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
		CloseHandle(hMenu);

	else if (action == MenuAction_Select)
	{
		char sInfo[24];
		GetMenuItem(hMenu, item, sInfo, sizeof(sInfo));

		char sUserId[11], sPointsToSend[11];

		int pos = BreakString(sInfo, sUserId, sizeof(sUserId));
		BreakString(sInfo[pos], sPointsToSend, sizeof(sPointsToSend));

		FakeClientCommand(client, "sm_sp #%i %i", StringToInt(sUserId), StringToInt(sPointsToSend));
	}

	return 0;
}

public Action Command_BuyList(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_buylist <alias>");
		return Plugin_Handled;
	}

	char sFirstArg[32];
	GetCmdArg(1, sFirstArg, sizeof(sFirstArg));

	enProduct product;

	int productPos = LookupProductByAlias(sFirstArg, product);

	if (productPos == -1)
	{
		PrintToChat(client, "\x04[PS]\x03 Error: Product could not be found!");
		return Plugin_Handled;
	}

	bool bAnyPlayers;

	Handle hMenu = CreateMenu(BuyListMenu_Handler);

	SetMenuTitle(hMenu, "Choose a player to give %s\nYour Points: %i", product.sName, GetClientPoints(client));

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (GetClientTeam(i) != GetClientTeam(client) || i == client || IsFakeClient(i))
			continue;

		if (!PSAPI_CanProductBeBought(sFirstArg, client, i))
			continue;

		char sInfo[64], sName[64];
		FormatEx(sInfo, sizeof(sInfo), "%i %s", GetClientUserId(i), sFirstArg);    // c for category, p for product

		GetClientName(i, sName, sizeof(sName));
		AddMenuItem(hMenu, sInfo, sName);
		bAnyPlayers = true;
	}

	if (bAnyPlayers)
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	else
	{
		CloseHandle(hMenu);

		if (GetClientPoints(client) >= RoundToFloor(PSAPI_FetchProductCostByAlias(sFirstArg, client, client)))
			PrintToChat(client, "\x04[PS]\x03 Error: Could not find a player to buy for!");

		else
		{
			int iCost = RoundToFloor(PSAPI_FetchProductCostByAlias(sFirstArg, client, client));
			PrintToChat(client, PSAPI_NOT_ENOUGH_POINTS, iCost - GetClientPoints(client), GetClientPoints(client));
		}
	}

	return Plugin_Handled;
}

public int BuyListMenu_Handler(Handle hMenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
		CloseHandle(hMenu);

	else if (action == MenuAction_Select)
	{
		char sInfo[64];
		GetMenuItem(hMenu, item, sInfo, sizeof(sInfo));

		char sUserId[11], sAlias[32];

		int pos = BreakString(sInfo, sUserId, sizeof(sUserId));
		BreakString(sInfo[pos], sAlias, sizeof(sAlias));

		FakeClientCommand(client, "sm_buy %s #%i", sAlias, StringToInt(sUserId));
	}

	return 0;
}

void BuildBuyMenu(int client, int iCategory = -1)
{
	ResetGlobalError();

	Call_StartForward(g_fwOnCanBuyProducts);

	Call_PushCell(client);
	Call_PushCell(client);

	Action result;
	Call_Finish(result);

	if (result >= Plugin_Handled)
	{
		if (g_error[0] != EOS)
			PrintToChat(client, g_error);

		return;
	}

	Handle hMenu = CreateMenu(BuyMenu_Handler);
	SetMenuTitle(hMenu, "Your Points: %i\nUse sm_ps for help about Point System", GetClientPoints(client));

	if (iCategory != -1)
		SetMenuExitBackButton(hMenu, true);

	ArrayList aCategories = g_aCategories.Clone();
	ArrayList aProducts   = g_aProducts.Clone();

	SortADTArrayCustom(aCategories, SortFunc_enCategory_sName);
	SortADTArrayCustom(aProducts, SortFunc_enProduct_sName);

	int iCategoriesSize = GetArraySize(aCategories);
	int iProductsSize   = GetArraySize(aProducts);

	bool bAnyItems = false;

	for (int i = 0; i < iCategoriesSize; i++)
	{
		enCategory cat;
		GetArrayArray(aCategories, i, cat);

		if (cat.iCategory != iCategory)
			continue;

		enProduct impostorProduct;

		impostorProduct.iBuyFlags = cat.iBuyFlags;

		bool bShouldReturn;

		if (PSAPI_GetErrorFromBuyflags(client, "", impostorProduct, _, _, _, bShouldReturn) && bShouldReturn)
			continue;

		char sName[64];
		sName = cat.sName;

		if (cat.iBuyFlags & BUYFLAG_CUSTOMNAME)
		{
			Call_StartForward(g_fwOnGetParametersCategory);

			enCategory alteredCategory;
			alteredCategory = cat;

			Call_PushCell(client);
			Call_PushString(alteredCategory.sID);
			Call_PushStringEx(alteredCategory.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);

			result = Plugin_Continue;
			Call_Finish(result);

			if (result >= Plugin_Handled)
				continue;

			sName = alteredCategory.sName;
		}

		char sInfo[128];
		FormatEx(sInfo, sizeof(sInfo), "c%s", cat.sID);    // c for category, p for product
		AddMenuItem(hMenu, sInfo, sName);
		bAnyItems = true;
	}

	for (int i = 0; i < iProductsSize; i++)
	{
		enProduct product;
		GetArrayArray(aProducts, i, product);

		if (product.iCategory != iCategory)
			continue;

		bool bShouldReturn;

		if (PSAPI_GetErrorFromBuyflags(client, "", product, _, _, _, bShouldReturn) && bShouldReturn)
			continue;

		char sInfo[128];
		FormatEx(sInfo, sizeof(sInfo), "p%s", product.sAliases);    // c for category, p for product

		char sDisplay[128], sFirstAlias[32];
		BreakString(product.sAliases, sFirstAlias, sizeof(sFirstAlias));

		char sName[64];
		sName = product.sName;

		if (product.iBuyFlags & BUYFLAG_CUSTOMNAME)
		{
			Call_StartForward(g_fwOnGetParametersProduct);

			enProduct alteredProduct;
			alteredProduct = product;

			Call_PushCell(client);
			Call_PushString(alteredProduct.sAliases);
			Call_PushStringEx(alteredProduct.sInfo, sizeof(enProduct::sInfo), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushStringEx(alteredProduct.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushStringEx(alteredProduct.sDescription, sizeof(enProduct::sDescription), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(client);
			Call_PushCellRef(alteredProduct.fCost);
			Call_PushFloatRef(alteredProduct.fDelay);
			Call_PushFloatRef(alteredProduct.fCooldown);

			Call_Finish();

			sName = alteredProduct.sName;
		}

		FormatEx(sDisplay, sizeof(sDisplay), "%s\nChat: !buy %s", sName, sFirstAlias);
		AddMenuItem(hMenu, sInfo, sDisplay);
		bAnyItems = true;
	}

	CloseHandle(aProducts);
	CloseHandle(aCategories);

	if (bAnyItems)
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

	else
		CloseHandle(hMenu);
}

/**
 * Sort comparison function for ADT Array elements. Function provides you with
 * indexes currently being sorted, use ADT Array functions to retrieve the
 * index values and compare.
 *
 * @param index1        First index to compare.
 * @param index2        Second index to compare.
 * @param array         Array that is being sorted (order is undefined).
 * @param hndl          Handle optionally passed in while sorting.
 * @return              -1 if first should go before second
 *                      0 if first is equal to second
 *                      1 if first should go after second
 */
public int SortFunc_enCategory_sName(int index1, int index2, Handle array, Handle hndl)
{
	enCategory product1;
	enCategory product2;

	GetArrayArray(array, index1, product1);
	GetArrayArray(array, index2, product2);

	return strcmp(product1.sName, product2.sName, false);
}

public int SortFunc_enProduct_sName(int index1, int index2, Handle array, Handle hndl)
{
	enProduct product1;
	enProduct product2;

	GetArrayArray(array, index1, product1);
	GetArrayArray(array, index2, product2);

	return strcmp(product1.sName, product2.sName, false);
}

public int BuyMenu_Handler(Handle hMenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
		CloseHandle(hMenu);

	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack)
	{
		char sInfo[256];

		// Get first item, check which category it belongs to.
		GetMenuItem(hMenu, 0, sInfo, sizeof(sInfo));

		bool bCategory = false;

		if (sInfo[0] == 'c')
		{
			bCategory = true;

			// c for category, p for product
			ReplaceStringEx(sInfo, sizeof(sInfo), "c", "");
		}
		else
		{
			// c for category, p for product
			ReplaceStringEx(sInfo, sizeof(sInfo), "p", "");
		}

		int iCurrentCategory = -1;

		if (bCategory)
		{
			int iCategory = FindCategoryByIdentifier(sInfo);

			enCategory cat;
			GetArrayArray(g_aCategories, iCategory, cat);

			iCurrentCategory = cat.iCategory;
		}
		else
		{
			char sFirstArg[64];

			BreakString(sInfo, sFirstArg, sizeof(sFirstArg));

			enProduct product;

			LookupProductByAlias(sFirstArg, product);

			iCurrentCategory = product.iCategory;
		}

		enCategory curcat;
		GetArrayArray(g_aCategories, iCurrentCategory, curcat);

		BuildBuyMenu(client, curcat.iCategory);
	}
	else if (action == MenuAction_Select)
	{
		char sInfo[256];

		GetMenuItem(hMenu, item, sInfo, sizeof(sInfo));

		bool bCategory = false;

		if (sInfo[0] == 'c')
		{
			bCategory = true;

			// c for category, p for product
			ReplaceStringEx(sInfo, sizeof(sInfo), "c", "");
		}
		else
		{
			// c for category, p for product
			ReplaceStringEx(sInfo, sizeof(sInfo), "p", "");
		}

		if (bCategory)
		{
			int iCategory = FindCategoryByIdentifier(sInfo);
			BuildBuyMenu(client, iCategory);
		}
		else
		{
			char sFirstArg[64];

			BreakString(sInfo, sFirstArg, sizeof(sFirstArg));

			ShowConfirmPurchaseMenu(client, sFirstArg);
		}
	}
	return 0;
}

void ShowConfirmPurchaseMenu(int client, char[] sFirstArg)
{
	enProduct product;

	LookupProductByAlias(sFirstArg, product);

	Handle hMenu = CreateMenu(ConfirmBuyMenu_Handler);

	Call_StartForward(g_fwOnGetParametersProduct);

	enProduct alteredProduct;
	alteredProduct = product;

	Call_PushCell(client);
	Call_PushString(alteredProduct.sAliases);
	Call_PushStringEx(alteredProduct.sInfo, sizeof(enProduct::sInfo), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(alteredProduct.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(alteredProduct.sDescription, sizeof(enProduct::sDescription), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(client);
	Call_PushCellRef(alteredProduct.fCost);
	Call_PushFloatRef(alteredProduct.fDelay);
	Call_PushFloatRef(alteredProduct.fCooldown);

	Call_Finish();

	if (alteredProduct.sDescription[0] != EOS)
		SetMenuTitle(hMenu, "%s\nCost: %i\nDescription: %s\nYour Points: %i", alteredProduct.sName, RoundToFloor(alteredProduct.fCost), alteredProduct.sDescription, GetClientPoints(client));

	else
		SetMenuTitle(hMenu, "%s\nCost: %i\nYour Points: %i", alteredProduct.sName, RoundToFloor(alteredProduct.fCost), GetClientPoints(client));

	SetMenuExitBackButton(hMenu, true);

	AddMenuItem(hMenu, sFirstArg, "Yes");

	char sInfo[16];
	IntToString(product.iCategory, sInfo, sizeof(sInfo));

	AddMenuItem(hMenu, sInfo, "No");

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int ConfirmBuyMenu_Handler(Handle hMenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
		CloseHandle(hMenu);

	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack)
	{
		// 1 = The "No" item that we gave the category number
		char sInfo[16];
		GetMenuItem(hMenu, 1, sInfo, sizeof(sInfo));

		BuildBuyMenu(client, StringToInt(sInfo));
	}
	else if (action == MenuAction_Select)
	{
		if (item == 0)
		{
			char sFirstArg[64];
			GetMenuItem(hMenu, item, sFirstArg, sizeof(sFirstArg));

			char sArgString[16];

			FormatEx(sArgString, sizeof(sArgString), "#%i", GetClientUserId(client));

			PerformPurchaseOnAlias(client, sFirstArg, sArgString);
		}
	}

	return 0;
}

stock bool IsTeamSurvivor(int client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (GetClientTeam(client) != 2) return false;
	return true;
}

stock bool IsTeamInfected(int client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (GetClientTeam(client) != 3) return false;
	return true;
}

stock int GetTanksCount()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (!IsPlayerAlive(i) || !IsTeamInfected(i))
			continue;

		else if (GetEntProp(i, Prop_Send, "m_zombieClass") != view_as<int>(L4D2ZombieClass_Tank))
			continue;

		count++;
	}

	return count;
}
/*
stock int CalculateGhostCost()
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
*/
stock void ExecuteFullHeal(int client)
{
	if (GetClientTeam(client) == view_as<int>(L4DTeam_Survivor))
	{
		bool bIncap, bPinned;
		bIncap  = L4D_IsPlayerIncapacitated(client);
		bPinned = L4D_IsPlayerPinned(client);
		if (bIncap && bPinned)
		{
			Handle convar = FindConVar("survivor_incap_health");

			SetEntityHealth(client, GetConVarInt(convar));
		}
		else if (bIncap)
		{
			FullyHealPlayer(client);

			if (L4D_IsPlayerIncapacitated(client))
				L4D2_VScriptWrapper_ReviveFromIncap(client);

			SetEntityHealthToMax(client);
		}
		else
		{
			FullyHealPlayer(client);

			if (L4D_IsPlayerIncapacitated(client))
				L4D2_VScriptWrapper_ReviveFromIncap(client);

			SetEntityHealthToMax(client);
		}
	}
	else
	{
		SetEntityHealthToMax(client);
	}

	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
}

stock void SetEntityHealthToMax(int entity)
{
	SetEntityHealth(entity, GetEntProp(entity, Prop_Send, "m_iMaxHealth"));
}

stock void FullyHealPlayer(int client)
{
	char code[512];

	FormatEx(code, sizeof(code), "ret <- GetPlayerFromUserID(%d).GiveItem(\"health\"); <RETURN>ret</RETURN>", GetClientUserId(client));

	char sOutput[512];
	L4D2_GetVScriptOutput(code, sOutput, sizeof(sOutput));
}
stock int LookupProductByAlias(char[] sAlias, enProduct finalProduct)
{
	int iSize = GetArraySize(g_aProducts);

	for (int i = 0; i < iSize; i++)
	{
		enProduct product;
		GetArrayArray(g_aProducts, i, product);

		char sAliasArray[8][32];
		int  iAliasSize = ExplodeString(product.sAliases, " ", sAliasArray, sizeof(sAliasArray), sizeof(sAliasArray[]));

		for (int a = 0; a < iAliasSize; a++)
		{
			if (StrEqual(sAlias, sAliasArray[a], false))
			{
				finalProduct = product;

				return i;
			}
		}
	}

	return -1;
}

stock void PerformPurchaseOnAlias(int client, char[] sFirstArg, char[] sSecondArg)
{
	if (GetClientTeam(client) != view_as<int>(L4DTeam_Survivor) && GetClientTeam(client) != view_as<int>(L4DTeam_Infected))
	{
		PrintToChat(client, "\x04[PS]\x03 Error: You must be in-game!");
		return;
	}

	enProduct product;

	int productPos = LookupProductByAlias(sFirstArg, product);

	if (productPos == -1)
	{
		PrintToChat(client, "\x04[PS]\x03 Error: Product could not be found!");
		return;
	}

	char target_name[MAX_TARGET_LENGTH];
	int  fake_target_list[MAXPLAYERS + 1], fake_target_count;
	int  target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;

	fake_target_count = ProcessTargetString(
		sSecondArg,
		client,
		fake_target_list,
		MAXPLAYERS + 1,
		COMMAND_FILTER_NO_IMMUNITY,
		target_name,
		sizeof(target_name),
		tn_is_ml);

	if (fake_target_count > 0)
	{
		for (int i = 0; i < fake_target_count; i++)
		{
			int targetclient = fake_target_list[i];

			if (GetClientTeam(client) == GetClientTeam(targetclient))
			{
				target_list[target_count++] = targetclient;
			}
		}
	}
	// To handle errors.
	else
		target_count = fake_target_count;

	if (target_count <= 0)
	{
		ReplyToTargetError(client, target_count);
		return;
	}

	for (int i = 0; i < target_count; i++)
	{
		int targetclient = target_list[i];

		ResetGlobalError();

		Call_StartForward(g_fwOnCanBuyProducts);

		Call_PushCell(client);
		Call_PushCell(targetclient);

		Action result;
		Call_Finish(result);

		if (result >= Plugin_Handled)
		{
			if (g_error[0] != EOS)
				PrintToChat(client, g_error);

			return;
		}

		Call_StartForward(g_fwOnGetParametersProduct);

		enProduct alteredProduct;
		alteredProduct = product;

		Call_PushCell(client);
		Call_PushString(alteredProduct.sAliases);
		Call_PushStringEx(alteredProduct.sInfo, sizeof(enProduct::sInfo), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushStringEx(alteredProduct.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushStringEx(alteredProduct.sDescription, sizeof(enProduct::sDescription), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(targetclient);
		Call_PushCellRef(alteredProduct.fCost);
		Call_PushFloatRef(alteredProduct.fDelay);
		Call_PushFloatRef(alteredProduct.fCooldown);

		Call_Finish();

		alteredProduct.fCost = float(RoundToFloor(alteredProduct.fCost));

		char sError[256];
		bool bShouldReturn;

		if (PSAPI_GetErrorFromBuyflags(client, sFirstArg, alteredProduct, targetclient, sError, sizeof(sError), bShouldReturn))
		{
			PrintToChat(client, sError);

			if (bShouldReturn)
				return;

			else
				continue;
		}

		ResetGlobalError();

		Call_StartForward(g_fwOnTryBuyProduct);

		Call_PushCell(client);
		Call_PushString(alteredProduct.sInfo);
		Call_PushString(alteredProduct.sAliases);
		Call_PushString(alteredProduct.sName);
		Call_PushCell(targetclient);
		Call_PushCell(alteredProduct.fCost);
		Call_PushFloat(alteredProduct.fDelay);
		Call_PushFloat(alteredProduct.fCooldown);

		result = Plugin_Continue;
		Call_Finish(result);

		if (result >= Plugin_Handled)
		{
			if (g_error[0] != EOS)
				PrintToChat(client, g_error);

			continue;
		}

		g_fPoints[client] -= alteredProduct.fCost;

		SetArrayArray(g_aProducts, productPos, product);

		Handle   hTimer;
		DataPack DP;

		char sTargetName[64];
		GetClientName(targetclient, sTargetName, sizeof(sTargetName));

		// Creating a 0.0 timer will trigger it instantly, no time to populate the datapack.
		if (alteredProduct.fDelay < 0.1)
		{
			hTimer = CreateDataTimer(1.0, Timer_DelayGiveProduct, DP, TIMER_FLAG_NO_MAPCHANGE);

			if (targetclient == client)
			{
				if (GetConVarBool(Notifications))
					PrintToChat(client, "\x04[PS]\x03 Bought\x04 %s\x03 for\x05 yourself\x03 (??: \x05%d\x03)", alteredProduct.sName, GetClientPoints(client));
			}
			else
			{
				PrintToChat(client, "\x04[PS]\x03 Successfully bought\x04 %s\x03 for Player\x05 %N\x03 (??: \x05%d\x03)", alteredProduct.sName, targetclient, GetClientPoints(client));
				PrintToChat(targetclient, "\x04[PS]\x03 Player \x05%N \x03bought you\x04 %s", client, sFirstArg);
			}
		}
		else
		{
			hTimer = CreateDataTimer(0.1, Timer_DelayGiveProduct, DP, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

			if (targetclient == client)
			{
				PrintToChat(client, "\x04[PS]\x03 You will buy\x04 %s\x03 for\x05 yourself\x03 in %.1fsec\x03  (??: \x05%d\x03)", alteredProduct.sName, alteredProduct.fDelay, GetClientPoints(client));
			}
			else
			{
				PrintToChat(client, "\x04[PS]\x03 You will buy\x04 %s\x03 for Player\x05 %N\x03 in %.1fsec\x03  (??: \x05%d\x03)", alteredProduct.sName, targetclient, alteredProduct.fDelay, GetClientPoints(client));
				PrintToChat(targetclient, "\x04[PS]\x03 Player \x05%N \x03will buy you\x04 %s\x03 in %.1fsec", client, alteredProduct.sName, alteredProduct.fDelay);
			}
		}

		DP.WriteFloat(alteredProduct.fDelay);
		DP.WriteCell(GetClientUserId(client));
		DP.WriteCell(GetClientUserId(targetclient));
		DP.WriteString(sFirstArg);
		DP.WriteCellArray(alteredProduct, sizeof(alteredProduct));

		product.fNextBuyProduct[targetclient] = GetGameTime() + alteredProduct.fDelay + alteredProduct.fCooldown;

		enDelayedProduct dProduct;

		dProduct.timer        = hTimer;
		dProduct.fCost        = alteredProduct.fCost;
		dProduct.buyerUserId  = GetClientUserId(client);
		dProduct.targetUserId = GetClientUserId(targetclient);
		FormatEx(dProduct.sAlias, strlen(sFirstArg) + 1, sFirstArg);
		dProduct.sInfo = alteredProduct.sInfo;

		PushArrayArray(g_aDelayedProducts, dProduct);

		if (alteredProduct.fDelay < 0.1)
			TriggerTimer(hTimer, true);
	}
}

public Action Timer_DelayGiveProduct(Handle hTimer, DataPack DP)
{
	DP.Reset();

	float fTimeleft    = DP.ReadFloat();
	int   client       = GetClientOfUserId(DP.ReadCell());
	int   targetclient = GetClientOfUserId(DP.ReadCell());
	char  sFirstArg[32];

	DP.ReadString(sFirstArg, sizeof(sFirstArg));

	enProduct alteredProduct;
	DP.ReadCellArray(alteredProduct, sizeof(alteredProduct));

	DP.Reset();

	fTimeleft -= 0.1;

	DP.WriteFloat(fTimeleft);

	enProduct product;

	int productPos = LookupProductByAlias(sFirstArg, product);

	// Should not happen
	if (productPos == -1)
	{
		PrintToChat(client, "\x04[PS]\x03 Error: Product could not be found!");

		RemoveDelayedProductByTimer(hTimer);

		return Plugin_Stop;
	}

	else if (client == targetclient && client == 0)
	{
		RemoveDelayedProductByTimer(hTimer);

		return Plugin_Stop;
	}

	else if (targetclient == 0)
	{
		RemoveDelayedProductByTimer(hTimer);
		g_fPoints[client] += alteredProduct.fCost;
		PrintToChat(client, "\x04[PS]\x03 Refunded %s\x05 + %d\x03 points(??: \x05%d\x03)", sFirstArg, RoundToFloor(alteredProduct.fCost), GetClientPoints(client));
		return Plugin_Stop;
	}

	if (alteredProduct.iBuyFlags & BUYFLAG_REALTIME_REFUNDS)
	{
		ResetGlobalError();

		Call_StartForward(g_fwOnCanBuyProducts);

		Call_PushCell(client);
		Call_PushCell(targetclient);

		Action result;
		Call_Finish(result);

		if (result >= Plugin_Handled)
		{
			g_fPoints[client] += alteredProduct.fCost;

			if (alteredProduct.fCost > 0)
			{
				alteredProduct.fNextBuyProduct[targetclient] = 0.0;
				SetArrayArray(g_aProducts, productPos, product);

				PSAPI_SetErrorByPriority(50, "\x04[PS]\x03 Refunded %s\x05 + %d\x03 points(??: \x05%d\x03)", sFirstArg, RoundToFloor(alteredProduct.fCost), GetClientPoints(client));

				PrintToChat(client, g_error);
			}

			RemoveDelayedProductByTimer(hTimer);

			return Plugin_Stop;
		}

		ResetGlobalError();

		Call_StartForward(g_fwOnRealTimeRefundProduct);

		Call_PushCell(client);
		Call_PushString(alteredProduct.sInfo);
		Call_PushString(alteredProduct.sAliases);
		Call_PushString(alteredProduct.sName);
		Call_PushCell(targetclient);
		Call_PushCell(alteredProduct.fCost);
		Call_PushFloat(fTimeleft);

		result = Plugin_Continue;
		Call_Finish(result);

		if (result >= Plugin_Handled)
		{
			g_fPoints[client] += alteredProduct.fCost;

			if (alteredProduct.fCost > 0)
			{
				alteredProduct.fNextBuyProduct[targetclient] = 0.0;
				SetArrayArray(g_aProducts, productPos, product);

				PSAPI_SetErrorByPriority(50, "\x04[PS]\x03 Refunded %s\x05 + %d\x03 points(??: \x05%d\x03)", sFirstArg, RoundToFloor(alteredProduct.fCost), GetClientPoints(client));

				PrintToChat(client, g_error);
			}

			RemoveDelayedProductByTimer(hTimer);

			return Plugin_Stop;
		}
	}

	if (fTimeleft > 0.0)
		return Plugin_Continue;

	ResetGlobalError();

	Call_StartForward(g_fwOnCanBuyProducts);

	Call_PushCell(client);
	Call_PushCell(targetclient);

	Action result;
	Call_Finish(result);

	if (result >= Plugin_Handled)
	{
		if (g_error[0] != EOS)
			PrintToChat(client, g_error);

		RemoveDelayedProductByTimer(hTimer);

		return Plugin_Stop;
	}

	ResetGlobalError();

	Call_StartForward(g_fwOnBuyProductPost);

	Call_PushCell(client);
	Call_PushString(alteredProduct.sInfo);
	Call_PushString(alteredProduct.sAliases);
	Call_PushString(alteredProduct.sName);
	Call_PushCell(targetclient);
	Call_PushCell(alteredProduct.fCost);
	Call_PushFloat(alteredProduct.fDelay);
	Call_PushFloat(alteredProduct.fCooldown);

	result = Plugin_Continue;
	Call_Finish(result);

	if (result >= Plugin_Handled)
	{
		g_fPoints[client] += alteredProduct.fCost;

		if (alteredProduct.fCost > 0)
		{
			product.fNextBuyProduct[targetclient] = 0.0;
			SetArrayArray(g_aProducts, productPos, product);
			PSAPI_SetErrorByPriority(50, "\x04[PS]\x03 Refunded %s\x05 + %d\x03 points(??: \x05%d\x03)", sFirstArg, RoundToFloor(alteredProduct.fCost), GetClientPoints(client));

			PrintToChat(client, g_error);
		}

		RemoveDelayedProductByTimer(hTimer);

		return Plugin_Stop;
	}

	Call_StartForward(g_fwOnShouldGiveProduct);

	Call_PushCell(client);
	Call_PushString(alteredProduct.sInfo);
	Call_PushString(alteredProduct.sAliases);
	Call_PushString(alteredProduct.sName);
	Call_PushCell(targetclient);
	Call_PushCell(alteredProduct.fCost);
	Call_PushFloat(alteredProduct.fDelay);
	Call_PushFloat(alteredProduct.fCooldown);

	Call_Finish(result);

	if (result >= Plugin_Handled)
	{
		g_fPoints[client] += alteredProduct.fCost;

		if (alteredProduct.fCost > 0)
		{
			product.fNextBuyProduct[targetclient] = 0.0;
			SetArrayArray(g_aProducts, productPos, product);
			PSAPI_SetErrorByPriority(50, "\x04[PS]\x03 Refunded %s\x05 + %d\x03 points(??: \x05%d\x03)", sFirstArg, RoundToFloor(alteredProduct.fCost), GetClientPoints(client));

			PrintToChat(client, g_error);
		}

		RemoveDelayedProductByTimer(hTimer);

		return Plugin_Stop;
	}

	RemoveDelayedProductByTimer(hTimer);

	return Plugin_Stop;
}

stock void ResetProductCooldowns()
{
	int iSize = GetArraySize(g_aProducts);

	for (int i = 0; i < iSize; i++)
	{
		enProduct product;
		GetArrayArray(g_aProducts, i, product);

		for (int a = 0; a < sizeof(product.fNextBuyProduct); a++)
			product.fNextBuyProduct[a] = 0.0;

		SetArrayArray(g_aProducts, i, product);
	}
}

stock void DeleteProductsByAliases(char[] sAliases)
{
	// i can be decremented, mustn't use int iSize = GetArraySize(g_aProducts)
	for (int i = 0; i < GetArraySize(g_aProducts); i++)
	{
		enProduct product;
		GetArrayArray(g_aProducts, i, product);

		char sAliasArray[8][32];
		int  iAliasSize = ExplodeString(product.sAliases, " ", sAliasArray, sizeof(sAliasArray), sizeof(sAliasArray[]));

		char sAliasArray2[8][32];
		int  iAliasSize2 = ExplodeString(sAliases, " ", sAliasArray2, sizeof(sAliasArray2), sizeof(sAliasArray2[]));

		for (int a = 0; a < iAliasSize; a++)
		{
			for (int b = 0; b < iAliasSize2; b++)
			{
				if (StrEqual(sAliasArray[a], sAliasArray2[b], false))
				{
					RemoveFromArray(g_aProducts, i);

					// Exit the loops of "a" and "b", re-do the item in loop of "i".
					a = iAliasSize;
					b = iAliasSize2;
					i--;
				}
			}
		}
	}
}

stock int FindCategoryByIdentifier(char[] sID)
{
	// i can be decremented, mustn't use int iSize = GetArraySize(g_aProducts)
	for (int i = 0; i < GetArraySize(g_aCategories); i++)
	{
		enCategory cat;
		GetArrayArray(g_aCategories, i, cat);

		if (StrEqual(cat.sID, sID, false))
		{
			return i;
		}
	}

	return -1;
}

stock int FindEntityByTargetname(int startEnt, const char[] TargetName, bool caseSensitive, bool bContains)    // Same as FindEntityByClassname with sensitivity and contain features
{
	int entCount = GetEntityCount();

	char EntTargetName[300];

	for (int i = startEnt + 1; i < entCount; i++)
	{
		if (!IsValidEntity(i))
			continue;

		else if (!IsValidEdict(i))
			continue;

		GetEntPropString(i, Prop_Data, "m_iName", EntTargetName, sizeof(EntTargetName));

		if ((StrEqual(EntTargetName, TargetName, caseSensitive) && !bContains) || (StrContains(EntTargetName, TargetName, caseSensitive) != -1 && bContains))
			return i;
	}

	return -1;
}

stock int GetClientPoints(int client)
{
	return RoundToFloor(g_fPoints[client]);
}

/**
 * Adds an informational string to the server's public "tags".
 * This string should be a short, unique identifier.
 *
 *
 * @param tag            Tag string to append.
 * @noreturn
 */
stock void AddServerTag2(const char[] tag)
{
	Handle hTags = INVALID_HANDLE;
	hTags        = FindConVar("sv_tags");

	if (hTags != INVALID_HANDLE)
	{
		int flags = GetConVarFlags(hTags);

		SetConVarFlags(hTags, flags & ~FCVAR_NOTIFY);

		char tags[50];    // max size of sv_tags cvar
		GetConVarString(hTags, tags, sizeof(tags));
		if (StrContains(tags, tag, true) > 0) return;
		if (strlen(tags) == 0)
		{
			Format(tags, sizeof(tags), tag);
		}
		else
		{
			Format(tags, sizeof(tags), "%s,%s", tags, tag);
		}
		SetConVarString(hTags, tags, true);

		SetConVarFlags(hTags, flags);
	}
}

/**
 * Removes a tag previously added by the calling plugin.
 *
 * @param tag            Tag string to remove.
 * @noreturn
 */
stock void RemoveServerTag2(const char[] tag)
{
	Handle hTags = INVALID_HANDLE;
	hTags        = FindConVar("sv_tags");

	if (hTags != INVALID_HANDLE)
	{
		int flags = GetConVarFlags(hTags);

		SetConVarFlags(hTags, flags & ~FCVAR_NOTIFY);

		char tags[50];    // max size of sv_tags cvar
		GetConVarString(hTags, tags, sizeof(tags));
		if (StrEqual(tags, tag, true))
		{
			Format(tags, sizeof(tags), "");
			SetConVarString(hTags, tags, true);
			return;
		}

		int pos = StrContains(tags, tag, true);
		int len = strlen(tags);
		if (len > 0 && pos > -1)
		{
			bool found;
			char taglist[50][50];
			ExplodeString(tags, ",", taglist, sizeof(taglist[]), sizeof(taglist));
			for (int i = 0; i < sizeof(taglist[]); i++)
			{
				if (StrEqual(taglist[i], tag, true))
				{
					Format(taglist[i], sizeof(taglist), "");
					found = true;
					break;
				}
			}
			if (!found) return;
			ImplodeStrings(taglist, sizeof(taglist[]), ",", tags, sizeof(tags));
			if (pos == 0)
			{
				tags[0] = 0x20;
			}
			else if (pos == len - 1)
			{
				Format(tags[strlen(tags) - 1], sizeof(tags), "");
			}
			else
			{
				ReplaceString(tags, sizeof(tags), ",,", ",");
			}

			SetConVarString(hTags, tags, true);

			SetConVarFlags(hTags, flags);
		}
	}
}

stock void ResetGlobalError()
{
	g_error[0]      = EOS;
	g_errorPriority = 0;
}

stock bool RemoveDelayedProductByTimer(Handle hTimer)
{
	// i can be decremented, mustn't use int iSize = GetArraySize(g_aProducts)
	for (int i = 0; i < GetArraySize(g_aDelayedProducts); i++)
	{
		enDelayedProduct dProduct;
		GetArrayArray(g_aDelayedProducts, i, dProduct);

		if (dProduct.timer == hTimer)
		{
			RemoveFromArray(g_aDelayedProducts, i);
			return true;
		}
	}

	return false;
}