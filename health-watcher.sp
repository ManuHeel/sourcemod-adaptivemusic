#include <sourcemod>
#include <sdktools>

enum struct HealthWatcher {
    bool active;
    char parameter[64];
    int lastKnownHealth;
}

/**
 * Console command to get the player's health
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_GetHealth(int client, int args) {
    int player = 1; // Player is always 1 in singleplayer
    int playerHealth = GetPlayerHealth(player);
    if (playerHealth >= 0) {
        PrintToServer("AdaptiveMusic SourceMod Plugin - Player health = %i", playerHealth);
    }
    return Plugin_Handled;
}

/**
 * Get a player's current health
 * @param player  Player entity index
 * @return  Return description
 */
int GetPlayerHealth(int player) {
    if (HasEntProp(player, Prop_Data, "m_iHealth")) {
        return GetEntProp(player, Prop_Data, "m_iHealth");
    }
    return -1;
}