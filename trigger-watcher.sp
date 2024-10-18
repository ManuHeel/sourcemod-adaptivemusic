#include <sourcemod>
#include <sdktools>

enum struct Trigger {
    char entityClassname[64];
    char entityName[64];
    char parameter[64];
    bool lastKnownTriggerStatus;
}

enum struct TriggerWatcher {
    bool active;
    int triggerCount;
}

Trigger triggerWatcherTriggers[16];

/**
 * Console command to get a trigger's toggled status
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_GetTriggerStatus(int client, int args) {
    if (args < 2) {
        ReplyToCommand(client, "Usage: amm_gettriggerstatus <entity_classname> <entity_name>");
        return Plugin_Handled;	
    }
    char argsArray[2][64];
    char argsString[64+1+64];
    GetCmdArgString(argsString, sizeof(argsString));
    ExplodeString(argsString, " ", argsArray, sizeof(argsArray), 64);
    bool triggerStatus = IsTriggerToggled(argsArray[0],argsArray[1]);
    PrintToServer("AMM Plugin - Trigger %s (%s) has a toggled state of %i", argsArray[1], argsArray[0], triggerStatus);
    return Plugin_Handled;
}

/**
 * Get if a trigger is currently toggled
 * @param entityClassname  Trigger entity name
 * @param entityName  Trigger entity name
 * @return  True if the trigger is toggled, false if not
 */
bool IsTriggerToggled(char[] entityClassname, char[] entityName) {
    if (strcmp(entityClassname, "trigger_once") == 0) { 
        // For trigger_once (only support as of now),...
        // ...we assume they exist when asked for, and as they delete themselves when toggled, we return 0 if they do exist, and 1 if they don't
        int entity = FindEntityByClassname(-1, "trigger_once");
        while (entity != -1) {
            char foundEntityName[64];
            if (HasEntProp(entity, Prop_Data, "m_iName")) {
                GetEntPropString(entity, Prop_Data, "m_iName", foundEntityName, sizeof(foundEntityName));
                if (strcmp(foundEntityName, entityName) == 0) {
                    // We've found a trigger_once with this name,...
                    // ...so it still exists, or it hasn't been triggered yet
                    return false;
                }
            }
            entity = FindEntityByClassname(entity, "trigger_once");
        }
        // We've haven't found a trigger_once with this name, so it doesn't exists,...
        // ...so it either does not exist at all (you should have made sure it exists before calling it !!!) or it has been triggered
        return true;
    } else {
        // Unsupported trigger type...
        return false;
    }
}