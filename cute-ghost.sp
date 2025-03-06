#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#include <shavit>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

bool	  g_bDisabled[MAXPLAYERS + 1];
bool g_bReplayAvailable = false;

int		  g_iBeam;

ArrayList g_aFrames = null;

Handle	  g_hGhostEnabled;

public Plugin myinfo =
{
	name		= "cute-ghost",
	author		= "may",
	description = "i love kaworu",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/lilac1337"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_ghost", Command_Ghost, "i'm gay");
	RegConsoleCmd("sm_beam", Command_Ghost, "i'm gay");

	g_hGhostEnabled = RegClientCookie("cuteghost_enabled", "Ghost Enabled", CookieAccess_Protected);
}

public void OnMapStart()
{
	g_iBeam = PrecacheModel("materials/shavit/zone_beam.vmt", true);
}

public void OnClientCookiesCached(int client)
{
	char sCookieValue[12];
	GetClientCookie(client, g_hGhostEnabled, sCookieValue, sizeof(sCookieValue));
	g_bDisabled[client] = view_as<bool>(StringToInt(sCookieValue));
}

public void Shavit_OnReplaysLoaded()
{
	g_aFrames = Shavit_GetReplayFrames(0, 0);

	g_bReplayAvailable = (g_aFrames != null);
}

public void Shavit_OnWorldRecord(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldwr, float oldtime, float perfs, float avgvel, float maxvel, int timestamp)
{
	if (style == 0 && track == 0)
	{
		g_aFrames = Shavit_GetReplayFrames(style, track);

		g_bReplayAvailable = true;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!(cmdnum % 10) && !g_bDisabled[client] && g_bReplayAvailable)
	{
		int baseFrame = RoundToNearest(Shavit_GetClosestReplayTime(client) / GetTickInterval());

		baseFrame += 125;

		for (int i = 0; i <= 10; i++)
		{
			frame_t frame, nextFrame;

			g_aFrames.GetArray(baseFrame + i * 5, frame, sizeof(frame_t));
			g_aFrames.GetArray(baseFrame + i * 5 + 5, nextFrame, sizeof(frame_t));

			TE_SetupBeamPoints(frame.pos, nextFrame.pos, g_iBeam, 0, 0, 10, GetTickInterval() * 10.0, 1.0, 1.0, 0, 0.0, { 207, 159, 255, 124 }, 15);
			TE_SendToClient(client, 0.0);
		}
	}
}

public Action Command_Ghost(int client, int args)
{
	if (AreClientCookiesCached(client))
	{
		char sCookieValue[12];

		g_bDisabled[client] = !g_bDisabled[client];

		Shavit_PrintToChat(client, "Ghost has been %s.", (g_bDisabled[client]) ? "disabled" : "enabled");

		IntToString(g_bDisabled[client], sCookieValue, sizeof(sCookieValue));

		SetClientCookie(client, g_hGhostEnabled, sCookieValue);
	}

	return Plugin_Handled;
}
