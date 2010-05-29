#pragma semicolon 1

#include <sourcemod>
#include <tads>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Modificator, Admins",
	author      = "Thrawn",
	description = "Display Admins in ads",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

new Handle:g_hCvarFlags = INVALID_HANDLE;
new String:g_sFlags[16];

public OnPluginStart() {
	CreateConVar("sm_tads_admin_version", PL_VERSION, "Display admins in ads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hCvarFlags = CreateConVar("sm_tads_admin_flags", "a", "Show players with these flags as admin", FCVAR_PLUGIN);

	HookConVarChange(g_hCvarFlags, Cvar_Changed);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnConfigsExecuted() {
	GetConVarString(g_hCvarFlags, g_sFlags, sizeof(g_sFlags));
}

public Action:Ads_OnSend(String:sText[], size) {
	if (StrContains(sText, "{admins}") != -1) {
		new String:sBuffer[255];

		for(new i = 1; i < MaxClients; i++) {
			if(IsClientConnected(i) && IsClientInGame(i) && HasFlag(i, g_sFlags)) {
				Format(sBuffer, sizeof(sBuffer), "%s%N, ", sBuffer, i);
			}
		}

		new String:result[strlen(sBuffer)];
		strcopy(result, strlen(sBuffer)-1, sBuffer);

		ReplaceString(sText, size, "{admins}", result);
	}

	return Plugin_Changed;
}