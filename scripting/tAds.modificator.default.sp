#pragma semicolon 1

#include <sourcemod>
#include <tads>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Modificator, Standard",
	author      = "Thrawn, Tsunami",
	description = "Display some standard infos in ads",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

public OnPluginStart() {
	CreateConVar("sm_tads_standard_version", PL_VERSION, "Display standard infos in ads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:Ads_OnSend(String:sText[], size) {
	decl String:sBuffer[256];

	if (StrContains(sText, "{DATE}")       != -1) {
		FormatTime(sBuffer, sizeof(sBuffer), "%m/%d/%Y");
		ReplaceString(sText, size, "{DATE}", sBuffer, false);
	}

	if (StrContains(sText, "{CURRENTMAP}") != -1) {
		GetCurrentMap(sBuffer, sizeof(sBuffer));
		ReplaceString(sText, size, "{CURRENTMAP}", sBuffer);
	}

	if (StrContains(sText, "{TIME}")       != -1) {
		FormatTime(sBuffer, sizeof(sBuffer), "%I:%M:%S%p");
		ReplaceString(sText, size, "{TIME}",       sBuffer);
	}

	if (StrContains(sText, "{TIME24}")     != -1) {
		FormatTime(sBuffer, sizeof(sBuffer), "%H:%M:%S");
		ReplaceString(sText, size, "{TIME24}",     sBuffer);
	}

	if (StrContains(sText, "{TIMELEFT}")   != -1) {
		new iMins, iSecs, iTimeLeft;

		if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0) {
			iMins = iTimeLeft / 60;
			iSecs = iTimeLeft % 60;
		}

		Format(sBuffer, sizeof(sBuffer), "%d:%02d", iMins, iSecs);
		ReplaceString(sText, size, "{TIMELEFT}",   sBuffer);
	}

	if (StrContains(sText, "\\n")          != -1) {
		Format(sBuffer, sizeof(sBuffer), "%c", 13);
		ReplaceString(sText, size, "\\n",          sBuffer);
	}

	return Plugin_Changed;
}