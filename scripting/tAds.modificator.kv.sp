#pragma semicolon 1

#include <sourcemod>
#include <tads>

#define PL_VERSION		"0.0.1"
#define MAX_MODIFIERS	64

enum modifier {
	String:modificator[MSG_SIZE],
	String:replacement[MSG_SIZE]
}

new g_oList[MAX_MODIFIERS][modifier];

public Plugin:myinfo = {
	name        = "tAds, Modificator, KeyValues",
	author      = "Thrawn",
	description = "Load modificators from a keyvalues file",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

new Handle:g_hConfigParser = INVALID_HANDLE;
new g_iCount = 0;

public OnPluginStart() {
	CreateConVar("sm_tads_modkv_version", PL_VERSION, "Load modificators from a keyvalues file", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_tads_modkv_reload", Command_ReloadAds, ADMFLAG_BAN);
	PrepareConfigParser();
}

public Action:Command_ReloadAds(client, args) {
	ParseConfig();
}

public OnMapStart() {
	ParseConfig();
}

public PrepareConfigParser() {
	g_hConfigParser = SMC_CreateParser();
	SMC_SetReaders(g_hConfigParser, NewSection, KeyValue, EndSection);
}

public ResetModificators() {
	for(new i = 0; i < g_iCount; i++) {
		strcopy(g_oList[i][modificator],MSG_SIZE,"");
		strcopy(g_oList[i][replacement],MSG_SIZE,"");
	}

	g_iCount = 0;
}

public ParseConfig() {
	ResetModificators();

	decl String:configPath[256];
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/tAds.modificators.dynamic.txt");

	if (!FileExists(configPath))
	{
		LogError("Unable to locate dynamic modificators file: %s", configPath);

		return;
	}

	new line;
	new SMCError:err = SMC_ParseFile(g_hConfigParser, configPath, line);
	if (err != SMCError_Okay)
	{
		decl String:error[256];
		SMC_GetErrorString(err, error, sizeof(error));
		LogError("Could not parse file (line %d, file \"%s\"):", line, configPath);
		LogError("Parser encountered error: %s", error);
	}

	return;
}

public SMCResult:NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
}

public SMCResult:KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	strcopy(g_oList[g_iCount][modificator],MSG_SIZE,key);
	strcopy(g_oList[g_iCount][replacement],MSG_SIZE,value);

	g_iCount++;
}

public SMCResult:EndSection(Handle:smc)
{
	LogMessage("Found %i modificators.", g_iCount);
}

public Action:Ads_OnSend(String:sText[], size) {
	for(new i = 0; i < g_iCount; i++) {
		new String:pattern[MSG_SIZE];
		Format(pattern, MSG_SIZE, "{%s}", g_oList[i][modificator]);

		ReplaceString(sText, size, pattern, g_oList[i][replacement], false);
	}

	return Plugin_Changed;
}