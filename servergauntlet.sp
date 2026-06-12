#include <clientprefs>
#include <sdktools>
#include <sourcemod>

#include <shavit>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

float g_fPoints[MAXPLAYERS + 1];

int g_iRunners;
int g_iPlace;
int g_iNextmap;

bool g_bRunner[MAXPLAYERS + 1];
bool g_bCompleted[MAXPLAYERS + 1];
bool g_bFrozen[MAXPLAYERS + 1];
bool g_bStarted;

Handle g_hPoints;

chatstrings_t gS_ChatStrings;

/*char g_sMaps[][] = {
    "bhop_monster_jam",
    "bhop_lego2",
    "bhop_fury",
    "bhop_catalyst_fix",
    "bhop_addict_v2",
    "bhop_arcane_v2",
    "bhop_lego",
    "bhop_toc",
    "bhop_null_fix",
    "bhop_exodus_fix",
    "bhop_freakin",
    "bhop_depot",
    "bhop_flocci",
    "bhop_ivy_sr",
    "bhop_cutekittenz",
    "bhop_fps_max_sr",
    "bhop_sqee",
    "bhop_haddock",
    "bhop_underground_crypt",
    "bhop_badges"
};*/

char g_sMaps[][] = {
	"bhop_kz_dydhop",
	"bhop_badges",
	"bhop_lego2",
	"bhop_sj",
	"bhop_cutekittenz",
	"bhop_polyworld",
	"bhop_victory",
	"bhop_arcane_v2",
	"bhop_dreamtour2"
};

public Plugin myinfo =
{
	name        = "server gauntlet race",
	author      = "may",
	description = "i love kaworu",
	version     = PLUGIN_VERSION,
	url         = "Your website URL/AlliedModders profile URL"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_leaderboard", Command_Leaderboard, "");
	RegConsoleCmd("sm_lb", Command_Leaderboard, "");

	RegConsoleCmd("sm_resetpoints", Command_Reset, "");

	RegConsoleCmd("sm_pool", Command_Pool, "");
	RegConsoleCmd("sm_mappool", Command_Pool, "");

	RegAdminCmd("gauntlet_start", Command_GauntletStart, ADMFLAG_ROOT);
	RegAdminCmd("gauntlet_end", Command_GauntletEnd, ADMFLAG_ROOT);

	g_hPoints = RegClientCookie("gauntletPoints", "Gauntlet Points", CookieAccess_Protected);
}

public void OnMapStart()
{
	char buffer[32];
	GetCurrentMap(buffer, sizeof(buffer));

	for (int i; i < sizeof(g_sMaps); i++)
	{
		if (StrEqual(buffer, g_sMaps[i]))
		{
			g_iNextmap = i + 1;
			break;
		}
	}

	g_bStarted = false;
	g_iPlace   = 0;
	g_iRunners = 0;
}

public void OnClientPutInServer(int client)
{
	g_bRunner[client]    = false;
	g_bCompleted[client] = false;
	g_bFrozen[client]    = false;
}

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStringsStruct(gS_ChatStrings);
}

public void Shavit_OnFinish(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldtime, float perfs, float avgvel, float maxvel, int timestamp)
{
	if (g_bRunner[client] && track == Track_Main && !g_bCompleted[client] && style == 0)
	{
		g_iPlace++;
		g_bCompleted[client] = true;
		char buffer[32], newtime[32], cookie[32], mapName[32];

		GetCurrentMap(mapName, sizeof(mapName));

		FormatSeconds(time, newtime, sizeof(newtime));
		GetClientName(client, buffer, sizeof(buffer));

		float pts = (10.0 / (g_iPlace * 1.0 / 3.0) / 2);
		if (pts < 1.0) pts = 1.0;
		if (pts > 10.0) pts = 10.0;

		GetClientCookie(client, g_hPoints, cookie, sizeof(cookie));
		g_fPoints[client] = pts + StringToFloat(cookie);
		FloatToString(g_fPoints[client], cookie, sizeof(cookie));
		SetClientCookie(client, g_hPoints, cookie);

		switch (g_iPlace)
		{
			case 1:
			{
				Shavit_PrintToChatAll("%s%s%s has finished the map %sfirst%s in %s%s%s!", gS_ChatStrings.sVariable, buffer, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, newtime, gS_ChatStrings.sText);
				Shavit_PrintToChatAll("They now have %s%.0f%s (%s+10%s) points.", gS_ChatStrings.sVariable2, g_fPoints[client], gS_ChatStrings.sText, gS_ChatStrings.sVariable2, gS_ChatStrings.sText);

				if (!StrEqual(mapName, g_sMaps[sizeof(g_sMaps) - 1]))
				{
					Shavit_PrintToChatAll("Map will change to %s%s%s in %s5 minutes%s (%s!pool%s).", gS_ChatStrings.sVariable, g_sMaps[g_iNextmap], gS_ChatStrings.sText, gS_ChatStrings.sWarning, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText);

					CreateTimer(120.0, ThreeMinuteRemaining, client);
					CreateTimer(180.0, TwoMinuteRemaining, client);
					CreateTimer(240.0, OneMinuteRemaining, client);
					CreateTimer(270.0, ThirtySecondsRemaining, client);
					CreateTimer(290.0, TenSecondsRemaining, client);
					CreateTimer(295.0, MapChangeCountdown, client);
					CreateTimer(300.0, MapChange, client);
				}
			}
			case 2:
			{
				Shavit_PrintToChatAll("%s%s%s has finished the map in %s%s%s coming in %s2nd place%s!", gS_ChatStrings.sVariable, buffer, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, newtime, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText);
				Shavit_PrintToChatAll("They now have %s%.0f%s (%s+%.0f%s) points.", gS_ChatStrings.sVariable2, g_fPoints[client], gS_ChatStrings.sText, gS_ChatStrings.sVariable2, 10.0 / (g_iPlace * 1.0 / 3.0) / 2, gS_ChatStrings.sText);
			}
			case 3:
			{
				Shavit_PrintToChatAll("%s%s%s has finished the map in %s%s%s coming in %s3rd place%s!", gS_ChatStrings.sVariable, buffer, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, newtime, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText);
				Shavit_PrintToChatAll("They now have %s%.0f%s (%s+%.0f%s) points.", gS_ChatStrings.sVariable2, g_fPoints[client], gS_ChatStrings.sText, gS_ChatStrings.sVariable2, 10.0 / (g_iPlace * 1.0 / 3.0) / 2, gS_ChatStrings.sText);
			}
			default:
			{
				Shavit_PrintToChatAll("%s%s%s has finished the map in %s%s%s coming in %s%ith place%s!", gS_ChatStrings.sVariable, buffer, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, newtime, gS_ChatStrings.sText, gS_ChatStrings.sStyle, g_iPlace, gS_ChatStrings.sText);
				Shavit_PrintToChatAll("They now have %s%.0f%s (%s+%.0f%s) points.", gS_ChatStrings.sVariable2, g_fPoints[client], gS_ChatStrings.sText, gS_ChatStrings.sVariable2, 10.0 / (g_iPlace * 1.0 / 3.0) / 2, gS_ChatStrings.sText);
			}
		}

		if (StrEqual(mapName, g_sMaps[sizeof(g_sMaps) - 1]) && g_iPlace == g_iRunners)
		{
			PrintLeaderboard(0);
		}
	}
}

/*public void Shavit_OnLeaveZone(int client, int type, int track, int id, int entity, int data)
{
    if (!g_bStarted && g_bRunner[client])
    {
        Shavit_RestartTimer(client, track, true);
        Shavit_PrintToChat(client, "Please wait until the race starts");
    }
}*/
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!g_bStarted && g_bRunner[client] && Shavit_GetClientTime(client) > 0.05)
	{
		Shavit_RestartTimer(client, Track_Main, true);
		Shavit_PrintToChat(client, "Please wait until the race starts");
	}
}

public Action Command_GauntletStart(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i) && Shavit_GetBhopStyle(i) == 0)
		{
			char buffer[32];
			GetCurrentMap(buffer, sizeof(buffer));
			g_bRunner[i] = true;
			g_iRunners++;

			Shavit_RestartTimer(i, Track_Main, true);
			g_bFrozen[client] = true;

			if (AreClientCookiesCached(i) && StrEqual(buffer, g_sMaps[0]))
			{
				SetClientCookie(i, g_hPoints, "0.0");
			}
		}
	}

	StartCountdown(null, 5);
}

public Action Command_GauntletEnd(int client, int args)
{
	PrintLeaderboard(0);
}

public Action MapChange(Handle timer, int client)
{
	ServerCommand("sm_map %s", g_sMaps[g_iNextmap]);
}

public Action StartCountdown(Handle timer, any data)
{
	if (data == 0)
	{
		Shavit_PrintToChatAll("%sGO", gS_ChatStrings.sStyle);
		g_bStarted = true;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (g_bFrozen[i]) g_bFrozen[i] = false;
		}
	}
	else
	{
		Shavit_PrintToChatAll("%s%d", gS_ChatStrings.sWarning, data);
		CreateTimer(1.0, StartCountdown, data - 1);
	}
	return Plugin_Stop;
}

public Action MapChangeCountdown(Handle timer, int client)
{
	Shavit_PrintToChatAll("%s5 seconds%s remaining.", gS_ChatStrings.sWarning, gS_ChatStrings.sText);

	CreateTimer(1.0, MapChangeCountdown1, client);
	CreateTimer(2.0, MapChangeCountdown2, client);
	CreateTimer(3.0, MapChangeCountdown3, client);
	CreateTimer(4.0, MapChangeCountdown4, client);
}

public Action MapChangeCountdown1(Handle timer, int client)
{
	Shavit_PrintToChatAll("%s4 seconds%s remaining.", gS_ChatStrings.sWarning, gS_ChatStrings.sText);
}

public Action MapChangeCountdown2(Handle timer, int client)
{
	Shavit_PrintToChatAll("%s3 seconds%s remaining.", gS_ChatStrings.sWarning, gS_ChatStrings.sText);
}

public Action MapChangeCountdown3(Handle timer, int client)
{
	Shavit_PrintToChatAll("%s2 seconds%s remaining.", gS_ChatStrings.sWarning, gS_ChatStrings.sText);
}

public Action MapChangeCountdown4(Handle timer, int client)
{
	Shavit_PrintToChatAll("%s1 second%s remaining.", gS_ChatStrings.sWarning, gS_ChatStrings.sText);
}

public Action OneMinuteRemaining(Handle timer, int client)
{
	Shavit_PrintToChatAll("%s1 minute%s remaining.", gS_ChatStrings.sWarning, gS_ChatStrings.sText);
}

public Action TwoMinuteRemaining(Handle timer, int client)
{
	Shavit_PrintToChatAll("%s2 minutes%s remaining.", gS_ChatStrings.sWarning, gS_ChatStrings.sText);
}

public Action ThreeMinuteRemaining(Handle timer, int client)
{
	Shavit_PrintToChatAll("%s3 minutes%s remaining", gS_ChatStrings.sWarning, gS_ChatStrings.sText);
}

public Action ThirtySecondsRemaining(Handle timer, int client)
{
	Shavit_PrintToChatAll("%s30 seconds%s remaining.", gS_ChatStrings.sWarning, gS_ChatStrings.sText);
}

public Action TenSecondsRemaining(Handle timer, int client)
{
	Shavit_PrintToChatAll("%s10 seconds%s remaining.", gS_ChatStrings.sWarning, gS_ChatStrings.sText);
}

public Action Command_Leaderboard(int client, int args)
{
	PrintLeaderboard(client);
}

public void PrintLeaderboard(int client)
{
	int   first, second, third, fourth, fifth;
	float points[MAXPLAYERS + 1], pointsUnsorted[MAXPLAYERS + 1];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			char cookie[32];
			GetClientCookie(i, g_hPoints, cookie, sizeof(cookie));
			points[i]         = StringToFloat(cookie);
			pointsUnsorted[i] = StringToFloat(cookie);
		}
	}

	SortFloats(points, sizeof(points), Sort_Descending);

	for (int i = 1; i <= MaxClients; i++)
	{
		char cookie[32];
		GetClientCookie(i, g_hPoints, cookie, sizeof(cookie));
		float pts = StringToFloat(cookie);
		if (IsValidClient(i) && i < MaxClients)
		{
			if (pts == points[0])
			{
				first = i;
			}
			if (pts == points[1])
			{
				second = i;
			}
			if (pts == points[2])
			{
				third = i;
			}
			if (pts == points[3])
			{
				fourth = i;
			}
			if (pts == points[4])
			{
				fifth = i;
			}
		}
		else if (i == MaxClients && client > 0)
		{
			Shavit_PrintToChat(client, "---------------------------------------------------------------");
			Shavit_PrintToChat(client, "%s%N%s is in %sfirst%s place with %s%.0f%s points!", gS_ChatStrings.sVariable, first, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, pointsUnsorted[first], gS_ChatStrings.sText);
			Shavit_PrintToChat(client, "%s%N%s is in %ssecond%s place with %s%.0f%s points!", gS_ChatStrings.sVariable, second, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, pointsUnsorted[second], gS_ChatStrings.sText);
			Shavit_PrintToChat(client, "%s%N%s is in %sthird%s place with %s%.0f%s points!", gS_ChatStrings.sVariable, third, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, pointsUnsorted[third], gS_ChatStrings.sText);
			Shavit_PrintToChat(client, "%s%N%s is in %sfourth%s place with %s%.0f%s points!", gS_ChatStrings.sVariable, fourth, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, pointsUnsorted[fourth], gS_ChatStrings.sText);
			Shavit_PrintToChat(client, "%s%N%s is in %sfifth%s place with %s%.0f%s points!", gS_ChatStrings.sVariable, fifth, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, pointsUnsorted[fifth], gS_ChatStrings.sText);
			Shavit_PrintToChat(client, "---------------------------------------------------------------");
		}
		else if (i == MaxClients)
		{
			Shavit_PrintToChatAll("---------------------------------------------------------------");
			Shavit_PrintToChatAll("%s%N%s came in %sfirst%s place with %s%.0f%s points!", gS_ChatStrings.sVariable, first, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, pointsUnsorted[first], gS_ChatStrings.sText);
			Shavit_PrintToChatAll("%s%N%s came in %ssecond%s place with %s%.0f%s points!", gS_ChatStrings.sVariable, second, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, pointsUnsorted[second], gS_ChatStrings.sText);
			Shavit_PrintToChatAll("%s%N%s came in %sthird%s place with %s%.0f%s points!", gS_ChatStrings.sVariable, third, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, pointsUnsorted[third], gS_ChatStrings.sText);
			Shavit_PrintToChatAll("%s%N%s came in %sfourth%s place with %s%.0f%s points!", gS_ChatStrings.sVariable, fourth, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, pointsUnsorted[fourth], gS_ChatStrings.sText);
			Shavit_PrintToChatAll("%s%N%s came in %sfifth%s place with %s%.0f%s points!", gS_ChatStrings.sVariable, fifth, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, pointsUnsorted[fifth], gS_ChatStrings.sText);
			Shavit_PrintToChatAll("---------------------------------------------------------------");
			Shavit_PrintToChatAll("Thank you for playing %s<3", gS_ChatStrings.sStyle);
		}
	}
}

public Action Command_Reset(int client, int args)
{
	if (AreClientCookiesCached(client))
	{
		SetClientCookie(client, g_hPoints, "0.0");
	}
}

public Action Command_Pool(int client, int args)
{
	Shavit_PrintToChat(client, "---------------------------------------------------------------");
	for (int i; i < sizeof(g_sMaps); i++)
	{
		if (i < g_iNextmap - 1)
		{
			Shavit_PrintToChat(client, "%s%s", gS_ChatStrings.sVariable, g_sMaps[i]);
		}
		else if (i < g_iNextmap)
		{
			Shavit_PrintToChat(client, "%s%s", gS_ChatStrings.sVariable2, g_sMaps[i]);
		}
		else
		{
			Shavit_PrintToChat(client, "%s%s", gS_ChatStrings.sStyle, g_sMaps[i]);
		}
	}
	Shavit_PrintToChat(client, "---------------------------------------------------------------");
}
