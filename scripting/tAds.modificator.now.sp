#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>

#define PL_VERSION    "0.0.1"
#define CVAR_DISABLED "OFF"
#define CVAR_ENABLED  "ON"

public Plugin:myinfo = {
	name        = "tAds, Modificator, Now",
	author      = "Thrawn",
	description = "Display current time in ads",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

//Regular Expressions
new Handle:g_rNowFormat = INVALID_HANDLE;
new Handle:g_rThenFormat = INVALID_HANDLE;

public OnPluginStart() {
	CreateConVar("sm_tads_time_version", PL_VERSION, "Display time left till date in ads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_rNowFormat = CompileRegex("{now:'(.*)'}", PCRE_CASELESS|PCRE_UNGREEDY);
	g_rThenFormat = CompileRegex("{then:'(.*)':([0-9]+)}", PCRE_CASELESS|PCRE_UNGREEDY);
}

public Action:Ads_OnSend(String:sText[], size) {
	while(MatchRegex(g_rNowFormat, sText) > 0) {
		new String:full[255];
		new String:buffer[255];
		new String:timeformat[255];

		new cnt = 0;
		while(GetRegexSubString(g_rNowFormat, cnt, buffer, sizeof(buffer))) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: timeformat = buffer;
				case 2: break;
			}

			cnt++;
		}

		FormatTime(buffer, sizeof(buffer), timeformat);

		ReplaceString(sText, size, full, buffer);
	}

	while(MatchRegex(g_rThenFormat, sText) > 0) {
		new String:full[255];
		new String:buffer[255];
		new String:timeformat[255];
		new InputTime;

		new cnt = 0;
		while(GetRegexSubString(g_rThenFormat, cnt, buffer, sizeof(buffer))) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: timeformat = buffer;
				case 2: InputTime = StringToInt(buffer);
				case 3: break;
			}

			cnt++;
		}

		FormatTime(buffer, sizeof(buffer), timeformat, InputTime);

		ReplaceString(sText, size, full, buffer);
	}

	return Plugin_Changed;
}