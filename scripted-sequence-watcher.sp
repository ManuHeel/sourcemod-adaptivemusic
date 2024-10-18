#include <sourcemod>
#include <sdktools>

enum struct ScriptedSequence {
    char entityName[64];
    char parameter[64];
    bool lastKnownScriptedSequenceStatus;
}

enum struct ScriptedSequenceWatcher {
    bool active;
    int scriptedSequenceCount;
}

ScriptedSequence scriptedSequenceWatcherScriptedSequences[16];

/**
 * Console command to get a trigger's toggled status
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_GetScriptedSequenceStatus(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "Usage: amm_getscriptedsequencestatus <entity_name>");
        return Plugin_Handled;	
    }
    char argsString[64];
    GetCmdArgString(argsString, sizeof(argsString));
    bool scriptedSequenceStatus = IsScriptedSequencePlaying(argsString);
    PrintToServer("AMM Plugin - ScriptedSequence %s has a playing state of %i", args, scriptedSequenceStatus);
    return Plugin_Handled;
}

/**
 * Get if a scripted_sequence is currently playing
 * @param entityName scripted_sequence entity name
 * @return True if the scripted_sequence is playing, false if not
 */
bool IsScriptedSequencePlaying(char[] entityName) {
    int entity = FindEntityByClassname(-1, "scripted_sequence");
    while (entity != -1) {
        char foundEntityName[64];
        if (HasEntProp(entity, Prop_Data, "m_iName")) {
            GetEntPropString(entity, Prop_Data, "m_iName", foundEntityName, sizeof(foundEntityName));
            if (strcmp(foundEntityName, entityName) == 0) {
                if (HasEntProp(entity, Prop_Data, "m_bThinking")) {
                    int isThinking = GetEntProp(entity, Prop_Data, "m_bThinking");
                    return (isThinking >= 1);
                }
            }
        }
        entity = FindEntityByClassname(entity, "scripted_sequence");
    }
    return false;
}