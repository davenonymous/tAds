#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>

#define PL_VERSION    "0.0.1"
#define CVAR_DISABLED "OFF"
#define CVAR_ENABLED  "ON"

public Plugin:myinfo = {
	name        = "tAds, Time left till date",
	author      = "Thrawn",
	description = "Display time left until a certain date in ads",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

//Regular Expressions
new Handle:g_rTimeLeft = INVALID_HANDLE;

public OnPluginStart() {
	CreateConVar("sm_tads_time_version", PL_VERSION, "Display time left till date in ads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_rTimeLeft = CompileRegex("{timetill:([0-9]*)}", PCRE_CASELESS|PCRE_UNGREEDY);
}

public Action:Ads_OnSend(String:sText[], size) {
	while(MatchRegex(g_rTimeLeft, sText) > 0) {

		new String:full[255];
		new String:buffer[255];
		new cnt = 0;
		new bool:neg = false;
		while(GetRegexSubString(g_rTimeLeft, cnt, buffer, sizeof(buffer))) {
			if(cnt==0) {
				full = buffer;
			} else {
				new diff = StringToInt(buffer) - GetTime();
				if(diff < 0) {
					diff *= -1;
					neg = true;
				}
				new sec = diff % 60;
				new min = RoundToFloor(diff / 60.0) % 60;
				new hrs = RoundToFloor(diff / (60.0 * 60)) % 24;
				new days = RoundToFloor(diff / (60.0 * 60 * 24)) % 365;
				new yrs = RoundToFloor(diff / (60.0 * 60 * 24 * 365));

				//LogMessage("%i seconds are: %iy %id %ih %im %is", diff, yrs, days, hrs, min, sec);

				Format(buffer, sizeof(buffer), "");
				if(yrs > 0)
					Format(buffer, sizeof(buffer), "%iy", yrs);

				if(days > 0 || yrs > 0)
					Format(buffer, sizeof(buffer), "%s %id", buffer, days);

				if(hrs > 0 || yrs > 0 || days > 0)
					Format(buffer, sizeof(buffer), "%s %ih", buffer, hrs);

				if(min > 0 || hrs > 0 || yrs > 0 || days > 0)
					Format(buffer, sizeof(buffer), "%s %im", buffer, min);

				if(sec > 0 || min > 0 || hrs > 0 || yrs > 0 || days > 0)
					Format(buffer, sizeof(buffer), "%s %is", buffer, sec);

				if(neg)
					Format(buffer, sizeof(buffer), "%s (after)", buffer);

				ReplaceString(sText, size, full, buffer);
			}

			cnt++;
		}
	}

	return Plugin_Changed;
}