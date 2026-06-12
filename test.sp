#include <sourcemod>
#include <sdktools>
#include <sendproxy>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

//int g_iClientTickCount[MAXPLAYERS + 1];

float g_vecAbsAngles[MAXPLAYERS + 1][3];
float g_vecVelocity[MAXPLAYERS + 1][3];

public Plugin myinfo = 
{
	name = "optieyes", 
	author = "kaworu from neon genesis evangelion", 
	description = "Brief description of plugin functionality here!", 
	version = PLUGIN_VERSION, 
	url = "Your website URL/AlliedModders profile URL"
};

public void OnPluginStart()
{
	HookEvent("player_jump", Event_PlayerJump, EventHookMode_Pre);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	
	
}

public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	
	//g_iClientTickCount[client]++;
	
	if (!IsFakeClient(client) && !IsClientObserver(client) && IsClientInGame(client))
	{
		
		//float vecBaseVelocity[3];
		
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_vecVelocity[client]);
		
		
		
		//PrintToChat(client, "m_vecVelocity[0]: %f | m_vecVelocity[1]: %f | m_vecVelocity[2]: %f", g_vecVelocity[client][0], g_vecVelocity[client][1], g_vecVelocity[client][2]);
		
		//SendProxy_Hook(client, "m_vecBaseVelocity", Prop_Vector, ProxyCallbackVector);
		
		SendProxy_Hook(client, "m_vecVelocity[0]", Prop_Float, ProxyCallback);
		SendProxy_Hook(client, "m_vecVelocity[1]", Prop_Float, ProxyCallback);
		SendProxy_Hook(client, "m_vecVelocity[2]", Prop_Float, ProxyCallback);
		SendProxy_Hook(client, "m_vecVelocity[3]", Prop_Float, ProxyCallback);
		
		//GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", vecBaseVelocity);
		//PrintToChat(client, "m_vecBaseVelocity[0]: %f | m_vecBaseVelocity[1]: %f | m_vecBaseVelocity[2]: %f", vecBaseVelocity[0], vecBaseVelocity[1], vecBaseVelocity[2]);
		
		GetClientAbsAngles(client, g_vecAbsAngles[client]);
		
		CreateTimer(GetTickInterval(), ResetVelocityProp, client);
		
		//g_iClientTickCount[client] = 0;
	}
	
	return Plugin_Handled;
}

public Action ProxyCallback(int entity, const char[] PropName, float &flValue, int element)
{
	flValue = 0.0;
	return Plugin_Changed;
}

/*public Action ProxyCallbackVector(int entity, const char[] PropName, float vecValues[3], int element)
{
	vecValues[0] = g_vecVelocity[entity][0];
	vecValues[1] = g_vecVelocity[entity][1];
	vecValues[2] = g_vecVelocity[entity][2];
	
	return Plugin_Changed;
}*/

public Action ResetVelocityProp(Handle timer, int client)
{
	//SendProxy_Unhook(client, "m_vecBaseVelocity", ProxyCallbackVector);
	SendProxy_Unhook(client, "m_vecVelocity[0]", ProxyCallback);
	SendProxy_Unhook(client, "m_vecVelocity[1]", ProxyCallback);
	SendProxy_Unhook(client, "m_vecVelocity[2]", ProxyCallback);
	SendProxy_Unhook(client, "m_vecVelocity[3]", ProxyCallback);
	
	float newAngles[3], result[3];
	GetClientAbsAngles(client, newAngles);
	
	
	
	if (newAngles[1] < 0.0 && g_vecAbsAngles[client][1] > 0.0) // fix false negative/positive when player looks in a new axis during the tick
	{
		newAngles[1] = newAngles[1] * -1.0;
	}
	
	if (newAngles[1] > 0.0 && g_vecAbsAngles[client][1] < 0.0)
	{
		newAngles[1] = newAngles[1] * -1.0;
	}
	
	SubtractVectors(newAngles, g_vecAbsAngles[client], result);
	
	if (result[1] > 90.0 || result[1] < -90.0)
	{
		//KickClient(client, "Definite Opti");
		PrintToChat(client, "Definite opti: %f", result[1]);
	}
	else if (result[1] > 60.0 || result[1] < -60.0)
	{
		//KickClient(client, "Potential Opti");
		PrintToChat(client, "Potential opti: %f", result[1]);
	}
	
	//PrintToChat(client, "newAngles[1]: %f result[1]: %f g_vecAbsAngles[1]: %f", newAngles[1], result[1], g_vecAbsAngles[client][1]);
}

