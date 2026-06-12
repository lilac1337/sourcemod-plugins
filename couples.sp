#include <clientprefs>
#include <sdktools>
#include <sourcemod>

#include <shavit/core>
#include <shavit/rankings>
#include <shavit/wr>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

bool gB_Queried[MAXPLAYERS + 1];
int  gI_Proposer[MAXPLAYERS + 1];
bool gB_Married[MAXPLAYERS + 1];
int  gI_Spouse[MAXPLAYERS + 1];
char gS_Spouse[MAXPLAYERS + 1][32 + 1];
int  gI_ResultIndex;

// Database gH_Database = null;
Database shavitdb = null;
char     gS_ShavitPrefix[32];

chatstrings_t gS_ChatStrings;

public Plugin myinfo =
{
	name        = "couples",
	author      = "may and rtldg",    // puff did all the hard stuff @_@
	description = "i love kaworu (fuck u puff)",
	version     = PLUGIN_VERSION,
	url         = "Your website URL/AlliedModders profile URL"
};

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStringsStruct(gS_ChatStrings);
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_marry", Command_Marry, "");
	RegConsoleCmd("sm_divorce", Command_Divorce, "");
	RegConsoleCmd("sm_couples", Command_Couples, "");
	RegConsoleCmd("sm_accept", Command_Accept, "");
	RegConsoleCmd("sm_reject", Command_Reject, "");

	RegConsoleCmd("sm_couplesdebug", Command_Debug, "");

	LoadTranslations("common.phrases");
	SetUpDB();
}

void SetUpDB()
{
	GetTimerSQLPrefix(gS_ShavitPrefix, 32);
	shavitdb = GetTimerDatabaseHandle();

	SQL_Query(shavitdb, "CREATE TABLE IF NOT EXISTS couples (steamid INT, spouseid INT, points FLOAT, timestamp INT)");
}

public void OnClientConnected(int client)
{
	gB_Queried[client]   = false;
	gB_Married[client]   = false;
	gI_Proposer[client]  = 0;
	gS_Spouse[client][0] = '\0';
	gI_Spouse[client]    = 0;
}

public void OnClientDisconnect(int client)
{
	for (int i = 0; i < MaxClients; i++)
	{
		if (gI_Proposer[i] == client)
			gI_Proposer[i] = 0;
	}
}

public void OnClientAuthorized(int client)
{
	if (!IsFakeClient(client))
	{
		int  steamid = GetSteamAccountID(client);
		char query[512];
		FormatEx(query, sizeof(query),
		         "SELECT * FROM couples WHERE steamid = %d OR spouseid = %d",
		         steamid, steamid);
		shavitdb.Query(SQL_GetSpouse, query, GetClientSerial(client));
	}
}

public Action Command_Marry(int client, int args)
{
	if (!gB_Queried[client]) return Plugin_Handled;
	// if (args < 1) return Plugin_Handled;

	char name[32 + 1];
	GetCmdArgString(name, sizeof(name));

	int target = FindTarget(client, name, true, false);

	if (target == -1)
	{
		// PrintToChat(client, "no matching client found");
		return Plugin_Handled;
	}

	if (!IsClientAuthorized(target) || !gB_Queried[target])
	{
		PrintToChat(client, "%N isn't authorized...", target);
		return Plugin_Handled;
	}

	if (gB_Married[target])
	{
		PrintToChat(client, "%sthe person you love is already married to %s%s", gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_Spouse[target]);
		return Plugin_Handled;
	}

	if (gB_Married[client])
	{
		PrintToChat(client, "%syou are already married to %s%s", gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_Spouse[client]);
		return Plugin_Handled;
	}

	if (target == client)
	{
		PrintToChat(client, "%syou can't marry yourself!", gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_Spouse[client]);
		return Plugin_Handled;
	}

	gI_Proposer[target] = client;

	PrintToChat(client, "%syou've sent a request to %s%N", gS_ChatStrings.sText, gS_ChatStrings.sStyle, target);
	PrintToChat(target, "%syou've received a marriage proposal from %s%N%s, accept it with %s!accept%s or decline with %s!reject", gS_ChatStrings.sText, gS_ChatStrings.sStyle, client, gS_ChatStrings.sText, gS_ChatStrings.sWarning, gS_ChatStrings.sText, gS_ChatStrings.sWarning);

	return Plugin_Handled;
}

public Action Command_Divorce(int client, int args)
{
	if (gB_Queried[client] && gB_Married[client])
	{
		PrintToChatAll("%s%N%s just divorced %s%s%s ;w; %s</3", gS_ChatStrings.sVariable, client, gS_ChatStrings.sText, gS_ChatStrings.sVariable, gS_Spouse[client], gS_ChatStrings.sText, gS_ChatStrings.sStyle);

		char query[512];
		FormatEx(query, sizeof(query),
		         "DELETE FROM couples WHERE steamid = %i OR spouseid = %i",
		         GetSteamAccountID(client), GetSteamAccountID(client));

		shavitdb.Query(SQL_Divorce, query, GetClientSerial(client));

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsValidClient(i) && GetSteamAccountID(i) == gI_Spouse[client])
			{
				gB_Married[i] = false;
				gI_Spouse[i]  = 0;
			}
		}
		gB_Married[client] = false;
		gI_Spouse[client]  = 0;
	}
	else
	{
		PrintToChat(client, "%syou are not married ;w;", gS_ChatStrings.sText);
	}
}

public Action Command_Couples(int client, int args)
{
	char query[512];
	FormatEx(query, sizeof(query), "SELECT u1.name, u2.name, steamid, spouseid, FORMAT(c.points, 2), timestamp FROM couples c JOIN users u1 ON u1.auth = steamid JOIN users u2 ON u2.auth = spouseid ORDER BY c.points DESC LIMIT 100;");

	shavitdb.Query(SQL_Couples, query, GetClientSerial(client));
}

public Action Command_Accept(int client, int args)
{
	int proposer = gI_Proposer[client];

	if (!proposer)
	{
		PrintToChat(client, "%syou have no current proposals", gS_ChatStrings.sText);
		return Plugin_Handled;
	}

	PrintToChat(client, "%syou're now married to %s%N%s <3", gS_ChatStrings.sText, gS_ChatStrings.sVariable, proposer, gS_ChatStrings.sStyle);
	PrintToChat(proposer, "%syou're now married to %s%N%s <3", gS_ChatStrings.sText, gS_ChatStrings.sVariable, client, gS_ChatStrings.sStyle);

	PrintToChatAll("%s%N%s and %s%N%s are now married!! ^w^", gS_ChatStrings.sVariable, proposer, gS_ChatStrings.sText, gS_ChatStrings.sVariable, client, gS_ChatStrings.sText);

	char query[512];
	FormatEx(query, sizeof(query),
	         "INSERT INTO couples (steamid, spouseid, points, timestamp) VALUES (%i, %i, %f, %i)",
	         GetSteamAccountID(proposer), GetSteamAccountID(client), 0.0, GetTime());

	gB_Married[client]    = true;
	gB_Married[proposer]  = true;
	gI_Proposer[client]   = 0;    // clear our proposals too
	gI_Proposer[proposer] = 0;    // clear out any proposals they have because they're married too...
	gI_Spouse[client]     = GetSteamAccountID(proposer);
	gI_Spouse[proposer]   = GetSteamAccountID(client);
	GetClientName(client, gS_Spouse[proposer], 32);
	GetClientName(proposer, gS_Spouse[client], 32);

	shavitdb.Query(SQL_InsertMarriage, query, GetClientSerial(client));

	return Plugin_Handled;
}

public Action Command_Reject(int client, int args)
{
	PrintToChat(gI_Proposer[client], "%syou've been rejected ;w;", gS_ChatStrings.sText);
	PrintToChat(client, "%syou've rejected %s%N%s </3", gS_ChatStrings.sText, gS_ChatStrings.sVariable, gI_Proposer[client], gS_ChatStrings.sStyle);

	gI_Proposer[client] = 0;

	return Plugin_Handled;
}

public Action Command_Debug(int client, int args)
{
	char stylestrings[64];
	Shavit_GetStyleStrings(Shavit_GetBhopStyle(client), sSpecialString, stylestrings, sizeof(stylestrings));
	PrintToChat(client, "ghjk: %i %i %i %i", gB_Queried[client], gB_Married[client], !Shavit_IsPracticeMode(client), StrContains(stylestrings, "segments", false) == -1);

	return Plugin_Handled;
}

public void Shavit_OnFinish(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldtime, float perfs, float avgvel, float maxvel, int timestamp)
{
	char stylestrings[64];
	Shavit_GetStyleStrings(style, sSpecialString, stylestrings, sizeof(stylestrings));
//	PrintToChat(client, "%d %d %d %d %d", gB_Queried[client], gB_Married[client], !Shavit_IsPracticeMode(client), (StrContains(stylestrings, "segments", false) == -1), (oldtime == 0) ? true : (oldtime > time));
	if (gB_Queried[client] && gB_Married[client] && !Shavit_IsPracticeMode(client) && StrContains(stylestrings, "segments", false) == -1 && (oldtime == 0) ? true : (oldtime > time))
	{
		char query[512], map[32];
		float wr = (Shavit_GetWorldRecord(style, track) == 0.0) ? time : Shavit_GetWorldRecord(style, track);
		GetCurrentMap(map, sizeof(map));
		//PrintToChat(client, "%N %f", client, Shavit_GuessPointsForTime(track, style, Shavit_GetMapTier(map), time, wr));

		FormatEx(query, sizeof(query),
		         "UPDATE couples SET points = points + %f where steamid = %i OR spouseid = %i",
		         Shavit_GuessPointsForTime(track, style, Shavit_GetMapTier(map), time, wr), GetSteamAccountID(client), GetSteamAccountID(client));

		shavitdb.Query(SQL_UpdatePoints, query, GetClientSerial(client));
	}
}

void SQL_GetSpouse(Database db, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_GetSpouse error: '%s'", error);
		return;
	}

	int client = GetClientFromSerial(serial);
	if (client < 1) return;

	gB_Queried[client] = true;

	if (results.FetchRow())
	{
		int a = results.FetchInt(0);
		int b = results.FetchInt(1);

		int spouseid       = (a == GetSteamAccountID(client)) ? b : a;
		gI_Spouse[client]  = spouseid;
		gB_Married[client] = true;

		char namequery[512];
		FormatEx(namequery, sizeof(namequery),
		         "SELECT auth, name FROM %susers WHERE auth = %d;",
		         gS_ShavitPrefix, spouseid);
		shavitdb.Query(SQL_SpouseNameQuery, namequery, serial);
	}
}

void SQL_SpouseNameQuery(Database db, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_SpouseNameQuery error: '%s'", error);
		return;
	}

	int client = GetClientFromSerial(serial);
	if (client < 1) return;

	if (results.FetchRow())
	{
		int auth = results.FetchInt(0);
		if (auth == gI_Spouse[client])
		{
			results.FetchString(1, gS_Spouse[client], 32);
		}
	}
}

void SQL_InsertMarriage(Database db, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_InsertMarriage error: '%s'", error);
		return;
	}

	// fuck it, don't care to do anything other than log errors here
}

void SQL_UpdatePoints(Database db, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_UpdatePoints error: '%s'", error);
		return;
	}

	PrintToChatAll("%s", error);

	// fuck it, don't care to do anything other than log errors here
}

void SQL_Divorce(Database db, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_Divorce error: '%s'", error);
		return;
	}

	// fuck it, don't care to do anything other than log errors here
}

void SQL_Couples(Database db, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_Couples error: '%s'", error);
		return;
	}

	int client = GetClientFromSerial(serial);
	if (client < 1) return;

	Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	menu.SetTitle("Top couples ^w^");
	while (results.FetchRow())
	{
		gI_ResultIndex++;
		char result[128], name[32], name1[32], points[32], time[64];
		results.FetchString(0, name, sizeof(name));
		results.FetchString(1, name1, sizeof(name1));
		results.FetchString(4, points, sizeof(points));
		FormatTime(time, sizeof(time), "%x", results.FetchInt(5));
		Format(result, sizeof(result), "#%i | %s & %s: %s points (%s)", gI_ResultIndex, name, name1, points, time);

		menu.AddItem("", result, ITEMDRAW_RAWLINE);
	}

	menu.ExitButton = true;
	menu.Display(client, 9999999999999999);

	gI_ResultIndex = 0;
}

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
}
