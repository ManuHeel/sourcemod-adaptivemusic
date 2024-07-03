#include <sourcemod>
#include <sdktools>

enum struct ChasedWatcher {
    bool active;
    char parameter[64];
    int lastKnownChasedCount;
}

// List of entity classnames we can consider as enemies
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

/**
 * Checks if the ennemy class is considered an ennemy
 * @param ennemyClass The entity class of the NPC
 * @return True if the class is considered an ennemy, false otherwise
 */
bool IsNPCEnnemy(char[] ennemyClass){
    for (int i = 0; i < sizeof(enemies); i++) {
        if (strcmp(ennemyClass, enemies[i]) == 0) {
            return true;
        }
    }
    return false;
}

/**
 * Console command to get the player's "chased count" (how many enemies are currently targeting the player)
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_GetChasedCount(int client, int args) {
    int player = 1; // Player is usually 1 in singleplayer
    int playerChasedCount = GetPlayerChasedCount(player);
    if (playerChasedCount >= 0) {
        PrintToServer("AdaptiveMusic SourceMod Plugin - Player chased by %i ennemies", playerChasedCount);
    }
    return Plugin_Handled;
}

/**
 * Get a player's current "chased count" (how many enemies are currently targeting the player)
 * @param player  Player entity index
 * @return  Return description
 */
int GetPlayerChasedCount(int player) {
    int chasedcount = 0;
    int entity = FindEntityByClassname(-1, "npc_*");
    while (entity != -1) {
        char entityClassName[128];
        GetEntityClassname(entity, entityClassName, sizeof entityClassName);
        if (IsNPCEnnemy(entityClassName) && HasEntProp(entity, Prop_Data, "m_hEnemy") && HasEntProp(entity, Prop_Data, "m_lifeState")) {
            int enemyEntity = GetEntPropEnt(entity, Prop_Data, "m_hEnemy");
            int lifeState = GetEntProp(entity, Prop_Data, "m_lifeState"); // lifeState is 1 if the entity is dead
            if (!lifeState && enemyEntity == player) {
                chasedcount++;
            }
        }
        entity = FindEntityByClassname(entity, "npc_*");
    }
    return chasedcount;
}
