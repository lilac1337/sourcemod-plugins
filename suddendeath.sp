#include <clientprefs>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#include <bhopstats>
#include <shavit/core>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

int g_iGroundTicks[MAXPLAYERS + 1];

Handle g_hSuddenDeathEnabled;

public Plugin myinfo =
{
	name        = "sudden death",
	author      = "kaworu from neon genesis evangelion",
	description = "Brief description of plugin functionality here!",
	version     = PLUGIN_VERSION,
	url         = "Your website URL/AlliedModders profile URL"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_suddendeath", Command_SuddenDeath, "i'm gay");

	HookEvent("player_jump", Event_PlayerJump, EventHookMode);

	g_hSuddenDeathEnabled = RegClientCookie("suddendeath_enabled", "Sudden Death Enabled", CookieAccess_Protected);
}

public Action Command_SuddenDeath(int client, int args)
{
	if (AreClientCookiesCached(client))
	{
		char sCookieValue[12];
		GetClientCookie(client, g_hSuddenDeathEnabled, sCookieValue, sizeof(sCookieValue));
		int cookieValue = StringToInt(sCookieValue);
		switch (cookieValue)
		{
			case 0:
			{
				cookieValue++;

				Shavit_PrintToChat(client, "Sudden Death has been enabled.");
			}
			case 1:
			{
				cookieValue--;

				Shavit_PrintToChat(client, "Sudden Death has been disabled.");
			}
		}

		IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));

		SetClientCookie(client, g_hSuddenDeathEnabled, sCookieValue);
	}

	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	char sCookieValue[12];
	GetClientCookie(client, g_hSuddenDeathEnabled, sCookieValue, sizeof(sCookieValue));
	int cookieValue = StringToInt(sCookieValue);

	if (cookieValue)
	{
		if (Bunnyhop_IsOnGround(client) && Shavit_GetClientTime(client) > 0.1)
		{
			g_iGroundTicks[client]++;
			if (g_iGroundTicks[client] > 1) Shavit_RestartTimer(client, Shavit_GetClientTrack(client));
		}
	}
}

public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	g_iGroundTicks[client] = 0;
}
