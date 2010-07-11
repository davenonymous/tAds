#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>
#include <sdktools>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Filter, Team",
	author      = "Thrawn",
	description = "Display ads for players in a certain team only",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

//Regular Expressions
new Handle:g_rTeam = INVALID_HANDLE;


public OnPluginStart() {
	CreateConVar("sm_tads_f_team_version", PL_VERSION, "Display ads for players in a certain team only.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_rTeam = CompileRegex("{team:'(.*)'}", PCRE_CASELESS|PCRE_UNGREEDY);
}

public Action:Ads_OnSendFilter(String:sFilter[], client) {
	new String:sFil[MSG_SIZE+1];
	strcopy(sFil, sizeof(sFil), sFilter);

	while(MatchRegex(g_rTeam, sFil) > 0) {
		new String:full[MSG_SIZE+1];
		new String:buffer[MSG_SIZE+1];
		new String:sText[MSG_SIZE+1];

		new cnt = 0;
		while(GetRegexSubString(g_rTeam, cnt, buffer, sizeof(buffer)+1)) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: sText = buffer;
				case 2: break;
			}

			cnt++;
		}


		new teamID = FindTeamByName(sText);

		if (teamID < 0) {
			LogMessage("Unknown team in filter: %s", sText);
			ReplaceString(sFil, sizeof(sFil), full, "");
		} else {
			if(GetClientTeam(client) == teamID) {
				return Plugin_Continue;
			} else {
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}