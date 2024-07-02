#include <sourcemod>
#include <sdktools>

enum struct Zone {
    float minOrigin[3];
    float maxOrigin[3];
    char parameter[64];
    bool lastKnownZoneStatus;
}

enum struct ZoneWatcher {
    bool active;
    int zoneCount;
}

Zone zoneWatcherZones[16];

/**
 * Console command to get the player's position
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_GetPos(int client, int args) {
    int player = 1; // Player is usually 1 in singleplayer
    float playerPos[3];
    playerPos = GetPlayerPos(player);
    if (!IsNullVector(playerPos)) {
        PrintToServer("AdaptiveMusic SourceMod Plugin - Position x=%f, y=%f, z=%f", playerPos[0], playerPos[1], playerPos[2]);
    }
    return Plugin_Handled;
}

/**
 * Get a player's current position
 * @param player  Player entity index
 * @return  Return description
 */
float[] GetPlayerPos(int player) {
    float vector[3];
    vector = NULL_VECTOR;
    if (HasEntProp(player, Prop_Data, "m_vecOrigin")) {
        GetEntPropVector(player, Prop_Data, "m_vecOrigin", vector);
    }
    return vector;
}

bool IsVectorWithinBounds(float vector[3], float minOrigin[3], float maxOrigin[3]) {
    if (
            (vector[0] >= minOrigin[0] && vector[0] <= maxOrigin[0]) &&
            (vector[1] >= minOrigin[1] && vector[1] <= maxOrigin[1]) &&
            (vector[2] >= minOrigin[2] && vector[2] <= maxOrigin[2])) {
        return true;
    }
    return false;
}