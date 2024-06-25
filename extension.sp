#include <sourcemod>
#include <sdktools>
#include <adaptivemusic>

/**
 * Console command to load an FMOD bank through the Adaptive Music Extension
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_LoadBank(int client, int args) {
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: am_loadbank <bank_name>");
        return Plugin_Handled;	
    }
    char bankName[512];
    GetCmdArgString(bankName, sizeof(bankName));
    LoadBank(bankName)
    return Plugin_Handled;
}

/**
 * Load an FMOD bank through the Adaptive Music Extension
 * @param bankName  The name of the bank to load
 * @return  Return description
 */
int LoadBank(const char[] bankName) {
    LoadFMODBank(bankName);
    return 0;
}

/**
 * Console command to start an FMOD event through the Adaptive Music Extension
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_StartEvent(int client, int args) {
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: am_startevent <event_path>");
        return Plugin_Handled;	
    }
    char eventPath[512];
    GetCmdArgString(eventPath, sizeof(eventPath));
    StartEvent(eventPath)
    return Plugin_Handled;
}

/**
 * Start an FMOD event through the Adaptive Music Extension
 * @param eventPath  The path/name of the event to start
 * @return  Return description
 */
int StartEvent(const char[] eventPath) {
    StartFMODEvent(eventPath);
    return 0;
}

/**
 * Console command to stop an FMOD event through the Adaptive Music Extension
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_StopEvent(int client, int args) {
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: am_stopevent <event_path>");
        return Plugin_Handled;	
    }
    char eventPath[512];
    GetCmdArgString(eventPath, sizeof(eventPath));
    StopEvent(eventPath)
    return Plugin_Handled;
}

/**
 * Stop an FMOD event through the Adaptive Music Extension
 * @param eventPath  The path/name of the event to stop
 * @return  Return description
 */
int StopEvent(const char[] eventPath) {
    StopFMODEvent(eventPath);
    return 0;
}

/**
 * Console command to set an FMOD global parameter through the Adaptive Music Extension
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_SetGlobalParameter(int client, int args) {
    if (args < 2)
    {
        ReplyToCommand(client, "Usage: am_setglobalparameter <parameter_name> <value>");
        return Plugin_Handled;	
    }
    char parameterName[512];
    GetCmdArgString(parameterName, sizeof(parameterName));
    SplitString(parameterName, " ", parameterName, sizeof(parameterName));
    float value = GetCmdArgFloat(2)
    SetGlobalParameter(parameterName, value);
    return Plugin_Handled;
}

/**
 * Set an FMOD global parameter through the Adaptive Music Extension
 * @param eventPath  The path/name of the event to stop
 * @return  Return description
 */
int SetGlobalParameter(const char[] parameterName, float value) {
    SetFMODGlobalParameter(parameterName, value);
    return 0;
}
