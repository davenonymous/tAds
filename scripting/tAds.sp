#pragma semicolon 1

#include <sourcemod>
#include <colors>

#define PL_VERSION    "0.0.1"

#define MAX_ADS 32
#define MSG_SIZE 255

public Plugin:myinfo = {
	name        = "tAds",
	author      = "Thrawn, Tsunami",
	description = "Display advertisements, with modular replacements",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};


enum ad_types {
	TYPE_CENTER,
	TYPE_HINT,
	TYPE_MENU,
	TYPE_SAY,
	TYPE_TOP
}

enum AD_INFO {
	id = 0,
	ad_types:type = TYPE_SAY,
	Handle:timer = INVALID_HANDLE,
	String:flagList[16],
	bool:admins,
	bool:flags,
	Float:interval,
	String:text[256],
}

new Handle:g_hCenterAd[MAXPLAYERS + 1];
new Handle:g_hCvarEnable;
new Handle:g_hCvarFile;
new Handle:g_hCvarInterval;

//Convars:
new String:g_sPath[PLATFORM_MAX_PATH];
new bool:g_bEnabled;
new Float:g_fDefaultInterval = 30.0;

//Ad Tracking
new g_hAds[MAX_ADS][AD_INFO];
new g_iCount = 0;

//Forward
new Handle:g_hForwardSendAd;

static g_iTColors[13][3]         = {{255, 255, 255}, {255, 0, 0},    {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {255, 128, 0}, {255, 0, 128}, {128, 255, 0}, {0, 255, 128}, {128, 0, 255}, {0, 128, 255}};
static String:g_sTColors[13][12] = {"{WHITE}",       "{RED}",        "{GREEN}",   "{BLUE}",    "{YELLOW}",    "{PURPLE}",    "{CYAN}",      "{ORANGE}",    "{PINK}",      "{OLIVE}",     "{LIME}",      "{VIOLET}",    "{LIGHTBLUE}"};

public OnPluginStart() {
	CreateConVar("sm_tads_version", PL_VERSION, "Display advertisements", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hCvarEnable        = CreateConVar("sm_tads_enabled",  "1",                  "Enable/disable displaying advertisements.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarFile           = CreateConVar("sm_tads_file",     "advertisements.txt", "File to read the advertisements from.");
	g_hCvarInterval       = CreateConVar("sm_tads_interval", "2.0",                 "Amount of seconds between advertisements.");

	RegServerCmd("sm_tads_reload", Command_ReloadAds, "Reload the advertisements");

	g_hForwardSendAd = CreateGlobalForward("Ads_OnSend", ET_Ignore, Param_String, Param_Cell);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnable);

	decl String:sFile[PLATFORM_MAX_PATH];
	GetConVarString(g_hCvarFile, sFile, PLATFORM_MAX_PATH);
	BuildPath(Path_SM, g_sPath, PLATFORM_MAX_PATH, "configs/%s", sFile);

	g_fDefaultInterval = GetConVarFloat(g_hCvarInterval);

	ParseAds();
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

public Action:Command_ReloadAds(args) {
	ParseAds();
}

public OnPluginEnd() {
	ClearTimers();
}

public ClearTimers() {
	for(new i=0; i < MAX_ADS; i++) {
		if(g_hAds[i][timer] != INVALID_HANDLE) {
			KillTimer(g_hAds[i][timer]);
			g_hAds[i][timer] = INVALID_HANDLE;
		}
	}
}

stock ValidateClient(client, adID) {
	decl String:sFlags[16];
	strcopy(sFlags, 16, g_hAds[adID][flagList]);
	if	( IsClientInGame(client) && !IsFakeClient(client) &&
		(( !g_hAds[adID][admins] && !(g_hAds[adID][flags] && HasFlag(client, sFlags))) ||
			g_hAds[adID][admins] && (GetUserFlagBits(client) & ADMFLAG_GENERIC ||
									 GetUserFlagBits(client) & ADMFLAG_ROOT))) {
									 	return true;
	}

	return false;
}

public DisplayAd(adID, const String:newText[MSG_SIZE]) {
	if (g_hAds[adID][type] == TYPE_CENTER) {
		for (new i = 1; i <= MaxClients; i++) {
			if(ValidateClient(i, adID)) {
				PrintCenterText(i, newText);

				new Handle:hCenterAd;
				g_hCenterAd[i] = CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				WritePackCell(hCenterAd,   i);
				WritePackString(hCenterAd, newText);
			}
		}
	}
	if (g_hAds[adID][type] == TYPE_HINT) {
		for (new i = 1; i <= MaxClients; i++) {
			if(ValidateClient(i, adID)) {
				PrintHintText(i, newText);
			}
		}
	}
	if (g_hAds[adID][type] == TYPE_MENU) {
		new Handle:hPl = CreatePanel();
		DrawPanelText(hPl, newText);
		SetPanelCurrentKey(hPl, 10);

		for (new i = 1; i <= MaxClients; i++) {
			if(ValidateClient(i, adID)) {
				SendPanelToClient(hPl, i, Handler_DoNothing, 10);
			}
		}

		CloseHandle(hPl);
	}
	if (g_hAds[adID][type] == TYPE_SAY) {
		new String:buffer[MSG_SIZE];
		strcopy(buffer, MSG_SIZE, newText);
		CFormat(buffer, sizeof(buffer));

		for (new i = 1; i <= MaxClients; i++) {
			if(ValidateClient(i, adID)) {
				PrintToChat(i, buffer);
			}
		}
	}
	if (g_hAds[adID][type] == TYPE_TOP) {
		decl String:sColor[16];
		new iColor = -1, iPos = BreakString(newText, sColor, sizeof(sColor));

		for (new i = 0; i < sizeof(g_sTColors); i++) {
			if (StrEqual(sColor, g_sTColors[i])) {
				iColor = i;
			}
		}

		if (iColor == -1) {
			iPos     = 0;
			iColor   = 0;
		}

		new Handle:hKv = CreateKeyValues("Stuff", "title", newText[iPos]);
		KvSetColor(hKv, "color", g_iTColors[iColor][0], g_iTColors[iColor][1], g_iTColors[iColor][2], 255);
		KvSetNum(hKv,   "level", 1);
		KvSetNum(hKv,   "time",  10);

		for (new i = 1; i <= MaxClients; i++) {
			if(ValidateClient(i, adID)) {
				CreateDialog(i, hKv, DialogType_Msg);
			}
		}

		CloseHandle(hKv);
	}
}

public Action:Timer_CenterAd(Handle:htimer, Handle:pack) {
	decl String:sText[256];
	static iCount          = 0;

	ResetPack(pack);
	new iClient            = ReadPackCell(pack);
	ReadPackString(pack, sText, sizeof(sText));

	if (IsClientInGame(iClient) && ++iCount < 5) {
		PrintCenterText(iClient, sText);

		return Plugin_Continue;
	} else {
		iCount               = 0;
		g_hCenterAd[iClient] = INVALID_HANDLE;

		return Plugin_Stop;
	}
}

ParseAds() {
	if (g_bEnabled) {
		if (FileExists(g_sPath)) {
			ClearTimers();

			new Handle:hKVAdvertisements = CreateKeyValues("Advertisements");

			FileToKeyValues(hKVAdvertisements, g_sPath);

			if (!KvGotoFirstSubKey(hKVAdvertisements))
				return;

			g_iCount = 0;
			do {
				//if (KvGotoFirstSubKey(hKVAdvertisements)) {
					KvReadAdvertisementBlock(hKVAdvertisements);
					//KvGoBack(hKVAdvertisements);
				//}
			} while (KvGotoNextKey(hKVAdvertisements));

			LogMessage("Found %i ads.", g_iCount);

			CloseHandle(hKVAdvertisements);
		} else {
			LogMessage("File %s does not exist", g_sPath);
		}
	}
}

KvReadAdvertisementBlock(Handle:hKVAdvertisements) {
	new String:sText[MSG_SIZE], String:sFlags[16], String:sType[6];

	KvGetString(hKVAdvertisements, "type",  sType,  sizeof(sType));
	KvGetString(hKVAdvertisements, "text",  sText,  sizeof(sText));
	KvGetString(hKVAdvertisements, "flags", sFlags, sizeof(sFlags), "none");
	new Float:fInterval = KvGetFloat(hKVAdvertisements, "interval", g_fDefaultInterval);


	//Pack in one piece, create timer
	g_hAds[g_iCount][id] = g_iCount;
	g_hAds[g_iCount][interval] = fInterval;
	g_hAds[g_iCount][type] = ParseType(sType);
	strcopy(g_hAds[g_iCount][flagList], 16, sFlags);
	g_hAds[g_iCount][admins] = StrEqual(sFlags, "");
	g_hAds[g_iCount][flags] = !StrEqual(sFlags, "none");
	strcopy(g_hAds[g_iCount][text], MSG_SIZE, sText);
	g_hAds[g_iCount][timer] = CreateTimer(fInterval, Timer_ShowAd, g_iCount, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	g_iCount++;
}

public Action:Timer_ShowAd(Handle:htimer, any:data_id) {
	new String:sText[MSG_SIZE];
	strcopy(sText, MSG_SIZE, g_hAds[data_id][text]);

	Call_StartForward(g_hForwardSendAd);
	Call_PushStringEx(sText,MSG_SIZE,SM_PARAM_STRING_COPY,SM_PARAM_COPYBACK);
	Call_PushCell(MSG_SIZE);
	Call_Finish();

	DisplayAd(data_id, sText);
	//LogMessage("AD! %s", sText);
}

stock ad_types:ParseType(const String:sText[]) {
	if(StrEqual(sText, "C"))
		return TYPE_CENTER;

	if(StrEqual(sText, "H"))
		return TYPE_HINT;

	if(StrEqual(sText, "M"))
		return TYPE_MENU;

	if(StrEqual(sText, "S"))
		return TYPE_SAY;

	if(StrEqual(sText, "T"))
		return TYPE_TOP;

	//Default: Center
	return TYPE_CENTER;
}

bool:HasFlag(iClient, String:sFlags[16]) {
	decl AdminFlag:fFlagList[16];

	if (!StrEqual(sFlags, "none")) {
		FlagBitsToArray(ReadFlagString(sFlags), fFlagList, sizeof(fFlagList));

		new iFlags = GetUserFlagBits(iClient);
		if (iFlags & ADMFLAG_ROOT) {
			return true;
		} else {
			for (new i = 0; i < sizeof(fFlagList); i++) {
				if (iFlags & FlagToBit(fFlagList[i])) {
					return true;
				}
			}
		}
	}

	return false;
}