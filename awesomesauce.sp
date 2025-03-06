#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

int				 g_iTicksOnGround[MAXPLAYERS + 1]		= 0;
int				 g_iLastTickCount[MAXPLAYERS + 1]		= 0;

bool			 g_bPerfed[MAXPLAYERS + 1]				= false;
bool			 g_bJustJumped[MAXPLAYERS + 1]			= false;

// counters

int				 g_iBackwardsTickCounts[MAXPLAYERS + 1] = 0;
int				 g_iUserExtraDatas[MAXPLAYERS + 1]		= 0;

#define PLUGIN_VERSION "1337"

public Plugin myinfo =
{
	name		= "awesomesauce",
	author		= "may",
	description = "i love kaworu",
	version		= PLUGIN_VERSION,
	url			= "Your website URL/AlliedModders profile URL"
};

// fowards
public void OnPluginStart()
{
	HookEvent("player_jump", Event_PlayerJump, EventHookMode);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsClientInGame(client) || IsClientSourceTV(client) || IsFakeClient(client) && IsClientReplay(client) && IsClientObserver(client))
		return;

	int flags = GetEntityFlags(client);

	if (g_bJustJumped[client] && g_bPerfed[client] && buttons & IN_JUMP) printToCoolPeeps("asdf");

	checkButtons(client, buttons, vel);
	checkSidemove(client, vel);
	checkTickCount(client, tickcount);

	g_iTicksOnGround[client] = (flags & FL_ONGROUND) ? g_iTicksOnGround[client]++ : 0;
	g_bJustJumped[client]	 = false;
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	checkRetAddr(client, kv);
}

public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client			  = GetClientOfUserId(event.GetInt("userid"));

	g_bPerfed[client]	  = (g_iTicksOnGround[client] == 1);

	g_bJustJumped[client] = true;
}

// checks

void checkRetAddr(int client, KeyValues kv)
{
	// check for the userextradata keyvalue, sent by the client when the ret addr of certain functions are wrong

	char name[128];
	kv.GetSectionName(name, sizeof(name));

	if (!StrEqual(name, "UserExtraData"))
		return;

	g_iUserExtraDatas[client]++;

	printToCoolPeeps(" \x0E%N \x01had \x03%s\x01(\x0C%d\x01)", client, name, g_iUserExtraDatas[client]);
}

void checkSidemove(int client, float move[3])
{
	// make sure sidemove is not a weird value

	if (RoundToNearest(move[1]) % 100 != 0 && RoundToNearest(move[1]) <= 400)
		printToCoolPeeps("%N weird sidemove value: %f", client, move[1]);
}

void checkButtons(int client, int buttons, float move[3])
{
	// make sure buttons and sidemove values match
	// some shitty sync hacks only set sidemove without setting buttons and will get detected by this

	if (!(buttons & IN_MOVELEFT && buttons & IN_MOVERIGHT) && ((move[1] > 0.0 && buttons & IN_MOVELEFT) || (move[1] < 0.0 && buttons & IN_MOVERIGHT) || (move[1] && move[1] && (!(buttons & IN_MOVERIGHT) && !(buttons & IN_MOVELEFT)))))
		printToCoolPeeps("%N has invalid sidemove and buttons", client);
}

void checkTickCount(int client, int tickCount)
{
	if (tickCount < g_iLastTickCount[client])
	{
		g_iBackwardsTickCounts[client]++;
		printToCoolPeeps("%N just backtracked %d ticks! (%d)", client, g_iLastTickCount[client] - tickCount, g_iBackwardsTickCounts[client]);
	}

	g_iLastTickCount[client] = tickCount;
}

// funcs

void printToCoolPeeps(const char[] format, any...)
{
	char buffer[1024];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (GetAdminFlag(GetUserAdmin(i), Admin_RCON) || GetSteamAccountID(i) == 995580620))
		{
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToChat(i, "%s", buffer);
		}
	}
}