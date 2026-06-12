// PLEASE DON'T LOOK AT THIS ITS SO BAD
// agony

#define DEBUG 0

#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

int	 g_iSelectedMap	   = 0;
int	 g_iModelType[2]   = { 0, 1 };
int	 g_iTeamCounter[2] = { 0, 0 };

bool g_bCorrectMap	   = false;

/* map list */
char g_sMaps[][]	   = {
	  "cs_agency_2014_og",
	  "de_aztec_2013_og",
	  "de_cache_2014_og",
	  "de_cache_ve",
	  "de_cbble_2015_og",
	  "de_contra_b5",
	  "de_dust2_2013_og",
	  "de_dust2snow",
	  "de_inferno_2014_og",
	  "de_inferno_winter",
	  "de_inferno_ce",
	  "de_mill_ce_og",
	  "de_mirage_2015_og",
	  "de_mirage_winter",
	  "de_mirage_go",
	  "cs_motel_2014_og",
	  "de_nuke_2013_og",
	  "de_overpass_2014_og",
	  "de_overpass_2015_og",
	  "de_seaside_2014_og",
	  "de_season_2013_og",
	  "de_season_2015_og",
	  "de_train_2013_og",
	  "de_vertigo_2014_og",
	  "de_royal",
	  "de_santorini",
	  "de_stadium"
};

// which models from g_sPlayerModels
int g_iMapModels[] = {
	// cs_agency_2014_og
	10, 11,

	// de_aztec_2013_og
	0, 9,

	// de_cache_2014_og
	0, 1,

	// de_cache_ve
	0, 1,

	// de_cbble_2015_og
	0, 1,

	// de_contra_b5
	0, 1,

	// de_dust2_2013_og
	2, 3,

	// de_dust2snow
	2, 3,

	// de_inferno_2014_og
	4, 5,

	// de_inferno_winter
	4, 5,

	// de_inferno_ce
	4, 5,

	// de_mill_ce
	0, 9,

	// de_mirage_2013_og
	2, 5,

	// de_mirage_winter
	2, 5,

	// de_mirage_go
	2, 5,

	// cs_motel_2014_og
	0, 12,

	// de_nuke_2013_og
	6, 5,

	// de_overpass_2014_og
	0, 7,

	// de_overpass_2015_og
	0, 7,

	// de_seaside_2014_og
	8, 5,

	// de_season_2013_og
	0, 5,

	// de_season_2015_og
	0, 5,

	// de_train_2013_og
	0, 9,

	// de_vertigo_2014_og
	10, 12,

	// de_royal
	0, 5,

	// de_santorini
	0, 1,

	// de_stadium
	0, 5
};

/* each of these char arrs have 2 models per map */

char g_sArmModels[][] = {
	// cs_agency_2014_og
	"models/weapons/t_arms_professional.mdl",
	"models/weapons/ct_arms_fbi.mdl",

	// de_aztec_2013_og
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_st6.mdl",

	// de_cache_2014_og
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_gign.mdl",

	// de_cache_ve
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_gign.mdl",

	// de_cbble_2015_og
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_gign.mdl",

	// de_contra_b5
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_gign.mdl",

	// de_dust2_2013_og
	"models/weapons/t_arms_leet.mdl",
	"models/weapons/ct_arms_idf.mdl",

	// de_dust2snow
	"models/weapons/t_arms_leet.mdl",
	"models/weapons/ct_arms_idf.mdl",

	// de_inferno_2014_og
	"models/weapons/t_arms_separatist.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// de_inferno_winter
	"models/weapons/t_arms_separatist.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// de_inferno_ce
	"models/weapons/t_arms_separatist.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// de_mill_ce
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_st6.mdl",

	// de_mirage_2015_og
	"models/weapons/t_arms_leet.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// de_mirage_winter
	"models/weapons/t_arms_leet.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// de_mirage_ce
	"models/weapons/t_arms_leet.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// cs_motel_2014_og
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_swat.mdl",

	// de_nuke_2013_og
	"models/weapons/t_arms_balkan.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// de_overpass_2014_og
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_gsg9.mdl",

	// de_overpass_2015_og
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_gsg9.mdl",

	// de_seaside_2014_og
	"models/weapons/t_arms_pirate.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// de_season_2013_og
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// de_season_2015_og
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// de_train_2013_og
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_st6.mdl",

	// de_vertigo_2014_og
	"models/weapons/t_arms_professional.mdl",
	"models/weapons/ct_arms_swat.mdl",

	// de_royal
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_sas.mdl",

	// de_santorini
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_gign.mdl",

	// de_stadium
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/ct_arms_sas.mdl"

};

char g_sPlayerModels[][] = {
	/*// phoenix
	{ "models/player/tm_phoenix.mdl", "models/player/tm_phoenix_variantA.mdl", "models/player/tm_phoenix_variantB.mdl", "models/player/tm_phoenix_variantC.mdl", "models/player/tm_phoenix_variantD.mdl" },
	// gign
	{ "models/player/ctm_gign.mdl", "models/player/ctm_gign_variantA.mdl", "models/player/ctm_gign_variantB.mdl", "models/player/ctm_gign_variantC.mdl", "models/player/ctm_gign_variantD.mdl" },
	// leet
	{ "models/player/tm_leet_variantA.mdl", "models/player/tm_leet_variantB.mdl", "models/player/tm_leet_variantC.mdl", "models/player/tm_leet_variantD.mdl", "models/player/tm_leet_variantE.mdl" },
	// idf
	{ "models/player/ctm_idf.mdl", "models/player/ctm_idf_variantB.mdl", "models/player/ctm_idf_variantC.mdl", "models/player/ctm_idf_variantD.mdl", "models/player/ctm_idf_variantE.mdl", "models/player/ctm_idf_variantF.mdl" },
	// seperatist
	{ "models/player/tm_separatist.mdl", "models/player/tm_separatist_variantA.mdl", "models/player/tm_separatist_variant.mdlB", "models/player/tm_separatist_variantC.mdl", "models/player/tm_separatist_variantD.mdl" },
	// sas
	{ "models/player/ctm_sas.mdl", "models/player/ctm_sas_variantA.mdl", "models/player/ctm_sas_variantB.mdl", "models/player/ctm_sas_variantC.mdl", "models/player/ctm_sas_variantD.mdl", "models/player/ctm_sas_variantE.mdl", "models/player/ctm_sas_variantF.mdl", "models/player/ctm_sas_variantG.mdl" },
	// balkan
	{ "models/player/tm_balkan_variantA.mdl", "models/player/tm_balkan_variantB.mdl", "models/player/tm_balkan_variantC.mdl", "models/player/tm_balkan_variantD.mdl", "models/player/tm_balkan_variantE.mdl" },
	// gsg9
	{ "models/player/ctm_gsg9.mdl", "models/player/ctm_gsg9_variantA.mdl", "models/player/ctm_gsg9_variantB.mdl", "models/player/ctm_gsg9_variantC.mdl", "models/player/ctm_gsg9_variantD.mdl" },
	// pirate
	{ "models/player/tm_pirate.mdl", "models/player/tm_pirate_variantA.mdl", "models/player/tm_pirate_variantB.mdl", "models/player/tm_pirate_variantC.mdl", "models/player/tm_pirate_variantD.mdl" },
	// st6
	{ "models/player/ctm_st6.mdl", "models/player/ctm_st6_variantA.mdl", "models/player/ctm_st6_variantB.mdl", "models/player/ctm_st6_variantC.mdl", "models/player/ctm_st6_variantD.mdl" }*/
	"models/player/tm_phoenix", "models/player/ctm_gign", "models/player/tm_leet", "models/player/ctm_idf", "models/player/tm_separatist", "models/player/ctm_sas",
	"models/player/tm_balkan", "models/player/ctm_gsg9", "models/player/tm_pirate", "models/player/ctm_st6", "models/player/tm_professional", "models/player/ctm_fbi",
	"models/player/ctm_swat"
};

// adds an offset to 'A' if the map ends at a letter that isn't variantA
int g_iOffsets[] = {
	0, 0, -1, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0
};

// the amount of variants each model has
int g_iModelVariations[] = {
	5, 5, 5, 6, 5, 6, 4, 5, 5, 5, 5, 5, 5
};

// whether or not to use variable or var as the suffix
int g_bModelVarOrVariable[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0
};

// BUMP THIS WHEN ADDING MAPS holy moly i spent like an hour trying to fix a bug cause it didn't get bumped
ArrayList g_aIgnoredVariations[32];
ArrayList g_aMapVariations[2];

public Plugin myinfo =
{
	name		= "og models",
	author		= "may",
	description = "i love kaworu",
	version		= PLUGIN_VERSION,
	url			= "Your website URL/AlliedModders profile URL"
};

public void OnPluginStart()
{
	// RegConsoleCmd("sm_imgay", Command_Gay, "");
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	// allocate the array lists
	for (int i; i < sizeof(g_aIgnoredVariations); i++)
	{
		g_aIgnoredVariations[i] = new ArrayList();
	}

	for (int i; i < sizeof(g_aMapVariations); i++)
	{
		g_aMapVariations[i] = new ArrayList();
	}

	// add the ignored variations
	g_aIgnoredVariations[5].Push(5);
	g_aIgnoredVariations[5].Push(6);
}

public void OnMapStart()
{
	// loop through the arms models and precache them
	for (int i; i < sizeof(g_sArmModels); i++)
		PrecacheModel(g_sArmModels[i]);

	PrecacheModel("models/player/ct_animations.mdl");

	char mapBuffer[MAX_NAME_LENGTH];
	GetCurrentMap(mapBuffer, sizeof(mapBuffer));

	// find which map and make sure we should be setting a custom model on it
	for (int i; i < sizeof(g_sMaps); i++)
		if (StrEqual(g_sMaps[i], mapBuffer, false))
		{
			g_bCorrectMap  = true;
			g_iSelectedMap = i;
		}

	// set the model type for each team for this map
	g_iModelType[0] = g_iMapModels[g_iSelectedMap * 2];
	g_iModelType[1] = g_iMapModels[g_iSelectedMap * 2 + 1];

	for (int i; i < 2; i++)
	{
		for (int j; j < g_iModelVariations[g_iModelType[i]]; j++)
		{
			char buffer[128];

			// if the offset is -1 that means we start at variantA so we can just skip the base model
			if (g_iOffsets[g_iModelType[i]] == -1 && j == 0)
				continue;

			char suffix[32];

			Format(suffix, sizeof(suffix), ((g_bModelVarOrVariable[g_iModelType[i]]) ? ("var") : ("variant")));

			if (j == 0) Format(buffer, sizeof(buffer), "%s.mdl", g_sPlayerModels[g_iModelType[i]]);
			else Format(buffer, sizeof(buffer), "%s_%s%c.mdl", g_sPlayerModels[g_iModelType[i]], suffix, (g_bModelVarOrVariable[g_iModelType[i]]) ? '1' : 'A' + ((g_iOffsets[g_iModelType[i]] == -1) ? j - 1 : g_iOffsets[g_iModelType[i]] + j - 1));

			g_aMapVariations[i].Push(PrecacheModel(buffer));
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team   = GetClientTeam(client);

#if DEBUG
	PrintToChatAll("%N %b %b %b", client, !(IsClientInGame(client)), !(g_bCorrectMap), (team > CS_TEAM_CT || team < CS_TEAM_T));
#endif

	if (!IsClientInGame(client) || !g_bCorrectMap || (team > CS_TEAM_CT || team < CS_TEAM_T))
		return;

	setTeamModel(client, team - 2);
}

bool shouldIgnore(int model, int index)
{
	for (int i; i < g_aIgnoredVariations[model].Length; i++)
	{
		if (g_aIgnoredVariations[model].Get(i) == index) return true;
	}

	return false;
}

void setTeamModel(int client, int teamIndex)
{
	char buffer[128];

	// check if we're on the first variant (this is because the first variant doesn't have the _variant suffix)
	if (g_iOffsets[g_iModelType[teamIndex]] == -1 && g_iTeamCounter[teamIndex] == 0) g_iTeamCounter[teamIndex]++;

	while (shouldIgnore(g_iModelType[teamIndex], g_iTeamCounter[teamIndex] - 1))
	{
#if DEBUG
		PrintToChatAll("IGNORED %d %N", (((g_iOffsets[g_iModelType[teamIndex]] == -1) ? 0 : g_iOffsets[g_iModelType[teamIndex]]) + g_iTeamCounter[teamIndex] - 1), client);
#endif
		g_iTeamCounter[teamIndex]++;
	}

	if (g_iTeamCounter[teamIndex] >= g_aMapVariations[teamIndex].Length) (g_iOffsets[g_iModelType[teamIndex]] == -1) ? (g_iTeamCounter[teamIndex] = 2) : (g_iTeamCounter[teamIndex] = 0);

	char suffix[32];

	Format(suffix, sizeof(suffix), ((g_bModelVarOrVariable[g_iModelType[teamIndex]]) ? ("var") : ("variant")));

	if ((g_iTeamCounter[teamIndex] == 0)) Format(buffer, sizeof(buffer), "%s.mdl", g_sPlayerModels[g_iModelType[teamIndex]]);
	// append _variant to the model name
	else Format(buffer, sizeof(buffer), "models/player/%s_%s%c.mdl", g_sPlayerModels[g_iModelType[teamIndex]], suffix, ((g_bModelVarOrVariable[g_iModelType[teamIndex]]) ? '1' : 'A' + ((g_iOffsets[g_iModelType[teamIndex]] == -1) ? 0 : g_iOffsets[g_iModelType[teamIndex]]) + g_iTeamCounter[teamIndex] - 1));

// set the models
#if DEBUG
	PrintToChatAll("%N %s %d", client, buffer, (((g_iOffsets[g_iModelType[teamIndex]] == -1) ? 0 : g_iOffsets[g_iModelType[teamIndex]]) + g_iTeamCounter[teamIndex] - 1));
#endif

	// PrintToChatAll("%N %d", client, g_aMapVariations[teamIndex].Get(g_iTeamCounter[teamIndex]));
	SetEntProp(client, Prop_Data, "m_nModelIndex", g_aMapVariations[teamIndex].Get(g_iTeamCounter[teamIndex]), 2);
	SetEntPropString(client, Prop_Send, "m_szArmsModel", g_sArmModels[g_iSelectedMap * 2 + teamIndex]);
	SetVariantString(buffer);
	SetEntityModel(client, "models/player/ct_animations.mdl");
	// increment the model counter so the next player on the team is the next variant
	g_iTeamCounter[teamIndex] = (g_iTeamCounter[teamIndex] > (g_iModelVariations[g_iModelType[teamIndex]] + ((g_iOffsets[g_iModelType[teamIndex]] == -1) ? 1 : 0))) ? 0 : (g_iTeamCounter[teamIndex] + 1);
}

/*public Action Command_Gay(int client, int args)
{
	for (int i; i < sizeof(g_sPlayerModels); i++)
	{
		// loop through each variation
		for (int j; j < g_iModelVariations[i]; j++)
		{
			char buffer[128];

			// if the offset is -1 that means we start at variantA so we can just skip the base model
			if (g_iOffsets[i] == -1 && j == 0)
				continue;

			if (j == 0) Format(buffer, sizeof(buffer), "%s.mdl", g_sPlayerModels[i]);
			else Format(buffer, sizeof(buffer), "%s_variant%c.mdl", g_sPlayerModels[i], 'A' + ((g_iOffsets[i] == -1) ? j - 1 : g_iOffsets[i] + j - 1));

			PrintToChat(client, buffer);
		}
	}
}*/
