#pragma semicolon 1

#include <sourcemod>
#include <tads>
#include <regex>
#include <steamtools>

#define PL_VERSION	"0.0.1"
#define	MAX_GROUPS	3

enum steamgroup {
	bool:isKnown,
	bool:isMember,
	bool:isOfficer
}

enum reputation {
	bool:isKnown,
	bool:isBanned,
	score
}

enum gameplaystats {
	bool:isKnown,
	rank,
	totalConnects,
	totalMinutesPlayed
}

new Handle:g_rxSteamGroup = INVALID_HANDLE;
new Handle:g_rxGameplayStats = INVALID_HANDLE;
new Handle:g_rxReputation = INVALID_HANDLE;
new Handle:g_hCvarGroups = INVALID_HANDLE;


new g_xGameplayStats[gameplaystats];
new g_xReputation[reputation];

new g_xList[MAXPLAYERS+1][MAX_GROUPS][steamgroup];

new g_iGroupCount = 0;
new g_iGroupID[MAX_GROUPS];


public Plugin:myinfo = {
	name        = "tAds, Modificator, Steamtools",
	author      = "Thrawn",
	description = "Display various steamtools informations in ads",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

public OnPluginStart() {
	CreateConVar("sm_tads_steamtools_version", PL_VERSION, "Display various steamtools informations in ads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_rxSteamGroup = CompileRegex("{groupmembers:'([0-9]+)':'(0|1)'}", PCRE_CASELESS|PCRE_UNGREEDY);
	g_rxGameplayStats = CompileRegex("{server_stats:'(rank|connects|playtime)'}", PCRE_CASELESS|PCRE_UNGREEDY);
	g_rxReputation = CompileRegex("{server_reputation:'(banned|score)'}", PCRE_CASELESS|PCRE_UNGREEDY);

	g_hCvarGroups = CreateConVar("sm_tads_steamtools_groups", "", "Comma-seperated list of group-ids needed as your modificators.");
}

public OnConfigsExecuted() {
	decl String:sGroups[256];
	GetConVarString(g_hCvarGroups, sGroups, 256);

	new String:buffers[MAX_GROUPS][8];
	g_iGroupCount = ExplodeString(sGroups, ",", buffers, MAX_GROUPS, 8);

	for(new i = 0; i < g_iGroupCount; i++) {
		g_iGroupID[i] = StringToInt(buffers[i]);
	}
}

public Action:Ads_OnSendFilter(String:sFilter[], client) {
	while(MatchRegex(g_rxSteamGroup, sFilter) > 0) {
		new String:full[255];
		new String:buffer[255];
		new groupID; new bool:officersOnly;

		new cnt = 0;
		while(GetRegexSubString(g_rxSteamGroup, cnt, buffer, sizeof(buffer))) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: groupID = StringToInt(buffer);
				case 2: officersOnly = bool:StringToInt(buffer);
				case 3: break;
			}

			cnt++;
		}
		strcopy(buffer, sizeof(buffer), "");

		new gID = FindGroup(groupID);

		if(gID != -1) {
			if (g_xList[client][gID][isKnown] && g_xList[client][gID][isMember])
			{
				if(officersOnly && !g_xList[client][gID][isOfficer])
					return Plugin_Handled;

				return Plugin_Continue;
			}
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:Ads_OnSend(String:sText[], size) {
	while(MatchRegex(g_rxSteamGroup, sText) > 0) {
		new String:full[255];
		new String:buffer[255];
		new groupID; new bool:officersOnly;

		new cnt = 0;
		while(GetRegexSubString(g_rxSteamGroup, cnt, buffer, sizeof(buffer))) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: groupID = StringToInt(buffer);
				case 2: officersOnly = bool:StringToInt(buffer);
				case 3: break;
			}

			cnt++;
		}
		strcopy(buffer, sizeof(buffer), "");

		new gID = FindGroup(groupID);

		if(gID != -1) {
			for (new client = 1; client < MaxClients; client++)
			{
				if (g_xList[client][gID][isKnown] && g_xList[client][gID][isMember])
				{
					if(officersOnly && !g_xList[client][gID][isOfficer])
						continue;

					Format(buffer, sizeof(buffer), "%s%N, ", buffer, client);
				}
			}

			break;
		}


		new String:result[strlen(buffer)];
		strcopy(result, strlen(buffer)-1, buffer);

		ReplaceString(sText, size, full, result);
	}


	while(MatchRegex(g_rxGameplayStats, sText) > 0 && g_xGameplayStats[isKnown]) {
		new String:full[255];
		new String:buffer[255];
		new result;

		new cnt = 0;
		while(GetRegexSubString(g_rxGameplayStats, cnt, buffer, sizeof(buffer))) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: {
					if(StrEqual(buffer, "rank"))result = g_xGameplayStats[rank];
					else if(StrEqual(buffer, "connects"))result = g_xGameplayStats[totalConnects];
					else if(StrEqual(buffer, "playtime"))result = g_xGameplayStats[totalMinutesPlayed];
				}
				case 2: break;
			}

			cnt++;
		}

		Format(buffer, sizeof(buffer), "%i", result);
		ReplaceString(sText, size, full, buffer);
	}


	while(MatchRegex(g_rxReputation, sText) > 0 && g_xReputation[isKnown]) {
		new String:full[255];
		new String:buffer[255];
		new result;

		new cnt = 0;
		while(GetRegexSubString(g_rxGameplayStats, cnt, buffer, sizeof(buffer))) {
			switch(cnt) {
				case 0: full = buffer;
				case 1: {
					if(StrEqual(buffer, "banned"))result = _:g_xReputation[isBanned];
					else if(StrEqual(buffer, "score"))result = g_xReputation[score];
				}
				case 2: break;
			}

			cnt++;
		}

		Format(buffer, sizeof(buffer), "%i", result);
		ReplaceString(sText, size, full, buffer);
	}

	if (StrContains(sText, "{server_vacstate}", false) != -1) {
		ReplaceString(sText, size, "{server_vacstate}", Steam_IsVACEnabled()?"1":"0", false);
	}

	if (StrContains(sText, "{server_connectstate}", false) != -1) {
		ReplaceString(sText, size, "{server_connectstate}", Steam_IsConnected()?"1":"0", false);
	}

	if (StrContains(sText, "{server_ip}", false) != -1) {
		new octets[4]; new String:buffer[16];
		Steam_GetPublicIP(octets);

		Format(buffer, sizeof(buffer), "%d.%d.%d.%d", octets[0], octets[1], octets[2], octets[3]);
		ReplaceString(sText, size, "{server_ip}", buffer, false);
	}

	//Steam_IsVACEnabled()
	return Plugin_Changed;
}

public OnMapStart() {
	g_xReputation[isKnown] = false;
	Steam_RequestServerReputation();

	g_xGameplayStats[isKnown] = false;
	Steam_RequestGameplayStats();
}

public OnClientAuthorized(client, const String:auth[])
{
	for(new i = 0; i < g_iGroupCount; i++) {
		g_xList[client][i][isKnown] = false;
		Steam_RequestGroupStatus(client, g_iGroupID[i]);
	}
}

public FindGroup(gID) {
	for(new i = 0; i < g_iGroupCount; i++) {
		if(g_iGroupID[i] == gID)return i;
	}

	return -1;
}

public Action:Steam_GroupStatusResult(client, groupAccountID, bool:groupMember, bool:groupOfficer)
{
	new gID = FindGroup(groupAccountID);

	if(gID != -1) {
		g_xList[client][gID][isMember] = groupMember;
		g_xList[client][gID][isOfficer] = groupOfficer;
		g_xList[client][gID][isKnown] = true;
	}

	return Plugin_Continue;
}

public Action:Steam_Reputation(reputationScore, bool:banned, bannedIP, bannedPort, bannedGameID, banExpires)
{
	g_xReputation[score] = reputationScore;
	g_xReputation[isBanned] = banned;
	g_xReputation[isKnown] = true;

	return Plugin_Continue;
}


public Action:Steam_GameplayStats(iRank, iTotalConnects, iTotalMinutesPlayed)
{
	g_xGameplayStats[rank] = iRank;
	g_xGameplayStats[totalConnects] = iTotalConnects;
	g_xGameplayStats[totalMinutesPlayed] = iTotalMinutesPlayed;
	g_xGameplayStats[isKnown] = true;

	return Plugin_Continue;
}
