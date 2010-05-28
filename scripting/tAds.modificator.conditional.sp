#pragma semicolon 1

#include <sourcemod>
#include <tads>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Conditional Modificators",
	author      = "Thrawn",
	description = "Replaces based on conditions",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

//Regular Expressions
new Handle:g_rCond = INVALID_HANDLE;

public OnPluginStart() {
	CreateConVar("sm_tads_conditional_version", PL_VERSION, "Display conditional infos in ads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	decl String:pattern[255];
	pattern = "{if:(string|str|s|num|n):'(.+)'(==|!=|<|>|<=|>=)'(.+)'?'(.*)':'(.*)'}";
	//Example: Next Map will be: {if:s:'{cvar:sm_nextmap}'=='cp_dustbowl'?'Good old dustbowl':'{cvar:sm_nextmap}'};
	g_rCond = CompileRegex(pattern, PCRE_CASELESS|PCRE_UNGREEDY);
}

public Action:Ads_OnSendPost(String:sText[], size) {
	decl String:sBuffer[256];
	
	while(MatchRegex(g_rCond, sText) > 0) {
                new String:full[255];
		new String:type[8];
		new String:condA[255], String:condB[255];
		new String:operator[4];
		new String:ifTrue[255], String:ifFalse[255];
                new String:buffer[255];
                new cnt = 0;
                while(GetRegexSubString(g_rCvar, cnt, buffer, sizeof(buffer))) {
			switch(cnt) {
				case 0: {
					full = buffer;
				}
				case 1: {
					type = buffer;
				}
				case 2: {
					condA = buffer;
				}
				case 3: {
					condB = buffer;
				}
				case 4: {
					operator = buffer;
				}
				case 5: {
					ifTrue = buffer;
				}
				case 6: {
					ifFalse = buffer;
				}
			}

                        cnt++;
                }

		if(StrEqual(type,"string") || StrEqual(type,"str") || StrEqual(type,"s")) {
			if(StrEqual(operator,"==")) {
				if(StrEqual(condA,condB)) {
					ReplaceString(sText, size, full, ifTrue);
				} else {
					ReplaceString(sText, size, full, ifFalse);
				}
			} else if(StrEqual(operator,"!=")) {
				if(!StrEqual(condA,condB)) {
					ReplaceString(sText, size, full, ifTrue);
				} else {
					ReplaceString(sText, size, full, ifFalse);
				}
			} else {
				//Operator not supported for string
			}
		}
		
		if(StrEqual(type,"int") || StrEqual(type,"i")) {
			new iCondA, iCondB;
			iCondA = StringToInt(condA);
			iCondB = StringToInt(condB);

			if(StrEqual(operator,"==")) {
				if(iCondA == iCondB) {
					ReplaceString(sText, size, full, ifTrue);
				} else {
					ReplaceString(sText, size, full, ifFalse);
				}
			}
		}
		

	}
	

	return Plugin_Changed;
}
