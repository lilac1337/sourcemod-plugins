#include <clientprefs>
#include <sdktools>
#include <sourcemod>

#include <discord>
#include <shavit>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

float g_fLastYaw[MAXPLAYERS + 1];
float g_fMYaw[MAXPLAYERS + 1];

int g_iTick[MAXPLAYERS + 1];

bool g_bRecording[MAXPLAYERS + 1];

Handle g_hFile = INVALID_HANDLE;

char g_sPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name        = "optieyes - graph",
	author      = "may & oblivious",
	description = "i love kaworu",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/lilac1337"
};

public void OnPluginStart()
{
	RegAdminCmd("startrecord", Command_Record, ADMFLAG_ROOT);
	RegAdminCmd("stoprecord", Command_StopRecord, ADMFLAG_ROOT);

	char dir[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, dir, sizeof(dir), "data/graph");
	if (!DirExists(dir)) CreateDirectory(dir, 511);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (g_fLastYaw[client] && g_bRecording[client])
	{
		float absVelocity[3], optimal;
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", absVelocity);
		float velocity  = SquareRoot(absVelocity[0] * absVelocity[0] + absVelocity[1] * absVelocity[1]);
		float RawMouseX = (g_fLastYaw[client] - angles[1]) / g_fMYaw[client] / 10.0; // we have to divide all of the mousex calculations by 10 because ??????
		if (RawMouseX > 0) optimal = ArcTangent(30.0 / velocity) * 57.2957795131 / g_fMYaw[client] / 10.0;
		else if (RawMouseX < 0) optimal = ArcTangent(30.0 / velocity) * 57.2957795131 / g_fMYaw[client] / 10.0 * -1.0;

		if ((optimal > (RawMouseX * 5.0) && RawMouseX >= 0) || (optimal < (RawMouseX * 5.0) && RawMouseX <= 0)) optimal = 0.0; // we don't want to fuck up the graph with a high optimal number when you're not even strafing

		WriteFileLine(g_hFile, "%i, %f, %f", g_iTick[client], RawMouseX, optimal);

		g_iTick[client]++;
	}

	g_fLastYaw[client] = angles[1];
}

public void OnClientPutInServer(int client)
{
	QueryClientConVar(client, "m_yaw", OnYawRetrieved);
}

public void OnYawRetrieved(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	g_fMYaw[client] = StringToFloat(cvarValue);
}

public Action Command_Record(int client, int args)
{
	int target = GetSpectatorTarget(client); //.GetSpectatorTarget(client);    // GetSpectatorTarget(client)

	if (target != -1)
	{
		
		g_bRecording[target] = true;
		g_iTick[target]      = 0;

		char buffer[32];

		GetClientName(target, buffer, sizeof(buffer));

		BuildPath(Path_SM, g_sPath, sizeof(g_sPath), "data/graph/%s.csv", buffer);
		if (FileExists(g_sPath)) DeleteFile(g_sPath);
		g_hFile = OpenFile(g_sPath, "a+");
		WriteFileLine(g_hFile, "time, rawmousex, optimal");
	}

	else
		PrintToChat(client, "Please spectate the target.");

	return Plugin_Handled;
}

public Action Command_StopRecord(int client, int args)
{
	int target = GetSpectatorTarget(client); //    // 

	if (target != -1)
	{
		g_bRecording[target] = false;

		CloseHandle(g_hFile);
	}

	else
		PrintToChat(client, "Please spectate the target.");

	return Plugin_Handled;
}