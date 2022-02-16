

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <ps_api>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

char g_sSIClassnames[][]={"","smoker","boomer","hunter","spitter", "jockey","charger"};
char g_sBossClassnames[][]={"","smoker","boomer","hunter","spitter","jockey","charger", "","tank"};

Handle PointsPistol = INVALID_HANDLE;
Handle PointsMagnum = INVALID_HANDLE;
Handle PointsSMG = INVALID_HANDLE;
Handle PointsSSMG = INVALID_HANDLE;
Handle PointsMP5 = INVALID_HANDLE;
Handle PointsM16 = INVALID_HANDLE;
Handle PointsAK = INVALID_HANDLE;
Handle PointsDesert = INVALID_HANDLE;
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
Handle PointsEAmmoPack = INVALID_HANDLE;
Handle PointsIAmmoPack = INVALID_HANDLE;
Handle PointsRefill = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Infected Module --> Point System API",
	author = "Eyal282",
	description = "Survivor products that are automatically generated with dumpentityfactories",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	// Pistols
	PointsPistol = CreateConVar("l4d2_points_pistol", "4", "How many points the pistol costs");
	PointsMagnum = CreateConVar("l4d2_points_magnum", "6", "How many points the magnum costs");
	
	// Melee
	PointsBat = CreateConVar("l4d2_points_bat", "4", "How many points the baseball bat costs");
	PointsMachete = CreateConVar("l4d2_points_machete", "6", "How many points the machete costs");
	PointsKatana = CreateConVar("l4d2_points_katana", "6", "How many points the katana costs");
	PointsTonfa = CreateConVar("l4d2_points_tonfa", "4", "How many points the tonfa costs");
	PointsFireaxe = CreateConVar("l4d2_points_fireaxe", "4", "How many points the fireaxe costs");
	PointsKnife = CreateConVar("l4d2_points_knife", "50", "How many points the knife costs");
	PointsGuitar = CreateConVar("l4d2_points_guitar", "4", "How many points the guitar costs");
	PointsPan = CreateConVar("l4d2_points_pan", "4", "How many points the frying pan costs");
	PointsCrow = CreateConVar("l4d2_points_crowbar", "4", "How many points the crowbar costs");
	PointsClub = CreateConVar("l4d2_points_golfclub", "6", "How many points the golf club costs");
	PointsSaw = CreateConVar("l4d2_points_chainsaw", "10", "How many points the chainsaw costs");
	
	// Throwables
	PointsPipe = CreateConVar("l4d2_points_pipe", "8", "How many points the pipe bomb costs");
	PointsMolly = CreateConVar("l4d2_points_molotov", "8", "How many points the molotov costs");
	PointsBile = CreateConVar("l4d2_points_bile", "8", "How many points the bile jar costs");
	
	// Health Items
	PointsKit = CreateConVar("l4d2_points_kit", "20", "How many points the health kit costs");
	PointsDefib = CreateConVar("l4d2_points_defib", "20", "How many points the defib costs");
	PointsAdren = CreateConVar("l4d2_points_adrenaline", "10", "How many points the adrenaline costs");
	PointsPills = CreateConVar("l4d2_points_pills", "10", "How many points the pills costs");
	
	// SMG
	PointsSMG = CreateConVar("l4d2_points_smg", "7", "How many points the smg costs");
	PointsSSMG = CreateConVar("l4d2_points_ssmg", "7", "How many points the silenced smg costs");
	PointsMP5 = CreateConVar("l4d2_points_mp5", "7", "How many points the mp5 costs");
	
	// Shotguns
	PointsPump = CreateConVar("l4d2_points_pump", "7", "How many points the pump shotgun costs");
	PointsChrome = CreateConVar("l4d2_points_chrome", "7", "How many points the chrome shotgun costs");
	PointsAuto = CreateConVar("l4d2_points_autoshotgun", "10", "How many points the autoshotgun costs");
	PointsSpas = CreateConVar("l4d2_points_spas", "10", "How many points the spas shotgun costs");
	
	// Rifles
	PointsDesert = CreateConVar("l4d2_points_desert", "12", "How many points the desert rifle costs");	
	PointsSG = CreateConVar("l4d2_points_sg", "12", "How many points the sg552 costs");
	PointsM16 = CreateConVar("l4d2_points_m16", "12", "How many points the m16 costs");
	PointsAK = CreateConVar("l4d2_points_ak", "12", "How many points the ak47 costs");
	PointsM60 = CreateConVar("l4d2_points_m60", "50", "How many points the m60 costs");
	PointsGL = CreateConVar("l4d2_points_grenade", "15", "How many points the grenade launcher costs");
	
	// Snipers
	PointsScout = CreateConVar("l4d2_points_scout", "10", "How many points the scout sniper costs");
	PointsHunting = CreateConVar("l4d2_points_hunting_rifle", "10", "How many points the hunting rifle costs");
	PointsMilitary = CreateConVar("l4d2_points_military_sniper", "14", "How many points the military sniper costs");
	PointsAWP = CreateConVar("l4d2_points_awp", "15", "How many points the awp costs");

	// Weapon Upgrades
	PointsRefill = CreateConVar("l4d2_points_refill", "8", "How many points an ammo refill costs");
	PointsEAmmoPack = CreateConVar("l4d2_points_explosive_ammo_pack", "15", "How many points the explosive ammo pack costs");
	PointsIAmmoPack = CreateConVar("l4d2_points_incendiary_ammo_pack", "15", "How many points the incendiary ammo pack costs");
	
	// Misc
	PointsGasCan = CreateConVar("l4d2_points_gascan", "5", "How many points the gas can costs");
	PointsCola = CreateConVar("l4d2_points_cola", "8", "How many points cola bottles costs");
	PointsPropane = CreateConVar("l4d2_points_propane", "2", "How many points the propane tank costs");
	PointsOxy = CreateConVar("l4d2_points_oxygen", "2", "How many points the oxgen tank costs");
	PointsGnome = CreateConVar("l4d2_points_gnome", "8", "How many points the gnome costs");
	PointsFireWorks = CreateConVar("l4d2_points_fireworks", "2", "How many points the fireworks crate costs");
	
	CreateSurvivorProducts();
}

public void OnConfigsExecuted()
{
	CreateSurvivorProducts();
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "PointSystemAPI"))
	{
		PrintToChatAll("Create items");
		CreateSurvivorProducts();
	}
}

// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.
public Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, int iCost, float fDelay, float fCooldown)
{
	if(strncmp(sInfo, "give ", 5) == 0)
	{
		PSAPI_ExecuteCheatCommand(target, sInfo);
	}
	
	return Plugin_Continue;
}

public void CreateSurvivorProducts()
{
	
	// Pistols
	PS_CreateProduct(-1, GetConVarInt(PointsPistol), "Pistol", NO_DESCRIPTION, "pistol", "give pistol", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsMagnum), "Magnum", NO_DESCRIPTION, "magnum", "give pistol_magnum", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_BOTTEAM | BUYFLAG_INCAP);
	
	// Melee
	PS_CreateProduct(-1, GetConVarInt(PointsBat), "Bat", NO_DESCRIPTION, "bat", "give cricket_bat", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsMachete), "Machete", NO_DESCRIPTION, "machete", "give machete", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsKatana), "Katana", NO_DESCRIPTION, "katana", "give katana", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsTonfa), "Tonfa", NO_DESCRIPTION, "tonfa", "give tonfa", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsFireaxe), "Fireaxe", NO_DESCRIPTION, "fireaxe axe", "give fireaxe", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsKnife), "Knife", NO_DESCRIPTION, "knife", "give knife", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsGuitar), "Guitar", NO_DESCRIPTION, "guitar", "give electric_guitar", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsPan), "Pan", NO_DESCRIPTION, "pan", "give frying_pan", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsCrow), "Crowbar", NO_DESCRIPTION, "crow bar crowbar", "give crowbar", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsClub), "Golf Club", NO_DESCRIPTION, "golf club", "give golfclub", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsSaw), "Chainsaw", NO_DESCRIPTION, "chainsaw chain saw", "give chainsaw", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);

	
	// Throwables
	PS_CreateProduct(-1, GetConVarInt(PointsPipe), "Pipe Bomb", NO_DESCRIPTION, "pipe pipebomb", "give pipe_bomb", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsMolly), "Molotov", NO_DESCRIPTION, "molotov molly moly cocktail", "give molotov", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER);
	PS_CreateProduct(-1, GetConVarInt(PointsBile), "Bile Bomb", NO_DESCRIPTION, "bile jar", "give vomitjar", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	
	
	// Health Items
	PS_CreateProduct(-1, GetConVarInt(PointsKit), "First Aid Kit", NO_DESCRIPTION, "kit med medkit aid", "give first_aid_kit", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsDefib), "Defibrillator", NO_DESCRIPTION, "defib defibrillator defibrilator defibillator defibilator", "give defibrillator", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsAdren), "Adrenaline", NO_DESCRIPTION, "adren adrenaline shot", "give adrenaline", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsPills), "Pills", NO_DESCRIPTION, "pills pill", "give pain_pills", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	
	// SMG
	PS_CreateProduct(-1, GetConVarInt(PointsSMG), "SMG", NO_DESCRIPTION, "smg", "give smg", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsSSMG), "Silenced SMG", NO_DESCRIPTION, "ssmg", "give smg_silenced", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsMP5), "MP5", NO_DESCRIPTION, "mp5", "give smg_mp5", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	
	// Shotguns
	PS_CreateProduct(-1, GetConVarInt(PointsPump), "Pump Shotgun", NO_DESCRIPTION, "pump shotgun", "give pumpshotgun", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsChrome), "Chrome Shotgun", NO_DESCRIPTION, "chrome", "give shotgun_chrome", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsAuto), "Auto Shotgun", NO_DESCRIPTION, "auto autoshotgun", "give autoshotgun", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsSpas), "Spas", NO_DESCRIPTION, "spas", "give shotgun_spas", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	
	// Rifles
	PS_CreateProduct(-1, GetConVarInt(PointsDesert), "Desert Rifle", NO_DESCRIPTION, "desert desertrifle", "give rifle_desert", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsSG), "SG552", NO_DESCRIPTION, "sg sg552 sg556", "give rifle_sg552", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsM16), "M-16", NO_DESCRIPTION, "m16 m4a1 m4a4", "give rifle", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsAK), "AK-47", NO_DESCRIPTION, "ak ak47", "give rifle_ak47", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsM60), "M-60", NO_DESCRIPTION, "m60", "give rifle_m60", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsGL), "Grenade Launcher", NO_DESCRIPTION, "gl launcher grenadelauncher grenade", "give grenade_launcher", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	
	
	// Snipers
	PS_CreateProduct(-1, GetConVarInt(PointsScout), "Scout", NO_DESCRIPTION, "scout", "give sniper_scout", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsHunting), "Hunting Rifle", NO_DESCRIPTION, "hunt hunting", "give hunting_riflee", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsMilitary), "Military Sniper", NO_DESCRIPTION, "military", "give sniper_military", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsAWP), "AWP", NO_DESCRIPTION, "awp", "give sniper_awp", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);

	// Weapon Upgrades
	PS_CreateProduct(-1, GetConVarInt(PointsRefill), "Ammo", NO_DESCRIPTION, "ammo", "give ammo", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsEAmmoPack), "Explosive Ammo Pack", NO_DESCRIPTION, "expack packex", "give upgradepack_explosive", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsIAmmoPack), "Incendiary Ammo Pack", NO_DESCRIPTION, "incpack inpack packinc packin", "give upgradepack_incendiary", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	
	// Misc
	PS_CreateProduct(-1, GetConVarInt(PointsGasCan), "Gas Can", NO_DESCRIPTION, "gas gascan can", "give gascan", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsCola), "Cola Bottles", NO_DESCRIPTION, "cola colla", "give cola_bottles", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsPropane), "Propane Tank", NO_DESCRIPTION, "propane", "give propanetank", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsOxy), "Oxygen Tank", NO_DESCRIPTION, "oxy oxygen", "give oxygentank", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsFireWorks), "Fireworks", NO_DESCRIPTION, "fworks fwork fireworks firework", "give fireworkcrate", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
	PS_CreateProduct(-1, GetConVarInt(PointsGnome), "Gnome", NO_DESCRIPTION, "gnome", "give gnome", 0.0, 0.0, BUYFLAG_ALIVE | BUYFLAG_SURVIVOR | BUYFLAG_PINNED_NO_SMOKER | BUYFLAG_INCAP);
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

// bNoPick = cannot press mouse2 to change to another SI in a ghost spawn by the plugin l4d2_zcs.smx

stock bool SpawnInfectedBossByClassname(int client, const char[] name, bool bGhost=false, bool bNoPick = false)
{	
	// Regardless of bGhost, we switch to ghost. If not ghost, we materialize.
	
	// Part of sequence to confuse ZCS into thinking we teleported to survivors from the message "You are too far away from survivors"
	if(bNoPick)
		L4D_RespawnPlayer(client);
	
	L4D_State_Transition(client, STATE_GHOST);
		
	
	for (int i = 0; i < sizeof(g_sBossClassnames);i++)
	{
		if(StrEqual(g_sBossClassnames[i], name))
			L4D_SetClass(client, i);
	}
	
	if(!bGhost)
		L4D_MaterializeFromGhost(client);

	// To confuse ZCS into thinking we pressed E to teleport after being far from survivors.
	SetEntProp(client, Prop_Send, "m_isCulling", bNoPick);
	SetEntProp(client, Prop_Send, "m_isRelocating", bNoPick);
	
	// Repeating the process removes the "You are too far away from survivors" message when you have a no pick.
	
	if(bNoPick)
	{
		L4D_State_Transition(client, STATE_GHOST);
			
		
		for (int i = 0; i < sizeof(g_sBossClassnames);i++)
		{
			if(StrEqual(g_sSIClassnames[i], name))
				L4D_SetClass(client, i);
		}
	}
	return true;
}