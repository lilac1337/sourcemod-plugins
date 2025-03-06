#include <clientprefs>
#include <sdktools>
#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools_functions>

#pragma semicolon 1
#pragma newdecls required

#define ZONE_START 0
#define ZONE_END   1

/*
	---------- we love oop ----------
*/

enum struct ReplayFrame
{
	float pos[3];
	float viewAngles[3];

	int	  buttons;
	int	  flags;
	int	  mouse[2];
	int	  time;
}

enum struct PlayerData
{
	bool	  timerRunning;
	bool	  lastTickInStart;

	int		  completions;
	int		  pb;
	int		  perfs;
	int		  points;
	int		  jumps;
	int		  strafes;
	int		  ticksOnGround;
	int		  time;
	int		  zoningState;

	float	  zoningStartPoint1[3];
	float	  zoningStartPoint2[3];
	float	  zoningEndPoint1[3];
	float	  zoningEndPoint2[3];
	float	  velocity;

	ArrayList replayFrames;
}

enum struct MapData
{
	int		  tier;
	int		  completions;
	int		  wr;

	char	  wrHolder[64];
	char	  replayHolder[64];

	ArrayList wrReplayFrames;
}

enum struct Zone
{
	float point1[3];
	float point2[3];
}

/*
	---------- global vars ----------
*/

PlayerData player[MAXPLAYERS + 1];
MapData	   map;
Zone	   zones[2];
Database   db							   = null;

char	   pink[16]						   = "\x07FEC8D8";

int		   gI_WRMenuIndex[MAXPLAYERS + 1]  = 0;
int		   gI_TopMenuIndex[MAXPLAYERS + 1] = 0;
int		   gI_Bot						   = 0;
int		   gI_BotFrame					   = 0;

public Plugin myinfo =
{
	name		= "kawaii timer",
	author		= "may",
	description = "i love kaworu",
	version		= "PLUGIN_VERSION",
	url			= "https://github.com/lilac1337"
};

/*
	---------- timer funcs ----------
*/

bool isInZone(int client, int zone)
{
	float pos[3];

	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);

	switch (zone)
	{
		case ZONE_START:
		{
			return ((pos[0] > zones[ZONE_START].point1[0] && pos[0] < zones[ZONE_START].point2[0]) && (pos[1] < zones[ZONE_START].point1[1] && pos[1] > zones[ZONE_START].point2[1]) && (pos[2] >= (zones[ZONE_START].point1[2] - 1.0) && (pos[2] < zones[ZONE_START].point1[2] + 128.0)));
		}
		case ZONE_END:
		{
			return ((pos[0] > zones[ZONE_END].point1[0] && pos[0] < zones[ZONE_END].point2[0]) && (pos[1] < zones[ZONE_END].point1[1] && pos[1] > zones[ZONE_END].point2[1]) && (pos[2] >= (zones[ZONE_END].point1[2] - 1.0) && (pos[2] < zones[ZONE_END].point1[2] + 128.0)));
		}
	}

	return false;
}

float get2dVel(int client)
{
	float absVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", absVelocity);

	return SquareRoot(absVelocity[0] * absVelocity[0] + absVelocity[1] * absVelocity[1]);
}

char formatSeconds(int time, bool percise = false)
{
	char buffer[16];

	if (!time)
	{
		Format(buffer, sizeof(buffer), "N/A");

		return buffer;
	}

	int seconds = RoundToFloor(time * GetTickInterval());
	int minutes = RoundToFloor(seconds / 60.0);

	Format(buffer, sizeof(buffer), "%d:%s%d", minutes, (seconds % 60 < 10 ? "0" : ""), seconds % 60);

	if (percise)
	{
		char decimalBuffer[5];
		FloatToString(FloatFraction(time * GetTickInterval()), decimalBuffer, sizeof(decimalBuffer));
		Format(buffer, sizeof(buffer), "%s%s", buffer, decimalBuffer[1]);
	}

	return buffer;
}

void drawKeyText(int client)
{
	char keyText[256];

	Format(keyText, sizeof(keyText), "WR Holder: %s\n\nTier: %d\n\nWR: %s\nPB: %s\n\nCollective Completions: %d\nPersonal Completions: %d",
		   map.wrHolder, map.tier, formatSeconds(map.wr, true), formatSeconds(player[client].pb, true), map.completions, player[client].completions);

	Handle hKeyHintText = StartMessageOne("KeyHintText", client);
	BfWriteByte(hKeyHintText, 1);
	BfWriteString(hKeyHintText, keyText);
	EndMessage();
}

void drawHud(int client)
{
	int target = client;

	if (IsClientObserver(client))
		target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

	if (target < 0)
		return;

	char  hint[256];

	float perfRate = (player[target].perfs / float((player[target].jumps <= 1) ? 1 : player[target].jumps - 1) * 100.0);

	Format(hint, sizeof(hint), "Time: %s\nVel: %.1f\nJumps: %d\nPerfs: %.1f％", formatSeconds(player[target].time), player[target].velocity, player[target].jumps, perfRate);

	if (!player[target].timerRunning)
		Format(hint, sizeof(hint), "Timer not running");

	if (isInZone(target, ZONE_START) || isInZone(target, ZONE_END))
		Format(hint, sizeof(hint), "In Zone");

	if (target == gI_Bot && gI_BotFrame)
	{
		Format(hint, sizeof(hint), "Time: %s\nRun: %.1f％", formatSeconds(gI_BotFrame), float(gI_BotFrame) / float(map.wrReplayFrames.Length) * 100.0);

		if (!map.wrReplayFrames.Length)
			Format(hint, sizeof(hint), "no replay file!! ;w;");
	}

	PrintHintText(client, "%s", hint);
}

void drawZones(int client)
{
	int	  laser = PrecacheModel("materials/shavit/zone_beam.vmt", true);

	float points[2][4][3];
	int	  color[2][4] = {
		  {238,	 130, 238, 200},
		  { 135, 206, 250, 200}
	};

	for (int i = 0; i < 2; i++)
	{
		points[i][0]	= zones[i].point1;
		points[i][1][0] = zones[i].point1[0];
		points[i][1][1] = zones[i].point2[1];
		points[i][1][2] = zones[i].point1[2];
		points[i][2]	= zones[i].point2;
		points[i][3][0] = zones[i].point2[0];
		points[i][3][1] = zones[i].point1[1];
		points[i][3][2] = zones[i].point1[2];

		for (int j = 0; j <= 3; j++)
		{
			TE_SetupBeamPoints(points[i][j], points[i][(j >= 3) ? 0 : j + 1], laser, 0, 0, 1, GetTickInterval() * 100.0, 2.0, 1.0, 0, 0.0, color[i], 15);
			TE_SendToClient(client, 0.0);
		}
	}
}

void normalizeZones(float point1[3], float point2[3])
{
	if (point1[0] < point2[0] && point1[1] > point2[1])
		return;

	float pointBuffer[3];

	if (point1[0] > point2[0] && point1[1] < point2[1])
	{
		pointBuffer = point1;
		point1		= point2;
		point2		= pointBuffer;

		return;
	}

	// 3297 802 1856 ~ 3486 990 1856
	if (point1[0] < point2[0] && point1[1] < point2[1])
	{
		pointBuffer = point1;
		point1[1]	= point2[1];
		point2[1]	= pointBuffer[1];

		return;
	}

	if (point1[0] > point2[0] && point1[1] > point2[1])
	{
		pointBuffer = point1;
		point1[0]	= point2[0];
		point2[0]	= pointBuffer[0];

		return;
	}

	return;
}

void onLeave(int client)
{
	if (player[client].velocity >= 290)
	{
		float origin[3];

		origin[0] = (zones[ZONE_START].point2[0] - zones[ZONE_START].point1[0]) / 2 + zones[ZONE_START].point1[0];
		origin[1] = (zones[ZONE_START].point1[1] - zones[ZONE_START].point2[1]) / 2 + zones[ZONE_START].point2[1];
		origin[2] = zones[ZONE_START].point1[2] + 64.0;

		TeleportEntity(client, origin, NULL_VECTOR, { 0.0, 0.0, 0.0 });
		resetPlayer(client, false);

		return;
	}

	player[client].timerRunning = true;
}

void onFinish(int client)
{
	// PrintToChat(client, "%d", player[client].replayFrames.Length);

	if (!IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client))
		return;

	if (player[client].time < map.wr || !map.wr)
		PrintToChatAll("%snew wr!!!", pink);

	if (player[client].time < player[client].pb || !player[client].pb)
	{
		player[client].pb = player[client].time;

		PrintToChatAll("%s%N finished the map in %s", pink, client, formatSeconds(player[client].time, true));
	}

	if (player[client].time < map.wr || !map.wr)
	{
		map.wr = player[client].time;

		GetClientName(client, map.wrHolder, sizeof(map.wrHolder));
	}

	if (!map.wrReplayFrames.Length || map.wrReplayFrames.Length > player[client].time)
	{
		PrintToChat(client, "!map.wrReplayFrames || map.wrReplayFrames.Length > player[client].time");
		delete map.wrReplayFrames;

		char playerName[64], newBotName[64];

		GetClientName(client, playerName, sizeof(playerName));

		map.wrReplayFrames			= player[client].replayFrames;
		map.replayHolder			= playerName;

		player[client].replayFrames = null;

		Format(newBotName, sizeof(newBotName), "(REPLAY) ~ %s: %s", map.replayHolder, formatSeconds(map.wrReplayFrames.Length, true));

		SetClientName(gI_Bot, newBotName);
	}

	player[client].completions++;
	map.completions++;

	char mapName[256], query[512], timeQuery[512];

	GetCurrentMap(mapName, sizeof(mapName));

	FormatEx(query, sizeof(query),
			 "UPDATE maps SET completions = %d WHERE mapname = '%s'", map.completions, mapName);

	SQL_Query(db, query);

	FormatEx(timeQuery, sizeof(timeQuery),
			 "INSERT INTO times (steamId, time, mapName, date, jumps, perfs, strafes) VALUES (%d, %d, '%s', %d, %d, %d, %d)",
			 GetSteamAccountID(client), player[client].time, mapName, GetTime(), player[client].jumps, player[client].perfs, player[client].strafes);

	SQL_Query(db, timeQuery);

	char error[256];

	SQL_GetError(db, error, sizeof(error));

	PrintToChat(client, "%s", error);

	recalcPoints(client);

	resetPlayer(client, false);
}

void resetPlayer(int client, bool disconnect)
{
	player[client].timerRunning	   = false;
	player[client].lastTickInStart = false;
	player[client].perfs		   = 0;
	player[client].jumps		   = 0;
	player[client].strafes		   = 0;
	player[client].ticksOnGround   = 0;
	player[client].time			   = 0;
	player[client].velocity		   = 0.0;

	delete player[client].replayFrames;

	player[client].replayFrames = new ArrayList(sizeof(ReplayFrame));

	if (IsClientInGame(client) && IsPlayerAlive(client))
		SetEntityGravity(client, 1.0);

	if (disconnect)
	{
		player[client].completions		 = 0;
		player[client].points			 = 0;
		player[client].pb				 = 0;
		player[client].zoningState		 = 0;
		player[client].zoningStartPoint1 = NULL_VECTOR;
		player[client].zoningStartPoint2 = NULL_VECTOR;
		player[client].zoningEndPoint1	 = NULL_VECTOR;
		player[client].zoningEndPoint2	 = NULL_VECTOR;
	}
}

/*
	---------- server callbacks ----------
*/
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (client == gI_Bot && map.wrReplayFrames.Length)
	{
		if (!IsPlayerAlive(client))
			CS_RespawnPlayer(client);

		ReplayFrame curFrame;

		map.wrReplayFrames.GetArray(gI_BotFrame, curFrame, sizeof(ReplayFrame));

		// stolen from btimes lol
		float vVel[3], absOrigin[3];

		GetClientAbsOrigin(client, absOrigin);

		MakeVectorFromPoints(absOrigin, curFrame.pos, vVel);
		ScaleVector(vVel, 1.0 / GetTickInterval());

		SetEntityFlags(gI_Bot, curFrame.flags);
		TeleportEntity(gI_Bot, (gI_BotFrame == 1 || ((FloatAbs(curFrame.pos[0]) - FloatAbs(absOrigin[0]) > 64.0) || (FloatAbs(curFrame.pos[1]) - FloatAbs(absOrigin[1]) > 64.0))) ? curFrame.pos : NULL_VECTOR, curFrame.viewAngles, vVel);

		mouse		= curFrame.mouse;
		buttons		= curFrame.buttons;

		gI_BotFrame = (gI_BotFrame + 1 >= map.wrReplayFrames.Length) ? 0 : gI_BotFrame + 1;	   // THIS DOESNT LOOK RIGHT
	}

	if (!IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client))
		return;

	if (!IsClientObserver(client))
	{
		player[client].velocity = get2dVel(client);

		if (isInZone(client, ZONE_START))
		{
			resetPlayer(client, false);
			player[client].lastTickInStart = true;
		}

		if (isInZone(client, ZONE_END) && player[client].timerRunning)
			onFinish(client);

		if (!isInZone(client, ZONE_START) && !isInZone(client, ZONE_END) && player[client].lastTickInStart)
		{
			onLeave(client);
		}

		if (player[client].timerRunning)
		{
			player[client].time++;

			ReplayFrame curFrame;

			float		absOrigin[3];
			int			flags = GetEntityFlags(client);

			GetClientAbsOrigin(client, absOrigin);

			curFrame.pos		= absOrigin;
			curFrame.viewAngles = angles;
			curFrame.time		= player[client].time;
			curFrame.mouse		= mouse;
			curFrame.buttons	= buttons;
			curFrame.flags		= flags;

			player[client].replayFrames.PushArray(curFrame);
		}

		if (!isInZone(client, ZONE_START)) player[client].lastTickInStart = false;

		int flags = GetEntityFlags(client);

		if (flags & FL_ONGROUND) player[client].ticksOnGround++;
	}

	if (!(cmdnum % 5)) drawHud(client);
	if (!(cmdnum % 100))
	{
		drawZones(client);
		drawKeyText(client);
	}
}

public void OnConfigsExecuted()
{
	ConVar mp_limitteams		 = FindConVar("mp_limitteams");
	ConVar sv_hudhint_sound		 = FindConVar("sv_hudhint_sound");
	ConVar sv_enablebunnyhopping = FindConVar("sv_enablebunnyhopping");
	ConVar sv_airaccelerate		 = FindConVar("sv_airaccelerate");
	ConVar bot_zombie			 = FindConVar("bot_zombie");
	ConVar bot_stop				 = FindConVar("bot_stop");
	ConVar bot_chatter			 = FindConVar("bot_chatter");
	ConVar bot_join_after_player = FindConVar("bot_join_after_player");

	mp_limitteams.SetInt(30);
	sv_hudhint_sound.SetBool(false);
	sv_enablebunnyhopping.SetBool(true);
	sv_airaccelerate.SetFloat(100.0);
	bot_zombie.SetBool(true);
	bot_stop.SetBool(true);
	bot_chatter.SetString("off");
	bot_join_after_player.SetBool(false);
}

public void OnPluginStart()
{
	zones[ZONE_START].point1[0] = 831.97;
	zones[ZONE_START].point1[1] = -193.17;
	zones[ZONE_START].point1[2] = -447.97 - 64.0;

	zones[ZONE_START].point2[0] = 1343.52;
	zones[ZONE_START].point2[1] = -704.37;
	zones[ZONE_START].point2[2] = -447.97 - 64.0;

	RegConsoleCmd("sm_r", restartCommand);
	RegConsoleCmd("sm_start", restartCommand);
	RegConsoleCmd("sm_restart", restartCommand);
	RegConsoleCmd("sm_test", testCommand);
	RegConsoleCmd("sm_spec", setSpec);
	RegConsoleCmd("sm_spectate", setSpec);
	RegConsoleCmd("sm_top", showTop);
	RegConsoleCmd("sm_ranks", showTop);
	RegConsoleCmd("sm_rankings", showTop);
	RegConsoleCmd("sm_wr", showWrs);
	RegConsoleCmd("sm_times", showWrs);
	RegConsoleCmd("sm_glock", giveGlock);
	RegConsoleCmd("sm_usp", giveUsp);

	RegAdminCmd("sm_zone", setupZones, ADMFLAG_RCON);
	RegAdminCmd("sm_settier", setTier, ADMFLAG_RCON);

	HookEvent("bullet_impact", Event_BulletImpact);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_jump", Event_PlayerJump, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

	char error[255];
	db = SQL_Connect("kawaii", true, error, sizeof(error));
	if (!db) LogError(error);
	SQL_Query(db, "CREATE TABLE IF NOT EXISTS maps (mapname VARCHAR(256), tier INT, completions INT)");
	SQL_Query(db, "CREATE TABLE IF NOT EXISTS zones (mapname VARCHAR(256), sp1p1 FLOAT, sp1p2 FLOAT, sp1p3 FLOAT, sp2p1 FLOAT, sp2p2 FLOAT, sp2p3 FLOAT, ep1p1 FLOAT, ep1p2 FLOAT, ep1p3 FLOAT, ep2p1 FLOAT, ep2p2 FLOAT, ep2p3 FLOAT)");
	SQL_Query(db, "CREATE TABLE IF NOT EXISTS users (steamId INT, name VARCHAR(128), points INT, lastLogin INT)");
	SQL_Query(db, "CREATE TABLE IF NOT EXISTS times (steamId INT, time INT, mapName VARCHAR(256), date INT, jumps INT, perfs INT, strafes INT)");
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			resetPlayer(i, true);
	}

	delete map.wrReplayFrames;

	map.wrReplayFrames = new ArrayList(sizeof(ReplayFrame));

	ServerCommand("bot_kick all");
	ServerCommand("bot_add");

	char query[512], zoneQuery[512], wrQuery[512], mapname[256];
	GetCurrentMap(mapname, sizeof(mapname));

	FormatEx(query, sizeof(query),
			 "SELECT * FROM maps WHERE mapname = '%s'",
			 mapname);

	db.Query(SQL_CheckMap, query);

	FormatEx(zoneQuery, sizeof(zoneQuery),
			 "SELECT * FROM zones WHERE mapname = '%s'",
			 mapname);

	db.Query(SQL_CheckZones, zoneQuery);

	FormatEx(wrQuery, sizeof(wrQuery),
			 "SELECT times.time, users.name FROM times INNER JOIN users ON users.steamId=times.steamId WHERE mapname = '%s' ORDER BY times.time ASC LIMIT 1",
			 mapname);

	db.Query(SQL_CheckWR, wrQuery);
}

public void OnClientDisconnect_Post(int client)
{
	resetPlayer(client, true);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

	if (client)
	{
		checkUser(client);
		checkCompletions(client);
		recalcPoints(client);
	}
}

/*
	---------- sql commands ----------
*/

void checkCompletions(int client)
{
	char completionsQuery[512], mapName[128];

	GetCurrentMap(mapName, sizeof(mapName));

	FormatEx(completionsQuery, sizeof(completionsQuery),
			 "SELECT COUNT(times.time) FROM times WHERE mapName = '%s' AND steamId = %d",
			 mapName, GetSteamAccountID(client));

	db.Query(SQL_CheckCompletions, completionsQuery, GetClientSerial(client));
}

void checkUser(int client)
{
	char query[512];

	FormatEx(query, sizeof(query),
			 "SELECT * FROM users WHERE steamId = %d",
			 GetSteamAccountID(client));

	db.Query(SQL_CheckUser, query, GetClientSerial(client));
}

void recalcPoints(int client)
{
	char pointsQuery[512];

	FormatEx(pointsQuery, sizeof(pointsQuery),
			 "SELECT SUM(maps.tier) FROM (SELECT DISTINCT a.mapName FROM kawaii.times AS a WHERE steamId = %d) a INNER JOIN maps ON a.mapName = maps.mapName",
			 GetSteamAccountID(client));

	db.Query(SQL_CheckPoints, pointsQuery, GetClientSerial(client));
}

/*
	---------- sql callbacks ----------
*/

void SQL_CheckCompletions(Database callbackDb, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_CheckCompletions error: '%s'", error);
		return;
	}

	int client = GetClientFromSerial(serial);

	if (results.FetchRow())
	{
		player[client].completions = results.FetchInt(0);
	}
}

void SQL_CheckMap(Database callbackDb, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_CheckMap error: '%s'", error);
		return;
	}

	if (results.FetchRow())
	{
		map.tier		= results.FetchInt(1);
		map.completions = results.FetchInt(2);
	}
	else
	{
		map.tier		= 0;
		map.completions = 0;

		char mapName[256], query[512];

		GetCurrentMap(mapName, sizeof(mapName));

		FormatEx(query, sizeof(query), "INSERT INTO maps (mapname, tier, completions) VALUES ('%s', 0, 0)", mapName);

		SQL_Query(db, query);
	}
}

void SQL_CheckPB(Database callbackDb, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_CheckPB error: '%s'", error);
		return;
	}

	int client = GetClientFromSerial(serial);

	if (results.FetchRow())
	{
		player[client].pb = results.FetchInt(1);
	}
	else
	{
		player[client].pb = 0;
	}
}

void SQL_CheckPoints(Database callbackDb, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_CheckPoints error: '%s'", error);
		return;
	}

	int client = GetClientFromSerial(serial);

	if (results.FetchRow())
	{
		char query[512];

		FormatEx(query, sizeof(query), "UPDATE users SET points = %d WHERE steamId = %d", results.FetchInt(0), GetSteamAccountID(client));

		SQL_Query(db, query);

		player[client].points = results.FetchInt(0);
	}
	else
	{
		player[client].points = 0;
	}
}

void SQL_CheckUser(Database callbackDb, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_CheckUser error: '%s'", error);
		return;
	}

	int	 client = GetClientFromSerial(serial);

	char query[512], name[128];
	int	 steamId   = GetSteamAccountID(client);
	int	 lastLogin = GetTime();
	GetClientName(client, name, sizeof(name));

	if (results.FetchRow())
	{
		FormatEx(query, sizeof(query), "UPDATE users SET name = '%s', lastLogin = %d WHERE steamId = %d", name, lastLogin, steamId);

		char pbQuery[512], mapName[128];

		GetCurrentMap(mapName, sizeof(mapName));

		FormatEx(pbQuery, sizeof(pbQuery), "SELECT * FROM times WHERE steamId = %d AND mapName = '%s' ORDER BY time ASC", steamId, mapName);

		db.Query(SQL_CheckPB, pbQuery, GetClientSerial(client));
	}
	else
	{
		FormatEx(query, sizeof(query), "INSERT INTO users (steamId, name, points, lastLogin) VALUES (%d, '%s', 0, %d)", steamId, name, lastLogin);
	}

	SQL_Query(db, query);
}

void SQL_CheckWR(Database callbackDb, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_CheckWR error: '%s'", error);
		return;
	}

	if (results.FetchRow())
	{
		map.wr = results.FetchInt(0);

		results.FetchString(1, map.wrHolder, sizeof(map.wrHolder));
	}
	else
	{
		Format(map.wrHolder, sizeof(map.wrHolder), "N/A");
		map.wr = 0;
	}
}

void SQL_CheckZones(Database callbackDb, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_CheckZones error: '%s'", error);
		return;
	}

	if (results.FetchRow())
	{
		zones[0].point1[0] = results.FetchFloat(1);
		zones[0].point1[1] = results.FetchFloat(2);
		zones[0].point1[2] = results.FetchFloat(3);

		zones[0].point2[0] = results.FetchFloat(4);
		zones[0].point2[1] = results.FetchFloat(5);
		zones[0].point2[2] = results.FetchFloat(6);

		zones[1].point1[0] = results.FetchFloat(7);
		zones[1].point1[1] = results.FetchFloat(8);
		zones[1].point1[2] = results.FetchFloat(9);

		zones[1].point2[0] = results.FetchFloat(10);
		zones[1].point2[1] = results.FetchFloat(11);
		zones[1].point2[2] = results.FetchFloat(12);
	}
	else
	{
		zones[0].point1[0] = 0.0;
		zones[0].point1[1] = 0.0;
		zones[0].point1[2] = 0.0;

		zones[0].point2[0] = 0.0;
		zones[0].point2[1] = 0.0;
		zones[0].point2[2] = 0.0;

		zones[1].point1[0] = 0.0;
		zones[1].point1[1] = 0.0;
		zones[1].point1[2] = 0.0;

		zones[1].point2[0] = 0.0;
		zones[1].point2[1] = 0.0;
		zones[1].point2[2] = 0.0;

		char mapName[256], query[512];

		GetCurrentMap(mapName, sizeof(mapName));

		FormatEx(query, sizeof(query), "INSERT INTO zones (mapname, sp1p1, sp1p2, sp1p3, sp2p1, sp2p2, sp2p3, ep1p1, ep1p2, ep1p3, ep2p1, ep2p2, ep2p3) VALUES ('%s', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)", mapName);

		SQL_Query(db, query);
	}
}

void SQL_Top(Database callbackDb, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_Top error: '%s'", error);
		return;
	}

	int client = GetClientFromSerial(serial);
	if (client < 1) return;

	Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	menu.SetTitle("Top 100 players");

	while (results.FetchRow())
	{
		gI_TopMenuIndex[client]++;
		char result[128], playerName[64], date[64];

		results.FetchString(1, playerName, sizeof(playerName));

		FormatTime(date, sizeof(date), "%x", results.FetchInt(3));

		Format(result, sizeof(result), "#%d | %s ~ %d points (last seen: %s)", gI_TopMenuIndex[client], playerName, results.FetchInt(2), date);

		menu.AddItem("", result, ITEMDRAW_RAWLINE);
	}

	menu.ExitButton = true;
	menu.Display(client, 9999999999999999);

	gI_TopMenuIndex[client] = 0;
}

void SQL_WRs(Database callbackDb, DBResultSet results, const char[] error, int serial)
{
	if (results == null)
	{
		LogError("SQL_WRs error: '%s'", error);
		return;
	}

	int client = GetClientFromSerial(serial);
	if (client < 1) return;

	char mapName[128];

	GetCurrentMap(mapName, sizeof(mapName));

	Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	menu.SetTitle("Top 100 times for %s", mapName);
	while (results.FetchRow())
	{
		gI_WRMenuIndex[client]++;
		char result[128], playerName[64];

		results.FetchString(5, playerName, sizeof(playerName));

		Format(result, sizeof(result), "#%d | %s ~ %s (%d jumps)", gI_WRMenuIndex[client], playerName, formatSeconds(results.FetchInt(0), true), results.FetchInt(2));

		menu.AddItem("", result, ITEMDRAW_RAWLINE);
	}

	menu.ExitButton = true;
	menu.Display(client, 9999999999999999);

	gI_WRMenuIndex[client] = 0;
}

/*
	---------- menu handlers ----------
*/
public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
}

/*
	---------- event callbacks ----------
*/
public Action Event_BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	// FIXME: sometimes this gets fired twice????
	int	 client = GetClientOfUserId(event.GetInt("userid"));

	// PrintToChat(client, "bullet impact %1.f %1.f %1.f %d", event.GetFloat("x"), event.GetFloat("y"), event.GetFloat("z"), player[client].zoningState);
	// PrintToChat(client, "%d", gI_Bot);
	char mapName[256], query[512];

	GetCurrentMap(mapName, sizeof(mapName));

	switch (player[client].zoningState)
	{
		case 0:
			return;
		case 1:
		{
			player[client].zoningStartPoint1[0] = event.GetFloat("x");
			player[client].zoningStartPoint1[1] = event.GetFloat("y");
			player[client].zoningStartPoint1[2] = event.GetFloat("z");

			PrintToChat(client, "please shoot the next point");

			player[client].zoningState++;
		}
		case 2:
		{
			player[client].zoningStartPoint2[0] = event.GetFloat("x");
			player[client].zoningStartPoint2[1] = event.GetFloat("y");
			player[client].zoningStartPoint2[2] = event.GetFloat("z");

			normalizeZones(player[client].zoningStartPoint1, player[client].zoningStartPoint2);

			zones[ZONE_START].point1 = player[client].zoningStartPoint1;
			zones[ZONE_START].point2 = player[client].zoningStartPoint2;

			FormatEx(query, sizeof(query), "UPDATE zones SET sp1p1 = %f, sp1p2 = %f, sp1p3 = %f, sp2p1 = %f, sp2p2 = %f, sp2p3 = %f WHERE mapname = '%s'",
					 zones[ZONE_START].point1[0], zones[ZONE_START].point1[1], zones[ZONE_START].point1[2], zones[ZONE_START].point2[0], zones[ZONE_START].point2[1], zones[ZONE_START].point2[2], mapName);

			SQL_Query(db, query);

			PrintToChat(client, "successfully zoned start");

			player[client].zoningState = 0;
		}
		case 3:
		{
			player[client].zoningEndPoint1[0] = event.GetFloat("x");
			player[client].zoningEndPoint1[1] = event.GetFloat("y");
			player[client].zoningEndPoint1[2] = event.GetFloat("z");

			PrintToChat(client, "please shoot the next point");

			player[client].zoningState++;
		}
		case 4:
		{
			player[client].zoningEndPoint2[0] = event.GetFloat("x");
			player[client].zoningEndPoint2[1] = event.GetFloat("y");
			player[client].zoningEndPoint2[2] = event.GetFloat("z");

			normalizeZones(player[client].zoningEndPoint1, player[client].zoningEndPoint2);

			zones[ZONE_END].point1 = player[client].zoningEndPoint1;
			zones[ZONE_END].point2 = player[client].zoningEndPoint2;

			FormatEx(query, sizeof(query), "UPDATE zones SET ep1p1 = %f, ep1p2 = %f, ep1p3 = %f, ep2p1 = %f, ep2p2 = %f, ep2p3 = %f WHERE mapname = '%s'",
					 zones[ZONE_END].point1[0], zones[ZONE_END].point1[1], zones[ZONE_END].point1[2], zones[ZONE_END].point2[0], zones[ZONE_END].point2[1], zones[ZONE_END].point2[2], mapName);

			SQL_Query(db, query);

			PrintToChat(client, "successfully zoned end");

			player[client].zoningState = 0;
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsFakeClient(client) && event.GetInt("team") == CS_TEAM_T)
	{
		ChangeClientTeam(client, CS_TEAM_CT);

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	player[client].jumps++;

	if (player[client].ticksOnGround == 1) player[client].perfs++;

	player[client].ticksOnGround = 0;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && !IsClientSourceTV(i))
			gI_Bot = i;
	}

	if (!gI_Bot)
	{
		ServerCommand("bot_add");

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && !IsClientSourceTV(i))
				gI_Bot = i;
		}
	}

	CS_RespawnPlayer(gI_Bot);
	SetClientName(gI_Bot, "(REPLAY) ~ no time");
}

public Action OnTakeDamage(int victim, int &attacker)
{
	return Plugin_Handled;
}

/*
	---------- command callbacks ----------
*/

Action restartCommand(int client, int args)
{
	if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
		ChangeClientTeam(client, CS_TEAM_CT);

	if (!IsPlayerAlive(client))
		CS_RespawnPlayer(client);

	float origin[3];

	origin[0] = (zones[ZONE_START].point2[0] - zones[ZONE_START].point1[0]) / 2 + zones[ZONE_START].point1[0];
	origin[1] = (zones[ZONE_START].point1[1] - zones[ZONE_START].point2[1]) / 2 + zones[ZONE_START].point2[1];
	origin[2] = zones[ZONE_START].point1[2] + 64.0;

	TeleportEntity(client, origin, NULL_VECTOR, { 0.0, 0.0, 0.0 });
	resetPlayer(client, false);
}

Action testCommand(int client, int args)
{
	ReplayFrame curFrame;
	char		sPath[PLATFORM_MAX_PATH], mapName[128], steamId[32];

	GetCurrentMap(mapName, sizeof(mapName));

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/kawaii/%s.kawaii", mapName);

	if (!FileExists(sPath))
		return;

	File file = OpenFile(sPath, "rb");

	file.ReadLine(steamId, sizeof(steamId));

	delete map.wrReplayFrames;

	map.wrReplayFrames = new ArrayList(sizeof(ReplayFrame));

	for (int i = 0; i < map.wrReplayFrames.Length; i++)
	{
		gI_BotFrame = 0;
		file.Read(curFrame, sizeof(ReplayFrame), 4);
		map.wrReplayFrames.PushArray(curFrame);
	}

	map.replayHolder = steamId;

	SetClientName(gI_Bot, steamId);

	PrintToChat(client, "map.wrReplayFrames.Length: %d", map.wrReplayFrames.Length);

	file.Close();

	/*ReplayFrame curFrame;
	char		sPath[PLATFORM_MAX_PATH], mapName[128];

	GetCurrentMap(mapName, sizeof(mapName));

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/kawaii/%s.kawaii", mapName);

	if (FileExists(sPath))
		DeleteFile(sPath);

	File file = OpenFile(sPath, "wb");

	file.WriteLine("%d", GetSteamAccountID(client));

	for (int i = 0; i < map.wrReplayFrames.Length; i++)
	{
		map.wrReplayFrames.GetArray(i, curFrame, sizeof(ReplayFrame));
		file.Write(curFrame, sizeof(ReplayFrame), 4);
	}
	
	file.Close();
	*/
}

Action setupZones(int client, int args)
{
	char arg[128];

	GetCmdArgString(arg, sizeof(arg));

	player[client].zoningState = (StrContains(arg, "end", false) == -1) ? 1 : 3;

	PrintToChat(client, "please shoot the first point");
}

Action setSpec(int client, int args)
{
	ChangeClientTeam(client, CS_TEAM_SPECTATOR);
}

Action setTier(int client, int args)
{
	char arg[128];

	GetCmdArgString(arg, sizeof(arg));

	map.tier = StringToInt(arg);

	char mapName[256], query[512];

	GetCurrentMap(mapName, sizeof(mapName));

	FormatEx(query, sizeof(query), "UPDATE maps SET tier = %d WHERE mapname = '%s'", map.tier, mapName);

	SQL_Query(db, query);
}

Action showTop(int client, int args)
{
	char query[512];

	FormatEx(query, sizeof(query), "SELECT * FROM users ORDER BY users.points DESC LIMIT 100;");

	db.Query(SQL_Top, query, GetClientSerial(client));
}

Action showWrs(int client, int args)
{
	char query[512], mapName[128];

	GetCurrentMap(mapName, sizeof(mapName));

	FormatEx(query, sizeof(query), "SELECT times.time, times.date, times.jumps, times.perfs, times.strafes, users.name FROM times INNER JOIN users ON users.steamId=times.steamId WHERE mapname = '%s' ORDER BY times.time ASC LIMIT 100;", mapName);

	db.Query(SQL_WRs, query, GetClientSerial(client));
}

Action giveGlock(int client, int args)
{
	GivePlayerItem(client, "weapon_glock");
}

Action giveUsp(int client, int args)
{
	GivePlayerItem(client, "weapon_usp");
}