#include <clientprefs>
#include <sdktools>
#include <sourcemod>

#include <discord>
#include <shavit>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

int g_iLastMouseX[MAXPLAYERS + 1][2];
int g_iStrafeDuration[MAXPLAYERS + 1];
// int g_iPerfectTransitionsInARow[MAXPLAYERS + 1];
int g_iPerfectYawDeltasInARow[MAXPLAYERS + 1];
int g_iPerfectYawDeltas[MAXPLAYERS + 1];

float g_fYaw[MAXPLAYERS + 1];
float g_fYawDelta[MAXPLAYERS + 1];

chatstrings_t gS_ChatStrings;

public Plugin myinfo =
{
	name        = "optieyes or something",
	author      = "may & oblivious",
	description = "i love kaworu",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/lilac1337"
};

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStringsStruct(gS_ChatStrings);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	float absVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", absVelocity);
	float velocity        = SquareRoot(absVelocity[0] * absVelocity[0] + absVelocity[1] * absVelocity[1]);
	float yawdelta        = normalize_yaw(g_fYaw[client] - angles[1]);
	float perfectyawdelta = ArcSine(30.0 / velocity) * 57.2957795131;

	// bool dirchanged = (yawdelta > 0.0 && (g_fYawDelta[client] < 0.0 || g_fYawDelta[client] == 0.0)) || (yawdelta < 0.0 && (g_fYawDelta[client] > 0.0 || g_fYawDelta[client] == 0.0));

	float fuck = FloatAbs(yawdelta) - FloatAbs(perfectyawdelta);
	if (((fuck <= 0.01 && fuck >= 0.0) || (fuck >= -0.01 && fuck <= 0.0)) && IsValidACTarget(client))
	{
		g_iPerfectYawDeltasInARow[client]++;
		g_iPerfectYawDeltas[client]++;
	}
	else
	{
		if (g_iPerfectYawDeltasInARow[client] >= 4 && IsValidACTarget(client) && velocity < 1500.0)
		{
			AcLog(client, 0, velocity);
		}

		g_iPerfectYawDeltasInARow[client] = 0;
	}

	if (mouse[0] && !turnbinding(client))
	{
		g_iStrafeDuration[client]++;
	}

	if (((g_iLastMouseX[client][0] >= 0 && mouse[0] <= 0) || (g_iLastMouseX[client][0] <= 0 && mouse[0] >= 0)) && g_iStrafeDuration[client] && IsValidACTarget(client))
	{
		if (g_iStrafeDuration[client] >= 10 && (g_iPerfectYawDeltas[client] * 1.0) / (g_iStrafeDuration[client] * 1.0) > 0.15 && velocity < 1500.0)
		{
			AcLog(client, 1, velocity);
		}
		g_iPerfectYawDeltas[client] = 0;
		g_iStrafeDuration[client]   = 0;
	}

	// check for illegal sidemove
	// under normal circumstances sidemove should be either 400 or 200

	if (RoundToNearest(vel[1]) % 100 != 0 && RoundToNearest(vel[1]) <= 400 && IsValidACTarget(client))
		AcLog(client, 2, vel[1]);
	
	// make sure sidemove corresponds with the current buttons

	if (!(buttons & IN_MOVELEFT && buttons & IN_MOVERIGHT) && // make sure keys aren't overlapping otherwise you'll get false detections
		((vel[1] > 0.0 && buttons & IN_MOVELEFT) || 
		(vel[1] < 0.0 && buttons & IN_MOVERIGHT) ||
		(vel[1] && vel[1] && (!(buttons & IN_MOVERIGHT) && !(buttons & IN_MOVELEFT))))
		&& IsValidACTarget(client))
		AcLog(client, 3, vel[1], buttons);

	g_fYawDelta[client] = yawdelta;
	g_fYaw[client]      = angles[1];

	g_iLastMouseX[client][1] = g_iLastMouseX[client][0];
	g_iLastMouseX[client][0] = mouse[0];
}

stock float normalize_yaw(float _yaw)
{
	while (_yaw > 180.0) _yaw -= 360.0;
	while (_yaw < -180.0) _yaw += 360.0;
	return _yaw;
}

stock void AcLog(int client, int logType, float data = 0.0, int data2 = 0)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetAdminFlag(GetUserAdmin(i), Admin_Custom6))
		{
			switch (logType)
			{
				case 0:    // perfect delta streak
				{
					Shavit_StopChatSound();
					PrintToChat(i, "%s%N%s had %s%i%s perfect strafe angles in a row | vel: %s%.1f", gS_ChatStrings.sStyle, client, gS_ChatStrings.sText, gS_ChatStrings.sVariable2,
					            g_iPerfectYawDeltasInARow[client], gS_ChatStrings.sText, gS_ChatStrings.sVariable2, data);
				}
				case 1:    // perfect delta yaw percent too high
				{
					Shavit_StopChatSound();
					PrintToChat(i, "%s%N%s had %s%.1f％%s perfect yaw deltas | duration: %s%i%s | perfect Δ: %s%i%s | vel: %s%.1f",
					            gS_ChatStrings.sStyle, client, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, (g_iPerfectYawDeltas[client] * 1.0) / (g_iStrafeDuration[client] * 1.0) * 100.0,
					            gS_ChatStrings.sText, gS_ChatStrings.sVariable2, g_iStrafeDuration[client], gS_ChatStrings.sText, gS_ChatStrings.sVariable2,
					            g_iPerfectYawDeltas[client], gS_ChatStrings.sText, gS_ChatStrings.sVariable2, data);
				}
				case 2:    // illegal sidemove
				{
					Shavit_StopChatSound();
					PrintToChat(i, "%s%N%s had an illegal sidemove value of %s%f", gS_ChatStrings.sStyle, client, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, data);
				}
				case 3:    // impossible buttons and sidemove
				{
					char sButtons[16];
					// there is almost certainly a better way of doing this but yolo
					if (data2 & IN_MOVELEFT) sButtons = "IN_MOVELEFT";
					if (data2 & IN_MOVERIGHT) sButtons = "IN_MOVERIGHT";
					else sButtons = "no buttons";
//					Shavit_StopChatSound(); 
					PrintToChat(i, "%s%N%s had an illegal sidemove combination of %s%.1f%s & %s%s", gS_ChatStrings.sStyle, client, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, data, gS_ChatStrings.sText, gS_ChatStrings.sVariable2, sButtons);
				}
			}
		}
	}

	DiscordWebHook hook = new DiscordWebHook("");
	hook.SlackMode      = true;

	hook.SetUsername("shang abi");

	MessageEmbed Embed = new MessageEmbed();

	Embed.SetColor("#FFC0CB");

	char name[32], map[32], track[4];
	GetClientName(client, name, sizeof(name));
	GetCurrentMap(map, sizeof(map));
	IntToString(Shavit_GetClientTrack(client), track, sizeof(track));

	Embed.AddField("player", name, true);
	Embed.AddField("map", map, true);
	Embed.AddField("track", track, true);

	switch (logType)
	{
		case 0:
		{
			Embed.SetTitle("perfect delta streak");

			char streak[16], velocity[16];
			IntToString(g_iPerfectYawDeltasInARow[client], streak, sizeof(streak));
			FloatToString(data, velocity, sizeof(velocity));
			Embed.AddField("streak", streak, true);
			Embed.AddField("vel", velocity, true);

			if (g_iPerfectYawDeltasInARow[client] >= 30) hook.SetContent("@everyone");
		}
		case 1:
		{
			Embed.SetTitle("perfect delta yaw percent");

			char percent[16], duration[16], perfectdelta[16], velocity[16];
			FloatToString((g_iPerfectYawDeltas[client] * 1.0) / (g_iStrafeDuration[client] * 1.0) * 100.0, percent, sizeof(percent));
			IntToString(g_iStrafeDuration[client], duration, sizeof(duration));
			IntToString(g_iPerfectYawDeltas[client], perfectdelta, sizeof(perfectdelta));
			FloatToString(data, velocity, sizeof(velocity));
			Embed.AddField("percent", percent, true);
			Embed.AddField("duration", duration, true);
			Embed.AddField("perfect Δ", perfectdelta, true);
			Embed.AddField("vel", velocity, true);

			if ((g_iPerfectYawDeltas[client] * 1.0) / (g_iStrafeDuration[client] * 1.0) >= 0.6) hook.SetContent("@everyone");
		}
	}

	hook.Embed(Embed);

	hook.Send();
	delete hook;
}

bool turnbinding(int client)
{
	int buttons = GetClientButtons(client);
	if (buttons & IN_LEFT || buttons & IN_RIGHT)
		return true;
	
	return false;
}

bool IsValidACTarget(int client)
{
	char strings[128];
	Shavit_GetStyleStrings(Shavit_GetBhopStyle(client), sSpecialString, strings, sizeof(strings));

	if (IsValidClient(client, true) && !IsFakeClient(client) && !IsClientReplay(client) && !IsClientObserver(client) && !turnbinding(client) && StrContains(strings, "bash_bypass") == -1)
		return true;
	
	return false;
} 

