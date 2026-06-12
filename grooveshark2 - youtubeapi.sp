#include <clientprefs>
#include <sdktools>
#include <sourcemod>

#include <ripext>
#include <shavit>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

char gs_SongLink[256];
char gs_DJ[32 + 1];

chatstrings_t gS_ChatStrings;

public Plugin myinfo =
{
	name        = "grooveshark2",
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
}

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStringsStruct(gS_ChatStrings);
}

public Action Command_GrooveShark(int client, int args)
{
	char buffer[256];
	GetCmdArgString(buffer, sizeof(buffer));
	if (StrEqual(buffer, "")) { PrintToChat(client, "%splease enter a %ssong name%s!", gS_ChatStrings.sText, gS_ChatStrings.sWarning, gS_ChatStrings.sText); return Plugin_Handled; }
	HTTPRequest hHTTPRequest = new HTTPRequest("https://youtube.googleapis.com/youtube/v3/search");
	hHTTPRequest.AppendQueryParam("part", "snippet");
	hHTTPRequest.AppendQueryParam("maxResults", "1");
	hHTTPRequest.AppendQueryParam("q", buffer);
	hHTTPRequest.AppendQueryParam("key", "puturapikeyhere");
	hHTTPRequest.Get(OnHTTPResponse, client);

	return Plugin_Handled;
}

void OnHTTPResponse(HTTPResponse response, any value)
{
	char      url[256], title[128];
	JSONObject records = view_as<JSONObject>(response.Data);
	JSONArray arr = view_as<JSONArray>(records.Get("items"));
	JSONObject item = view_as<JSONObject>(arr.Get(0));
	JSONObject id = view_as<JSONObject>(item.Get("id"));
	JSONObject snippet = view_as<JSONObject>(item.Get("snippet"));
	id.GetString("videoId", url, sizeof(url));
	snippet.GetString("title", title, sizeof(title));

	PrintToChatAll("%s%N%s is now listening to %s%s%s (listen along with !%slisten%s)", gS_ChatStrings.sStyle, value, gS_ChatStrings.sText, gS_ChatStrings.sWarning, title, gS_ChatStrings.sText, gS_ChatStrings.sVariable, gS_ChatStrings.sText);

	Format(gs_SongLink, sizeof(gs_SongLink), "https://www.youtube.com/watch?v=%s", url);
	//PrintToChatAll(gs_SongLink);
	GetClientName(value, gs_DJ, sizeof(gs_DJ));

	delete records;
	delete arr;
	delete item;
	delete id;
	delete snippet;
}

public Action Command_Listen(int client, int args)
{
	Handle panel = CreateKeyValues("data");
	KvSetString(panel, "title", "Grooveshark");
	KvSetNum(panel, "type", MOTDPANEL_TYPE_URL);
	KvSetString(panel, "msg", gs_SongLink);
	
	ShowVGUIPanel(client, "info", panel, false);
	CloseHandle(panel);
}
