#include <sourcemod>
#include <sdktools>

enum struct EntityAliveWatcher {
    bool active;
    char entityClassname[128];
    char parameter[64];
    bool lastKnownEntityAliveStatus;
}

/**
 * Console command to get if an entity is alive
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_IsEntityAlive(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "Usage: am_isentityalive <entity_classname>");
        return Plugin_Handled;	
    }
    char entityClassname[128];
    GetCmdArgString(entityClassname, sizeof(entityClassname));
    bool isEntityAlive = IsEntityAlive(entityClassname);
    if (isEntityAlive) {
        PrintToServer("AdaptiveMusic SourceMod Plugin - Entity %s is alive ", entityClassname);
    } else {
        PrintToServer("AdaptiveMusic SourceMod Plugin - Entity %s is not alive (or not found)", entityClassname);
    }
    return Plugin_Handled;
}

/**
 * Get if an entity is currently alive
 * @param entityName  Entity name
 * @return  True if the entity is alive, false if not
 */
bool IsEntityAlive(char[] entityClassname) {
    int entity = FindEntityByClassname(-1, entityClassname);
    if (entity != -1) {
        if (HasEntProp(entity, Prop_Data, "m_lifeState")) {
            int lifeState = GetEntProp(entity, Prop_Data, "m_lifeState"); // lifeState is 1 if the entity is dead
            if (!lifeState) {
                return true;
            }
        }
    }
    return false;
}
