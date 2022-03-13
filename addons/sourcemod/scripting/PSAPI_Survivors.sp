

#include <ps_api>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

// float g_fNextBuyProduct[MAXPLAYERS + 1];

Handle PointsPistol    = INVALID_HANDLE;
Handle PointsMagnum    = INVALID_HANDLE;
Handle PointsSMG       = INVALID_HANDLE;
Handle PointsSSMG      = INVALID_HANDLE;
Handle PointsMP5       = INVALID_HANDLE;
Handle PointsM16       = INVALID_HANDLE;
Handle PointsAK        = INVALID_HANDLE;
Handle PointsDesert    = INVALID_HANDLE;
Handle PointsSG        = INVALID_HANDLE;
Handle PointsHunting   = INVALID_HANDLE;
Handle PointsMilitary  = INVALID_HANDLE;
Handle PointsAWP       = INVALID_HANDLE;
Handle PointsScout     = INVALID_HANDLE;
Handle PointsAuto      = INVALID_HANDLE;
Handle PointsSpas      = INVALID_HANDLE;
Handle PointsChrome    = INVALID_HANDLE;
Handle PointsPump      = INVALID_HANDLE;
Handle PointsGL        = INVALID_HANDLE;
Handle PointsM60       = INVALID_HANDLE;
Handle PointsGasCan    = INVALID_HANDLE;
Handle PointsOxy       = INVALID_HANDLE;
Handle PointsKnife     = INVALID_HANDLE;
Handle PointsPropane   = INVALID_HANDLE;
Handle PointsGnome     = INVALID_HANDLE;
Handle PointsFireWorks = INVALID_HANDLE;
Handle PointsBat       = INVALID_HANDLE;
Handle PointsMachete   = INVALID_HANDLE;
Handle PointsKatana    = INVALID_HANDLE;
Handle PointsTonfa     = INVALID_HANDLE;
Handle PointsFireaxe   = INVALID_HANDLE;
Handle PointsGuitar    = INVALID_HANDLE;
Handle PointsPan       = INVALID_HANDLE;
Handle PointsCrow      = INVALID_HANDLE;
Handle PointsClub      = INVALID_HANDLE;
Handle PointsShovel    = INVALID_HANDLE;
Handle PointsPitchfork = INVALID_HANDLE;
Handle PointsSaw       = INVALID_HANDLE;
Handle PointsPipe      = INVALID_HANDLE;
Handle PointsMolly     = INVALID_HANDLE;
Handle PointsBile      = INVALID_HANDLE;
Handle PointsKit       = INVALID_HANDLE;
Handle PointsDefib     = INVALID_HANDLE;
Handle PointsAdren     = INVALID_HANDLE;
Handle PointsPills     = INVALID_HANDLE;
Handle PointsEAmmoPack = INVALID_HANDLE;
Handle PointsIAmmoPack = INVALID_HANDLE;
Handle PointsRefill    = INVALID_HANDLE;

public Plugin myinfo =
{
	name        = "Survivors Module --> Point System API",
	author      = "Eyal282",
	description = "Survivor products that create physical items",
	version     = PLUGIN_VERSION,
	url         = ""
};

public void OnPluginStart()
{
	AutoExecConfig_SetFile("PointSystemAPI_Survivors");

	// Pistols
	PointsPistol = AutoExecConfig_CreateConVar("l4d2_points_pistol", "4", "How many points the pistol costs");
	PointsMagnum = AutoExecConfig_CreateConVar("l4d2_points_magnum", "6", "How many points the magnum costs");

	// Melee
	PointsBat       = AutoExecConfig_CreateConVar("l4d2_points_bat", "4", "How many points the baseball bat costs");
	PointsMachete   = AutoExecConfig_CreateConVar("l4d2_points_machete", "6", "How many points the machete costs");
	PointsKatana    = AutoExecConfig_CreateConVar("l4d2_points_katana", "6", "How many points the katana costs");
	PointsTonfa     = AutoExecConfig_CreateConVar("l4d2_points_tonfa", "4", "How many points the tonfa costs");
	PointsFireaxe   = AutoExecConfig_CreateConVar("l4d2_points_fireaxe", "4", "How many points the fireaxe costs");
	PointsKnife     = AutoExecConfig_CreateConVar("l4d2_points_knife", "50", "How many points the knife costs");
	PointsGuitar    = AutoExecConfig_CreateConVar("l4d2_points_guitar", "4", "How many points the guitar costs");
	PointsPan       = AutoExecConfig_CreateConVar("l4d2_points_pan", "4", "How many points the frying pan costs");
	PointsCrow      = AutoExecConfig_CreateConVar("l4d2_points_crowbar", "4", "How many points the crowbar costs");
	PointsClub      = AutoExecConfig_CreateConVar("l4d2_points_golfclub", "6", "How many points the golf club costs");
	PointsShovel    = AutoExecConfig_CreateConVar("l4d2_points_shovel", "6", "How many points the shovel costs");
	PointsPitchfork = AutoExecConfig_CreateConVar("l4d2_points_pitchfork", "6", "How many points the pitchfork costs");
	PointsSaw       = AutoExecConfig_CreateConVar("l4d2_points_chainsaw", "10", "How many points the chainsaw costs");

	// Throwables
	PointsPipe  = AutoExecConfig_CreateConVar("l4d2_points_pipe", "8", "How many points the pipe bomb costs");
	PointsMolly = AutoExecConfig_CreateConVar("l4d2_points_molotov", "8", "How many points the molotov costs");
	PointsBile  = AutoExecConfig_CreateConVar("l4d2_points_bile", "8", "How many points the bile jar costs");

	// Health Items
	PointsKit   = AutoExecConfig_CreateConVar("l4d2_points_kit", "20", "How many points the health kit costs");
	PointsDefib = AutoExecConfig_CreateConVar("l4d2_points_defib", "20", "How many points the defib costs");
	PointsAdren = AutoExecConfig_CreateConVar("l4d2_points_adrenaline", "10", "How many points the adrenaline costs");
	PointsPills = AutoExecConfig_CreateConVar("l4d2_points_pills", "10", "How many points the pills costs");

	// SMG
	PointsSMG  = AutoExecConfig_CreateConVar("l4d2_points_smg", "7", "How many points the smg costs");
	PointsSSMG = AutoExecConfig_CreateConVar("l4d2_points_ssmg", "7", "How many points the silenced smg costs");
	PointsMP5  = AutoExecConfig_CreateConVar("l4d2_points_mp5", "7", "How many points the mp5 costs");

	// Shotguns
	PointsPump   = AutoExecConfig_CreateConVar("l4d2_points_pump", "7", "How many points the pump shotgun costs");
	PointsChrome = AutoExecConfig_CreateConVar("l4d2_points_chrome", "7", "How many points the chrome shotgun costs");
	PointsAuto   = AutoExecConfig_CreateConVar("l4d2_points_autoshotgun", "10", "How many points the autoshotgun costs");
	PointsSpas   = AutoExecConfig_CreateConVar("l4d2_points_spas", "10", "How many points the spas shotgun costs");

	// Rifles
	PointsDesert = AutoExecConfig_CreateConVar("l4d2_points_desert", "12", "How many points the desert rifle costs");
	PointsSG     = AutoExecConfig_CreateConVar("l4d2_points_sg", "12", "How many points the sg552 costs");
	PointsM16    = AutoExecConfig_CreateConVar("l4d2_points_m16", "12", "How many points the m16 costs");
	PointsAK     = AutoExecConfig_CreateConVar("l4d2_points_ak", "12", "How many points the ak47 costs");
	PointsM60    = AutoExecConfig_CreateConVar("l4d2_points_m60", "50", "How many points the m60 costs");
	PointsGL     = AutoExecConfig_CreateConVar("l4d2_points_grenade", "15", "How many points the grenade launcher costs");

	// Snipers
	PointsScout    = AutoExecConfig_CreateConVar("l4d2_points_scout", "10", "How many points the scout sniper costs");
	PointsHunting  = AutoExecConfig_CreateConVar("l4d2_points_hunting_rifle", "10", "How many points the hunting rifle costs");
	PointsMilitary = AutoExecConfig_CreateConVar("l4d2_points_military_sniper", "14", "How many points the military sniper costs");
	PointsAWP      = AutoExecConfig_CreateConVar("l4d2_points_awp", "15", "How many points the awp costs");

	// Weapon Upgrades
	PointsRefill    = AutoExecConfig_CreateConVar("l4d2_points_refill", "8", "How many points an ammo refill costs");
	PointsEAmmoPack = AutoExecConfig_CreateConVar("l4d2_points_explosive_ammo_pack", "15", "How many points the explosive ammo pack costs");
	PointsIAmmoPack = AutoExecConfig_CreateConVar("l4d2_points_incendiary_ammo_pack", "15", "How many points the incendiary ammo pack costs");

	// Misc
	PointsGasCan    = AutoExecConfig_CreateConVar("l4d2_points_gascan", "5", "How many points the gas can costs");
	PointsPropane   = AutoExecConfig_CreateConVar("l4d2_points_propane", "2", "How many points the propane tank costs");
	PointsOxy       = AutoExecConfig_CreateConVar("l4d2_points_oxygen", "2", "How many points the oxgen tank costs");
	PointsGnome     = AutoExecConfig_CreateConVar("l4d2_points_gnome", "8", "How many points the gnome costs");
	PointsFireWorks = AutoExecConfig_CreateConVar("l4d2_points_fireworks", "2", "How many points the fireworks crate costs");

	CreateSurvivorProducts();

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
}

public void OnClientPutInServer(int client)
{
	Func_OnClientPutInServer(client);
}

public void Func_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponDropPost, SDKHook_OnWeaponDropPost);
}

public void SDKHook_OnWeaponDropPost(int client, int weapon)
{
	if (weapon == -1 || !IsValidEdict(weapon))
		return;

	char sClassname[64];
	GetEdictClassname(weapon, sClassname, sizeof(sClassname));

	if (!StrEqual(sClassname, "weapon_gascan"))
		return;

	char sTargetname[64];
	GetEntPropString(weapon, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

	if (strncmp(sTargetname, "PointSystemAPI", 14) != 0)
		return;

	PSAPI_SetGasolineGlow(weapon);
}

public void OnConfigsExecuted()
{
	CreateSurvivorProducts();
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "PointSystemAPI"))
	{
		CreateSurvivorProducts();
	}
}

public Action L4D2_CGasCan_ShouldStartAction(int client, int gascan)
{
	char sTargetname[64];
	GetEntPropString(gascan, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

	if (strncmp(sTargetname, "PointSystemAPI", 14) != 0)
		return Plugin_Continue;

	return Plugin_Handled;
}

// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.
public Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown)
{
	if (strncmp(sInfo, "give ", 5) == 0)
	{
		char sClassname[64];
		strcopy(sClassname, sizeof(sClassname), sInfo);
		ReplaceStringEx(sClassname, sizeof(sClassname), "give ", "weapon_");

		if (StrEqual(sClassname, "gascan"))
		{
			int iWeapon = CreateSpittableGascan(target);

			// 60 dictates time to delete this weapon if unowned.
			SetEntPropString(iWeapon, Prop_Data, "m_iName", "PointSystemAPI 60");

			PSAPI_SetGasolineGlow(iWeapon);

			return Plugin_Continue;
		}

		int iWeapon = GivePlayerItem(target, sClassname);

		if (iWeapon == -1)
		{
			// Nobody needs to know... CreateMeleeWeapon can freely create guns.
			ReplaceStringEx(sClassname, sizeof(sClassname), "weapon_", "");
			iWeapon = CreateMeleeWeapon(target, sClassname);
		}

		if (iWeapon == -1)
			return Plugin_Handled;

		// 60 dictates time to delete this weapon if unowned.
		SetEntPropString(iWeapon, Prop_Data, "m_iName", "PointSystemAPI 60");
	}

	return Plugin_Continue;
}

public void CreateSurvivorProducts()
{
	// Pistols
	int iWeaponsCategory = PSAPI_CreateCategory(-1, "survivors weapons", "Weapons Menu", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);

	int iCategory = -1;
	iCategory     = PSAPI_CreateCategory(iWeaponsCategory, "survivors pistols", "Pistols", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsPistol), "Pistol", NO_DESCRIPTION, "pistol", "give pistol", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsMagnum), "Magnum", NO_DESCRIPTION, "magnum", "give pistol_magnum", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_BOTTEAM | BUYFLAG_INCAP);

	// Melee
	iCategory = PSAPI_CreateCategory(iWeaponsCategory, "survivors melee", "Melee", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsBat), "Bat", NO_DESCRIPTION, "bat", "give cricket_bat", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsMachete), "Machete", NO_DESCRIPTION, "machete", "give machete", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsKatana), "Katana", NO_DESCRIPTION, "katana", "give katana", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsTonfa), "Tonfa", NO_DESCRIPTION, "tonfa", "give tonfa", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsFireaxe), "Fireaxe", NO_DESCRIPTION, "fireaxe axe", "give fireaxe", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsKnife), "Knife", NO_DESCRIPTION, "knife", "give knife", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsGuitar), "Guitar", NO_DESCRIPTION, "guitar", "give electric_guitar", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsPan), "Pan", NO_DESCRIPTION, "pan", "give frying_pan", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsCrow), "Crowbar", NO_DESCRIPTION, "crow bar crowbar", "give crowbar", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsClub), "Golf Club", NO_DESCRIPTION, "golf club", "give golfclub", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsShovel), "Shovel", NO_DESCRIPTION, "shovel", "give shovel", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsPitchfork), "Pitchfork", NO_DESCRIPTION, "fork pitch pitchfork forkpitch", "give pitchfork", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsSaw), "Chainsaw", NO_DESCRIPTION, "chainsaw chain saw", "give chainsaw", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);

	// Throwables
	iCategory = PSAPI_CreateCategory(iWeaponsCategory, "survivors throwables", "Throwables", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsPipe), "Pipe Bomb", NO_DESCRIPTION, "pipe pipebomb", "give pipe_bomb", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsMolly), "Molotov", NO_DESCRIPTION, "molotov molly moly molo cocktail", "give molotov", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsBile), "Bile Bomb", NO_DESCRIPTION, "bile jar", "give vomitjar", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);

	// Health Items
	iCategory = PSAPI_CreateCategory(-1, "health products", "Health Products", BUYFLAG_ALL_TEAMS | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsKit), "First Aid Kit", NO_DESCRIPTION, "kit med medkit aid", "give first_aid_kit", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP | BUYFLAG_TEAM);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsDefib), "Defibrillator", NO_DESCRIPTION, "defib defibrillator defibrilator defibillator defibilator", "give defibrillator", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsAdren), "Adrenaline", NO_DESCRIPTION, "adren adrenaline shot", "give adrenaline", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP | BUYFLAG_TEAM);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsPills), "Pills", NO_DESCRIPTION, "pills pill", "give pain_pills", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);

	// SMG
	iCategory = PSAPI_CreateCategory(iWeaponsCategory, "survivors smgs", "SMGs", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsSMG), "SMG", NO_DESCRIPTION, "smg", "give smg", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsSSMG), "Silenced SMG", NO_DESCRIPTION, "ssmg", "give smg_silenced", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsMP5), "MP5", NO_DESCRIPTION, "mp5", "give smg_mp5", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);

	// Shotguns
	iCategory = PSAPI_CreateCategory(iWeaponsCategory, "survivors shotguns", "Shotguns", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsPump), "Pump Shotgun", NO_DESCRIPTION, "pump shotgun", "give pumpshotgun", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsChrome), "Chrome Shotgun", NO_DESCRIPTION, "chrome", "give shotgun_chrome", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsAuto), "Auto Shotgun", NO_DESCRIPTION, "auto autoshotgun", "give autoshotgun", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsSpas), "Spas", NO_DESCRIPTION, "spas", "give shotgun_spas", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP | BUYFLAG_BOTTEAM);

	// Rifles
	iCategory = PSAPI_CreateCategory(iWeaponsCategory, "survivors rifles", "Rifles", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsDesert), "Desert Rifle", NO_DESCRIPTION, "desert desertrifle", "give rifle_desert", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsSG), "SG552", NO_DESCRIPTION, "sg sg552 sg556", "give rifle_sg552", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsM16), "M-16", NO_DESCRIPTION, "m16 m4a1 m4a4", "give rifle", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP | BUYFLAG_BOTTEAM);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsAK), "AK-47", NO_DESCRIPTION, "ak ak47", "give rifle_ak47", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP | BUYFLAG_BOTTEAM);

	// Special Rifles

	iCategory = PSAPI_CreateCategory(iWeaponsCategory, "survivors special rifles", "Special Rifles", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsM60), "M-60", NO_DESCRIPTION, "m60", "give rifle_m60", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP | BUYFLAG_TEAM);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsGL), "Grenade Launcher", NO_DESCRIPTION, "gl launcher grenadelauncher grenade rpg", "give grenade_launcher", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP | BUYFLAG_TEAM);

	// Snipers
	iCategory = PSAPI_CreateCategory(iWeaponsCategory, "survivors snipers", "Sniper Rifles", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsScout), "Scout", NO_DESCRIPTION, "scout", "give sniper_scout", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsHunting), "Hunting Rifle", NO_DESCRIPTION, "hunting hunt", "give hunting_rifle", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsMilitary), "Military Sniper", NO_DESCRIPTION, "military", "give sniper_military", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsAWP), "AWP", NO_DESCRIPTION, "awp", "give sniper_awp", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);

	// Weapon Upgrades
	iCategory = PSAPI_CreateCategory(-1, "weapon upgrades", "Weapon Upgrades", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsRefill), "Ammo", NO_DESCRIPTION, "ammo", "give ammo", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsEAmmoPack), "Explosive Ammo Pack", NO_DESCRIPTION, "expack packex", "give upgradepack_explosive", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsIAmmoPack), "Incendiary Ammo Pack", NO_DESCRIPTION, "incpack inpack packinc packin", "give upgradepack_incendiary", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);

	// Misc
	iCategory = PSAPI_CreateCategory(-1, "survivors misc", "Misc Menu", BUYFLAG_SURVIVOR | BUYFLAG_ALIVE | BUYFLAG_INCAP | BUYFLAG_PINNED);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsGasCan), "Gas Can", "A highly flammable gunpowder filled gas can\nYou cannot fuel anything with this", "gas gascan can", "give gascan", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsPropane), "Propane Tank", NO_DESCRIPTION, "propane", "give propanetank", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsOxy), "Oxygen Tank", NO_DESCRIPTION, "oxy oxygen", "give oxygentank", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsFireWorks), "Fireworks", NO_DESCRIPTION, "fworks fwork fireworks firework", "give fireworkcrate", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PSAPI_CreateProduct(iCategory, GetConVarFloat(PointsGnome), "Gnome", NO_DESCRIPTION, "gnome", "give gnome", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
}

// -1 for do nothing, 0 for active search
int g_iCheckEntity = -1;

stock int CreateSpittableGascan(int client)
{
	int iEnt = CreateEntityByName("weapon_scavenge_item_spawn");

	DispatchKeyValue(iEnt, "angles", "0 0 0");
	DispatchKeyValue(iEnt, "body", "0");
	DispatchKeyValue(iEnt, "disableshadows", "1");
	DispatchKeyValue(iEnt, "glowstate", "3");
	DispatchKeyValue(iEnt, "model", "models/props_junk/gascan001a.mdl");
	DispatchKeyValue(iEnt, "skin", "0");
	DispatchKeyValue(iEnt, "solid", "0");
	DispatchKeyValue(iEnt, "spawnflags", "2");
	DispatchKeyValue(iEnt, "targetname", "scavenge_gascans_spawn");
	DispatchSpawn(iEnt);

	float fOrigin[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", fOrigin);

	TeleportEntity(iEnt, fOrigin, NULL_VECTOR, NULL_VECTOR);

	g_iCheckEntity = 0;
	AcceptEntityInput(iEnt, "SpawnItem");

	AcceptEntityInput(iEnt, "Kill");

	if (g_iCheckEntity == 0)
		return -1;

	int iWeapon    = g_iCheckEntity;
	g_iCheckEntity = -1;

	if (!IsValidEdict(iWeapon))
		return -1;

	SetEntProp(iWeapon, Prop_Send, "m_nSkin", 0);
	EquipPlayerWeapon(client, iWeapon);

	return iWeapon;
}

stock int CreateMeleeWeapon(int client, const char[] sMeleeName)
{
	g_iCheckEntity = 0;

	char code[512];

	FormatEx(code, sizeof(code), "ret <- GetPlayerFromUserID(%d).GiveItem(\"%s\"); <RETURN>ret</RETURN>", GetClientUserId(client), sMeleeName);

	char sOutput[512];
	L4D2_GetVScriptOutput(code, sOutput, sizeof(sOutput));

	if (g_iCheckEntity == 0)
		return -1;

	int iWeapon    = g_iCheckEntity;
	g_iCheckEntity = -1;

	if (!IsValidEdict(iWeapon))
		return -1;

	char sClassname[64];
	GetEdictClassname(iWeapon, sClassname, sizeof(sClassname));

	// Before making the active search limiter, I sometimes got some instance entity instead of the katana.
	// PrintToChatAll("Class: %s", sClassname);

	// If you use EquipPlayerWeapon the server will crash :D
	// EquipPlayerWeapon(client, iWeapon);

	return iWeapon;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Left4Dhooks may decide to create a logic_script if no other one exists.
	if (StrEqual(classname, "logic_script"))
		return;

	else if (g_iCheckEntity == 0)
		g_iCheckEntity = entity;
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
