/* put the line below after all of the includes!
#pragma newdecls required
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ps_api>

#pragma newdecls required
#define PLUGIN_TITLE	"Point System API"
float version = 1.0;

ArrayList g_aCategories, g_aProducts;

GlobalForward g_fwOnGetParametersCategory; // Do not print errors here!!!
GlobalForward g_fwOnGetParametersProduct; // Do not print errors here!!!
GlobalForward g_fwOnTryBuyProduct; // Calculated before the delay.
GlobalForward g_fwOnBuyProductPost; // Calculated after the delay.
GlobalForward g_fwOnShouldGiveProduct; // We should now give the product to the user, because the delay has passed and not refunded.


float g_fPoints[MAXPLAYERS+1] = { 0.0, ... };
float g_fSavedSurvivorPoints[MAXPLAYERS+1], g_fSavedInfectedPoints[MAXPLAYERS+1] = {0.0, ... };

int MultipleDamageStack[MAXPLAYERS+1], SpitterDamageStack[MAXPLAYERS+1];
float NextMultipleDamage[MAXPLAYERS + 1], NextSpitterDamage[MAXPLAYERS + 1];



char g_sLastBoughtAlias[MAXPLAYERS + 1];
char g_sLastBoughtTargetArg[MAXPLAYERS + 1];

char MapName[30];
int hurtcount[MAXPLAYERS+1] = { 0, ... };
int protectcount[MAXPLAYERS+1] = { 0, ... };
int tankburning[MAXPLAYERS+1] = { 0, ... };
int tankbiled[MAXPLAYERS+1] = { 0, ... };
int witchburning[MAXPLAYERS+1] = { 0, ... };
int killcount[MAXPLAYERS+1] = { 0, ... };
int headshotcount[MAXPLAYERS+1] = { 0, ... };
//Definitions to save space
#define ATTACKER int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
#define CLIENT int client = GetClientOfUserId(GetEventInt(event, "userid"));
#define ACHECK2 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define CCHECK2 if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define ACHECK3 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define CCHECK3 if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 3 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
//Other
Handle Enable = INVALID_HANDLE;
Handle Modes = INVALID_HANDLE;
Handle Notifications = INVALID_HANDLE;
//Item buyables
/*

Handle PointsHeal = INVALID_HANDLE;
*/
//Survivor point earning things
Handle SValueKillingSpree = INVALID_HANDLE;
Handle SNumberKill = INVALID_HANDLE;
Handle SValueHeadSpree = INVALID_HANDLE;
Handle SNumberHead = INVALID_HANDLE;
Handle SSIKill = INVALID_HANDLE;
Handle STankKill = INVALID_HANDLE;
Handle SWitchKill = INVALID_HANDLE;
Handle SWitchCrown = INVALID_HANDLE;
Handle SHeal = INVALID_HANDLE;
Handle SHealWarning = INVALID_HANDLE;
Handle SProtect = INVALID_HANDLE;
Handle SRevive = INVALID_HANDLE;
Handle SLedge = INVALID_HANDLE;
Handle SDefib = INVALID_HANDLE;
Handle STBurn = INVALID_HANDLE;
Handle STSolo = INVALID_HANDLE;
Handle SWBurn = INVALID_HANDLE;
Handle STag = INVALID_HANDLE;
//Infected point earning things
Handle IChoke = INVALID_HANDLE;
Handle IPounce = INVALID_HANDLE;
Handle ICarry = INVALID_HANDLE;
Handle IImpact = INVALID_HANDLE;
Handle IRide = INVALID_HANDLE;
Handle ITag = INVALID_HANDLE;
Handle IIncap = INVALID_HANDLE;
Handle IHurt = INVALID_HANDLE;
Handle IKill = INVALID_HANDLE;
Handle IKarma = INVALID_HANDLE;
//Infected buyables
/*
Handle PointsJmob = INVALID_HANDLE;
Handle PointsGoggles = INVALID_HANDLE;
Handle MaxWitchesAlive = INVALID_HANDLE;
//Catergory Enables
Handle CatRifles = INVALID_HANDLE;
Handle CatSMG = INVALID_HANDLE;
Handle CatSnipers = INVALID_HANDLE;
Handle CatShotguns = INVALID_HANDLE;
Handle CatHealth = INVALID_HANDLE;
Handle CatUpgrades = INVALID_HANDLE;
Handle CatThrowables = INVALID_HANDLE;
Handle CatMisc = INVALID_HANDLE;
Handle CatMelee = INVALID_HANDLE;
Handle CatWeapons = INVALID_HANDLE;

//Misc
Handle TankLimit = INVALID_HANDLE;
Handle WitchLimit = INVALID_HANDLE;
*/
Handle ResetPoints = INVALID_HANDLE;
Handle StartPoints = INVALID_HANDLE;
//new Handle:ChangeTeam = INVALID_HANDLE;
//Handle BuyTankHealLimit = INVALID_HANDLE;
//Handle HelpTimer = INVALID_HANDLE;
//Handle HelpDelay = INVALID_HANDLE;

bool g_bIsAreaStart = false;


public Plugin myinfo = 
{
	name = "[L4D2] Points System API",
	author = "Eyal282 [Complete remake of McFlurry's script]",
	description = "Points system to buy products on the fly.",
	version = PLUGIN_TITLE,
	url = "N/A"
}

public void OnPluginStart()
{
	g_aCategories = new ArrayList(sizeof(enCategory));
	g_aProducts = new ArrayList(sizeof(enProduct));
	
	g_fwOnGetParametersCategory = CreateGlobalForward("PointSystemAPI_OnGetParametersCategory", ET_Event, Param_Cell, Param_String, Param_String);
	
	g_fwOnGetParametersProduct = CreateGlobalForward("PointSystemAPI_OnGetParametersProduct", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_String, Param_Cell, Param_CellByRef, Param_FloatByRef, Param_FloatByRef);
	
	g_fwOnTryBuyProduct = CreateGlobalForward("PointSystemAPI_OnTryBuyProduct", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Float, Param_Float);
	
	g_fwOnBuyProductPost = CreateGlobalForward("PointSystemAPI_OnBuyProductPost", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Float, Param_Float);
	
	g_fwOnShouldGiveProduct = CreateGlobalForward("PointSystemAPI_OnShouldGiveProduct", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Float, Param_Float);
	
	char game_name[128];
	GetGameFolderName(game_name, sizeof(game_name));
	if(!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("This plugin only supports Left 4 Dead 2");
	}	
	LoadTranslations("common.phrases");
	
	AutoExecConfig_SetFile("PointSystemAPI");
	
	StartPoints = AutoExecConfig_CreateConVar("l4d2_points_start", "0", "Points to start each round/map with.");
	Notifications = AutoExecConfig_CreateConVar("l4d2_points_notify", "1", "Show messages when points are earned?");
	Enable = AutoExecConfig_CreateConVar("l4d2_points_enable", "1", "Enable Point System?");
	Modes = AutoExecConfig_CreateConVar("l4d2_points_modes", "coop,realism,versus,teamversus", "Which game modes to use Point System");
	ResetPoints = AutoExecConfig_CreateConVar("l4d2_points_reset_mapchange", "versus,teamversus", "Which game modes to reset point count on round end and round start");
	SValueKillingSpree = AutoExecConfig_CreateConVar("l4d2_points_cikill_value", "2", "How many points does killing a certain amount of infected earn");
	SNumberKill = AutoExecConfig_CreateConVar("l4d2_points_cikills", "25", "How many kills you need to earn a killing spree bounty");
	SValueHeadSpree = AutoExecConfig_CreateConVar("l4d2_points_headshots_value", "4", "How many points does killing a certain amount of infected with headshots earn");
	SNumberHead = AutoExecConfig_CreateConVar("l4d2_points_headshots", "20", "How many kills you need to earn a killing spree bounty");
	SSIKill = AutoExecConfig_CreateConVar("l4d2_points_sikill", "1", "How many points does killing a special infected earn");
	STankKill = AutoExecConfig_CreateConVar("l4d2_points_tankkill", "2", "How many points does killing a tank earn");
	SWitchKill = AutoExecConfig_CreateConVar("l4d2_points_witchkill", "4", "How many points does killing a witch earn");
	SWitchCrown = AutoExecConfig_CreateConVar("l4d2_points_witchcrown", "2", "How many points does crowning a witch earn");
	SHeal = AutoExecConfig_CreateConVar("l4d2_points_heal", "5", "How many points does healing a team mate earn");
	SProtect = AutoExecConfig_CreateConVar("l4d2_points_protect", "1", "How many points does protecting a team mate earn");
	SHealWarning = AutoExecConfig_CreateConVar("l4d2_points_heal_warning", "1", "How many points does healing a team mate who did not need healing earn");
	SRevive = AutoExecConfig_CreateConVar("l4d2_points_revive", "3", "How many points does reviving a team mate earn");
	SLedge = AutoExecConfig_CreateConVar("l4d2_points_ledge", "1", "How many points does reviving a hanging team mate earn");
	SDefib = AutoExecConfig_CreateConVar("l4d2_points_defib_action", "5", "How many points does defibbing a team mate earn");
	STBurn = AutoExecConfig_CreateConVar("l4d2_points_tankburn", "2", "How many points does burning a tank earn");
	STSolo = AutoExecConfig_CreateConVar("l4d2_points_tanksolo", "8", "How many points does killing a tank single-handedly earn");
	SWBurn = AutoExecConfig_CreateConVar("l4d2_points_witchburn", "1", "How many points does burning a witch earn");
	STag = AutoExecConfig_CreateConVar("l4d2_points_bile_tank", "2", "How many points does biling a tank earn");
	IChoke = AutoExecConfig_CreateConVar("l4d2_points_smoke", "2", "How many points does smoking a survivor earn");
	IPounce = AutoExecConfig_CreateConVar("l4d2_points_pounce", "1", "How many points does pouncing a survivor earn");
	ICarry = AutoExecConfig_CreateConVar("l4d2_points_charge", "2", "How many points does charging a survivor earn");
	IImpact = AutoExecConfig_CreateConVar("l4d2_points_impact", "1", "How many points does impacting a survivor earn");
	IRide = AutoExecConfig_CreateConVar("l4d2_points_ride", "2", "How many points does riding a survivor earn");
	ITag = AutoExecConfig_CreateConVar("l4d2_points_boom", "1", "How many points does booming a survivor earn");
	IIncap = AutoExecConfig_CreateConVar("l4d2_points_incap", "3", "How many points does incapping a survivor earn");
	IHurt = AutoExecConfig_CreateConVar("l4d2_points_damage", "2", "How many points does doing damage earn");
	IKill = AutoExecConfig_CreateConVar("l4d2_points_kill", "5", "How many points does killing a survivor earn");
	IKarma = AutoExecConfig_CreateConVar("l4d2_points_karma", "5", "How many points does registering a karma event earn");
	
	// This makes an internal call to AutoExecConfig with the given configfile
	AutoExecConfig_ExecuteFile();

	// Cleaning should be done at the end
	AutoExecConfig_CleanFile();
	
	RegConsoleCmd("sm_rebuy", Command_Rebuy);
	RegConsoleCmd("sm_buystuff", BuyMenu);
	RegConsoleCmd("sm_buy", BuyMenu);
	RegConsoleCmd("sm_b", BuyMenu);
	RegConsoleCmd("sm_usepoints", BuyMenu);
	RegConsoleCmd("sm_points", ShowPoints);
	RegConsoleCmd("sm_send", Command_SendPoints, "sm_sendpoints <target> [amount]");
	RegConsoleCmd("sm_sendpoints", Command_SendPoints, "sm_sendpoints <target> [amount]");
	RegConsoleCmd("sm_sp", Command_SendPoints, "sm_sendpoints <target> [amount]");
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
	HookEvent ("player_team", Event_ChangeTeam, EventHookMode_Pre);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_Post);
}

public void L4D_OnServerHibernationUpdate(bool hibernating)
{
	if(!hibernating)
		RegPluginLibrary("PointSystemAPI");
}
// Global Forward
public void KarmaKillSystem_OnKarmaEventPost(int victim, int attacker, const char[] KarmaName)
{
	int Points = GetConVarInt(IKarma);
	
	g_fPoints[attacker] += float(Points);
	
	PrintToChat(attacker, "\x04[PS]\x01 Karma %s'd!!! + \x05%d\x03 points (Total: \x05%d\x03)", KarmaName, Points, GetClientPoints(attacker));
}
public Action CheckMultipleDamage(Handle hTimer, any number)
{
	if(!g_bIsAreaStart)
		return Plugin_Stop;
	
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i))
			continue;
			
		else if(!IsTeamInfected(i))
			continue;
		
		if(GetConVarBool(Notifications) && NextMultipleDamage[i] <= GetEngineTime() && MultipleDamageStack[i] != 0) 
		{
			NextMultipleDamage[i] = GetEngineTime() + 10.0;
			PrintToChat(i, "\x04[PS]\x03 Multiple Damage + \x05%d\x03 points *\x05 %dx\x03 =\x05 %d\x03 (Σ: \x05%d\x03)", GetConVarInt(IHurt), MultipleDamageStack[i] / GetConVarInt(IHurt), MultipleDamageStack[i], GetClientPoints(i));
			MultipleDamageStack[i] = 0;
		}
	}
	
	return Plugin_Continue;
}

public void OnMapStart()
{
	CreateTimer(1.0, Timer_Cleanup, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
	GetCurrentMap(MapName, sizeof(MapName));
	g_bIsAreaStart = false;
}	


public Action Timer_Cleanup(Handle hTimer)
{
	int iEntity = -1;
	
	while((iEntity = FindEntityByTargetname(iEntity, "PointSystemAPI", false, true)) != -1)
	{
		if(!HasEntProp(iEntity, Prop_Data, "m_hOwnerEntity") || GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity") != -1)
			continue;
		
		char sTargetname[64];
		GetEntPropString(iEntity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
		
		ReplaceStringEx(sTargetname, sizeof(sTargetname), "PointSystemAPI ", "");
		
		int iSecondsLeft = StringToInt(sTargetname);
		
		if(iSecondsLeft <= 0)
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
	for(int i=0;i < MaxEntities;i++)
	{
		if(!IsValidEdict(i))
			continue;
		
		GetEdictClassname(i, Classname, sizeof(Classname));
		
		if(StrEqual(Classname, "infected", true))
			AcceptEntityInput(i, "Kill");
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("PSAPI_CreateCategory", Native_CreateCategory);
	CreateNative("PSAPI_CreateProduct", Native_CreateProduct);
	CreateNative("PSAPI_FetchProductCostByAlias", Native_FetchProductCostByAlias);
	CreateNative("PSAPI_GetVersion", Native_GetVersion);
	CreateNative("PSAPI_SetPoints", Native_SetPoints);
	CreateNative("PSAPI_HardSetPoints", Native_HardSetPoints);
	CreateNative("PSAPI_GetPoints", Native_GetPoints);
	CreateNative("PSAPI_FullHeal", Native_FullHeal);
	
	RegPluginLibrary("PointSystemAPI");
	
	return APLRes_Success;
}

public any Native_CreateCategory(Handle plugin, int numParams)
{
	enCategory cat;	
	
	cat.iCategory = GetNativeCell(1);
	GetNativeString(2, cat.sID, sizeof(enCategory::sID));
	GetNativeString(3, cat.sName, sizeof(enCategory::sName));
	cat.iBuyFlags = GetNativeCell(4);
	
	int iCategory = FindCategoryByIdentifier(cat.sID);
	
	if(iCategory == -1)
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
	product.fCost = float(RoundToFloor(GetNativeCell(2)));
	
	
	GetNativeString(3, product.sName, sizeof(enProduct::sName));
	GetNativeString(4, product.sDescription, sizeof(enProduct::sDescription));
	GetNativeString(5, product.sAliases, sizeof(enProduct::sAliases));
	GetNativeString(6, product.sInfo, sizeof(enProduct::sInfo));
	
	product.fDelay = GetNativeCell(7);
	product.fCooldown = GetNativeCell(8);
	
	product.iBuyFlags = GetNativeCell(9);
	
	DeleteProductsByAliases(product.sAliases);
	
	PushArrayArray(g_aProducts, product);
	
	return true;
	
}

public any Native_FetchProductCostByAlias(Handle plugin, int numParams)
{
	char sAlias[64];
	
	GetNativeString(1, sAlias, sizeof(sAlias));
	
	int buyer = GetNativeCell(2);
	int targetclient = GetNativeCell(3);

	enProduct product;
	LookupProductByAlias(sAlias, product);
	
	Call_StartForward(g_fwOnGetParametersProduct);
	
	enProduct alteredProduct; 
	alteredProduct = product;
	
	Call_PushCell(buyer);
	Call_PushString(alteredProduct.sAliases);
	Call_PushStringEx(alteredProduct.sInfo, sizeof(enProduct::sInfo), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(alteredProduct.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(alteredProduct.sDescription, sizeof(enProduct::sDescription), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
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
	int client = GetNativeCell(1);
	float newval = GetNativeCell(2);
	g_fPoints[client] = newval;
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
	if(g_fPoints[client] > GetConVarFloat(StartPoints)) return;
	g_fPoints[client] = GetConVarFloat(StartPoints);
	g_fSavedSurvivorPoints[client] = GetConVarFloat(StartPoints);
	g_fSavedInfectedPoints[client] = GetConVarFloat(StartPoints);
	if(killcount[client] > 0) return;
	killcount[client] = 0;
	hurtcount[client] = 0;
	protectcount[client] = 0;
	headshotcount[client] = 0;
	NextMultipleDamage[client] = 0.0;
	NextSpitterDamage[client] = 0.0;
	MultipleDamageStack[client] = 0;
	SpitterDamageStack[client] = 0;
	g_sLastBoughtAlias[client][0] = EOS;
}	

public Action Event_ChangeTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	int team = GetEventInt(event, "team");
	int oldteam = GetEventInt(event, "oldteam");
	
	if(oldteam == 2)
		g_fSavedSurvivorPoints[client] = g_fPoints[client];
		
	else if(oldteam == 3)
		g_fSavedInfectedPoints[client] = g_fPoints[client];
		
	if ( team == 2 || team == 3)
	{
		if(team == 2)
			g_fPoints[client] = g_fSavedSurvivorPoints[client];
			
		else if(team == 3)
			g_fPoints[client] = g_fSavedInfectedPoints[client];
			
		hurtcount[client] = 0;
		protectcount[client] = 0;	
		headshotcount[client] = 0;
		killcount[client] = 0;
		NextMultipleDamage[client] = 0.0;
		MultipleDamageStack[client] = 0;
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerLeftStartArea(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ( client != 0 && IsPlayerAlive( client ) && IsInTeam( client, L4DTeam_Survivor ))
	{
		g_bIsAreaStart = true;
		CreateTimer(0.1, CheckMultipleDamage, 0, TIMER_REPEAT);
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client)) return;
	CreateTimer(3.0, Check, client);
	if(g_fPoints[client] > GetConVarFloat(StartPoints)) return;
	g_fPoints[client] = GetConVarFloat(StartPoints);
	killcount[client] = 0;
	hurtcount[client] = 0;
	protectcount[client] = 0;
	headshotcount[client] = 0;
}	

public Action Check(Handle Timer, any client)
{
	if(!IsClientConnected(client))
	{
		g_fPoints[client] = GetConVarFloat(StartPoints);
		killcount[client] = 0;
		hurtcount[client] = 0;
		protectcount[client] = 0;
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
	if(IsAllowedReset())
	{
		for (int i=1; i<=MaxClients; i++)
		{
			g_fPoints[i] = GetConVarFloat(StartPoints);
			g_fSavedSurvivorPoints[i] = GetConVarFloat(StartPoints);
			g_fSavedInfectedPoints[i] = GetConVarFloat(StartPoints);
			hurtcount[i] = 0;
			protectcount[i] = 0;
			headshotcount[i] = 0;
			killcount[i] = 0;
		}    
	}
	g_bIsAreaStart = false;
	
	int EntityCount = GetEntityCount();
	char sTemp[16];
	
	for (int i = MaxClients; i < EntityCount; i++) {
		if (IsValidEntity(i) && IsValidEdict(i)) {
				GetEdictClassname(i, sTemp, sizeof(sTemp));
	
				if( strcmp(sTemp, "infected") == 0 || strcmp(sTemp, "witch") == 0 )
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
	
	if(IsAllowedReset())
	{
		for (int i=1; i<=MaxClients; i++)
		{
			g_fPoints[i] = fStartPoints;
			g_fSavedSurvivorPoints[i] = fStartPoints;
			g_fSavedInfectedPoints[i] = fStartPoints;
			hurtcount[i] = 0;
			protectcount[i] = 0;
			headshotcount[i] = 0;
			killcount[i] = 0;
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
	if(StrEqual(gamemode, "versus", false) || StrEqual(gamemode, "teamversus", false)) return Plugin_Continue;
	for (int i=1; i<=MaxClients; i++)
	{
		g_fPoints[i] = GetConVarFloat(StartPoints);
		killcount[i] = 0;
		hurtcount[i] = 0;
		protectcount[i] = 0;
		headshotcount[i] = 0;
	}
	
	return Plugin_Continue;
}	

public Action Event_Kill(Handle event, const char[] name, bool dontBroadcast)
{
	bool headshot = GetEventBool(event, "headshot");
	
	int infected_id = GetEventInt(event, "infected_id");
	int R = 0;
	int G = 0;
	int B = 0;
	
	if(infected_id > 0)
	{
		SetEntProp(infected_id, Prop_Send, "m_glowColorOverride", R + (G * 256) + (B * 65536));
		SetEntProp(infected_id, Prop_Send, "m_iGlowType", 0); 
		SetEntPropFloat(infected_id, Prop_Data, "m_flModelScale", 1.0);
		AcceptEntityInput(GetEntPropEnt(infected_id, Prop_Send, "m_hRagdoll"), "Kill");
	}
	ATTACKER
	ACHECK2
	{
		if(headshot)
		{
			headshotcount[attacker]++;
		}	
		if(headshotcount[attacker] == GetConVarInt(SNumberHead) && GetConVarInt(SValueHeadSpree) > 0)
		{
			g_fPoints[attacker] += GetConVarFloat(SValueHeadSpree);
			headshotcount[attacker] = 0;
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Head Hunter \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(SValueHeadSpree), GetClientPoints(attacker));
		}
		killcount[attacker]++;
		if(killcount[attacker] == GetConVarInt(SNumberKill) && GetConVarInt(SValueKillingSpree) > 0)
		{
			g_fPoints[attacker] += GetConVarFloat(SValueKillingSpree);
			killcount[attacker] = 0;
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Killing Spree \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(SValueKillingSpree), GetClientPoints(attacker));
		}
	}	
	
	return Plugin_Continue;
}	

public Action Event_Incap(Handle event, const char[] name, bool dontBroadcast)
{
	int userid   = GetClientOfUserId(GetEventInt(event, "userid"));
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(IIncap) == -1) return Plugin_Continue;
		g_fPoints[attacker] += GetConVarFloat(IIncap);
		if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Incapped \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", userid, GetConVarInt(IIncap), GetClientPoints(attacker));
	}	
	
	return Plugin_Continue;
}	

public Action Event_Death(Handle event, const char[] name, bool dontBroadcast)
{
	ATTACKER
	CLIENT
	if(attacker > 0 && client > 0 && !IsFakeClient(attacker) && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if(GetClientTeam(attacker) == 2)
		{
			if(GetConVarInt(SSIKill) <= 0 || GetClientTeam(client) == 2) return Plugin_Continue;
			if(GetEntProp(client, Prop_Send, "m_zombieClass") == 8) return Plugin_Continue;
			g_fPoints[attacker] += GetConVarFloat(SSIKill);
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Killed \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", client, GetConVarInt(SSIKill), GetClientPoints(attacker));
		}
		if(GetClientTeam(attacker) == 3)
		{
			if(GetConVarInt(IKill) <= 0 || GetClientTeam(client) == 3) return Plugin_Continue;
			g_fPoints[attacker] += GetConVarFloat(IKill);
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Killed \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", client, GetConVarInt(IKill), GetClientPoints(attacker));
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
		if(solo && GetConVarInt(STSolo) > 0)
		{
			g_fPoints[attacker] += GetConVarFloat(STSolo);
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 TANK SOLO! \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(STSolo), GetClientPoints(attacker));
		}
	}
	for (int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && GetConVarInt(STankKill) > 0 && GetConVarInt(Enable) == 1 && IsAllowedGameMode())
		{
			g_fPoints[i] += GetConVarFloat(STankKill);
			if(GetConVarBool(Notifications)) PrintToChat(i, "\x04[PS]\x03 Killed Tank \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(STankKill), GetClientPoints(i));
		}	
	}
	tankburning[attacker] = 0;
	tankbiled[attacker] = 0;
	
	return Plugin_Continue;
}	

public Action Event_WitchDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int oneshot = GetEventBool(event, "oneshot");
	CLIENT
	CCHECK2
	{
		if(GetConVarInt(SWitchKill) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(SWitchKill);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Killed Witch + \x05%d\x03 points", GetConVarInt(SWitchKill), GetClientPoints(client));
		if(oneshot && GetConVarInt(SWitchCrown) > 0)
		{
			g_fPoints[client] += GetConVarFloat(SWitchCrown);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Crowned The Witch + \x05%d\x03 points (Σ: \x05%d\x03)", GetConVarInt(SWitchCrown), GetClientPoints(client));
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
	if(subject > 0 && client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if(client == subject) return Plugin_Continue;
		if(restored > 39)
		{
			if(GetConVarInt(SHeal) <= 0) return Plugin_Continue;
			g_fPoints[client] += GetConVarFloat(SHeal);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Healed \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", subject, GetConVarInt(SHeal), GetClientPoints(client));
		}
		else
		{
			if(GetConVarInt(SHealWarning) <= 0) return Plugin_Continue;
			g_fPoints[client] += GetConVarFloat(SHealWarning);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Don't Harvest Heal Points\x05 + %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(SHealWarning), GetClientPoints(client));
		}
	}
		
	return Plugin_Continue;
}	

public Action Event_Protect(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	int award = GetEventInt(event, "award");
	if(client > 0 && award == 67 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && !IsFakeClient(client) && IsAllowedGameMode())
	{
		if(GetConVarInt(SProtect) <= 0) return Plugin_Continue;
		protectcount[client]++;
		if(protectcount[client] == 6)
		{
			g_fPoints[client] += GetConVarFloat(SProtect);
			protectcount[client] = 0;
		}	
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Protected Teammate\x05 + %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(SProtect), GetClientPoints(client));
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
		if(subject == client) return Plugin_Continue;
		if(!ledge && GetConVarInt(SRevive) > 0)
        {
			g_fPoints[client] += GetConVarFloat(SRevive);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Revived \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", subject, GetConVarInt(SRevive), GetClientPoints(client));
		}
		if(ledge && GetConVarInt(SLedge) > 0)
		{
			g_fPoints[client] += GetConVarFloat(SLedge);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Revived \x01%N\x03 From Ledge\x05 + %d\x03 points (Σ: \x05%d\x03)", subject, GetConVarInt(SLedge), GetClientPoints(client));
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
		if(GetConVarInt(SDefib) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(SDefib);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Defibbed \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", subject, GetConVarInt(SDefib), GetClientPoints(client));
	}	
	
	return Plugin_Continue;
}	

public Action Event_Choke(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if(GetConVarInt(IChoke) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(IChoke);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Choked Survivor\x05 + %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(IChoke), GetClientPoints(client));
	}
		
	return Plugin_Continue;
}

public Action Event_Boom(Handle event, const char[] name, bool dontBroadcast)
{
	ATTACKER
	CLIENT
	if(attacker > 0 && !IsFakeClient(attacker) && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if(GetClientTeam(attacker) == 3 && GetConVarInt(ITag) > 0)
		{
			g_fPoints[attacker] += GetConVarFloat(ITag);
			if(GetClientTeam(client) == 2 && GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Boomed \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", client, GetConVarInt(ITag), GetClientPoints(attacker));
		}
		if(GetClientTeam(attacker) == 2 && GetConVarInt(STag) > 0)
		{
			g_fPoints[attacker] += GetConVarFloat(STag);
			if(GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Biled Tank + \x05%d\x03 points (Σ: \x05%d\x03)", GetConVarInt(STag), GetClientPoints(attacker));
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
		if(GetConVarInt(IPounce) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(IPounce);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Pounced Survivor \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(IPounce), GetClientPoints(client));
	}
		
	return Plugin_Continue;
}	

public Action Event_Ride(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if(GetConVarInt(IRide) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(IRide);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Jockeyed Survivor \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(IRide), GetClientPoints(client));
	}
		
	return Plugin_Continue;
}	

public Action Event_Carry(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if(GetConVarInt(ICarry) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(ICarry);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Charged Survivor \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(ICarry), GetClientPoints(client));
	}
		
	return Plugin_Continue;
}	

public Action Event_Impact(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if(GetConVarInt(IImpact) <= 0) return Plugin_Continue;
		g_fPoints[client] += GetConVarFloat(IImpact);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Impacted Survivor \x05+ %d\x03 points(Σ: \x05%d\x03)", GetConVarInt(IImpact), GetClientPoints(client));
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
		if(StrEqual(victim, "Tank", false) && tankburning[client] == 0 && GetConVarInt(STBurn) > 0)
		{
			g_fPoints[client] += GetConVarFloat(STBurn);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Burned The Tank \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(STBurn), GetClientPoints(client));
			tankburning[client] = 1;
		}
		if(StrEqual(victim, "Witch", false) && witchburning[client] == 0 && GetConVarInt(SWBurn) > 0)
		{
			g_fPoints[client] += GetConVarFloat(SWBurn);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Burned The Witch \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(SWBurn), GetClientPoints(client));
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
	if(attacker > 0 && client > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1 && GetConVarInt(IHurt) > 0)
	{
		hurtcount[attacker]++;
		//new String:weapon[64];
		//GetEventString(event, "weapon", weapon, sizeof(weapon));
		//PrintToChatAll(weapon);
		if(attacker > 0 && client > 0)  //I changed this line to this since mine has a IsValidClient bool here since the plugin for this topic doesn't have it
		{
          if(GetClientTeam(attacker) == 3)
          {
               if(dmg_type == 8 || dmg_type == 2056) return Plugin_Continue; //Block the infected player from earning points while killing stuff with fire

               if (dmg_type == 263168 || dmg_type == 265216) //This is for spitter damage since the same thing can be done with it as well.
               {
                    //code here
               }
          }
		}
		if(hurtcount[attacker] >= 3)
		{
			g_fPoints[attacker] += GetConVarFloat(IHurt);
			
			MultipleDamageStack[attacker] += GetConVarInt(IHurt);
			hurtcount[attacker] -= 3;
		}  
	}	
	
	return Plugin_Continue;
}	

public Action Command_Rebuy(int client, int args)
{		
	// No target, so let's make the target the buyer's userid?
	if(g_sLastBoughtTargetArg[client][0] == EOS) 
		FormatEx(g_sLastBoughtTargetArg[client], sizeof(g_sLastBoughtTargetArg[]), "#%i", GetClientUserId(client));
		
	PrintToChat(client, "%s |%s|", g_sLastBoughtAlias[client], g_sLastBoughtTargetArg[client]);
	PerformPurchaseOnAlias(client, g_sLastBoughtAlias[client], g_sLastBoughtTargetArg[client]);
	
	return Plugin_Handled;
}

public Action BuyMenu(int client, int args)
{
	if(!L4D_HasAnySurvivorLeftSafeAreaStock() && GetClientTeam(client) == view_as<int>(L4DTeam_Infected))
	{
		PrintToChat(client, "\x04[PS]\x03 Waiting for Survivors ...");
		return Plugin_Handled;
	}
	if(IsAllowedGameMode() && GetConVarInt(Enable) == 1 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && args == 0)
	{
		BuildBuyMenu(client);
		return Plugin_Handled;
	}
	else// Alias buy.
	{
		
		char sFirstArg[32];
		
		char sArgString[128];
		
		GetCmdArg(1, sFirstArg, sizeof(sFirstArg));
		TrimString(sFirstArg);
		
		if(sFirstArg[0] == EOS)
			return Plugin_Handled;
			
		GetCmdArgString(sArgString, sizeof(sArgString));
		
		// 2 and beyond are the target's name
		ReplaceStringEx(sArgString, sizeof(sArgString), sFirstArg, "");
		
		TrimString(sArgString);
		
		strcopy(g_sLastBoughtAlias[client], sizeof(g_sLastBoughtAlias[]), sFirstArg);
		
		strcopy(g_sLastBoughtTargetArg[client], sizeof(g_sLastBoughtTargetArg[]), sArgString);
		
		// No target, so let's make the target the buyer's userid?
		if(sArgString[0] == EOS) 
			FormatEx(sArgString, sizeof(sArgString), "#%i", GetClientUserId(client));
			
		PerformPurchaseOnAlias(client, sFirstArg, sArgString);
	}
	return Plugin_Handled;
}

public Action ShowPoints(int client, int args)
{
	if(IsAllowedGameMode() && GetConVarInt(Enable) == 1 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && args == 0)
	{
		PrintToChat(client, "\x04[PS]\x03 You have \x05%d\x03 points", GetClientPoints(client));
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
	if(args == 2)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		Amount = StringToInt(arg2);
	}
	char Path[256], LogFormat[100];
	BuildPath(Path_SM, Path, sizeof(Path), "logs/pointsystem.txt");
	
	if(args == 2)
		Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has set %s's health to %i", client, arg, Amount);
	else if(args != 0)
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
	int target_list[MAXPLAYERS+1], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		int targetclient;
		targetclient = target_list[i];
		if(args == 2)
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
	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_incap <target>");
		return Plugin_Handled;
	}	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS+1], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
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
	
		if(GetClientTeam(target) == 1)
			continue;
			
		else if(GetClientTeam(target) == 3 && GetEntProp(target, Prop_Send, "m_zombieClass") != 8)
			continue;
			
		else if(GetClientTeam(target) == 2 && GetEntProp(target, Prop_Send, "m_isIncapacitated") == 1)
			continue;
	
		if(IsValidEntity(target))
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
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setincaps <target> <amount left>");
		return Plugin_Handled;
	}	
	char arg[65], arg2[65];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS+1], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	int MAX_INCAPS = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	int Amount = (MAX_INCAPS - StringToInt(arg2));
	
	char Path[256], LogFormat[100];
	BuildPath(Path_SM, Path, sizeof(Path), "logs/pointsystem.txt");
	
	Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has set %s's incaps left to %i", client, arg, Amount);
	LogToFile(Path, LogFormat);
	
	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
	
		if(GetClientTeam(target) != 2)
			continue;
			
		SetEntProp(target, Prop_Send, "m_currentReviveCount", Amount);
		
		if(Amount >= MAX_INCAPS)
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
	int target_list[MAXPLAYERS+1], target_count;
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
			tn_is_ml)) > 0)
	{
		char Path[256], LogFormat[100];
		BuildPath(Path_SM, Path, sizeof(Path), "logs/pointsystem.txt");
		
		Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has given %i points to %s", client, StringToInt(arg2), arg);
		LogToFile(Path, LogFormat);
		for(int i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i) || i == client)
				continue;
				
			if(CheckCommandAccess(i, "sm_setincaps", ADMFLAG_ROOT))
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
	int target_list[MAXPLAYERS+1], target_count;
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
			tn_is_ml)) > 0)
	{
		char Path[256], LogFormat[100];
		BuildPath(Path_SM, Path, sizeof(Path), "logs/pointsystem.txt");
		
		Format(LogFormat, sizeof(LogFormat), "\x04[PS]\x03 Admin %N has set %s's points to %i", client, arg, StringToInt(arg2));
		LogToFile(Path, LogFormat);
		for(int i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i) || i == client)
				continue;
				
			if(CheckCommandAccess(i, "sm_setincaps", ADMFLAG_ROOT))
				PrintToChat(i, LogFormat);
		}
		
		for (int i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
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
	char command[200], targetarg[MAX_NAME_LENGTH], targetargsubstract[MAX_NAME_LENGTH+1];
	GetCmdArgString(command, sizeof(command));
	
	GetCmdArg(1, targetarg, sizeof(targetarg));
	
	Format(targetargsubstract, sizeof(targetargsubstract), "%s ", targetarg);
	ReplaceString(command, sizeof(command), targetargsubstract, ""); 
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS+1], target_count;
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
			tn_is_ml)) > 0)
	{
		for(int i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i) || i == client)
				continue;
				
			if(CheckCommandAccess(i, "sm_setincaps", ADMFLAG_ROOT))
				PrintToChat(i, "\x04[PS]\x03 Admin %N has executed %s on %s", client, command, targetarg);
		}
		
		char flaggedcommand[200];
		
		for(int i;i < strlen(command);i++)
		{
			if(IsCharSpace(command[i]) || command[i] == EOS)
				Format(flaggedcommand, i+1, command);
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
	char command[200], targetarg[MAX_NAME_LENGTH], targetargsubstract[MAX_NAME_LENGTH+1];
	GetCmdArgString(command, sizeof(command));
	
	GetCmdArg(1, targetarg, sizeof(targetarg));
	
	Format(targetargsubstract, sizeof(targetargsubstract), "%s ", targetarg);
	ReplaceString(command, sizeof(command), targetargsubstract, ""); 
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS+1], target_count;
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
			tn_is_ml)) > 0)
	{
		for(int i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i) || i == client)
				continue;
				
			if(CheckCommandAccess(i, "sm_setincaps", ADMFLAG_ROOT))
				PrintToChat(i, "\x04[PS]\x03 Admin %N has executed %s on %s", client, command, targetarg);
		}
		
		char flaggedcommand[200];
		
		for(int i;i < strlen(command);i++)
		{
			if(IsCharSpace(command[i]) || command[i] == EOS)
				Format(flaggedcommand, i+1, command);
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
		ReplyToCommand(client, "[SM] Usage: sm_sendpoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}
	char arg[MAX_NAME_LENGTH], arg2[10];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	
	if(!IsPlayerAlive(client) && IsTeamSurvivor(client))
	{
		ReplyToCommand(client, "\x04[PS]\x03 You cannot send points when you're dead.");
		return Plugin_Handled;
	}
	float pointsToSend = float(RoundToFloor(StringToFloat(arg2)));
	
	if(pointsToSend <= 0.0)
		return Plugin_Handled;
		
	if(pointsToSend > g_fPoints[client])
	{

		ReplyToCommand(client, "\x04[PS]\x03 You cannot send more points than you have. (\x05%d\x03)", GetClientPoints(client));
		return Plugin_Handled;
	}
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS+1], target_count;
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
			tn_is_ml)) > 0)
	{
		for (int i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			
			if(GetClientTeam(targetclient) != GetClientTeam(client) || targetclient == client || IsFakeClient(targetclient) || (!IsPlayerAlive(targetclient) && IsTeamSurvivor(targetclient)))
				continue;
			
			else if(pointsToSend > g_fPoints[client])
				return Plugin_Handled;
				
			g_fPoints[targetclient] += pointsToSend;
			g_fPoints[client] -= pointsToSend;
			
			char name[33], sendername[33];
			GetClientName(targetclient, name, sizeof(name)); 
			GetClientName(client, sendername, sizeof(sendername)); 
			ReplyToCommand(client, "\x04[PS]\x03 You gave \x05%d\x03 points to %s.", RoundToFloor(pointsToSend), name);
			PrintToChat(targetclient, "\x04[PS]\x03 %s gave you \x05%d\x03 points.", sendername, RoundToFloor(pointsToSend));
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}


void BuildBuyMenu(int client, int iCategory = -1)
{

	Handle hMenu = CreateMenu(BuyMenu_Handler);
	SetMenuTitle(hMenu, "Your Points: %i", GetClientPoints(client));
	
	if(iCategory != -1)
		SetMenuExitBackButton(hMenu, true);
		
	int iCategoriesSize = GetArraySize(g_aCategories);
	int iProductsSize = GetArraySize(g_aProducts);
	
	bool bAnyItems = false;
	
	for(int i=0;i < iCategoriesSize;i++)
	{
		enCategory cat;
		GetArrayArray(g_aCategories, i, cat);
		
		if(cat.iCategory != iCategory)
			continue;
			
		enProduct impostorProduct;
		
		impostorProduct.iBuyFlags = cat.iBuyFlags;
		
		bool bShouldReturn;
		
		if(PSAPI_GetErrorFromBuyflags(client, "", impostorProduct, _, _, _, bShouldReturn) && bShouldReturn)
			continue;
		
		char sName[64];
		sName = cat.sName;
		
		if(cat.iBuyFlags & BUYFLAG_CUSTOMNAME)
		{
			Call_StartForward(g_fwOnGetParametersCategory);
			
			enCategory alteredCategory; 
			alteredCategory = cat;
			
			Call_PushCell(client);
			Call_PushString(alteredCategory.sID);
			Call_PushStringEx(alteredCategory.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			
			Call_Finish();
			
			sName = alteredCategory.sName;
		}
	
		char sInfo[128];
		FormatEx(sInfo, sizeof(sInfo), "c%s", cat.sID); // c for category, p for product
		AddMenuItem(hMenu, sInfo, sName);
		bAnyItems = true;
	}
	
	for(int i=0;i < iProductsSize;i++)
	{
		enProduct product;
		GetArrayArray(g_aProducts, i, product);
		
		if(product.iCategory != iCategory)
			continue;
		
		bool bShouldReturn;
		
		if(PSAPI_GetErrorFromBuyflags(client, "", product, _, _, _, bShouldReturn) && bShouldReturn)
			continue;
			
		char sInfo[128];
		FormatEx(sInfo, sizeof(sInfo), "p%s", product.sAliases); // c for category, p for product
		
		char sDisplay[128], sFirstAlias[32];
		BreakString(product.sAliases, sFirstAlias, sizeof(sFirstAlias));
		
		char sName[64];
		sName = product.sName;
		
		if(product.iBuyFlags & BUYFLAG_CUSTOMNAME)
		{
			Call_StartForward(g_fwOnGetParametersProduct);
			
			enProduct alteredProduct; 
			alteredProduct = product;
			
			Call_PushCell(client);
			Call_PushString(alteredProduct.sAliases);
			Call_PushStringEx(alteredProduct.sInfo, sizeof(enProduct::sInfo), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushStringEx(alteredProduct.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushStringEx(alteredProduct.sDescription, sizeof(enProduct::sDescription), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
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
	
	if(bAnyItems)
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	else
		CloseHandle(hMenu);
	
	
}

public int BuyMenu_Handler(Handle hMenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
	{
		char sInfo[256];
		
		// Get first item, check which category it belongs to.
		GetMenuItem(hMenu, 0, sInfo, sizeof(sInfo));
		
		bool bCategory = false;
		
		if(sInfo[0] == 'c')
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
		
		if(bCategory)
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
	else if(action == MenuAction_Select)
	{
		char sInfo[256];
		
		GetMenuItem(hMenu, item, sInfo, sizeof(sInfo));
		
		bool bCategory = false;
		
		if(sInfo[0] == 'c')
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
		
		if(bCategory)
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
	Call_PushStringEx(alteredProduct.sInfo, sizeof(enProduct::sInfo), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(alteredProduct.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(alteredProduct.sDescription, sizeof(enProduct::sDescription), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(client);
	Call_PushCellRef(alteredProduct.fCost);
	Call_PushFloatRef(alteredProduct.fDelay);
	Call_PushFloatRef(alteredProduct.fCooldown);
	
	Call_Finish();
	
	if(alteredProduct.sDescription[0] != EOS)
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
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
	{
		// 1 = The "No" item that we gave the category number
		char sInfo[16];
		GetMenuItem(hMenu, 1, sInfo, sizeof(sInfo));
		
		BuildBuyMenu(client, StringToInt(sInfo));
	}
	else if(action == MenuAction_Select)
	{
		if(item == 0)
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
bool IsInTeam(int iClient, L4DTeam team)
{
	if( GetClientTeam( iClient ) == view_as<int>(team) )
	{
		return true;
	}
	return false;
}

stock bool IsTeamSurvivor(int client)
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) != 2 ) return false;
	return true;
}

stock bool IsTeamInfected(int client)
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) != 3 ) return false;
	return true;
}


stock int GetTanksCount()
{
	int count;
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsPlayerAlive(i) || !IsTeamInfected(i))
			continue;
			
		else if(GetEntProp(i, Prop_Send, "m_zombieClass") != view_as<int>(L4D2ZombieClass_Tank))
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
	if(GetClientTeam(client) == view_as<int>(L4DTeam_Survivor))
	{
		bool bIncap, bPinned;
		bIncap = L4D_IsPlayerIncapacitated(client);
		bPinned = L4D_IsPlayerPinned(client);
		if(bIncap && bPinned)
		{
			Handle convar = FindConVar("survivor_incap_health");
			
			SetEntityHealth(client, GetConVarInt(convar));
		}	
		else if(bIncap)
		{
			PSAPI_ExecuteCheatCommand(client, "give health");
			SetEntityHealthToMax(client);
		}
		else
		{
			PSAPI_ExecuteCheatCommand(client, "give health");
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

stock int LookupProductByAlias(char[] sAlias, enProduct finalProduct)
{
	
	int iSize = GetArraySize(g_aProducts);
	
	for (int i = 0; i < iSize;i++)
	{
		enProduct product;
		GetArrayArray(g_aProducts, i, product);
		
		char sAliasArray[8][32];
		int iAliasSize = ExplodeString(product.sAliases, " ", sAliasArray, sizeof(sAliasArray), sizeof(sAliasArray[]));
		
		for (int a = 0; a < iAliasSize;a++)
		{
			if(StrEqual(sAlias, sAliasArray[a], false))
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
	if(GetClientTeam(client) != view_as<int>(L4DTeam_Survivor) && GetClientTeam(client) != view_as<int>(L4DTeam_Infected))
	{
		PrintToChat(client, "\x04[PS]\x03 Error: You must be in-game!");
		return;
	}
	enProduct product;
		
	int productPos = LookupProductByAlias(sFirstArg, product);
	
	if(productPos == -1)
	{
		PrintToChat(client, "\x04[PS]\x03 Error: Product could not be found!");
		return;
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int fake_target_list[MAXPLAYERS+1], fake_target_count;
	int target_list[MAXPLAYERS+1], target_count;
	bool tn_is_ml;
	
	fake_target_count = ProcessTargetString(
			sSecondArg,
			client,
			fake_target_list,
			MAXPLAYERS+1,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml);

	if(fake_target_count > 0)
	{
		for (int i = 0; i < fake_target_count; i++)
		{
			int targetclient = fake_target_list[i];
			
			if(GetClientTeam(client) == GetClientTeam(targetclient))
			{
				target_list[target_count++] = targetclient;
			}
		}
	}
	// To handle errors.
	else
		target_count = fake_target_count;

	if(target_count <= 0)
	{
		ReplyToTargetError(client, target_count);
		return;
	}

	for (int i = 0; i < target_count; i++)
	{
		int targetclient = target_list[i];
		
	
		char sError[256];
		bool bShouldReturn;
		
		if(PSAPI_GetErrorFromBuyflags(client, sFirstArg, product, targetclient, sError, sizeof(sError), bShouldReturn))
		{
			PrintToChat(client, sError);
			
			if(bShouldReturn)
				return;
				
			else
				continue;
		}
	
		Call_StartForward(g_fwOnGetParametersProduct);
		
		enProduct alteredProduct; 
		alteredProduct = product;
		
		Call_PushCell(client);
		Call_PushString(alteredProduct.sAliases);
		Call_PushStringEx(alteredProduct.sInfo, sizeof(enProduct::sInfo), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushStringEx(alteredProduct.sName, sizeof(enProduct::sName), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushStringEx(alteredProduct.sDescription, sizeof(enProduct::sDescription), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(targetclient);
		Call_PushCellRef(alteredProduct.fCost);
		Call_PushFloatRef(alteredProduct.fDelay);
		Call_PushFloatRef(alteredProduct.fCooldown);
		
		Call_Finish();
		
		alteredProduct.fCost = float(RoundToFloor(alteredProduct.fCost));
		
		if(g_fPoints[client] < alteredProduct.fCost)
		{
			PrintToChat(client, PSAPI_NOT_ENOUGH_POINTS, RoundToFloor(alteredProduct.fCost - g_fPoints[client]), GetClientPoints(client));
			continue;
		}
		
		Call_StartForward(g_fwOnTryBuyProduct);
		
		Call_PushCell(client);
		Call_PushString(alteredProduct.sInfo);
		Call_PushString(alteredProduct.sAliases);
		Call_PushString(alteredProduct.sName);
		Call_PushCell(targetclient);
		Call_PushCell(alteredProduct.fCost);
		Call_PushFloat(alteredProduct.fDelay);
		Call_PushFloat(alteredProduct.fCooldown);
		
		Action result;
		Call_Finish(result);
		
		if(result >= Plugin_Handled)
		{
			continue;
		}
		
		product.fNextBuyProduct[targetclient] = GetGameTime() + alteredProduct.fCooldown;
		g_fPoints[client] -= alteredProduct.fCost;
		
		SetArrayArray(g_aProducts, productPos, product);
		
		Handle hTimer;
		DataPack DP;
		
		char sTargetName[64];
		GetClientName(targetclient, sTargetName, sizeof(sTargetName));
		
		// Creating a 0.0 timer will trigger it instantly, no time to populate the datapack.
		if(alteredProduct.fDelay < 0.1)
		{
			hTimer = CreateDataTimer(1.0, Timer_DelayGiveProduct, DP, TIMER_FLAG_NO_MAPCHANGE);
			 
			if(targetclient == client)
			{
				if(GetConVarBool(Notifications))
					PrintToChat(client, "\x04[PS]\x03 Bought %s for yourself", sFirstArg);
			}	
			else
			{
				PrintToChat(client, "\x04[PS]\x03 Successfully bought \x01%s \x03for Player \x01%N", sFirstArg, targetclient );
				PrintToChat(targetclient, "\x04[PS]\x03 Player \x01%N \x03bought you \x01%s", client, sFirstArg );
			}
		}	 
		else 
		{
			hTimer = CreateDataTimer(alteredProduct.fDelay, Timer_DelayGiveProduct, DP, TIMER_FLAG_NO_MAPCHANGE);
			
			PrintToChat(client, "\x04[PS]\x03 You will buy\x01 %s\x03 for\x04 %s\x01 in %.1fsec", sFirstArg, targetclient == client ? "\x03yourself" : sTargetName, alteredProduct.fDelay);
			
			if(targetclient != client)
				PrintToChat(targetclient, "\x04[PS]\x03 Player \x01%N \x03will buy you \x01%s\x01 in %.1fsec", client, sFirstArg, alteredProduct.fDelay );
		}
			
		DP.WriteCell(client);
		DP.WriteCell(targetclient);
		DP.WriteString(sFirstArg);
		DP.WriteCellArray(alteredProduct, sizeof(alteredProduct));
		
		if(alteredProduct.fDelay < 0.1)
			TriggerTimer(hTimer, true);
	
	}
	
}

public Action Timer_DelayGiveProduct(Handle hTimer, DataPack DP)
{
	DP.Reset();
	
	int client = DP.ReadCell();
	int targetclient = DP.ReadCell();
	char sFirstArg[32];
	DP.ReadString(sFirstArg, sizeof(sFirstArg));
	
	enProduct alteredProduct;
	DP.ReadCellArray(alteredProduct, sizeof(alteredProduct));
	
	enProduct product;
	
	int productPos = LookupProductByAlias(sFirstArg, product);
	
	// Should not happen/
	if(productPos == -1)
	{
		PrintToChat(client, "\x04[PS]\x03 Error: Product could not be found!");
		return Plugin_Stop;
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
	
	Action result;
	Call_Finish(result);
	
	if(result >= Plugin_Handled)
	{
		g_fPoints[client] += alteredProduct.fCost;
		
		if(alteredProduct.fCost > 0)
		{
			product.fNextBuyProduct[targetclient] = 0.0;
			SetArrayArray(g_aProducts, productPos, product);
			PrintToChat(client, "\x04[PS]\x03 Refunded %s\x05 + %d\x03 points(Σ: \x05%d\x03)", sFirstArg, RoundToFloor(alteredProduct.fCost), GetClientPoints(client));
		}
		
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
	
	if(result >= Plugin_Handled)
	{
		g_fPoints[client] += alteredProduct.fCost;
		
		if(alteredProduct.fCost > 0)
		{
			product.fNextBuyProduct[targetclient] = 0.0;
			SetArrayArray(g_aProducts, productPos, product);
			PrintToChat(client, "\x04[PS]\x03 Refunded %s\x05 + %d\x03 points(Σ: \x05%d\x03)", sFirstArg, RoundToFloor(alteredProduct.fCost), GetClientPoints(client));
		}
		
		return Plugin_Stop;
	}

	return Plugin_Stop;
}

stock void ResetProductCooldowns()
{
	int iSize = GetArraySize(g_aProducts);
	
	for (int i = 0; i < iSize;i++)
	{
		enProduct product;
		GetArrayArray(g_aProducts, i, product);
		
		for (int a = 0; a < sizeof(product.fNextBuyProduct);a++)
			product.fNextBuyProduct[a] = 0.0;
		
		SetArrayArray(g_aProducts, i, product);
	}
}

stock void DeleteProductsByAliases(char[] sAliases)
{	
	// i can be decremented, mustn't use int iSize = GetArraySize(g_aProducts)
	for (int i = 0; i < GetArraySize(g_aProducts);i++)
	{
		
		enProduct product;
		GetArrayArray(g_aProducts, i, product);
		
		char sAliasArray[8][32];
		int iAliasSize = ExplodeString(product.sAliases, " ", sAliasArray, sizeof(sAliasArray), sizeof(sAliasArray[]));
		
		char sAliasArray2[8][32];
		int iAliasSize2 = ExplodeString(sAliases, " ", sAliasArray2, sizeof(sAliasArray2), sizeof(sAliasArray2[]));
		
		for (int a = 0; a < iAliasSize;a++)
		{
			for (int b = 0; b < iAliasSize2;b++)
			{
				if(StrEqual(sAliasArray[a], sAliasArray2[b], false))
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
	for (int i = 0; i < GetArraySize(g_aCategories);i++)
	{
		enCategory cat;
		GetArrayArray(g_aCategories, i, cat);
		
		if(StrEqual(cat.sID, sID, false))
		{
			return i;
		}
	}
	
	return -1;
}

stock int FindEntityByTargetname(int startEnt, const char[] TargetName, bool caseSensitive, bool bContains) // Same as FindEntityByClassname with sensitivity and contain features
{
	int entCount = GetEntityCount();
	
	char EntTargetName[300];
	
	for(int i=startEnt+1;i < entCount;i++)
	{
		if(!IsValidEntity(i))
			continue;
			
		else if(!IsValidEdict(i))
			continue;
			
		GetEntPropString(i, Prop_Data, "m_iName", EntTargetName, sizeof(EntTargetName));
		
		if((StrEqual(EntTargetName, TargetName, caseSensitive) && !bContains) || (StrContains(EntTargetName, TargetName, caseSensitive) != -1 && bContains))
			return i;	
	}
	
	return -1;
}

stock int GetClientPoints(int client)
{
	return RoundToFloor(g_fPoints[client]);
}