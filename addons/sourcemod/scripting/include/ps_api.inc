#if defined _PS_API_included
 #endinput
#endif
#define _PS_API_included

#define BUYFLAG_ALIVE				(1<<0) // Can this product be bought while you're alive? Ghosts are a third life state for PSAPI
#define BUYFLAG_DEAD				(1<<10) // Can this product be bought while you're dead?
#define BUYFLAG_GHOST				(1<<20) // Can this product be bought while you're a ghost?

#define BUYFLAG_ANY_ALIVE			BUYFLAG_ALIVE|BUYFLAG_GHOST // Can this product be bought when a player has m_isAlive?

// On purpose that BUYFLAG_INFECTED_SMOKER == (1<<L4D2ZombieClass_Smoker) and all the others including survivor have this property in common.
#define BUYFLAG_INFECTED_SMOKER			(1<<1) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_BOOMER			(1<<2) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_HUNTER			(1<<3) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_SPITTER			(1<<4) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_JOCKEY			(1<<5) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_CHARGER			(1<<6) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_TANK			(1<<8) // Can this product be bought while you're a Charger?
#define BUYFLAG_INFECTED_NO_TANK		BUYFLAG_INFECTED_SMOKER|BUYFLAG_INFECTED_BOOMER|BUYFLAG_INFECTED_HUNTER|BUYFLAG_INFECTED_SPITTER|BUYFLAG_INFECTED_JOCKEY|BUYFLAG_INFECTED_CHARGER // Can this product be bought while you're a non-tank infected?
#define BUYFLAG_INFECTED			BUYFLAG_INFECTED_NO_TANK|BUYFLAG_INFECTED_TANK // Can this product be bought while you're an Infected?
#define BUYFLAG_SURVIVOR			(1<<9) // Can this product be bought while you're a Survivor?

// Below this line is only for products and not for categories.
// On purpose that BUYFLAG_INFECTED_SMOKER == (1<<(10+L4D2ZombieClass_Smoker)) and all the others have this property in common.
#define BUYFLAG_PINNED_SMOKER		(1<<11) // Can this product be bought while you're pinned by a Smoker?
#define BUYFLAG_PINNED_HUNTER				(1<<13) // Can this product be bought while you're pinned by any Special Infected?
#define BUYFLAG_PINNED_JOCKEY				(1<<15) // Can this product be bought while you're pinned by any Special Infected?
#define BUYFLAG_PINNED_CHARGER				(1<<16) // Can this product be bought while you're pinned by any Special Infected?

#define BUYFLAG_ONLY_PINNED (1<<17)					// Can this product be bought ONLY if you're pinned? Must activate a BUYFLAG_PINNED* flag for this. 
#define BUYFLAG_PINNED				BUYFLAG_PINNED_SMOKER|BUYFLAG_PINNED_HUNTER|BUYFLAG_PINNED_JOCKEY|BUYFLAG_PINNED_CHARGER
#define BUYFLAG_PINNED_NO_SMOKER	BUYFLAG_PINNED_HUNTER|BUYFLAG_PINNED_JOCKEY|BUYFLAG_PINNED_CHARGER
#define BUYFLAG_PINNED_NO_HUNTER	BUYFLAG_PINNED_SMOKER|BUYFLAG_PINNED_JOCKEY|BUYFLAG_PINNED_CHARGER
#define BUYFLAG_PINNED_NO_JOCKEY	BUYFLAG_PINNED_SMOKER|BUYFLAG_PINNED_HUNTER|BUYFLAG_PINNED_CHARGER
#define BUYFLAG_PINNED_NO_CHARGER	BUYFLAG_PINNED_SMOKER|BUYFLAG_PINNED_HUNTER|BUYFLAG_PINNED_JOCKEY

#define BUYFLAG_HUMANTEAM			(1<<18) // Can this product be bought to non-bot teammates?
#define BUYFLAG_BOTTEAM				(1<<19) // Can this product be bought for your bot teammates?
#define BUYFLAG_TEAM			BUYFLAG_BOTTEAM|BUYFLAG_HUMANTEAM // Can this product be bought for your teammates?

/*
Clarification: If BUYFLAG_TEAM is present and BUYFLAG_HUMANTEAM is not present,
you can basically help your bots, buying them products without disturbing any players. 
*/

native bool PS_CreateProduct(int iCategory, int iCost, char[] sName, char[] sDescription, char[] sAliases, char[] sInfo, float fDelay, float fCooldown, int iBuyFlags);

// Uses my own algorithm to fully heal a survivor, fixing the bug where you get to 100 hp when incapped and pinned.
native void PS_FullHeal(int client);

// Called even if you cannot afford the product.
// sAliases contain the original alias list, to compare your own alias as an identifier.
// Return Plugin_Handled to block purchase.
forward Action PointSystemAPI_OnTryBuyProduct(int buyer, const char[] sInfo, const char[] sAliases, const char[] sName, int &target, int &iCost, float &fDelay, float &fCooldown);
	
// If a delay exists, called several seconds after PointSystemAPI_OnBuyProduct. Otherwise this is called instantly. 
// sAliases contain the original alias list, to compare your own alias as an identifier.
// Return Plugin_Handled to refund.
forward Action PointSystemAPI_OnBuyProductPost(int buyer, const char[] info, const char[] sAliases, const char[] sName, int target, int iCost, float fDelay, float fCooldown);
	
// This forward should be used to give the product to a target player. This is after the delay, and after not refunding the product. Called instantly after PointSystemAPI_OnBuyProductPost
// sAliases contain the original alias list, to compare your own alias as an identifier.

// Return Plugin_Handled to refund if you cannot give the product, which should be rare.
forward Action PointSystemAPI_OnShouldGiveProduct(int buyer, const char[] info, const char[] sAliases, const char[] sName, int target, int iCost, float fDelay, float fCooldown);