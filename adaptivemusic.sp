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

char enemies[][] = {
	"npc_advisor",
	"npc_antlion",
	"npc_antlionguard",
	"npc_barnacle",
	"npc_breen",
	"npc_clawscanner",
	"npc_combinedropship",
	"npc_combinegunship",
	"npc_fastzombie",
	"npc_fastzombie_torso",
	"npc_headcrab",
	"npc_headcrab_black",
	"npc_headcrab_fast",
	"npc_helicopter",
	"npc_hunter",
	"npc_ichthyosaur",
	"npc_manhack",
	"npc_metropolice",
	"npc_poisonzombie",
	"npc_rollermine",
	"npc_sniper",
	"npc_stalker",
	"npc_strider",
	"npc_turret_ceiling",
	"npc_turret_floor",
	"npc_turret_ground",
	"npc_zombie",
	"npc_zombie_torso",
	"npc_zombine"
};

ArrayList g_enemiesList;

public void OnPluginStart()
{
	PrintToServer("AdaptiveMusic SourceMod Plugin - Loaded");
	// Set vars
	g_enemiesList = new ArrayList(64);
	for (int i = 0; i < sizeof(enemies); i++) {
		g_enemiesList.PushString(enemies[i]);
	}
	// Register Commands
	RegAdminCmd("am_getpos", Command_GetPos, ADMFLAG_GENERIC);
	RegAdminCmd("am_gethealth", Command_GetHealth, ADMFLAG_GENERIC);
	RegAdminCmd("am_getchasedcount", Command_GetChasedCount, ADMFLAG_GENERIC);
}

public Action Command_GetPos(int client, int args) {
	int player = 1; // Player is always 1 in singleplayer
	if (HasEntProp(player, Prop_Data, "m_vecOrigin")) {
		float vector[3];
		GetEntPropVector(player, Prop_Data, "m_vecOrigin", vector);
		PrintToServer("AdaptiveMusic SourceMod Plugin - Position x=%f, y=%f, z=%f", vector[0], vector[1], vector[2]);
	}
	return Plugin_Handled;
}

public Action Command_GetHealth(int client, int args) {
	int player = 1; // Player is always 1 in singleplayer
	if (HasEntProp(player, Prop_Data, "m_iHealth")) {
		int health = GetEntProp(player, Prop_Data, "m_iHealth");
		PrintToServer("AdaptiveMusic SourceMod Plugin - Health = %i", health);
	}
	return Plugin_Handled;
}

public Action Command_GetChasedCount(int client, int args) {
	int chasedcount = 0;
	int entity = FindEntityByClassname(-1, "npc_*");
	while (entity != -1) {
		char entityClassName[128];
		GetEntityClassname(entity, entityClassName, sizeof entityClassName);
		if (FindStringInArray(g_enemiesList, entityClassName) != -1 && HasEntProp(entity, Prop_Data, "m_hEnemy") && HasEntProp(entity, Prop_Data, "m_lifeState")) {
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

public int Modulo(int a, int b) {
	return a - a/b * b;
}

int lastThinkedTick = 0;
int thinkPeriod = 10;
public void OnGameFrame()
{
	int gameTick = GetGameTickCount();
	// Think
	if (gameTick != lastThinkedTick && Modulo(gameTick, thinkPeriod) == 0) {
		lastThinkedTick = gameTick;
		Think();
	}
}

public void Think() {
	Command_GetHealth(0, 0);
	Command_GetChasedCount(0, 0);
	Command_GetPos(0,0);
}

