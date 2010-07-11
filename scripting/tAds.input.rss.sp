#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>
#include <socket>

#define PL_VERSION		"0.0.1"
#define MAXFEEDS		5
#define MAXITEMS		5

public Plugin:myinfo = {
	name        = "tAds, Input, RSS",
	author      = "Thrawn",
	description = "Display advertisements fetched from rss feeds",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

new Handle:g_hCvarEnable;
new Handle:g_hCvarFile;

//Convars:
new String:g_sPath[PLATFORM_MAX_PATH];
new bool:g_bEnabled;

enum newsItem {
	String:sourceURL[256],
	String:title[256],
	String:desc[1024],
	String:pubdate[128]
}

enum rssSource {
	amount,
	count,
	Float:interval,
	String:flags[16],
	String:type[8],
	String:url[MSG_SIZE],
	String:trigger[MSG_SIZE]
}

new g_iSourcesCount;
new g_xSources[MAXFEEDS][rssSource];
new g_xItems[MAXFEEDS][MAXITEMS][newsItem];

new Handle:g_rItemTitle = INVALID_HANDLE;
new Handle:g_rItemDescription = INVALID_HANDLE;
new Handle:g_rItemPubDate = INVALID_HANDLE;

public OnPluginStart() {
	CreateConVar("sm_tads_rss_version", PL_VERSION, "Import advertisements from a rss feed", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hCvarEnable        = CreateConVar("sm_tads_rss_enabled",  "1",                  "Enable/disable displaying advertisements.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarFile           = CreateConVar("sm_tads_rss_kv_file",     "tads.rss.txt", "File to read the rss input feeds from.");

	g_rItemTitle = CompileRegex(		"<title>(.*)</title>", PCRE_CASELESS|PCRE_UNGREEDY);
	g_rItemDescription = CompileRegex(	"<description>(.*)</description>", PCRE_CASELESS|PCRE_UNGREEDY);
	g_rItemPubDate = CompileRegex(	"<pubDate>(.*)</pubDate>", PCRE_CASELESS|PCRE_UNGREEDY);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnable);

	decl String:sFile[PLATFORM_MAX_PATH];
	GetConVarString(g_hCvarFile, sFile, PLATFORM_MAX_PATH);
	BuildPath(Path_SM, g_sPath, PLATFORM_MAX_PATH, "configs/%s", sFile);

	ParseInputFeeds();
}

ParseInputFeeds() {
	if (g_bEnabled) {
		Ads_UnRegisterAds();
		g_iSourcesCount = 0;
		if (FileExists(g_sPath)) {
			new Handle:hKVRssSources = CreateKeyValues("RSSFeeds");

			FileToKeyValues(hKVRssSources, g_sPath);

			if (!KvGotoFirstSubKey(hKVRssSources))
				return;

			do {
				if(g_iSourcesCount == MAXFEEDS)
					break;

				KvReadAdvertisementBlock(hKVRssSources);
			} while (KvGotoNextKey(hKVRssSources));

			CloseHandle(hKVRssSources);
		} else {
			LogMessage("File %s does not exist", g_sPath);
		}
	}
}

KvReadAdvertisementBlock(Handle:hKVRssSources) {
	new String:sFlags[16], String:sType[6], String:sEnabled[3], String:sUrl[255], String:sTrigger[255];

	KvGetString(hKVRssSources, "enabled", sEnabled, sizeof(sEnabled), "1");
	KvGetString(hKVRssSources, "url", sUrl, sizeof(sUrl), "");

	if(StrEqual(sEnabled,"1") && !StrEqual(sUrl,"")) {
		KvGetString(hKVRssSources, "type",  sType,  sizeof(sType));
		KvGetString(hKVRssSources, "flags", sFlags, sizeof(sFlags), "none");
		KvGetString(hKVRssSources, "trigger", sTrigger, sizeof(sTrigger), "");

		strcopy(g_xSources[g_iSourcesCount][type], 8, sType);
		strcopy(g_xSources[g_iSourcesCount][url], MSG_SIZE, sUrl);
		strcopy(g_xSources[g_iSourcesCount][flags], 16, sFlags);
		strcopy(g_xSources[g_iSourcesCount][trigger], MSG_SIZE, sTrigger);
		g_xSources[g_iSourcesCount][interval] = KvGetFloat(hKVRssSources, "interval", 0.0);
		g_xSources[g_iSourcesCount][amount] = KvGetNum(hKVRssSources, "amount", 1);
		g_xSources[g_iSourcesCount][count] = 0;

		//TODO: Start download, wait for response, parsexml, register ads
		//Ads_RegisterAd(fInterval, , sFlags, sText, sTrigger);
		g_iSourcesCount++;
	}
}

public ParseXML(iFeed) {
	new String:xml[4096];
	new String:buffer[4096];
	new String:full[4096];

	decl String:configPath[256];
	BuildPath(Path_SM, configPath, sizeof(configPath), "rss2.xml");

	new iLine = 0;
	new iCount = 0;
	new Handle:file = OpenFile(configPath, "r");
	new bool:bInAnItem = false;
	while(ReadFileLine(file, xml, sizeof(xml))) {
		iLine++;
		if(StrContains(xml, "<item>") != -1) {
			bInAnItem = true;
			continue;
		}

		if(bInAnItem && MatchRegex(g_rItemTitle, xml) > 0) {
			new String:content[4096];

			new cnt = 0;
			while(GetRegexSubString(g_rItemTitle, cnt, buffer, sizeof(buffer))) {
				switch(cnt) {
					case 0: full = buffer;
					case 1: content = buffer;
					case 2: break;
				}

				cnt++;
			}

			ReplaceString(xml, sizeof(xml), full, "");
			ReplaceString(content, sizeof(content), "<![CDATA[", "");
			ReplaceString(content, sizeof(content), "]]>", "");
			TrimString(content);

			strcopy(g_xItems[iFeed][iCount][title], 255, content);
		}

		if(bInAnItem && MatchRegex(g_rItemDescription, xml) > 0) {
			new String:content[4096];

			new cnt = 0;
			while(GetRegexSubString(g_rItemDescription, cnt, buffer, sizeof(buffer))) {
				switch(cnt) {
					case 0: full = buffer;
					case 1: content = buffer;
					case 2: break;
				}

				cnt++;
			}

			ReplaceString(xml, sizeof(xml), full, "");
			ReplaceString(content, sizeof(content), "<![CDATA[", "");
			ReplaceString(content, sizeof(content), "]]>", "");
			TrimString(content);

			strcopy(g_xItems[iFeed][iCount][desc], 1024, content);
		}

		if(bInAnItem && MatchRegex(g_rItemPubDate, xml) > 0) {
			new String:content[4096];

			new cnt = 0;
			while(GetRegexSubString(g_rItemPubDate, cnt, buffer, sizeof(buffer))) {
				switch(cnt) {
					case 0: full = buffer;
					case 1: content = buffer;
					case 2: break;
				}

				cnt++;
			}

			ReplaceString(xml, sizeof(xml), full, "");
			ReplaceString(content, sizeof(content), "<![CDATA[", "");
			ReplaceString(content, sizeof(content), "]]>", "");
			TrimString(content);

			strcopy(g_xItems[iFeed][iCount][pubdate], 128, content);
		}

		if(StrContains(xml, "</item>") != -1) {
			iCount++;
			bInAnItem = false;

			if(iCount == MAXITEMS)
				break;

			continue;
		}

		g_xSources[iFeed][count] = iCount;
	}
	CloseHandle(file);
}
