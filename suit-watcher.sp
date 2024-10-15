#include <sourcemod>
#include <sdktools>

enum struct SuitWatcher {
    bool active;
    char parameter[64];
    int lastKnownSuitStatus;
}

/**
 * Console command to get the player's suit-wearing status
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_GetSuitStatus(int client, int args) {
    int player = 1; // Player is usually 1 in singleplayer
    int playerSuitStatus = GetPlayerSuitStatus(player);
    PrintToServer("AMM Plugin - Player suit status = %i", playerSuitStatus);
    return Plugin_Handled;
}

/**
 * Get a player's current suit-wearing status
 * @param player  Player entity index
 * @return  Return description
 */
int GetPlayerSuitStatus(int player) {
    if (HasEntProp(player, Prop_Data, "m_bWearingSuit")) {
        return GetEntProp(player, Prop_Data, "m_bWearingSuit");
    }
    return -1;
}