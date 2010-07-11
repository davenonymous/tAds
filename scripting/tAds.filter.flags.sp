#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>
#include <sdktools>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Filter, AccessFlags",
	author      = "Thrawn",
	description = "Display ads for players with a certain flag only",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

//Regular Expressions
new Handle:g_rTeam = INVALID_HANDLE;


public OnPluginStart() {
	CreateConVar("sm_tads_f_flags_version", PL_VERSION, "Display ads for players with a certain flag only.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_rTeam = CompileRegex("{flags:'(.*)'}", PCRE_CASELESS|PCRE_UNGREEDY);
}

public Action:Ads_OnSendFilter(String:sFilter[], client) {
	new String:sFil[MSG_SIZE+1];
	strcopy(sFil, sizeof(sFil), sFilter);

	if (StrContains(sFilter, "{noadmin}", false) != -1 && GetUserFlagBits(client) != 0)
			return Plugin_Handled;

	while(MatchRegex(g_rTeam, sFil) > 0) {
		new String:full[MSG_SIZE+1];
		new String:buffer[MSG_SIZE+1];
		new String:sText[16];

		new cnt = 0;
		while(GetRegexSubString(g_rTeam, cnt, buffer, sizeof(buffer)+1)) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: strcopy(sText,16,buffer);
				case 2: break;
			}

			cnt++;
		}


		if(HasFlag(client, sText)) {
			return Plugin_Continue;
		} else {
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}