#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Condition, Modificators",
	author      = "Thrawn",
	description = "Display ads for certain games only",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

//Regular Expressions
new Handle:g_rModificator = INVALID_HANDLE;

new Handle:g_hForwardSendAd;
new Handle:g_hForwardSendAdPost;


public OnPluginStart() {
	CreateConVar("sm_tads_c_mod_version", PL_VERSION, "Only show ads if a certain modificator returns a value not zero or empty.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_rModificator = CompileRegex("{mod:<(.*)>}", PCRE_CASELESS|PCRE_UNGREEDY);
	g_hForwardSendAd = CreateGlobalForward("Ads_OnSend", ET_Ignore, Param_String, Param_Cell);
	g_hForwardSendAdPost = CreateGlobalForward("Ads_OnSendPost", ET_Ignore, Param_String, Param_Cell);
}

public Action:Ads_OnSendCondition(String:sCondition[]) {
	new String:sCond[MSG_SIZE+1];
	strcopy(sCond, sizeof(sCond), sCondition);

	while(MatchRegex(g_rModificator, sCond) > 0) {
		new String:full[MSG_SIZE+1];
		new String:buffer[MSG_SIZE+1];
		new String:sText[MSG_SIZE+1];

		new cnt = 0;
		while(GetRegexSubString(g_rModificator, cnt, buffer, sizeof(buffer)+1)) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: sText = buffer;
				case 2: break;
			}

			cnt++;
		}


		Call_StartForward(g_hForwardSendAd);
		Call_PushStringEx(sText,MSG_SIZE,SM_PARAM_STRING_COPY,SM_PARAM_COPYBACK);
		Call_PushCell(MSG_SIZE);
		Call_Finish();

		Call_StartForward(g_hForwardSendAdPost);
		Call_PushStringEx(sText,MSG_SIZE,SM_PARAM_STRING_COPY,SM_PARAM_COPYBACK);
		Call_PushCell(MSG_SIZE);
		Call_Finish();

		if(StrEqual(sText,"") || StrEqual(sText,"0")) {
			return Plugin_Handled;
		} else {
			ReplaceString(sCond, sizeof(sCond), full, "");
		}
	}

	return Plugin_Continue;
}