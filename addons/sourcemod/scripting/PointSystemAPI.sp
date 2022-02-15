/* put the line below after all of the includes!
#pragma newdecls required
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <ps_api>

#pragma newdecls required
#define PLUGIN_TITLE	"Point System API"

//char g_sBossClasses[][]={"","smoker","boomer","hunter","spitter","jockey","charger","witch","tank","survivor"};
char g_sBossNames[][]={"","Smoker","Boomer","Hunter","Spitter","Jockey","Charger","Witch","Tank","Survivor"};


enum struct enCategory
{
	char sID[64]; // Identifier between plugins, players cannot see this.
	char sName[64]; // Category Name
	int iBuyFlags; // Must use variable that determines flags that specify when you can buy. BUYFLAG_* in ps_api.inc
}

enum struct enProduct
{
	int iCategory; // Category number this product belongs to, or -1 for main buy menu.
	int iCost; // Cost of this product.
	int iBuyFlags; // Must use variable that determines flags that specify when you can buy. BUYFLAG_* in ps_api.inc
	char sName[64]; // Product Name
	char sDescription[128]; // Optional Description
	char sAliases[256]; // Alises, seperated by spaces, to buy directly with !buy <alias>
	char sInfo[64]; // Info that only devs can see.

	float fDelay; // Delay between purchase to obtaining the product.
	float fCooldown; // Cooldown between purchases.
	
	float NextBuyProduct[MAXPLAYERS + 1]; // Next time each player can buy this product.
}

ArrayList g_aCategories, g_aProducts;

GlobalForward g_fwOnTryBuyProduct; // Calculated before the delay.
GlobalForward g_fwOnBuyProductPost; // Calculated after the delay.
GlobalForward g_fwOnShouldGiveProduct; // We should now give the product to the user, because the delay has passed and not refunded.

int MultipleDamageStack[MAXPLAYERS+1], SpitterDamageStack[MAXPLAYERS+1];
float NextMultipleDamage[MAXPLAYERS + 1], NextSpitterDamage[MAXPLAYERS + 1];

int SavedSurvivorPoints[MAXPLAYERS+1], SavedInfectedPoints[MAXPLAYERS+1];

float version = 1.0;

char MapName[30];
//int boughtcost[MAXPLAYERS+1] = { 0, ... };
int hurtcount[MAXPLAYERS+1] = { 0, ... };
int protectcount[MAXPLAYERS+1] = { 0, ... };
//int cost[MAXPLAYERS+1] = { 0, ... };
int tankburning[MAXPLAYERS+1] = { 0, ... };
int tankbiled[MAXPLAYERS+1] = { 0, ... };
int witchburning[MAXPLAYERS+1] = { 0, ... };
int points[MAXPLAYERS+1] = { 0, ... };
int killcount[MAXPLAYERS+1] = { 0, ... };
int headshotcount[MAXPLAYERS+1] = { 0, ... };
int wassmoker[MAXPLAYERS+1] = { 0, ... };
//Definitions to save space
#define ATTACKER int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
#define CLIENT int client = GetClientOfUserId(GetEventInt(event, "userid"));
#define ACHECK2 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define CCHECK2 if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define ACHECK3 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define CCHECK3 if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 3 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define NOT_ENOUGH_POINTS "\x04[PS]\x03 Failed! You need \x05%d\x03 more points to buy it! (Σ: \x05%d\x03)"
//Other
Handle Enable = INVALID_HANDLE;
Handle Modes = INVALID_HANDLE;
Handle Notifications = INVALID_HANDLE;
//Item buyables
/*
Handle PointsPistol = INVALID_HANDLE;
Handle PointsMagnum = INVALID_HANDLE;
Handle PointsSMG = INVALID_HANDLE;
Handle PointsSSMG = INVALID_HANDLE;
Handle PointsMP5 = INVALID_HANDLE;
Handle PointsM16 = INVALID_HANDLE;
Handle PointsAK = INVALID_HANDLE;
Handle PointsSCAR = INVALID_HANDLE;
Handle PointsSG = INVALID_HANDLE;
Handle PointsHunting = INVALID_HANDLE;
Handle PointsMilitary = INVALID_HANDLE;
Handle PointsAWP = INVALID_HANDLE;
Handle PointsScout = INVALID_HANDLE;
Handle PointsAuto = INVALID_HANDLE;
Handle PointsSpas = INVALID_HANDLE;
Handle PointsChrome = INVALID_HANDLE;
Handle PointsPump = INVALID_HANDLE;
Handle PointsGL = INVALID_HANDLE;
Handle PointsM60 = INVALID_HANDLE;
Handle PointsGasCan = INVALID_HANDLE;
Handle PointsOxy = INVALID_HANDLE;
Handle PointsKnife = INVALID_HANDLE;
Handle PointsPropane = INVALID_HANDLE;
Handle PointsGnome = INVALID_HANDLE;
Handle PointsCola = INVALID_HANDLE;
Handle PointsFireWorks = INVALID_HANDLE;
Handle PointsBat = INVALID_HANDLE;
Handle PointsMachete = INVALID_HANDLE;
Handle PointsKatana = INVALID_HANDLE;
Handle PointsTonfa = INVALID_HANDLE;
Handle PointsFireaxe = INVALID_HANDLE;
Handle PointsGuitar = INVALID_HANDLE;
Handle PointsPan = INVALID_HANDLE;
Handle PointsCBat = INVALID_HANDLE;
Handle PointsCrow = INVALID_HANDLE;
Handle PointsClub = INVALID_HANDLE;
Handle PointsSaw = INVALID_HANDLE;
Handle PointsPipe = INVALID_HANDLE;
Handle PointsMolly = INVALID_HANDLE;
Handle PointsBile = INVALID_HANDLE;
Handle PointsKit = INVALID_HANDLE;
Handle PointsDefib = INVALID_HANDLE;
Handle PointsAdren = INVALID_HANDLE;
Handle PointsPills = INVALID_HANDLE;
Handle PointsEAmmo = INVALID_HANDLE;
Handle PointsIAmmo = INVALID_HANDLE;
Handle PointsEAmmoPack = INVALID_HANDLE;
Handle PointsIAmmoPack = INVALID_HANDLE;
Handle PointsLSight = INVALID_HANDLE;
Handle PointsRefill = INVALID_HANDLE;
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
//Infected buyables
/*Handle PointsSuicide = INVALID_HANDLE;
Handle PointsHunter = INVALID_HANDLE;
Handle PointsJockey = INVALID_HANDLE;
Handle PointsSmoker = INVALID_HANDLE;
Handle PointsCharger = INVALID_HANDLE;
Handle PointsBoomer = INVALID_HANDLE;
Handle PointsSpitter = INVALID_HANDLE;
Handle PointsIHeal = INVALID_HANDLE;
Handle PointsWitch = INVALID_HANDLE;
Handle PointsTank = INVALID_HANDLE;
Handle PointsTankHealMult = INVALID_HANDLE;
Handle PointsHorde = INVALID_HANDLE;
Handle PointsMob = INVALID_HANDLE;
Handle PointsUmob = INVALID_HANDLE;
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
Handle PisserTimer = INVALID_HANDLE;
Handle WitchPisser = INVALID_HANDLE;

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
	
	g_fwOnTryBuyProduct = CreateGlobalForward("PointSystemAPI_OnTryBuyProduct", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_FloatByRef);
	
	g_fwOnBuyProductPost = CreateGlobalForward("PointSystemAPI_OnBuyProductPost", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Float, Param_Float);
	
	g_fwOnShouldGiveProduct = CreateGlobalForward("PointSystemAPI_OnShouldGiveProduct", ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Float, Param_Float);
	
	char game_name[128];
	GetGameFolderName(game_name, sizeof(game_name));
	if(!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("This plugin only supports Left 4 Dead 2");
	}	
	LoadTranslations("common.phrases");
	StartPoints = CreateConVar("l4d2_points_start", "200", "Points to start each round/map with.");
	Notifications = CreateConVar("l4d2_points_notify", "1", "Show messages when points are earned?");
	Enable = CreateConVar("l4d2_points_enable", "1", "Enable Point System?");
	Modes = CreateConVar("l4d2_points_modes", "coop,realism,versus,teamversus", "Which game modes to use Point System");
	ResetPoints = CreateConVar("l4d2_points_reset_mapchange", "versus,teamversus", "Which game modes to reset point count on round end and round start");
	SValueKillingSpree = CreateConVar("l4d2_points_cikill_value", "2", "How many points does killing a certain amount of infected earn");
	SNumberKill = CreateConVar("l4d2_points_cikills", "25", "How many kills you need to earn a killing spree bounty");
	SValueHeadSpree = CreateConVar("l4d2_points_headshots_value", "4", "How many points does killing a certain amount of infected with headshots earn");
	SNumberHead = CreateConVar("l4d2_points_headshots", "20", "How many kills you need to earn a killing spree bounty");
	SSIKill = CreateConVar("l4d2_points_sikill", "1", "How many points does killing a special infected earn");
	STankKill = CreateConVar("l4d2_points_tankkill", "2", "How many points does killing a tank earn");
	SWitchKill = CreateConVar("l4d2_points_witchkill", "4", "How many points does killing a witch earn");
	SWitchCrown = CreateConVar("l4d2_points_witchcrown", "2", "How many points does crowning a witch earn");
	SHeal = CreateConVar("l4d2_points_heal", "5", "How many points does healing a team mate earn");
	SProtect = CreateConVar("l4d2_points_protect", "1", "How many points does protecting a team mate earn");
	SHealWarning = CreateConVar("l4d2_points_heal_warning", "1", "How many points does healing a team mate who did not need healing earn");
	SRevive = CreateConVar("l4d2_points_revive", "3", "How many points does reviving a team mate earn");
	SLedge = CreateConVar("l4d2_points_ledge", "1", "How many points does reviving a hanging team mate earn");
	SDefib = CreateConVar("l4d2_points_defib_action", "5", "How many points does defibbing a team mate earn");
	STBurn = CreateConVar("l4d2_points_tankburn", "2", "How many points does burning a tank earn");
	STSolo = CreateConVar("l4d2_points_tanksolo", "8", "How many points does killing a tank single-handedly earn");
	SWBurn = CreateConVar("l4d2_points_witchburn", "1", "How many points does burning a witch earn");
	STag = CreateConVar("l4d2_points_bile_tank", "2", "How many points does biling a tank earn");
	IChoke = CreateConVar("l4d2_points_smoke", "2", "How many points does smoking a survivor earn");
	IPounce = CreateConVar("l4d2_points_pounce", "1", "How many points does pouncing a survivor earn");
	ICarry = CreateConVar("l4d2_points_charge", "2", "How many points does charging a survivor earn");
	IImpact = CreateConVar("l4d2_points_impact", "1", "How many points does impacting a survivor earn");
	IRide = CreateConVar("l4d2_points_ride", "2", "How many points does riding a survivor earn");
	ITag = CreateConVar("l4d2_points_boom", "1", "How many points does booming a survivor earn");
	IIncap = CreateConVar("l4d2_points_incap", "3", "How many points does incapping a survivor earn");
	IHurt = CreateConVar("l4d2_points_damage", "2", "How many points does doing damage earn");
	IKill = CreateConVar("l4d2_points_kill", "5", "How many points does killing a survivor earn");
	
	RegConsoleCmd("sm_buystuff", BuyMenu);
	RegConsoleCmd("sm_buy", BuyMenu);
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
	HookEvent("versus_round_start", Event_VSRStart);
	HookEvent("finale_win", Event_Finale);
	HookEvent ("player_team", Event_ChangeTeam, EventHookMode_Pre);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_Post);
	//AutoExecConfig(true, "l4d2_points_system");
}

// Global Forward
public void KarmaKillSystem_OnKarmaEventPost(int victim, int attacker, const char[] KarmaName)
{
	int Points = 75;
	
	points[attacker] += Points;
	
	PrintToChat(attacker, "\x04[PS]\x01 Karma %s'd!!! + \x05%d\x03 points (Total: \x05%d\x03)", KarmaName, Points, points[attacker]);
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
			PrintToChat(i, "\x04[PS]\x03 Multiple Damage + \x05%d\x03 points *\x05 %dx\x03 =\x05 %d\x03 (Σ: \x05%d\x03)", GetConVarInt(IHurt), MultipleDamageStack[i] / GetConVarInt(IHurt), MultipleDamageStack[i], points[i]);
			MultipleDamageStack[i] = 0;
		}
	}
	
	return Plugin_Continue;
}

public void OnMapStart()
{
	PrecacheModel("models/v_models/v_rif_sg552.mdl", true);
	PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl", true);
	PrecacheModel("models/v_models/v_snip_awp.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl", true);
	PrecacheModel("models/v_models/v_snip_scout.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl", true);
	PrecacheModel("models/v_models/v_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/50cal.mdl", true);
	PrecacheModel("models/w_models/v_rif_m60.mdl", true);
	PrecacheModel("models/w_models/weapons/w_m60.mdl", true);
	PrecacheModel("models/v_models/v_m60.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	GetCurrentMap(MapName, sizeof(MapName));
	g_bIsAreaStart = false;
	PisserTimer = INVALID_HANDLE;
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


public Action HelpMessage(Handle Timer, any client)
{
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			
		if(IsTeamSurvivor(i))
			PrintHintText(i, "Recommended products to buy for human:\n!buy spas | !buy molly | !buy katana | !buy exammo | !buy fheal");
			
		else if(IsTeamInfected(i))
			PrintHintText(i, "Recommended products to buy for infected:\n!buy horde | !buy witch | !buy charger | !buy tank");
			
		PrintToChat(i, "Use \x03!suggest\x01 if you think you know how to improve the server!");
	}
	return Plugin_Continue;
}


public Action Event_VSRStart(Handle event, char[] event_name, bool dontBroadcast)
{
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			
		if(IsTeamSurvivor(i))
			PrintHintText(i, "Recommended products to buy for human:\n!buy spas | !buy molly | !buy katana | !buy exammo | !buy fheal");
			
		else if(IsTeamInfected(i))
			PrintHintText(i, "Recommended products to buy for infected:\n!buy horde | !buy witch | !buy charger | !buy tank");
	}
	
	return Plugin_Continue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("PS_CreateCategory", Native_CreateCategory);
	CreateNative("PS_CreateProduct", Native_CreateProduct);
	CreateNative("PS_GetVersion", Native_GetVersion);
	CreateNative("PS_SetPoints", Native_SetPoints);
	CreateNative("PS_HardSetPoints", Native_HardSetPoints);
	CreateNative("PS_GetPoints", Native_GetPoints);
	CreateNative("PS_FullHeal", Native_FullHeal);

	RegPluginLibrary("PointSystemAPI");
	return APLRes_Success;
}

public any Native_CreateCategory(Handle plugin, int numParams)
{
	return true;
}

public any Native_CreateProduct(Handle plugin, int numParams)
{
	enProduct product;
	
	product.iCategory = GetNativeCell(1);
	product.iCost = GetNativeCell(2);
	
	
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

public any Native_GetVersion(Handle plugin, int numParams)
{
	return version;
}

public int Native_SetPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int newval = GetNativeCell(2);
	points[client] = newval;
	
	return true;
}

public int Native_HardSetPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int newval = GetNativeCell(2);
	points[client] = newval;
	SavedInfectedPoints[client] = newval;
	SavedSurvivorPoints[client] = newval;
	
	return true;
}


public int Native_GetPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return points[client];
}	

public any Native_FullHeal(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	ExecuteFullHeal(client);
	
	return true;
}


public void OnClientAuthorized(int client, const char[] auth)
{
	if(points[client] > GetConVarInt(StartPoints)) return;
	points[client] = GetConVarInt(StartPoints);
	SavedSurvivorPoints[client] = GetConVarInt(StartPoints);
	SavedInfectedPoints[client] = GetConVarInt(StartPoints);
	if(killcount[client] > 0) return;
	killcount[client] = 0;
	wassmoker[client] = 0;
	hurtcount[client] = 0;
	protectcount[client] = 0;
	headshotcount[client] = 0;
	NextMultipleDamage[client] = 0.0;
	NextSpitterDamage[client] = 0.0;
	MultipleDamageStack[client] = 0;
	SpitterDamageStack[client] = 0;
}	

public Action Event_ChangeTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	int team = GetEventInt(event, "team");
	int oldteam = GetEventInt(event, "oldteam");
	
	if(oldteam == 2)
		SavedSurvivorPoints[client] = points[client];
		
	else if(oldteam == 3)
		SavedInfectedPoints[client] = points[client];
		
	if ( team == 2 || team == 3)
	{
		if(team == 2)
			points[client] = SavedSurvivorPoints[client];
			
		else if(team == 3)
			points[client] = SavedInfectedPoints[client];
			
		hurtcount[client] = 0;
		protectcount[client] = 0;	
		headshotcount[client] = 0;
		killcount[client] = 0;
		wassmoker[client] = 0;
		NextMultipleDamage[client] = 0.0;
		MultipleDamageStack[client] = 0;
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerLeftStartArea(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ( IsValidClient( client ) && IsPlayerAlive( client ) && IsInTeam( client, L4DTeam_Survivor ))
	{
		g_bIsAreaStart = true;
		CreateTimer(0.1, CheckMultipleDamage, 0, TIMER_REPEAT);
	}
	
	return Plugin_Continue;
}

public Action PissAWitch(Handle hTimer)
{
	int MaxEntities = GetEntityCount();
	
	int WitchArray[100], pos, PlayersArray[MAXPLAYERS+1], PlayersPos;

	
	char Classname[11];
	for(int i=0;i < MaxEntities;i++)
	{
		if(!IsValidEdict(i))
			continue;
		
		GetEdictClassname(i, Classname, sizeof(Classname));
		
		if(StrEqual(Classname, "witch", true))
		{
			WitchArray[pos] = i;
			pos++;
		}
	}	
	
	if(pos > 0)
	{
		for(int i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			else if(!IsPlayerAlive(i))
				continue;
			
			else if (IsFakeClient(i)) // Bots do not trigger the witch.
				continue;
				
			else if(GetClientTeam(i) != view_as<int>(L4DTeam_Survivor))
				continue;
				
			PlayersArray[PlayersPos] = i;
			PlayersPos++;
		}
		if(PlayersPos > 0)
		{
			int attacker = PlayersArray[GetRandomInt(0, PlayersPos-1)];
			int victim = WitchArray[GetRandomInt(0, pos-1)];
			
			int inflictor = GetPlayerWeaponSlot(attacker, 1);
			
			if(inflictor == -1) inflictor = attacker;
			
			SetEntPropFloat(victim, Prop_Send, "m_rage", 10000.0);
			SetEntPropFloat(victim, Prop_Send, "m_wanderrage", 10000.0);
			SDKHooks_TakeDamage(victim, inflictor, attacker, 1.0, DMG_GENERIC);
		}
	}
	return Plugin_Continue;
}	

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client)) return;
	CreateTimer(3.0, Check, client);
	if(points[client] > GetConVarInt(StartPoints)) return;
	points[client] = GetConVarInt(StartPoints);
	killcount[client] = 0;
	wassmoker[client] = 0;
	hurtcount[client] = 0;
	protectcount[client] = 0;
	headshotcount[client] = 0;
}	

public Action Check(Handle Timer, any client)
{
	if(!IsClientConnected(client))
	{
		points[client] = GetConVarInt(StartPoints);
		killcount[client] = 0;
		wassmoker[client] = 0;
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
			points[i] = GetConVarInt(StartPoints);
			SavedSurvivorPoints[i] = GetConVarInt(StartPoints);
			SavedInfectedPoints[i] = GetConVarInt(StartPoints);
			hurtcount[i] = 0;
			protectcount[i] = 0;
			headshotcount[i] = 0;
			killcount[i] = 0;
			wassmoker[i] = 0;
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
	RequestFrame(WipeThemAll, 0);
	
	if(PisserTimer != INVALID_HANDLE)
	{
		CloseHandle(PisserTimer);
		PisserTimer = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}	

public void WipeThemAll(int zero)
{
	WipeAllInfected();
}	
	
public Action Event_RStart(Handle event, char[] event_name, bool dontBroadcast)
{
	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl")) PrecacheModel("models/w_models/weapons/w_m60.mdl");
	if (!IsModelPrecached("models/v_models/v_m60.mdl")) PrecacheModel("models/v_models/v_m60.mdl");
	int iStartPoints = GetConVarInt(StartPoints);
	
	if(IsAllowedReset())
	{
		for (int i=1; i<=MaxClients; i++)
		{
			points[i] = GetConVarInt(StartPoints);
			SavedSurvivorPoints[i] = iStartPoints;
			SavedInfectedPoints[i] = iStartPoints;
			hurtcount[i] = 0;
			protectcount[i] = 0;
			headshotcount[i] = 0;
			killcount[i] = 0;
			wassmoker[i] = 0;
		}  
	}
	PrintToChatAll("\x04[PS]\x03 Your Start Points: \x05%i", iStartPoints);
	
	ResetProductCooldowns();
	
	CreateTimer(5.0, HelpMessage);
	
	if(PisserTimer != INVALID_HANDLE)
	{
		CloseHandle(PisserTimer);
		PisserTimer = INVALID_HANDLE;
	}

	PisserTimer = CreateTimer(GetConVarFloat(WitchPisser), PissAWitch, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}	

public Action Event_Finale(Handle event, char[] event_name, bool dontBroadcast)
{
	char gamemode[40];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if(StrEqual(gamemode, "versus", false) || StrEqual(gamemode, "teamversus", false)) return Plugin_Continue;
	for (int i=1; i<=MaxClients; i++)
	{
		points[i] = GetConVarInt(StartPoints);
		killcount[i] = 0;
		hurtcount[i] = 0;
		protectcount[i] = 0;
		headshotcount[i] = 0;
		wassmoker[i] = 0;
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
		if(headshotcount[attacker] == GetConVarInt(SValueHeadSpree) && GetConVarInt(SValueHeadSpree) > 0)
		{
			points[attacker] += GetConVarInt(SValueHeadSpree);
			headshotcount[attacker] -= GetConVarInt(SNumberHead);
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Head Hunter \x05+ %d\x03 points", GetConVarInt(SValueHeadSpree));
		}
		killcount[attacker]++;
		if(killcount[attacker] == GetConVarInt(SNumberKill) && GetConVarInt(SValueKillingSpree) > 0)
		{
			points[attacker] += GetConVarInt(SValueKillingSpree);
			killcount[attacker] -= GetConVarInt(SNumberKill);
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Killing Spree \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(SValueKillingSpree), points[attacker]);
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
		points[attacker] += GetConVarInt(IIncap);
		if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Incapped \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", userid, GetConVarInt(IIncap), points[attacker]);
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
			if(GetConVarInt(SSIKill) == -1 || GetClientTeam(client) == 2) return Plugin_Continue;
			if(GetEntProp(client, Prop_Send, "m_zombieClass") == 8) return Plugin_Continue;
			points[attacker] += GetConVarInt(SSIKill);
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Killed \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", client, GetConVarInt(SSIKill), points[attacker]);
		}
		if(GetClientTeam(attacker) == 3)
		{
			if(GetConVarInt(IKill) == -1 || GetClientTeam(client) == 3) return Plugin_Continue;
			points[attacker] += GetConVarInt(IKill);
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Killed \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", client, GetConVarInt(IKill), points[attacker]);
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
			points[attacker] += GetConVarInt(STSolo);
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 TANK SOLO! \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(STSolo), points[attacker]);
		}
	}
	for (int i=1; i<=MaxClients; i++)
	{
		if(i && IsClientInGame(i)&& !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && GetConVarInt(STankKill) > 0 && GetConVarInt(Enable) == 1 && IsAllowedGameMode())
		{
			points[i] += GetConVarInt(STankKill);
			if(GetConVarBool(Notifications)) PrintToChat(i, "\x04[PS]\x03 Killed Tank \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(STankKill), points[i]);
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
		if(GetConVarInt(SWitchKill) == -1) return Plugin_Continue;
		points[client] += GetConVarInt(SWitchKill);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Killed Witch + \x05%d\x03 points (Σ: \x05%d\x03)", GetConVarInt(SWitchKill), points[client]);
		if(oneshot && GetConVarInt(SWitchCrown) > 0)
		{
			points[client] += GetConVarInt(SWitchCrown);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Crowned The Witch + \x05%d\x03 points", GetConVarInt(SWitchCrown));
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
			if(GetConVarInt(SHeal) == -1) return Plugin_Continue;
			points[client] += GetConVarInt(SHeal);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Healed \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", subject, GetConVarInt(SHeal), points[client]);
		}
		else
		{
			if(GetConVarInt(SHealWarning) <= 0) return Plugin_Continue;
			points[client] += GetConVarInt(SHealWarning);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Don't Harvest Heal Points!", GetConVarInt(SHealWarning));
		}
	}
		
	return Plugin_Continue;
}	

public Action Event_Protect(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	int award = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && award == 67 && GetConVarInt(SProtect) > 0 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && !IsFakeClient(client) && IsAllowedGameMode())
	{
		if(GetConVarInt(SProtect) == -1) return Plugin_Continue;
		protectcount[client]++;
		if(protectcount[client] == 6)
		{
			points[client] += GetConVarInt(SProtect);
			protectcount[client] = 0;
		}	
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Protected Teammate\x05 + %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(SProtect), points[client]);
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
			points[client] += GetConVarInt(SRevive);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Revived \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", subject, GetConVarInt(SRevive), points[client]);
		}
		if(ledge && GetConVarInt(SLedge) > 0)
		{
			points[client] += GetConVarInt(SLedge);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Revived \x01%N\x03 From Ledge\x05 + %d\x03 points (Σ: \x05%d\x03)", subject, GetConVarInt(SLedge), points[client]);
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
		if(GetConVarInt(SDefib) == -1) return Plugin_Continue;
		points[client] += GetConVarInt(SDefib);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Defibbed \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", subject, GetConVarInt(SDefib), points[client]);
	}	
	
	return Plugin_Continue;
}	

public Action Event_Choke(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if(GetConVarInt(IChoke) == -1) return Plugin_Continue;
		points[client] += GetConVarInt(IChoke);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Choked Survivor\x05 + %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(IChoke), points[client]);
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
			points[attacker] += GetConVarInt(ITag);
			if(GetClientTeam(client) == 2 && GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Boomed \x01%N\x05 + %d\x03 points (Σ: \x05%d\x03)", client, GetConVarInt(ITag), points[attacker]);
		}
		if(GetClientTeam(attacker) == 2 && GetConVarInt(STag) > 0)
		{
			points[attacker] += GetConVarInt(STag);
			if(GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && GetConVarBool(Notifications)) PrintToChat(attacker, "\x04[PS]\x03 Biled Tank + \x05%d\x03 points (Σ: \x05%d\x03)", GetConVarInt(STag), points[attacker]);
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
		if(GetConVarInt(IPounce) == -1) return Plugin_Continue;
		points[client] += GetConVarInt(IPounce);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Pounced Survivor \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(IPounce), points[client]);
	}
		
	return Plugin_Continue;
}	

public Action Event_Ride(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if(GetConVarInt(IRide) == -1) return Plugin_Continue;
		points[client] += GetConVarInt(IRide);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Jockeyed Survivor \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(IRide), points[client]);
	}
		
	return Plugin_Continue;
}	

public Action Event_Carry(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if(GetConVarInt(ICarry) == -1) return Plugin_Continue;
		points[client] += GetConVarInt(ICarry);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Charged Survivor \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(ICarry), points[client]);
	}
		
	return Plugin_Continue;
}	

public Action Event_Impact(Handle event, const char[] name, bool dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if(GetConVarInt(IImpact) == -1) return Plugin_Continue;
		points[client] += GetConVarInt(IImpact);
		if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Impacted Survivor \x05+ %d\x03 points(Σ: \x05%d\x03)", GetConVarInt(IImpact), points[client]);
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
			points[client] += GetConVarInt(STBurn);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Burned The Tank \x05+ %d\x03 points", GetConVarInt(STBurn));
			tankburning[client] = 1;
		}
		if(StrEqual(victim, "Witch", false) && witchburning[client] == 0 && GetConVarInt(SWBurn) > 0)
		{
			points[client] += GetConVarInt(SWBurn);
			if(GetConVarBool(Notifications)) PrintToChat(client, "\x04[PS]\x03 Burned The Witch \x05+ %d\x03 points (Σ: \x05%d\x03)", GetConVarInt(SWBurn), points[client]);
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
			points[attacker] += GetConVarInt(IHurt);
			
			MultipleDamageStack[attacker] += GetConVarInt(IHurt);
			hurtcount[attacker] -= 3;
		}  
	}	
	
	return Plugin_Continue;
}	

public Action BuyMenu(int client, int args)
{
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
		GetCmdArgString(sArgString, sizeof(sArgString));
		
		// 2 and beyond are the target's name
		ReplaceStringEx(sArgString, sizeof(sArgString), sFirstArg, "");
		
		PrintToChat(client, "|%s|", sArgString);
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
		PrintToChat(client, "\x04[PS]\x03 You have \x05%d\x03 points", points[client]);
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
			COMMAND_FILTER_ALIVE,
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
			points[targetclient] += StringToInt(arg2);
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
			points[targetclient] = StringToInt(arg2);
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
	int pointsToSend = StringToInt(arg2);
	
	if(pointsToSend <= 0)
		return Plugin_Handled;
	if(pointsToSend > points[client])
	{

		ReplyToCommand(client, "\x04[PS]\x03 You cannot send more points than you have. (\x05%d\x03)", points[client]);
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
			
			else if(pointsToSend > points[client])
				return Plugin_Handled;
				
			points[targetclient] += pointsToSend;
			points[client] -= pointsToSend;
			
			char name[33], sendername[33];
			GetClientName(targetclient, name, sizeof(name)); 
			GetClientName(client, sendername, sizeof(sendername)); 
			ReplyToCommand(client, "\x04[PS]\x03 You gave \x05%d\x03 points to %s.", pointsToSend, name);
			PrintToChat(targetclient, "\x04[PS]\x03 %s gave you \x05%d\x03 points.", sendername, pointsToSend);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

/*
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
*/

void BuildBuyMenu(int client)
{
	if(client)
		return;
}	
	

bool IsValidClient(int iClient)
{
	if ( iClient < 1 || iClient > MaxClients ) return false;
	if ( !IsClientConnected( iClient )) return false;
	return ( IsClientInGame( iClient ));
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
			L4D_ReviveSurvivor(client);
		}
		else
			SetEntityHealthToMax(client);
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

stock int LookupProductByAlias(int client, char[] sAlias, enProduct finalProduct)
{
	
	int iSize = GetArraySize(g_aProducts);
	
	PrintToChatAll("%i", iSize);
	
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
	enProduct product;
		
	int productPos = LookupProductByAlias(client, sFirstArg, product);
	if(productPos == -1)
	{
		PrintToChat(client, "\x04[PS]\x03 Error: Product could not be found!");
		return;
	}
	
	L4DTeam iTeam = view_as<L4DTeam>(GetClientTeam(client));
	
	int iBuyFlags = product.iBuyFlags;
	
	if( (iBuyFlags & BUYFLAG_INFECTED != BUYFLAG_INFECTED && iTeam == L4DTeam_Infected) || (!(iBuyFlags & BUYFLAG_SURVIVOR) && iTeam == L4DTeam_Survivor))
	{
		PrintToChat(client, "\x04[PS]\x03 Error: Only %s can buy this!", iBuyFlags & BUYFLAG_SURVIVOR ? "Survivors" : "Infected");
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
			0,
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
		
		if(!(iBuyFlags & BUYFLAG_TEAM) && targetclient != client)
		{
			PrintToChat(client, "\x04[PS]\x03 Cannot buy %s for teammates", sFirstArg);
			continue;
		}
		
		char Name[64];
		GetClientName(targetclient, Name, sizeof(Name));
		bool bBot = IsFakeClient(targetclient);
		bool bAlive = IsPlayerAlive(targetclient);
		bool bPinned = L4D_IsPlayerPinned(targetclient);
		int pinningClient = L4D_GetPinnedInfected(targetclient);
		int pinningClass = 0;
		bool bProperClass = IsProperZombieClassForProduct(targetclient, product);
		
		if(pinningClient > 0)
			pinningClass = view_as<int>(L4D2_GetPlayerZombieClass(client));
		
		
		if(!(iBuyFlags & BUYFLAG_HUMANTEAM) && targetclient != client && !bBot)
		{
			PrintToChat(client, "\x04[PS]\x03 Cannot buy %s for non-bot teammates", sFirstArg);
			continue;
		}
		
		else if(!(iBuyFlags & BUYFLAG_DEAD) && !bAlive)
		{
			PrintToChat(client, "\x04[PS]\x03 %s must be alive to buy %s", targetclient == client ? "You" : Name, sFirstArg);
			continue;
		}
		
		else if(!(iBuyFlags & BUYFLAG_ALIVE) && bAlive)
		{
			PrintToChat(client, "\x04[PS]\x03 %s must be dead to buy %s", targetclient == client ? "You" : Name, sFirstArg);
			continue;
		}
		
		else if(!bProperClass)
		{
			L4D2ZombieClassType class = L4D2_GetPlayerZombieClass(client);
			
			PrintToChat(client, "\x04[PS]\x03 %s mustn't be %s to buy %s", targetclient == client ? "You" : Name, g_sBossNames[view_as<int>(class)], sFirstArg);
			continue;
		}
		
		else if(!(iBuyFlags & BUYFLAG_PINNED) && bPinned)
		{
			PrintToChat(client, "\x04[PS]\x03 %s mustn't be pinned to buy %s", targetclient == client ? "You" : Name, sFirstArg);
			continue;
		}
		
		else if(!(iBuyFlags & pinningClass))
		{
			PrintToChat(client, "\x04[PS]\x03 %s mustn't be pinned by a %s to buy %s", targetclient == client ? "You" : Name, g_sBossNames[pinningClass], sFirstArg);
			continue;
		}
		
		else if(product.NextBuyProduct[targetclient] > GetGameTime())
		{
			PrintToChat(client, "\x04[PS]\x03 %s is in %.2fsec cooldown for %s", sFirstArg, product.NextBuyProduct[targetclient] - GetGameTime(), targetclient == client ? "You" : Name);
			continue;
		}
	
		Call_StartForward(g_fwOnTryBuyProduct);
		
		enProduct alteredProduct; 
		alteredProduct = product;
		
		Call_PushCell(client);
		Call_PushString(alteredProduct.sInfo);
		Call_PushString(alteredProduct.sAliases);
		Call_PushString(alteredProduct.sName);
		Call_PushCellRef(targetclient);
		Call_PushCellRef(alteredProduct.iCost);
		Call_PushFloatRef(alteredProduct.fDelay);
		Call_PushFloatRef(alteredProduct.fCooldown);
		
		Action result;
		Call_Finish(result);
		
		if(result >= Plugin_Handled)
		{
			continue;
		}
		
		if(points[client] < alteredProduct.iCost)
		{
			PrintToChat(client, NOT_ENOUGH_POINTS, alteredProduct.iCost - points[client], points[client]);
			continue;
		}
		
		product.NextBuyProduct[targetclient] = GetGameTime() + alteredProduct.fCooldown;
		points[client] -= alteredProduct.iCost;
		
		SetArrayArray(g_aProducts, productPos, product);
		
		Handle hTimer;
		DataPack DP;
		
		// Creating a 0.0 timer will trigger it instantly, no time to populate the datapack.
		if(alteredProduct.fDelay < 0.1)
		{
			 hTimer = CreateDataTimer(1.0, Timer_DelayGiveProduct, DP, TIMER_FLAG_NO_MAPCHANGE);
			 
			 PrintToChat(client, "\x04[PS]\x03 Bought %s for %s", sFirstArg, targetclient == client ? "yourself" : Name);
		}	 
		else 
		{
			hTimer = CreateDataTimer(alteredProduct.fDelay, Timer_DelayGiveProduct, DP, TIMER_FLAG_NO_MAPCHANGE);
			
			PrintToChat(client, "\x04[PS]\x03 %s will be bought for %s in %.2fsec", sFirstArg, targetclient == client ? "yourself" : Name, alteredProduct.fDelay);
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
	
	int productPos = LookupProductByAlias(client, sFirstArg, product);
	
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
	Call_PushCell(alteredProduct.iCost);
	Call_PushFloat(alteredProduct.fDelay);
	Call_PushFloat(alteredProduct.fCooldown);
	
	Action result;
	Call_Finish(result);
	
	if(result >= Plugin_Handled)
	{
		points[client] += alteredProduct.iCost;
		
		if(alteredProduct.iCost > 0)
		{
			product.NextBuyProduct[targetclient] = 0.0;
			SetArrayArray(g_aProducts, productPos, product);
			PrintToChat(client, "\x04[PS]\x03 Refunded %s\x05 + %d\x03 points(Σ: \x05%d\x03)", sFirstArg, alteredProduct.iCost, points[client]);		
		}
		
		return Plugin_Stop;
	}
	
	Call_StartForward(g_fwOnShouldGiveProduct);
	
	Call_PushCell(client);
	Call_PushString(alteredProduct.sInfo);
	Call_PushString(alteredProduct.sAliases);
	Call_PushString(alteredProduct.sName);
	Call_PushCell(targetclient);
	Call_PushCell(alteredProduct.iCost);
	Call_PushFloat(alteredProduct.fDelay);
	Call_PushFloat(alteredProduct.fCooldown);	
	
	Call_Finish(result);
	
	if(result >= Plugin_Handled)
	{
		points[client] += alteredProduct.iCost;
		
		if(alteredProduct.iCost > 0)
		{
			product.NextBuyProduct[targetclient] = 0.0;
			SetArrayArray(g_aProducts, productPos, product);
			PrintToChat(client, "\x04[PS]\x03 Refunded %s\x05 + %d\x03 points(Σ: \x05%d\x03)", sFirstArg, alteredProduct.iCost, points[client]);		
		}
		
		return Plugin_Stop;
	}

	return Plugin_Stop;
}

stock bool IsProperZombieClassForProduct(int client, enProduct product)
{
	return view_as<bool>(product.iBuyFlags & view_as<int>(L4D2_GetPlayerZombieClass(client)));
}

stock void ResetProductCooldowns()
{
	int iSize = GetArraySize(g_aProducts);
	
	for (int i = 0; i < iSize;i++)
	{
		enProduct product;
		GetArrayArray(g_aProducts, i, product);
		
		for (int a = 0; a < sizeof(product.NextBuyProduct);a++)
			product.NextBuyProduct[a] = 0.0;
		
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