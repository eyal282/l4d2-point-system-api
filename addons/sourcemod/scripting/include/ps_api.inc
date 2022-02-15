#if defined _PS_API_included
 #endinput
#endif
#define _PS_API_included

#define BUYFLAG_ALIVE				(1<<0) // Can this product be bought while you're alive?
#define BUYFLAG_DEAD				(1<<1) // Can this product be bought while you're dead?

#define BUYFLAG_INFECTED			(1<<2) // Can this product be bought while you're an Infected?
#define BUYFLAG_SURVIVOR			(1<<3) // Can this product be bought while you're a Survivor?

// Below this line is only for products and not for categories.
#define BUYFLAG_PINNED				(1<<4) // Can this product be bought while you're pinned by any Special Infected?
#define BUYFLAG_TEAM				(1<<5) // Can this product be bought for your team in general?
#define BUYFLAG_HUMANTEAM				(1<<6) // If BUYFLAG_TEAM is present, can this product be bought to non-bot teammates?

/*
Clarification: If BUYFLAG_TEAM is present and BUYFLAG_HUMANTEAM is not present,
you can basically help your bots, buying them products without disturbing any players. 
*/

native bool PS_CreateProduct(int iCategory, int iCost, char[] sName, char[] sDescription, char[] sAliases, char[] sInfo, char[] sNoInfectedList, float fDelay, float fCooldown, int iBuyFlags);

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