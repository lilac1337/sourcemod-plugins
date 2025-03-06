#include <clientprefs>
#include <sdktools>
#include <sourcemod>

#include <shavit>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

chatstrings_t gS_ChatStrings;

public Plugin myinfo =
{
	name        = "welcome",
	author      = "may",
	description = "i love kaworu",
	version     = PLUGIN_VERSION,
	url         = "Your website URL/AlliedModders profile URL"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_tutorial", Command_Tutorial, "bhop tutorial");
}

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStringsStruct(gS_ChatStrings);
}

public Action OnClientCommandKeyValues(int client)
{
	if (Shavit_GetPoints(client) < 1.0)
	{
		Shavit_PrintToChat(client, "Welcome to %sCuteHops%s, if this is your first time playing bhop check out %s!tutorial", gS_ChatStrings.sVariable, gS_ChatStrings.sText, gS_ChatStrings.sStyle);
	}
}

// https://www.youtube.com/watch?v=_0g4yq3eEUo&list=PLRpPuTzNftfjj4cIeyQ8JkSn855XZN56R
public Action Command_Tutorial(int client, int args)
{
	ShowMOTDPanel(client, "Bhop Tutorial", "https://www.youtube.com/watch?v=_0g4yq3eEUo&list=PLRpPuTzNftfjj4cIeyQ8JkSn855XZN56R", 2);
}