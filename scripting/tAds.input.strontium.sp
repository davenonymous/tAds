#pragma semicolon 1

#include <sourcemod>
#include <tads>

#define PL_VERSION		"0.0.1"
#define MAXTRIES		20
new Handle:g_hDatabase = INVALID_HANDLE;
new Handle:g_hCvarEnable;
new Handle:g_hCvarDBName;

new bool:g_bEnabled;
new String:g_sDatabaseName[64];
new iTries = 0;

public Plugin:myinfo = {
	name        = "tAds, Input, MySQL, Strontium",
	author      = "Thrawn, Tsunami, <eVa>Dog",
	description = "Advertisement source: mysql (strontium)",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

public OnPluginStart()
{
	CreateConVar("sm_tads_strontium_version", PL_VERSION, "Import advertisements from a MySQL DB with StrontiumDogs scheme", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hCvarEnable = CreateConVar("sm_tads_strontium_enabled", "1", "Enable/disable loading ads from mysql (strontium).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarDBName = CreateConVar("sm_tads_strontium_dbname", "admintools", "Use this db for ads.", FCVAR_PLUGIN);

	RegAdminCmd("sm_tads_strontium_reload", Command_ReloadAds, ADMFLAG_BAN, " - reloads the ads");

	HookConVarChange(g_hCvarDBName, Convar_Changed);
	HookConVarChange(g_hCvarEnable, Convar_Changed);
}

public Convar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(convar == g_hCvarEnable) {
		g_bEnabled = GetConVarBool(g_hCvarEnable);

		if(!g_bEnabled)
			Ads_UnRegisterAds();
		else
			LoadAds();
	}

	if(convar == g_hCvarDBName) {
		GetConVarString(g_hCvarDBName,g_sDatabaseName,sizeof(g_sDatabaseName));

		Ads_UnRegisterAds();
		SQL_TConnect(SQL_Connected, g_sDatabaseName);
	}
}



public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnable);
	GetConVarString(g_hCvarDBName,g_sDatabaseName,sizeof(g_sDatabaseName));

	SQL_TConnect(SQL_Connected, g_sDatabaseName);
}

public SQL_Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(g_hDatabase != INVALID_HANDLE) {
		CloseHandle(g_hDatabase);
		g_hDatabase = INVALID_HANDLE;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("[tAds-Strontium] Database failure: %s", error);
		return;
	}

	g_hDatabase = hndl;
	LogMessage("[tAds-Strontium] Connected Successfully to Database");
}

public OnMapStart()
{
	iTries = 0;
	CreateTimer(0.5, Timer_SetupAds, TIMER_REPEAT);
}

public LoadAds() {
	if(g_hDatabase == INVALID_HANDLE)
		return;

	new String:sQuery[1024];

	Format(sQuery, sizeof(sQuery), "SELECT * FROM adsmysql ORDER BY id;");
	SQL_TQuery(g_hDatabase, SQL_ParseAds, sQuery, _, DBPrio_High);
}

public SQL_ParseAds(Handle:db, Handle:hQuery, const String:error[], any:client)
{
	if(hQuery == INVALID_HANDLE) {
		LogError("[tAds-Strontium] Query failed! %s", error);
		return;
	}

	if (g_bEnabled) {
		Ads_UnRegisterAds();
		new String:sTrigger[MSG_SIZE];

		if(SQL_GetRowCount(hQuery) > 0)
		{
			LogMessage("[tAds-Strontium] %i rows found", SQL_GetRowCount(hQuery));
			new count = 0;
			while(SQL_FetchRow(hQuery))
			{
				new String:sText[MSG_SIZE], String:sFlags[27], String:sType[2], String:sGame[64], String:sCondition[MSG_SIZE], String:sFilter[MSG_SIZE];

				SQL_FetchString(hQuery, 1, sType, 2);
				SQL_FetchString(hQuery, 2, sText, MSG_SIZE);
				SQL_FetchString(hQuery, 3, sFlags, 27);
				SQL_FetchString(hQuery, 4, sGame, 64);

				new String:sResultFlags[16];
				if(StrEqual("", sFlags)) {
					//If DB field	is empty 	--> only admins
					//				is 'a'	 	--> no admins
					//				is 'none'	--> everyone
					Format(sResultFlags, sizeof(sResultFlags), "a");
				} else if (StrEqual("a", sFlags)) {
					Format(sFilter, sizeof(sFilter), "{noadmins}");
				}

				if(!StrEqual("All", sGame, false)) {
					Format(sCondition, sizeof(sCondition), "{game:'%s'}", sGame);
				}

				Ads_RegisterAd(0.0, sType, sResultFlags, sText, sTrigger, sCondition, sFilter);
				//LogMessage("[tAds-Strontium] Ad %d found in database: %s, %s, %s, %s, %s", count, sType, sText, sResultFlags, sCondition, sFilter);
				count++;
			}
		}

		CloseHandle(hQuery);
	}
}

public Action:Command_ReloadAds(client, args)
{
	if(g_hDatabase == INVALID_HANDLE) {
		ReplyToCommand(client, "Error: Database not connected.");
		return Plugin_Handled;
	}

	LoadAds();
	return Plugin_Handled;
}

public Action:Timer_SetupAds(Handle:timer, any:timedelay)
{
	if(g_hDatabase != INVALID_HANDLE) {
		LoadAds();
		iTries = 0;
		return Plugin_Stop;
	}

	if(iTries > MAXTRIES) {
		LogMessage("Error: DB-Connection could not be established.");
		return Plugin_Stop;
	}

	iTries++;
	return Plugin_Continue;
}
