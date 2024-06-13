#include <sourcemod>

public Plugin myinfo =
{
	name = "Adaptive Music",
	author = "Manuel Russello",
	description = "Client-side plugin of the AdaptiveMusic plugin system for Source Engine",
	version = "1.0",
	url = "https://hl2musicmod.russello.studio"
};

public void OnPluginStart()
{
	PrintToServer("AdaptiveMusic SourceMod Plugin - Loaded");
}