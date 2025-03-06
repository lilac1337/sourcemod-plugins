#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1337"

public Plugin myinfo =
{
	name        = "aoc 2022 day 1",
	author      = "may",
	description = "i love kaworu",
	version     = PLUGIN_VERSION,
	url         = "Your website URL/AlliedModders profile URL"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_day1", Command_Day1, "");

	char dir[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, dir, sizeof(dir), "data/aoc");
	if (!DirExists(dir)) CreateDirectory(dir, 511);
}

public Action Command_Day1(int client, int args)
{
	char path[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, path, sizeof(path), "data/aoc/day1.txt");

	File file = OpenFile(path, "r");

	PrintToChat(client, "Part A: %d\nPart B: %d", partA(file), partB(file));

	CloseHandle(file);
}

int partA(File file)
{
	int  mostCalories, currentCalories;
	char buffer[32];

	file.Seek(0, 0);

	while (file.ReadLine(buffer, sizeof(buffer)))
	{
		if (!StringToInt(buffer))
		{
			mostCalories = (currentCalories > mostCalories) ? currentCalories : mostCalories;

			currentCalories = 0;
		}
		else
			currentCalories += StringToInt(buffer);
	}

	return mostCalories;
}

int partB(File file)
{
	int       currentCalories;
	char      buffer[32];
	ArrayList totalCookies = new ArrayList(1);

	file.Seek(0, 0);

	while (file.ReadLine(buffer, sizeof(buffer)))
	{
		if (!StringToInt(buffer))
		{
			totalCookies.Push(currentCalories);

			currentCalories = 0;
		}
		else
			currentCalories += StringToInt(buffer);
	}

	totalCookies.Sort(Sort_Descending, Sort_Integer);
	
	return totalCookies.Get(0) + totalCookies.Get(1) + totalCookies.Get(2);
}
