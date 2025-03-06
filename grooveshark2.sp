#include <clientprefs>
#include <sdktools>
#include <sourcemod>

#include <ripext>
#include <shavit>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2"

char gs_SongLink[256];
char gs_SongTitle[128];
char gs_DJ[32 + 1];

chatstrings_t gS_ChatStrings;

public Plugin myinfo =
{
	name        = "grooveshark",
	author      = "may",
	description = "i love kaworu",
	version     = PLUGIN_VERSION,
	url         = "Your website URL/AlliedModders profile URL"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_gs", Command_GrooveShark, "link");
	RegConsoleCmd("sm_listen", Command_Listen, "open");
	RegConsoleCmd("sm_gsplay", Command_Listen, "open");
	RegConsoleCmd("sm_cancelsong", Command_CancelSong, "cancel");
}

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStringsStruct(gS_ChatStrings);
}

public Action Command_GrooveShark(int client, int args)
{
	char buffer[256];
	GetCmdArgString(buffer, sizeof(buffer));
	if (StrEqual(buffer, ""))
	{
		PrintToChat(client, "%splease enter a %ssong name%s!", gS_ChatStrings.sText, gS_ChatStrings.sWarning, gS_ChatStrings.sText);
		return Plugin_Handled;
	}
	HTTPRequest hHTTPRequest = new HTTPRequest("https://invidious.slipfox.xyz/api/v1/search");
	hHTTPRequest.AppendQueryParam("q", buffer);
	hHTTPRequest.Get(OnHTTPResponse, client);

	return Plugin_Handled;
} 

void OnHTTPResponse(HTTPResponse response, any value)
{
	char       url[256];
	JSONArray  records = view_as<JSONArray>(response.Data);
	JSONObject results = view_as<JSONObject>(records.Get(0));
	results.GetString("videoId", url, sizeof(url));
	results.GetString("title", gs_SongTitle, sizeof(gs_SongTitle));

	PrintToChatAll("%s%N%s is now listening to %s%s%s (listen along with !%slisten%s)", gS_ChatStrings.sStyle, value, gS_ChatStrings.sText, gS_ChatStrings.sWarning, gs_SongTitle, gS_ChatStrings.sText, gS_ChatStrings.sVariable, gS_ChatStrings.sText);

	Format(gs_SongLink, sizeof(gs_SongLink), "https://www.youtube.com./watch?v=%s", url);
	// PrintToChatAll(gs_SongLink);
	GetClientName(value, gs_DJ, sizeof(gs_DJ));

	delete records;
	delete results;

	PlaySong(value, gs_SongLink);
}

public Action Command_Listen(int client, int args)
{
	PlaySong(client, gs_SongLink);

	PrintToChat(client, "%snow playing: %s%s%s request by %s%s", gS_ChatStrings.sText, gS_ChatStrings.sWarning, gs_SongTitle, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gs_DJ);
}

public Action Command_CancelSong(int client, int args)
{
	PlaySong(client, "");
}

public void PlaySong(int client, char songlink[256])
{
	Handle panel = CreateKeyValues("data");
	KvSetString(panel, "title", "Grooveshark");
	KvSetNum(panel, "type", MOTDPANEL_TYPE_URL);
	KvSetString(panel, "msg", songlink);

	ShowVGUIPanel(client, "info", panel, false);
	CloseHandle(panel);

	QueryClientConVar(client, "cl_disablehtmlmotd", OnMotdChecked);
}

public void OnMotdChecked(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (StrEqual(cvarValue, "1", false))
		PrintToChat(client, "%splease set %scl_disablehtmlmotd%s to %s0%s if you want to use this plugin!", gS_ChatStrings.sText, gS_ChatStrings.sWarning, gS_ChatStrings.sText, gS_ChatStrings.sStyle, gS_ChatStrings.sText);	
}