#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>
#include <sdktools>

#define PL_VERSION    "0.0.1"

#define TEAM_UNSIG 0
#define TEAM_SPEC 1
#define TEAM_RED 2
#define TEAM_BLUE 3

public Plugin:myinfo = {
	name        = "tAds, Filter, Dead or alive",
	author      = "Thrawn",
	description = "Display ads for players in a certain team only",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

public OnPluginStart() {
	CreateConVar("sm_tads_f_doa_version", PL_VERSION, "Display ads for dead or alive players only.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:Ads_OnSendFilter(String:sFilter[], client) {
	new bool:bIsAlive = IsPlayerAlive(client);

	if(GetClientTeam(client) < TEAM_RED)
		bIsAlive = false;

	if (StrContains(sFilter, "{dead}", false) != -1 && bIsAlive)
			return Plugin_Handled;

	if (StrContains(sFilter, "{alive}", false) != -1 && !bIsAlive)
			return Plugin_Handled;

	return Plugin_Continue;
}