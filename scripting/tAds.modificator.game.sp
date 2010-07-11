#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Modificator, Game",
	author      = "Thrawn",
	description = "Display current game in ads",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

enum xGame {
	xGame_Unknown = -1,
	xGame_CSS,
	xGame_DODS,
	xGame_L4D,
	xGame_L4D2,
	xGame_TF,
	xGame_HL2MP,
	xGame_INSMOD,
	xGame_FF,
	xGame_ZPS,
	xGame_AOC,
	xGame_FOF,
	xGame_GES
};

//Current Gamemode
new xGame:g_xGame = xGame_Unknown;

public OnPluginStart() {
	DetectGame();

	CreateConVar("sm_tads_game_version", PL_VERSION, "Display current game in ads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:Ads_OnSend(String:sText[], size) {
	decl String:sBuffer[256];

	if (StrContains(sText, "{GAME}", false)       != -1) {
		GetGame(sBuffer, sizeof(sBuffer), false);
		ReplaceString(sText, size, "{GAME}", sBuffer, false);
	}

	if (StrContains(sText, "{GAMESHORT}", false)       != -1) {
		GetGame(sBuffer, sizeof(sBuffer), true);
		ReplaceString(sText, size, "{GAMESHORT}", sBuffer, false);
	}
}

stock GetGame(String:out[], size, bool:short = false) {
	switch(g_xGame) {
		case xGame_Unknown:	Format(out, size, "%s", short ? "?" : "unknown");
		case xGame_CSS:		Format(out, size, "%s", short ? "css" : "Counter-Strike");
		case xGame_DODS:	Format(out, size, "%s", short ? "dods" : "Day of Defeat");
		case xGame_HL2MP:	Format(out, size, "%s", short ? "hl2mp" : "Half-Life 2 Deathmatch");
		case xGame_TF:		Format(out, size, "%s", short ? "tf" : "Team Fortress");
		case xGame_L4D:		Format(out, size, "%s", short ? "l4d" : "Left4Dead");
		case xGame_L4D2:	Format(out, size, "%s", short ? "l4d2" : "Left4Dead2");
		case xGame_INSMOD:	Format(out, size, "%s", short ? "ins" : "Insurgency");
		case xGame_FOF:		Format(out, size, "%s", short ? "fof" : "Fistful of frags");
		case xGame_FF:		Format(out, size, "%s", short ? "ff" : "Fortress Forever");
		case xGame_GES:		Format(out, size, "%s", short ? "ges" : "gesource");
		case xGame_ZPS:		Format(out, size, "%s", short ? "zps" : "ZPS");
		case xGame_AOC:		Format(out, size, "%s", short ? "aoc" : "Age of Chivalry");
	}
}

DetectGame()
{
	// Adapted from HLX:CE ingame plugin :3
	if (g_xGame == xGame_Unknown)
	{
		new String: szGameDesc[64];
		GetGameDescription(szGameDesc, 64, true);

		if (StrContains(szGameDesc, "Counter-Strike", false) != -1)
		{
			g_xGame = xGame_CSS;
		}
		else if (StrContains(szGameDesc, "Day of Defeat", false) != -1)
		{
			g_xGame = xGame_DODS;
		}
		else if (StrContains(szGameDesc, "Half-Life 2 Deathmatch", false) != -1)
		{
			g_xGame = xGame_HL2MP;
		}
		else if (StrContains(szGameDesc, "Team Fortress", false) != -1)
		{
			g_xGame = xGame_TF;
		}
		else if (StrContains(szGameDesc, "L4D", false) != -1 || StrContains(szGameDesc, "Left 4 D", false) != -1)
		{
			g_xGame = (GuessSDKVersion() >= SOURCE_SDK_LEFT4DEAD) ? xGame_L4D : xGame_L4D2;
		}
		else if (StrContains(szGameDesc, "Insurgency", false) != -1)
		{
			g_xGame = xGame_INSMOD;
		}
		else if (StrContains(szGameDesc, "Fortress Forever", false) != -1)
		{
			g_xGame = xGame_FF;
		}
		else if (StrContains(szGameDesc, "ZPS", false) != -1)
		{
			g_xGame = xGame_ZPS;
		}
		else if (StrContains(szGameDesc, "Age of Chivalry", false) != -1)
		{
			g_xGame = xGame_AOC;
		}
		// game could not detected, try further
		if (g_xGame == xGame_Unknown)
		{
			new String: szGameDir[64];
			GetGameFolderName(szGameDir, 64);

			if (StrContains(szGameDir, "cstrike", false) != -1)
			{
				g_xGame = xGame_CSS;
			}
			else if (StrContains(szGameDir, "dod", false) != -1)
			{
				g_xGame = xGame_DODS;
			}
			else if (StrContains(szGameDir, "hl2mp", false) != -1 || StrContains(szGameDir, "hl2ctf", false) != -1)
			{
				g_xGame = xGame_HL2MP;
			}
			else if (StrContains(szGameDir, "fistful_of_frags", false) != -1)
			{
				g_xGame = xGame_FOF;
			}
			else if (StrContains(szGameDir, "tf", false) != -1)
			{
				g_xGame = xGame_TF;
			}
			else if (StrContains(szGameDir, "left4dead", false) != -1)
			{
				g_xGame = (GuessSDKVersion() == SOURCE_SDK_LEFT4DEAD) ? xGame_L4D : xGame_L4D2;
			}
			else if (StrContains(szGameDir, "insurgency", false) != -1)
			{
				g_xGame = xGame_INSMOD;
			}
			else if (StrContains(szGameDir, "FortressForever", false) != -1)
			{
				g_xGame = xGame_FF;
			}
			else if (StrContains(szGameDir, "zps", false) != -1)
			{
				g_xGame = xGame_ZPS;
			}
			else if (StrContains(szGameDir, "ageofchivalry", false) != -1)
			{
				g_xGame = xGame_AOC;
			}
			else if (StrContains(szGameDir, "gesource", false) != -1)
			{
				g_xGame = xGame_GES;
			}
		}
	}
}