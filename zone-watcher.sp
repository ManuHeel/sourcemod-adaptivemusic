public Action Command_GetPos(int client, int args) {
    int player = 1; // Player is always 1 in singleplayer
    float playerPos[3];
    playerPos = GetPlayerPos(player);
    if (!IsNullVector(playerPos)) {
        PrintToServer("AdaptiveMusic SourceMod Plugin - Position x=%f, y=%f, z=%f", playerPos[0], playerPos[1], playerPos[2]);
    }
    return Plugin_Handled;
}

float[] GetPlayerPos(int player) {
    float vector[3];
    vector = NULL_VECTOR;
    if (HasEntProp(player, Prop_Data, "m_vecOrigin")) {
        GetEntPropVector(player, Prop_Data, "m_vecOrigin", vector);
    }
    return vector;
}