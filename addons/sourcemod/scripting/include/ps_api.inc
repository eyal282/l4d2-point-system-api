#if defined _PSAPI_API_included
 #endinput
#endif
#define _PSAPI_API_included

#include <autoexecconfig>
#include <left4dhooks>

#define PSAPI_NOT_ENOUGH_POINTS "\x04[PS]\x03 Failed! You need \x05%d\x03 more points to buy it! (Σ: \x05%d\x03)"

stock char g_sSINames[][]={"","Smoker","Boomer","Hunter","Spitter","Jockey","Charger"};
stock char g_sSIClassnames[][]={"","smoker","boomer","hunter","spitter","jockey","charger"};

stock char g_sBossNames[][]={"","Smoker","Boomer","Hunter","Spitter","Jockey","Charger","Witch","Tank","Survivor"};
stock char g_sBossClassnames[][]={"","smoker","boomer","hunter","spitter","jockey","charger","witch","tank","survivor"};

enum struct enCategory
{
	int iCategory; // Category number this category belongs to, or -1 for main buy menu.
	char sID[256]; // Identifier between plugins, players cannot see this.
	char sName[64]; // Category Name
	int iBuyFlags; // Must use variable that determines flags that specify when you can buy. BUYFLAG_* in PSAPI_api.inc
}

enum struct enProduct
{
	int iCategory; // Category number this product belongs to, or -1 for main buy menu.
	float fCost; // Cost of this product rounded down.
	int iBuyFlags; // Must use variable that determines flags that specify when you can buy. BUYFLAG_* in PSAPI_api.inc
	char sName[64]; // Product Name
	char sDescription[512]; // Optional Description
	char sAliases[256]; // Alises, seperated by spaces, to buy directly with !buy <alias>
	char sInfo[256]; // Info that only devs can see.

	float fDelay; // Delay between purchase to obtaining the product.
	float fCooldown; // Cooldown between purchases.
	
	float fNextBuyProduct[MAXPLAYERS + 1]; // Next time each player can buy this product.
}


#define NO_DESCRIPTION "" // Simple way to understand the empty space is a description



#define BUYFLAG_NO_DEAD_SURVIVORS	(BUYFLAG_ALIVE|BUYFLAG_INCAP|BUYFLAG_DEAD_INFECTED|BUYFLAG_GHOST)
#define BUYFLAG_ALL_LIFESTATES		(BUYFLAG_ALIVE|BUYFLAG_INCAP|BUYFLAG_DEAD|BUYFLAG_GHOST)
#define BUYFLAG_ANY_ALIVE			(BUYFLAG_ALIVE|BUYFLAG_GHOST|BUYFLAG_INCAP) // Can this product be bought when a player has m_isAlive?
#define BUYFLAG_ALIVE_NO_INCAP			BUYFLAG_ALIVE|BUYFLAG_GHOST // Can this product be bought when a player has m_isAlive?
#define BUYFLAG_ALIVE				(1<<0) // Can this product be bought while you're alive? Ghosts are a third life state for PSAPI
#define BUYFLAG_INCAP				(1<<10) // Can this product be bought while you're incapacitated?
#define BUYFLAG_DEAD				(BUYFLAG_DEAD_SURVIVORS|BUYFLAG_DEAD_INFECTED)
#define BUYFLAG_DEAD_SURVIVORS (1<<20) // Can this product be bought while you're a dead survivor?
#define BUYFLAG_DEAD_INFECTED				(1<<21) // Can this product be bought while you're a dead infected?
#define BUYFLAG_GHOST				(1<<22) // Can this product be bought while you're a ghost? 
#define BUYFLAG_ONLY_INCAP				(1<<23) // Can this product be bought ONLY if you're incapacitated?

// On purpose that BUYFLAG_INFECTED_SMOKER == (1<<L4D2ZombieClass_Smoker) and all the others including survivor have this property in common.
#define BUYFLAG_ALL_TEAMS				(BUYFLAG_SURVIVOR|BUYFLAG_INFECTED)
#define BUYFLAG_INFECTED_SMOKER			(1<<1) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_BOOMER			(1<<2) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_HUNTER			(1<<3) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_SPITTER			(1<<4) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_JOCKEY			(1<<5) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_CHARGER			(1<<6) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_TANK			(1<<8) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_NO_TANK		(BUYFLAG_INFECTED_SMOKER|BUYFLAG_INFECTED_BOOMER|BUYFLAG_INFECTED_HUNTER|BUYFLAG_INFECTED_SPITTER|BUYFLAG_INFECTED_JOCKEY|BUYFLAG_INFECTED_CHARGER) // Can this product be bought while you're a non-tank infected?
#define BUYFLAG_INFECTED			(BUYFLAG_INFECTED_NO_TANK|BUYFLAG_INFECTED_TANK) // Can this product be bought while you're an Infected?
#define BUYFLAG_SURVIVOR			(1<<9) // Can this product be bought while you're a Survivor?


// On purpose that BUYFLAG_INFECTED_SMOKER == (1<<(10+L4D2ZombieClass_Smoker)) and all the others have this property in common.
#define BUYFLAG_PINNED_SMOKER		(1<<11) // Can this product be bought while you're pinned by a Smoker?
#define BUYFLAG_PINNED_HUNTER				(1<<13) // Can this product be bought while you're pinned by any Special Infected?
#define BUYFLAG_PINNED_JOCKEY				(1<<15) // Can this product be bought while you're pinned by any Special Infected?
#define BUYFLAG_PINNED_CHARGER				(1<<16) // Can this product be bought while you're pinned by any Special Infected?

#define BUYFLAG_ONLY_PINNED (1<<17)					// Can this product be bought ONLY if you're pinned? Must activate a BUYFLAG_PINNED* flag for this. 
#define BUYFLAG_PINNED				(BUYFLAG_PINNED_SMOKER|BUYFLAG_PINNED_HUNTER|BUYFLAG_PINNED_JOCKEY|BUYFLAG_PINNED_CHARGER)
#define BUYFLAG_PINNED_NO_SMOKER	(BUYFLAG_PINNED_HUNTER|BUYFLAG_PINNED_JOCKEY|BUYFLAG_PINNED_CHARGER)
#define BUYFLAG_PINNED_NO_HUNTER	(BUYFLAG_PINNED_SMOKER|BUYFLAG_PINNED_JOCKEY|BUYFLAG_PINNED_CHARGER)
#define BUYFLAG_PINNED_NO_JOCKEY	(BUYFLAG_PINNED_SMOKER|BUYFLAG_PINNED_HUNTER|BUYFLAG_PINNED_CHARGER)
#define BUYFLAG_PINNED_NO_CHARGER	(BUYFLAG_PINNED_SMOKER|BUYFLAG_PINNED_HUNTER|BUYFLAG_PINNED_JOCKEY)

// Below this line is only for products and not for categories
#define BUYFLAG_HUMANTEAM			(1<<18) // Can this product be bought to non-bot teammates?
#define BUYFLAG_BOTTEAM				(1<<19) // Can this product be bought for your bot teammates?
#define BUYFLAG_TEAM			(BUYFLAG_BOTTEAM|BUYFLAG_HUMANTEAM) // Can this product be bought for your teammates?

#define BUYFLAG_CUSTOMNAME			(1<<30) // Ask for this product's name when opening !buy menu
#define BUYFLAG_REALTIME_REFUNDS			(1<<31) // Check for the ability to refund this product in real-time. 

/*
Clarification: If BUYFLAG_TEAM is present and BUYFLAG_HUMANTEAM is not present,
you can basically help your bots, buying them products without disturbing any players. 
*/

// Natives

// Creates or edits a category.
// Not all buy flags work with categories, check BUYFLAG_* for more info.
// sID is an identifier that is not shared to the player.
native int PSAPI_CreateCategory(int iCategory, char[] sID, char[] sName, int iBuyFlags)

// Creates or edits a product.
// The first alias is documented in the buy menu.
// fCost is rounded to an integer.
// Each alias is maxed at 32 characters.
native bool PSAPI_CreateProduct(int iCategory, float fCost, char[] sName, char[] sDescription, char[] sAliases, char[] sInfo, float fDelay, float fCooldown, int iBuyFlags);

// Finds a category by sID
// To invoke:
// enCategory cat;
// PSAPI_FindCategoryByIdentifier(sID, cat);
native bool PSAPI_FindCategoryByIdentifier(const char[] sID, any[] aCat);

// Finds a product by one of their aliases.
// To invoke:
// enProduct product;
// PSAPI_FindProductByAlias(sAlias, product);
native bool PSAPI_FindProductByAlias(const char[] sAlias, any[] aProduct);

// Returns negative for disabled or non-existent product, returns 0.0 for free product, returns positive for the cost.
native float PSAPI_FetchProductCostByAlias(const char[] sAlias, int buyer, int targetclient);

// Gets the current version of Point System API.
native float PSAPI_GetVersion();

// Gets a client's points in his current team.
// Points are always displayed as integers by rounding down
native float PSAPI_GetPoints(int client);

// Sets a client's point for every team. You should almost always use PSAPI_SetPoints for setting points.
native void PSAPI_HardSetPoints(int client, float fPoints);

// Sets a client's points for his current team.
native void PSAPI_SetPoints(int client, float fPoints);

stock void PSAPI_GivePoints(int client,  float fPoints)
{
	PSAPI_SetPoints(client, PSAPI_GetPoints(client) + fPoints);
}

stock void PSAPI_RemovePoints(int client, float fPoints)
{
	PSAPI_SetPoints(client, PSAPI_GetPoints(client) - fPoints);
}

// Uses my own algorithm to fully heal a player, fixing the bug where you get to 100 hp when incapped and pinned.
native void PSAPI_FullHeal(int client);

// Checks how many times a tank has healed, don't use for non-tanks
// Also checks the maximum amount of heals within the cvar.
native void PSAPI_GetTankHealCount(int client, int &maxHeals);

// Adds amount of tank heal counts, also useful for special tanks that shouldn't be able to heal.
native void PSAPI_AddTankHealCount(int client, int amount);


// Forwards

// No return
forward void PointSystemAPI_OnGetParametersCategory(int buyer, const char[] sID, char[] sName);

// Called even if you cannot afford the product, and even if you didn't try to buy the product'.
// sAliases contain the original alias list, to compare your own alias as an identifier.
// If the cost drops below 0, the item is disabled!!!
// Every cost of an item will always be treated as a whole number.
// No return
forward void PointSystemAPI_OnGetParametersProduct(int buyer, const char[] sAliases, char[] sInfo, char[] sName, char[] sDescription, int target, float &fCost, float &fDelay, float &fCooldown);

// sAliases contain the original alias list, to compare your own alias as an identifier.
// You should print an error because blocking purchase prints nothing
// Return Plugin_Handled to block purchase
forward Action PointSystemAPI_OnTryBuyProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown);

// sAliases contain the original alias list, to compare your own alias as an identifier.
// Called every 0.1 seconds during the delay of arrival.
// Product must have BUYFLAG_REALTIME_REFUNDS.
// fTimeleft can be 0.0, and in this case, in the same frame PointSystemAPI_OnBuyProductPost will be called, so you don't need PointSystemAPI_OnBuyProductPost if you have this.
// You should reconsider printing an error because blocking purchase prints a refund point gain.
// Return Plugin_Handled to refund purchase
forward Action PointSystemAPI_OnRealTimeRefundProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fTimeleft)
	
	
// If a delay exists, called several seconds after PointSystemAPI_OnTryBuyProduct. Otherwise this is called instantly. 
// sAliases contain the original alias list, to compare your own alias as an identifier.

// You should reconsider printing an error because blocking purchase prints a refund point gain.
// Return Plugin_Handled to refund.
forward Action PointSystemAPI_OnBuyProductPost(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown);
	
// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.

// You should reconsider printing an error because blocking purchase prints a refund point gain.
// Return Plugin_Handled to refund if you cannot give the product, which should be rare.
forward Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] info, const char[] sAliases, const char[] sName, int target, float fCost, float fDelay, float fCooldown);





// Stocks

stock int PSAPI_GetTeamHumansCount(L4DTeam team, bool bAliveOnly)
{
	int iCount;
	
	for (int i = 1; i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			
		else if(GetClientTeam(i) != view_as<int>(team))
			continue;
			
		else if(bAliveOnly && !IsPlayerAlive(i))
			continue;
			
		iCount++;
	}
	
	return iCount;
}

// Gets the combined number of points a team has.
stock float PSAPI_GetTeamPoints(L4DTeam team, bool bAliveOnly)
{	
	float fTotalPoints = 0.0;
	for (int i = 1; i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			
		else if(GetClientTeam(i) != view_as<int>(team))
			continue;
			
		else if(bAliveOnly && !IsPlayerAlive(i))
			continue;
			
		fTotalPoints += PSAPI_GetPoints(i);
	}
	
	return fTotalPoints;	
}
stock void PSAPI_ExecuteCheatCommand(int client, const char[] command, any ...)
{
	char sFirstArg[64];
	
	BreakString(command, sFirstArg, sizeof(sFirstArg));
	
	int flags = GetCommandFlags(sFirstArg);

	SetCommandFlags(sFirstArg, flags & ~FCVAR_CHEAT);
	
	char formattedCommand[256];
	
	VFormat(formattedCommand, sizeof(formattedCommand), command, 3);
	
	FakeClientCommand(client, command);
	
	SetCommandFlags(sFirstArg, flags);
}


// Target == 0 for buyer
// Sneaking in a fake product requires to populate: iBuyFlags, fNextBuyProduct[MAXPLAYERS+1]
stock bool PSAPI_GetErrorFromBuyflags(int buyer, char[] sFirstArg, enProduct product, int target=0, char[] sError="", int iLength=0, bool &bShouldReturn=false)
{
	if(target == 0)
		target = buyer;
		
	int iBuyFlags = product.iBuyFlags;
	L4DTeam iTeam = view_as<L4DTeam>(GetClientTeam(buyer));
	
	if(product.fCost < 0.0)
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 Error: This product is disabled!", iBuyFlags & BUYFLAG_SURVIVOR ? "Survivors" : "Infected");
		bShouldReturn = true;
		return true;
	}
	
	if( (iBuyFlags & BUYFLAG_INFECTED != BUYFLAG_INFECTED && iTeam == L4DTeam_Infected) || (!(iBuyFlags & BUYFLAG_SURVIVOR) && iTeam == L4DTeam_Survivor))
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 Error: Only %s can buy this!", iBuyFlags & BUYFLAG_SURVIVOR ? "Survivors" : "Infected");
		bShouldReturn = true;
		return true;
	}
	else if(!(iBuyFlags & BUYFLAG_TEAM) && target != buyer)
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 Cannot buy %s for teammates", sFirstArg);
		return true;
	}
	
	char sName[64];
	GetClientName(target, sName, sizeof(sName));
	bool bBot = IsFakeClient(target);
	bool bAlive = IsPlayerAlive(target);
	bool bGhost = L4D_IsPlayerGhost(target);
	bool bPinned = L4D_IsPlayerPinned(target);
	bool bIncap = L4D_IsPlayerIncapacitated(target);
	int pinningClient = L4D_GetPinnedInfected(target);
	int pinningClass = view_as<int>(L4D2ZombieClass_NotInfected);
	bool bProperClass = PSAPI_IsProperZombieClassForProduct(target, product);
	
	if(pinningClient > 0)
		pinningClass = view_as<int>(L4D2_GetPlayerZombieClass(pinningClient));
	
	
	if(!(iBuyFlags & BUYFLAG_HUMANTEAM) && target != buyer && !bBot)
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 Cannot buy %s for non-bot teammates", sFirstArg);
		return true;
	}
	
	else if(!(iBuyFlags & BUYFLAG_BOTTEAM) && target != buyer && bBot)
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 Cannot buy %s for bot teammates", sFirstArg);
		return true;
	}
	

	else if(!(iBuyFlags & BUYFLAG_INCAP) && bIncap)
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 %s mustn't be incapped to buy %s", target == buyer ? "You" : sName, sFirstArg);
		return true;
	}
	
	else if(iBuyFlags & BUYFLAG_ONLY_INCAP && !bIncap)
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 %s must be incapped to buy %s", target == buyer ? "You" : sName, sFirstArg);
		return true;
	}
	else if(!(iBuyFlags & BUYFLAG_GHOST) && bGhost)
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 %s must be %s to buy %s", target == buyer ? "You" : sName, iBuyFlags & BUYFLAG_ALIVE ? "alive" : "dead", sFirstArg);
		return true;
	}
	else if( ( !(iBuyFlags & BUYFLAG_DEAD_SURVIVORS) && !bAlive && iTeam == L4DTeam_Survivor ) || ( !(iBuyFlags & BUYFLAG_DEAD_INFECTED) && !bAlive && iTeam == L4DTeam_Infected ))
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 %s must be alive to buy %s", target == buyer ? "You" : sName, sFirstArg);
		return true;
	}
	
	else if(!(iBuyFlags & BUYFLAG_ALIVE) && bAlive)
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 %s must be dead to buy %s", target == buyer ? "You" : sName, sFirstArg);
		return true;
	}
	
	else if(!(iBuyFlags & BUYFLAG_PINNED) && bPinned)
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 %s mustn't be pinned to buy %s", target == buyer ? "You" : sName, sFirstArg);
		return true;
	}
	
	else if(iBuyFlags & BUYFLAG_ONLY_PINNED && !bPinned)
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 %s must be pinned to buy %s", target == buyer ? "You" : sName, sFirstArg);
		return true;
	}
	
	// 10 is a constant created by the fact that BUYFLAG_PINNED_SMOKER = (1<< (L4D2ZombieClass_Smoker + 10))
	else if(pinningClass != view_as<int>(L4D2ZombieClass_NotInfected) && iBuyFlags & (1<< (10 + pinningClass)) != (1<< (10 + pinningClass)))
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 %s mustn't be pinned by a %s to buy %s", target == buyer ? "You" : sName, g_sBossNames[pinningClass], sFirstArg);
		return true;		
	}
	else if(!bProperClass)
	{
		L4D2ZombieClassType class = L4D2_GetPlayerZombieClass(target);
		
		FormatEx(sError, iLength, "\x04[PS]\x03 %s mustn't be a %s to buy %s", target == buyer ? "You" : sName, g_sBossNames[class], sFirstArg);
		return true;
	}
	
	else if(product.fNextBuyProduct[target] > GetGameTime())
	{
		FormatEx(sError, iLength, "\x04[PS]\x03 %s is in %.2fsec cooldown for %s", sFirstArg, product.fNextBuyProduct[target] - GetGameTime(), target == buyer ? "You" : sName);
		return true;
	}
	
	return false;
}


stock bool PSAPI_IsProperZombieClassForProduct(int client, enProduct product)
{
	if(!IsPlayerAlive(client))
		return true;
		
	else if(GetClientTeam(client) == view_as<int>(L4DTeam_Survivor))
		return true;
		
	return view_as<bool>(product.iBuyFlags & view_as<int>(L4D2_GetPlayerZombieClass(client)));
}

// bNoPick = cannot press mouse2 to change to another SI in a ghost spawn by the plugin l4d2_zcs.smx

stock bool PSAPI_SpawnInfectedBossByClassname(int client, const char[] name, bool bGhost=false, bool bNoPick = false)
{	
	if(StrEqual(name, "survivor") || StrEqual(name, "witch"))
		return false;
		
	// Regardless of bGhost, we switch to ghost. If not ghost, we materialize.
	
	// Multi tanks will create utter chaos if we don't first swap to a non-tank class prior to spawning the player.
	L4D_SetClass(client, view_as<int>(L4D2ZombieClass_Charger));
	L4D2_SetPlayerZombieClass(client, L4D2ZombieClass_Charger);

	float fOrigin[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", fOrigin);

	L4D_State_Transition(client, STATE_GHOST);
		
	if(bNoPick)
	{
		// To confuse ZCS into thinking we pressed E to teleport after being far from survivors.
		SetEntProp(client, Prop_Send, "m_isCulling", bNoPick);
		SetEntProp(client, Prop_Send, "m_isRelocating", bNoPick);

		// Respawn is required to make ZCS think we relocated. Must put state transition above to ensure spec2ghost take the OnEnterGhostState
		L4D_RespawnPlayer(client);

		// Since we must switch to ghost again, we must recreate the spectator origin to activate spec2ghost
		TeleportEntity(client, fOrigin);

		// On top of state transition required to negate RespawnPlayer, you must switch state twice to remove a fake message of "You are too far away from survivors" caused by either isRelocating or isCulling
		L4D_State_Transition(client, STATE_GHOST);
	}
	
	for (int i = 0; i < sizeof(g_sBossClassnames);i++)
	{
		if(StrEqual(g_sBossClassnames[i], name))
		{
			L4D_SetClass(client, i);
			L4D2_SetPlayerZombieClass(client, view_as<L4D2ZombieClassType>(i));
		}
	}
	
	PSAPI_FullHeal(client); // I don't know how, but I once spawned as a tank health smoker.
	
	if(!bGhost)
		L4D_MaterializeFromGhost(client);

	return true;
}

stock void PSAPI_SetGasolineGlow(int iWeapon)
{
	L4D2_SetEntityGlow(iWeapon, L4D2Glow_Constant, 0, 0, { 0, 200, 0 }, true );
}