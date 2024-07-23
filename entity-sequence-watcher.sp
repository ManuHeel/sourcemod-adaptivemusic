#include <sourcemod>
#include <sdktools>

enum struct EntitySequenceWatcher {
    bool active;
    char entityClassname[128];
    char entityName[128];
    char parameter[64];
    int lastKnownEntitySequence;
}

/**
 * Console command to get the current entity sequence
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_GetEntitySequence(int client, int args) {
    if (args < 2) {
        ReplyToCommand(client, "Usage: am_getentitysequence <entity_classname> <entity_name>");
        return Plugin_Handled;	
    }
    char argsArray[2][128];
    char argsString[256];
    GetCmdArgString(argsString, sizeof(argsString));
    ExplodeString(argsString, " ", argsArray, sizeof(argsArray), 128);
    int entitySequence = GetEntitySequence(argsArray[0], argsArray[1]);
    if (entitySequence != -1) {
        PrintToServer("AdaptiveMusic SourceMod Plugin - Entity %s (class %s) has its sequence at ID %i", argsArray[1], argsArray[0], entitySequence);
    } else {
        PrintToServer("AdaptiveMusic SourceMod Plugin - Could not find the sequence ID of entity %s (class %s)", argsArray[1], argsArray[0]);
    }
    return Plugin_Handled;
}

/**
 * Get an entity's current sequence ID
 * @param entityClassname  Entity classname
 * @param entityName
 * @return  The current ID of the entity's sequence, or -1 if either the entity or its sequence could not be found
 */
int GetEntitySequence(char[] entityClassname, char[] entityName) {
    int entity = FindEntityByClassname(-1, entityClassname);
    char foundEntityName[128];
    while (entity != -1) {
        if (HasEntProp(entity, Prop_Data, "m_iName")) {
            GetEntPropString(entity, Prop_Data, "m_iName", foundEntityName, sizeof(foundEntityName));
            if (strcmp(foundEntityName, entityName) == 0) {
                if (HasEntProp(entity, Prop_Data, "m_nSequence")) {
                    return GetEntProp(entity, Prop_Data, "m_nSequence");
                }
            }
        }
        entity = FindEntityByClassname(entity, entityClassname)
    }
    return -1;
}
