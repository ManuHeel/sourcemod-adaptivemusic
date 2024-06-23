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
 * @param bankName  Player entity index
 * @return  Return description
 */
int LoadBank(const char[] bankName) {
    LoadFMODBank(bankName);
    return 0;
}