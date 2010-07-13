#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>
#include <sdktools>
#include <tf2_stocks>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Filter, TF2, Class",
	author      = "Thrawn",
	description = "Display ads for players playing a certain class only",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

//Regular Expressions
new Handle:g_rClass = INVALID_HANDLE;


stock FindClassByName(const String:name[]) {
	new cnt = 0;
	new match = -1;

	if(	StrContains("engineer", name, false) || StrContains("engie", name, false) ) {
		match = _:TFClass_Engineer;
		cnt++;
	}

	if( StrContains("scout", name, false) ) {
		match = _:TFClass_Scout;
		cnt++;
	}

	if(cnt > 1) {
		return -2;
	}

	return match;
}

public OnPluginStart() {
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(!(StrEqual(game, "tf")))
	{
		SetFailState("This plugin is not for %s", game);
	}

	CreateConVar("sm_tads_f_tf_class_version", PL_VERSION, "Display ads for players playing a certain class only.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_rClass = CompileRegex("{class:'(.*)'}", PCRE_CASELESS|PCRE_UNGREEDY);
}

public Action:Ads_OnSendFilter(String:sFilter[], client) {
	new String:sFil[MSG_SIZE+1];
	strcopy(sFil, sizeof(sFil), sFilter);

	while(MatchRegex(g_rClass, sFil) > 0) {
		new String:full[MSG_SIZE+1];
		new String:buffer[MSG_SIZE+1];
		new String:sText[MSG_SIZE+1];

		new cnt = 0;
		while(GetRegexSubString(g_rClass, cnt, buffer, sizeof(buffer)+1)) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: sText = buffer;
				case 2: break;
			}

			cnt++;
		}

		new classID = FindClassByName(sText);

		if (classID < 0) {
			LogMessage("Unknown class in filter: %s", sText);
			ReplaceString(sFil, sizeof(sFil), full, "");
		} else {
			if(_:TF2_GetPlayerClass(client) == classID) {
				return Plugin_Continue;
			} else {
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}