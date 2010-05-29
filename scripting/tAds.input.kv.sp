#pragma semicolon 1

#include <sourcemod>
#include <tads>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Input, KV",
	author      = "Thrawn, Tsunami",
	description = "Display advertisements, with modular replacements",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

new Handle:g_hCvarEnable;
new Handle:g_hCvarFile;

//Convars:
new String:g_sPath[PLATFORM_MAX_PATH];
new bool:g_bEnabled;


public OnPluginStart() {
	CreateConVar("sm_tads_kv_version", PL_VERSION, "Import advertisements from a KeyValues file", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hCvarEnable        = CreateConVar("sm_tads_kv_enabled",  "1",                  "Enable/disable displaying advertisements.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarFile           = CreateConVar("sm_tads_kv_file",     "advertisements.txt", "File to read the advertisements from.");

	RegAdminCmd("sm_tads_kv_reload", Command_ReloadAds, ADMFLAG_BAN);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnable);

	decl String:sFile[PLATFORM_MAX_PATH];
	GetConVarString(g_hCvarFile, sFile, PLATFORM_MAX_PATH);
	BuildPath(Path_SM, g_sPath, PLATFORM_MAX_PATH, "configs/%s", sFile);

	ParseAds();
}

public Action:Command_ReloadAds(client, args) {
	if (!g_bEnabled) {
		ReplyToCommand(client, "tAds, Input, KV is not enabled");
	}

	if (!FileExists(g_sPath)) {
		ReplyToCommand(client, "File %s does not exist", g_sPath);
	}

	ParseAds();
}

ParseAds() {
	if (g_bEnabled) {
		Ads_UnRegisterAds();

		if (FileExists(g_sPath)) {
			new Handle:hKVAdvertisements = CreateKeyValues("Advertisements");

			FileToKeyValues(hKVAdvertisements, g_sPath);

			if (!KvGotoFirstSubKey(hKVAdvertisements))
				return;

			do {
				//if (KvGotoFirstSubKey(hKVAdvertisements)) {
					KvReadAdvertisementBlock(hKVAdvertisements);
					//KvGoBack(hKVAdvertisements);
				//}
			} while (KvGotoNextKey(hKVAdvertisements));

			CloseHandle(hKVAdvertisements);
		} else {
			LogMessage("File %s does not exist", g_sPath);
		}
	}
}

KvReadAdvertisementBlock(Handle:hKVAdvertisements) {
	new String:sText[MSG_SIZE], String:sFlags[16], String:sType[6], String:sEnabled[3], String:sTrigger[255];

	KvGetString(hKVAdvertisements, "enabled", sEnabled, sizeof(sEnabled), "1");
	if(StrEqual(sEnabled,"1")) {
		KvGetString(hKVAdvertisements, "type",  sType,  sizeof(sType));
		KvGetString(hKVAdvertisements, "text",  sText,  sizeof(sText));
		KvGetString(hKVAdvertisements, "flags", sFlags, sizeof(sFlags), "none");
		KvGetString(hKVAdvertisements, "trigger", sTrigger, sizeof(sTrigger), "");

		new Float:fInterval = KvGetFloat(hKVAdvertisements, "interval", 0.0);
		Ads_RegisterAd(fInterval, ParseType(sType), sFlags, sText, sTrigger);
	}
}