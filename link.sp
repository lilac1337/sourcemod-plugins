#include <clientprefs>
#include <sdktools>
#include <sourcemod>

#include <shavit>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

char gs_LastLink[256];
char gs_Linker[32 + 1];

chatstrings_t gS_ChatStrings;

public Plugin myinfo =
{
	name        = "link",
	author      = "may",
	description = "i love kaworu",
	version     = PLUGIN_VERSION,
	url         = "Your website URL/AlliedModders profile URL"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_link", Command_Link, "link");
	RegConsoleCmd("sm_open", Command_Open, "open");
}

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStringsStruct(gS_ChatStrings);
}

public Action Command_Link(int client, int args)
{
	char buffer[256];
	GetCmdArgString(buffer, sizeof(buffer));
	
	if (StrContains(buffer, "http", false) < 0)
	{
		PrintToChat(client, "\"%s%s%s\" isn't a valid link!", gS_ChatStrings.sWarning, buffer, gS_ChatStrings.sText);
		return Plugin_Handled;
	}

	GetClientName(client, gs_Linker, sizeof(gs_Linker));
	gs_LastLink = buffer;

	Shavit_StopChatSound();
	PrintToChatAll("%s%N%s has posted a link: %s%s%s (view it with !%sopen%s)", gS_ChatStrings.sStyle, client, gS_ChatStrings.sText, gS_ChatStrings.sWarning, gs_LastLink, gS_ChatStrings.sText, gS_ChatStrings.sVariable, gS_ChatStrings.sText);
	return Plugin_Handled;
}

public Action Command_Open(int client, int args)
{
	ShowMOTDPanel(client, gs_Linker, gs_LastLink, 2);
}