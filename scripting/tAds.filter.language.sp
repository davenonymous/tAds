#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>
#include <sdktools>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Filter, Language",
	author      = "Thrawn",
	description = "Display ads for players with a certain language only",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

//Regular Expressions
new Handle:g_rLanguage = INVALID_HANDLE;


public OnPluginStart() {
	CreateConVar("sm_tads_f_language_version", PL_VERSION, "Display ads for players with a certain language only.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_rLanguage = CompileRegex("{language:'(.*)'}", PCRE_CASELESS|PCRE_UNGREEDY);
}

public Action:Ads_OnSendFilter(String:sFilter[], client) {
	new String:sFil[MSG_SIZE+1];
	strcopy(sFil, sizeof(sFil), sFilter);

	while(MatchRegex(g_rLanguage, sFil) > 0) {
		new String:full[MSG_SIZE+1];
		new String:buffer[MSG_SIZE+1];
		new String:sText[MSG_SIZE+1];

		new cnt = 0;
		while(GetRegexSubString(g_rLanguage, cnt, buffer, sizeof(buffer)+1)) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: sText = buffer;
				case 2: break;
			}

			cnt++;
		}

		new String:sCode[4];
		GetLanguageInfo(GetClientLanguage(client), sCode, sizeof(sCode));

		if(StrEqual(sText, sCode)) {
			return Plugin_Continue;
		} else {
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}