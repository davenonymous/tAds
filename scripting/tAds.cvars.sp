#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>

#define PL_VERSION    "0.0.1"
#define CVAR_DISABLED "OFF"
#define CVAR_ENABLED  "ON"

public Plugin:myinfo = {
	name        = "tAds, Cvars",
	author      = "Thrawn",
	description = "Display CVars in ads",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

//Regular Expressions
new Handle:g_rCvar = INVALID_HANDLE;
new Handle:g_rBool = INVALID_HANDLE;

public OnPluginStart() {
	CreateConVar("sm_tads_cvars_version", PL_VERSION, "Display CVars in ads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_rCvar = CompileRegex("{cvar:(.*)}", PCRE_CASELESS|PCRE_UNGREEDY);
	g_rBool = CompileRegex("{bool:(.*)}", PCRE_CASELESS|PCRE_UNGREEDY);
}

public Action:Ads_OnSend(String:sText[], size) {
	while(MatchRegex(g_rCvar, sText) > 0) {

		new String:full[255];
		new String:buffer[255];
		new cnt = 0;
		while(GetRegexSubString(g_rCvar, cnt, buffer, sizeof(buffer))) {
			if(cnt==0) {
				full = buffer;
			} else {
				new Handle:hConVar = FindConVar(buffer);

				if (hConVar != INVALID_HANDLE) {
					GetConVarString(hConVar, buffer, sizeof(buffer));
					ReplaceString(sText, size, full, buffer);
				} else {
					ReplaceString(sText, size, full, "<ERROR: Cvar not registered>");
				}
			}

			cnt++;
		}
	}

	while(MatchRegex(g_rBool, sText) > 0) {
		new String:full[255];
		new String:buffer[255];
		new cnt = 0;
		while(GetRegexSubString(g_rBool, cnt, buffer, sizeof(buffer))) {
			if(cnt==0) {
				full = buffer;
			} else {
				new Handle:hConVar = FindConVar(buffer);

				if (hConVar != INVALID_HANDLE) {
					ReplaceString(sText, size, full, GetConVarBool(hConVar) ? CVAR_ENABLED : CVAR_DISABLED);
				} else {
					ReplaceString(sText, size, full, "<ERROR: Cvar not registered>");
				}
			}

			cnt++;
		}
	}

	return Plugin_Changed;
}