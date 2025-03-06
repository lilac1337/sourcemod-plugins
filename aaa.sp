#include <clientprefs>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#include <bhopstats>
#include <shavit/core>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

int g_iEarlyTicks[MAXPLAYERS + 1];
int g_iLateTicks[MAXPLAYERS + 1];
int g_iPerfed[MAXPLAYERS + 1];
int g_iFlopped[MAXPLAYERS + 1];    // av🥑cado — Today at 6:27 PM Okay, I, as the authority on scroll, have decided to call it a "flop".
int g_iGroundTicks[MAXPLAYERS + 1];
int g_iLastCmdnumOrSomeShit[MAXPLAYERS + 1];    // my brain is fried rn and i can't think of any way to do this properly

float g_fLastY[MAXPLAYERS + 1];

bool g_bJumped[MAXPLAYERS + 1];
bool g_bPostJump[MAXPLAYERS + 1];
bool g_bSecondHalfOfJump[MAXPLAYERS + 1];
bool g_bEarlyTicksResetable[MAXPLAYERS + 1];

Handle g_hScrollHudEnabled;

public Plugin myinfo =
{
	name        = "scroll hud",
	author      = "kaworu from neon genesis evangelion",
	description = "Brief description of plugin functionality here!",
	version     = PLUGIN_VERSION,
	url         = "Your website URL/AlliedModders profile URL"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_scrollhud", Command_ScrollHud, "i'm gay");

	HookEvent("player_jump", Event_PlayerJump, EventHookMode);

	g_hScrollHudEnabled = RegClientCookie("scrollhud_enabled", "Scroll Hud Enabled", CookieAccess_Protected);
}

public Action Command_ScrollHud(int client, int args)
{
	if (AreClientCookiesCached(client))
	{
		char sCookieValue[12];
		GetClientCookie(client, g_hScrollHudEnabled, sCookieValue, sizeof(sCookieValue));
		int cookieValue = StringToInt(sCookieValue);
		switch (cookieValue)
		{
			case 0:
			{
				cookieValue++;

				Shavit_PrintToChat(client, "Scroll Hud has been enabled.");
			}
			case 1:
			{
				cookieValue--;

				Shavit_PrintToChat(client, "Scroll Hud has been disabled.");
			}
		}

		IntToString(cookieValue, sCookieValue, sizeof(sCookieValue));

		SetClientCookie(client, g_hScrollHudEnabled, sCookieValue);
	}

	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	char sCookieValue[12];
	GetClientCookie(client, g_hScrollHudEnabled, sCookieValue, sizeof(sCookieValue));
	int cookieValue = StringToInt(sCookieValue);

	if (cookieValue)
	{
		if (Bunnyhop_IsOnGround(client))
		{
			g_iGroundTicks[client]++;
		}

		float pos[3];

		GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);

		if (g_fLastY[client] > pos[2])
		{
			g_bSecondHalfOfJump[client] = true;

			if (!(g_iLastCmdnumOrSomeShit[client] == cmdnum - 1))
			{
				g_bEarlyTicksResetable[client] = true;
			}

			g_iLastCmdnumOrSomeShit[client] = cmdnum;
		}

		if (buttons & IN_JUMP)
		{
			if (!g_bJumped[client] && g_bSecondHalfOfJump[client])
			{
				if (g_bEarlyTicksResetable[client])
				{
					g_iEarlyTicks[client]          = 0;
					g_bEarlyTicksResetable[client] = false;
				}
				g_iEarlyTicks[client]++;
			}

			if (!g_bSecondHalfOfJump[client])
			{
				g_iLateTicks[client]++;
			}

			if (g_bJumped[client])
			{
				g_iLateTicks[client] = 0;

				g_bJumped[client] = false;
			}
		}

		if (cmdnum % 5 == 0)
		{
			if (g_iFlopped[client])
			{
				SetHudTextParams(-1.0, 0.4, GetTickInterval() * 5, 220, 20, 60, 255, 0, 0.0, 0.0);
				ShowHudText(client, 5, "%i | Flop (%i) | %i", g_iEarlyTicks[client], g_iFlopped[client], g_iLateTicks[client]);
			}
			else if (g_iPerfed[client])
			{
				SetHudTextParams(-1.0, 0.4, GetTickInterval() * 5, 0, 191, 255, 255, 0, 0.0, 0.0);
				ShowHudText(client, 5, "%i | Perf (%i) | %i", g_iEarlyTicks[client], g_iPerfed[client], g_iLateTicks[client]);
			}
			else
			{
				SetHudTextParams(-1.0, 0.4, GetTickInterval() * 5, 255, 255, 255, 255, 0, 0.0, 0.0);
				ShowHudText(client, 5, "%i | N/A | %i", g_iEarlyTicks[client], g_iPerfed[client], g_iLateTicks[client]);
			}
		}

		g_fLastY[client] = pos[2];
	}
}

public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client                  = GetClientOfUserId(event.GetInt("userid"));
	g_bJumped[client]           = true;
	g_bPostJump[client]         = true;
	g_bSecondHalfOfJump[client] = false;

	if (g_iGroundTicks[client] == 1)
	{
		g_iFlopped[client] = 0;
		g_iPerfed[client]++;
	}
	else
	{
		g_iPerfed[client] = 0;
		g_iFlopped[client]++;
	}

	CreateTimer(0.32, Timer_ResetJumpBool, client);

	g_iGroundTicks[client] = 0;
}

public Action Timer_ResetJumpBool(Handle timer, int client)
{
	g_bPostJump[client] = false;
}