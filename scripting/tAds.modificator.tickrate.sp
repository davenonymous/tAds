#pragma semicolon 1

#include <sourcemod>
#include <tads>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Tickrate",
	author      = "Thrawn, Tsunami",
	description = "Display Tickrate in ads",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

new g_iFrames                 = 0;
new g_iTickrate;
new bool:g_bTickrate          = true;
new Float:g_fTime;


public OnPluginStart() {
	CreateConVar("sm_tads_tickrate_version", PL_VERSION, "Display Tickrate in ads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnGameFrame() {
	if (g_bTickrate) {
		g_iFrames++;

		new Float:fTime = GetEngineTime();
		if (fTime >= g_fTime) {
			if (g_iFrames == g_iTickrate) {
				g_bTickrate = false;
			} else {
				g_iTickrate = g_iFrames;
				g_iFrames   = 0;
				g_fTime     = fTime + 1.0;
			}
		}
	}
}

public Action:Ads_OnSend(String:sText[], size) {
	if (StrContains(sText, "{TICKRATE}")   != -1) {
		new String:sBuffer[255];
		IntToString(g_iTickrate, sBuffer, sizeof(sBuffer));
		ReplaceString(sText, size, "{TICKRATE}",   sBuffer);
	}

	return Plugin_Changed;
}