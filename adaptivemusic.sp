#include <sourcemod>
#include <sdktools>

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
	// Register Commands
	RegAdminCmd("am_gethealth", Command_GetHealth, ADMFLAG_GENERIC);
	RegAdminCmd("am_getchasedcount", Command_GetChasedCount, ADMFLAG_GENERIC);
}

public Action Command_GetHealth(int client, int args) {
	int playerHealth = GetClientHealth(1);
	PrintToServer("AdaptiveMusic SourceMod Plugin - Health = %i", playerHealth);
	return Plugin_Handled;
}

public Action Command_GetChasedCount(int client, int args) {
	int chasedcount = 0;
	int entity = FindEntityByClassname(-1, "npc_*");
	while (entity != -1) {
		char entityName[128];
		GetEntityClassname(entity, entityName, sizeof entityName);
		if (HasEntProp(entity, Prop_Data, "m_hEnemy") && HasEntProp(entity, Prop_Data, "m_lifeState")) {
			int enemyEntity = GetEntPropEnt(entity, Prop_Data, "m_hEnemy");
			int lifeState = GetEntProp(entity, Prop_Data, "m_lifeState"); // 1 if dead
			if (!lifeState && enemyEntity == 1) { // Player entity index
				chasedcount++;
			}
		}
		entity = FindEntityByClassname(entity, "npc_*");
	}
	PrintToServer("AdaptiveMusic SourceMod Plugin - Player chased by %i ennemies", chasedcount);
	return Plugin_Handled;
}

public void OnGameFrame()
{
	Command_GetHealth(0, 0);
	Command_GetChasedCount(0, 0);
}

