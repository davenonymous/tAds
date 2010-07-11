#pragma semicolon 1

#include <sourcemod>
#include <colors>
#include <tads>

#define PL_VERSION    "0.0.1"

#define MAX_ADS 16

public Plugin:myinfo = {
	name        = "tAds",
	author      = "Thrawn, Tsunami",
	description = "Display advertisements, with modular replacements",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

enum AD_INFO {
	id = 0,
	Float:interval,
	plugin,
	Handle:timer = INVALID_HANDLE,
	String:flagList[16],
	String:type[8],
	String:text[MSG_SIZE],
	String:trigger[MSG_SIZE],
	String:condition[MSG_SIZE],
	String:filter[MSG_SIZE]
}

new Handle:g_hCenterAd[MAXPLAYERS + 1];
new Handle:g_hCvarEnable;
new Handle:g_hCvarInterval;

//Convars:
new bool:g_bEnabled;
new Float:g_fDefaultInterval = 30.0;
new bool:g_bHaveTrigger = false;

//Ad Tracking
new g_hAds[MAX_ADS][AD_INFO];
new g_iCount = 0;

//Forward
new Handle:g_hForwardSendAd;
new Handle:g_hForwardSendAdPost;
new Handle:g_hForwardSendAdCondition;
new Handle:g_hForwardSendAdFilter;

static g_iTColors[13][3]         = {{255, 255, 255}, {255, 0, 0},    {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {255, 128, 0}, {255, 0, 128}, {128, 255, 0}, {0, 255, 128}, {128, 0, 255}, {0, 128, 255}};
static String:g_sTColors[13][12] = {"{WHITE}",       "{RED}",        "{GREEN}",   "{BLUE}",    "{YELLOW}",    "{PURPLE}",    "{CYAN}",      "{ORANGE}",    "{PINK}",      "{OLIVE}",     "{LIME}",      "{VIOLET}",    "{LIGHTBLUE}"};

public OnPluginStart() {
	CreateConVar("sm_tads_version", PL_VERSION, "Display advertisements", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hCvarEnable        = CreateConVar("sm_tads_enabled",  "1",                  "Enable/disable displaying advertisements.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarInterval       = CreateConVar("sm_tads_interval", "30.0",                 "Amount of seconds between advertisements.");

	g_hForwardSendAd = CreateGlobalForward("Ads_OnSend", ET_Ignore, Param_String, Param_Cell);
	g_hForwardSendAdPost = CreateGlobalForward("Ads_OnSendPost", ET_Ignore, Param_String, Param_Cell);
	g_hForwardSendAdCondition = CreateGlobalForward("Ads_OnSendCondition", ET_Hook, Param_String);
	g_hForwardSendAdFilter = CreateGlobalForward("Ads_OnSendFilter", ET_Hook, Param_String, Param_Cell);

	RegConsoleCmd("say", Event_Triggers);
	RegConsoleCmd("say_team", Event_Triggers);
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
	public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	RegPluginLibrary("tads");

	CreateNative("Ads_GetAdCount", Native_GetAdCount);
	CreateNative("Ads_GetAdText", Native_GetAdText);
	CreateNative("Ads_RegisterAd", Native_RegisterAd);
	CreateNative("Ads_UnRegisterAds", Native_UnRegisterAds);

	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
		return APLRes_Success;
	#else
		return true;
	#endif
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnable);

	g_fDefaultInterval = GetConVarFloat(g_hCvarInterval);
}

public Action:Event_Triggers(iClient, iArgs)
{
	if(g_bHaveTrigger) {
		if (iClient < 1 || iClient > MaxClients) return Plugin_Continue;
		if (iArgs < 1) return Plugin_Continue;

		// Retrieve the first argument and check it's a valid trigger
		decl String:strArgument[64]; GetCmdArg(1, strArgument, sizeof(strArgument));

		for(new i = 0; i < MAX_ADS; i++) {
			if(StrEqual(g_hAds[i][trigger],strArgument,false)) {
				new Handle:pack;
				LogMessage("Triggered ad: %i (for client: %N)", i, iClient);
				CreateDataTimer(0.0, Timer_ShowSpawnAd, pack, TIMER_FLAG_NO_MAPCHANGE);

				WritePackCell(pack, iClient);
				WritePackCell(pack, i);

				return Plugin_Handled;
			}
		}
	}
	// If no valid argument found, pass
	return Plugin_Continue;
}

public Native_GetAdCount(Handle:hPlugin, iNumParams) {
	return g_iCount;
}

public Native_GetAdText(Handle:hPlugin, iNumParams)
{
	new iAdId = GetNativeCell(1);
	new iAdSize = GetNativeCell(2);

	//LogMessage("looking for attribute: %i", iAttributeId);

	if(g_hAds[iAdId][id] != 0) {
		SetNativeString(2, g_hAds[iAdId][text], iAdSize, false);
		return true;
	}

	return false;
}

//native Ads_RegisterAd(Float:interval, String:types[], const String:flags[], const String:text[]);
public Native_RegisterAd(Handle:hPlugin, iNumParams)
{
	new Float:fInterval = GetNativeCell(1);

	if(fInterval == 0.0) {
		fInterval = g_fDefaultInterval;
	}

	new String:sTypes[8];
	GetNativeString(2, sTypes, sizeof(sTypes)+1);

	new String:sFlags[16];
	GetNativeString(3, sFlags, sizeof(sFlags)+1);

	new String:sText[MSG_SIZE];
	GetNativeString(4, sText, sizeof(sText)+1);

	new String:sTrigger[MSG_SIZE];
	GetNativeString(5, sTrigger, sizeof(sTrigger)+1);

	new String:sCondition[MSG_SIZE];
	GetNativeString(6, sCondition, sizeof(sCondition)+1);

	new String:sFilter[MSG_SIZE];
	GetNativeString(7, sFilter, sizeof(sFilter)+1);


	//Pack in one piece, create timer
	g_hAds[g_iCount][id] = g_iCount;
	g_hAds[g_iCount][interval] = fInterval;
	g_hAds[g_iCount][plugin] = _:hPlugin;
	strcopy(g_hAds[g_iCount][type], 8, sTypes);
	strcopy(g_hAds[g_iCount][flagList], 16, sFlags);
	strcopy(g_hAds[g_iCount][text], MSG_SIZE, sText);
	strcopy(g_hAds[g_iCount][trigger], MSG_SIZE, sTrigger);
	strcopy(g_hAds[g_iCount][condition], MSG_SIZE, sCondition);
	strcopy(g_hAds[g_iCount][filter], MSG_SIZE, sFilter);


	LogMessage("Registered ad: %s", sText);

	if(fInterval > 0) {
		g_hAds[g_iCount][timer] = CreateTimer(fInterval, Timer_ShowAd, g_iCount, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	if(!StrEqual(sTrigger,""))
		g_bHaveTrigger = true;

	g_iCount++;
}

public Native_UnRegisterAds(Handle:hPlugin, iNumParams)
{
	for(new i = 0; i < MAX_ADS; i++) {
		if(g_hAds[i][plugin] == _:hPlugin) {
			g_hAds[i][id] = 0;
			g_hAds[i][interval] = 0.0;
			g_hAds[i][plugin] = 0;
			g_hAds[i][timer] = INVALID_HANDLE;
			strcopy(g_hAds[i][type], 8, "");
			strcopy(g_hAds[i][text], MSG_SIZE, "");
			strcopy(g_hAds[i][trigger], MSG_SIZE, "");
			strcopy(g_hAds[i][condition], MSG_SIZE, "");
			strcopy(g_hAds[i][filter], MSG_SIZE, "");
			strcopy(g_hAds[i][flagList], 16, "");
		}
	}
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
	if(!IsClientInGame(client) || IsFakeClient(client))
		return false;

	decl String:sFlags[16];
	strcopy(sFlags, 16, g_hAds[adID][flagList]);

	Call_StartForward(g_hForwardSendAdFilter);
	Call_PushString(g_hAds[adID][filter]);
	Call_PushCell(client);

	new result;
	Call_Finish(result);

	new bAllowed = result == 0 ? true : false;

	if	( bAllowed &&
		(( !StrEqual(sFlags, "") && !(!StrEqual(sFlags, "none", false) && HasFlag(client, sFlags))) ||
			StrEqual(sFlags, "") && (GetUserFlagBits(client) & ADMFLAG_GENERIC ||
									 GetUserFlagBits(client) & ADMFLAG_ROOT))) {
									 	return true;
	}

	return false;
}

stock DisplayAd(adID, const String:newText[MSG_SIZE], client = 0) {
	if(strlen(newText)>0) {
		if (HasType(g_hAds[adID][type], TYPE_CENTER)) {
			for (new i = (client == 0 ? 1 : client); i <= (client == 0 ? MaxClients : client); i++) {
				if(ValidateClient(i, adID)) {
					PrintCenterText(i, newText);

					new Handle:hCenterAd;
					g_hCenterAd[i] = CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					WritePackCell(hCenterAd,   i);
					WritePackString(hCenterAd, newText);
				}
			}
		}
		if (HasType(g_hAds[adID][type], TYPE_HINT)) {
			for (new i = (client == 0 ? 1 : client); i <= (client == 0 ? MaxClients : client); i++) {
				if(ValidateClient(i, adID)) {
					PrintHintText(i, newText);
				}
			}
		}
		if (HasType(g_hAds[adID][type], TYPE_DEBUG)) {
			LogMessage("%s", newText);
		}
		if (HasType(g_hAds[adID][type], TYPE_MENU)) {
			new Handle:hPl = CreatePanel();
			DrawPanelText(hPl, newText);
			SetPanelCurrentKey(hPl, 10);

			for (new i = (client == 0 ? 1 : client); i <= (client == 0 ? MaxClients : client); i++) {
				if(ValidateClient(i, adID)) {
					SendPanelToClient(hPl, i, Handler_DoNothing, 10);
				}
			}

			CloseHandle(hPl);
		}
		if (HasType(g_hAds[adID][type], TYPE_SAY)) {
			new String:buffer[MSG_SIZE];
			strcopy(buffer, MSG_SIZE, newText);
			//CFormat(buffer, sizeof(buffer));

			for (new i = (client == 0 ? 1 : client); i <= (client == 0 ? MaxClients : client); i++) {
				if(ValidateClient(i, adID)) {
					CPrintToChat(i, buffer);
				}
			}
		}
		if (HasType(g_hAds[adID][type], TYPE_TOP)) {
			decl String:sColor[16];
			new iColor = -1, iPos = BreakString(newText, sColor, sizeof(sColor));

			for (new i = 0; i < sizeof(g_sTColors); i++) {
				if (StrEqual(sColor, g_sTColors[i], false)) {
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

			for (new i = (client == 0 ? 1 : client); i <= (client == 0 ? MaxClients : client); i++) {
				if(ValidateClient(i, adID)) {
					CreateDialog(i, hKv, DialogType_Msg);
				}
			}

			CloseHandle(hKv);
		}
	}
}
public OnClientPutInServer(client) {
	if(g_bEnabled) {
		for(new i = 0; i < MAX_ADS; i++) {
			if(g_hAds[i][interval] < 0.0) {
				new Handle:pack;
				CreateDataTimer(g_hAds[i][interval] * -1, Timer_ShowSpawnAd, pack, TIMER_FLAG_NO_MAPCHANGE);

				LogMessage("Showing %i to %N", i, client);
				WritePackCell(pack, client);
				WritePackCell(pack, i);
			}
		}
	}
}

public Action:Timer_ShowSpawnAd(Handle:spawn_timer, Handle:pack)
{
	if(g_bEnabled) {
		new client, data_id;

		ResetPack(pack);
		client = ReadPackCell(pack);
		data_id = ReadPackCell(pack);

		if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client)) {
			new String:sText[MSG_SIZE];
			strcopy(sText, MSG_SIZE, g_hAds[data_id][text]);
			LogMessage("triggered input: %s", sText);
			Call_StartForward(g_hForwardSendAdCondition);
			Call_PushString(g_hAds[data_id][condition]);
			new result;
			Call_Finish(result);

			LogMessage("Condition error level: %i", result);
			if(result > 0)
				return;

			Call_StartForward(g_hForwardSendAd);
			Call_PushStringEx(sText,MSG_SIZE,SM_PARAM_STRING_COPY,SM_PARAM_COPYBACK);
			Call_PushCell(MSG_SIZE);
			Call_Finish();

			Call_StartForward(g_hForwardSendAdPost);
			Call_PushStringEx(sText,MSG_SIZE,SM_PARAM_STRING_COPY,SM_PARAM_COPYBACK);
			Call_PushCell(MSG_SIZE);
			Call_Finish();

			if(!StrEqual(sText,""))
				DisplayAd(data_id, sText, client);
		}
	}
}

public Action:Timer_CenterAd(Handle:htimer, Handle:pack) {
	decl String:sText[MSG_SIZE];
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

public Action:Timer_ShowAd(Handle:htimer, any:data_id) {
	if(g_bEnabled) {
		new String:sText[MSG_SIZE];
		strcopy(sText, MSG_SIZE, g_hAds[data_id][text]);

		Call_StartForward(g_hForwardSendAdCondition);
		Call_PushString(g_hAds[data_id][condition]);
		new result;
		Call_Finish(result);

		if(result > 0)
			return;

		Call_StartForward(g_hForwardSendAd);
		Call_PushStringEx(sText,MSG_SIZE,SM_PARAM_STRING_COPY,SM_PARAM_COPYBACK);
		Call_PushCell(MSG_SIZE);
		Call_Finish();

		Call_StartForward(g_hForwardSendAdPost);
		Call_PushStringEx(sText,MSG_SIZE,SM_PARAM_STRING_COPY,SM_PARAM_COPYBACK);
		Call_PushCell(MSG_SIZE);
		Call_Finish();

		if(!StrEqual(sText,""))
			DisplayAd(data_id, sText);
	}
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

public OnMapStart() {
	g_iCount = 0;
	for(new i=0; i < MAX_ADS; i++) {
		g_hAds[i][id] = 0;
		g_hAds[i][interval] = 0.0;
		g_hAds[i][plugin] = 0;
		g_hAds[i][timer] = INVALID_HANDLE;
		strcopy(g_hAds[i][type], 8, "");
		strcopy(g_hAds[i][text], MSG_SIZE, "");
		strcopy(g_hAds[i][trigger], MSG_SIZE, "");
		strcopy(g_hAds[i][condition], MSG_SIZE, "");
		strcopy(g_hAds[i][filter], MSG_SIZE, "");
		strcopy(g_hAds[i][flagList], 16, "");
	}
}

public OnMapEnd() {
	ClearTimers();
}
