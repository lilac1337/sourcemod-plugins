#include <sourcemod>
#include <sdktools>

#include <adminmenu>

#include <shavit>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

#include "funcommands.sp"

public Plugin myinfo = 
{
	name = "shavit-drug",
	author = "AlliedModders",
	description = "dude weed lmao",
	version = PLUGIN_VERSION,
	url = "www.sex.com"
};

public void Shavit_OnStyleChanged(int client, int oldstyle, int newstyle, int track, bool manual)
{
	char sSpecial[128];
	Shavit_GetStyleStrings(newstyle, sSpecialString, sSpecial, 128);
	if(StrContains(sSpecial, "drug", false) != -1) 
	{
		CreateDrug(client);
	} 
	
	else 
	{
		KillDrug(client);
	}
}

public void OnClientPutInServer(int client)
{
	char sSpecial[128];
	int style = Shavit_GetBhopStyle(client);
	Shavit_GetStyleStrings(style, sSpecialString, sSpecial, 128);
	if(StrContains(sSpecial, "drug", false) != -1) 
	{
		KillDrug(client);
		CreateDrug(client);
	} 
	
	else 
	{
		KillDrug(client);
	}
}