#include <sourcemod>
#include <sdktools>
#include <adaptivemusic>

/**
 * Standard SourceMod plugin info 
 */
public Plugin myinfo =
{
    name = "Adaptive Music",
    author = "Manuel Russello",
    description = "Client-side plugin of the AdaptiveMusic plugin system for Source Engine",
    version = "1.0",
    url = "https://hl2musicmod.russello.studio"
};

#include "helpers.sp"
#include "health-watcher.sp"
#include "chased-watcher.sp"
#include "zone-watcher.sp"
#include "extension.sp"

public void OnPluginStart()
{
    PrintToServer("AdaptiveMusic SourceMod Plugin - Loaded");
    // Init watchers
    ChasedWatcher_Init();
    // Register Commands
    RegAdminCmd("am_getpos", Command_GetPos, ADMFLAG_GENERIC);
    RegAdminCmd("am_gethealth", Command_GetHealth, ADMFLAG_GENERIC);
    RegAdminCmd("am_getchasedcount", Command_GetChasedCount, ADMFLAG_GENERIC);
    RegAdminCmd("am_loadbank", Command_LoadBank, ADMFLAG_GENERIC);
    RegAdminCmd("am_startevent", Command_StartEvent, ADMFLAG_GENERIC);
    RegAdminCmd("am_stopevent", Command_StopEvent, ADMFLAG_GENERIC);
    RegAdminCmd("am_setglobalparameter", Command_SetGlobalParameter, ADMFLAG_GENERIC);
}

public void OnMapInit() {
    // Parse the KeyVales of the map
    char mapName[64];
    GetCurrentMap(mapName, sizeof mapName);
    char kvFilePath[256];
    BuildPath( Path_SM, kvFilePath, sizeof( kvFilePath ), "data/adaptivemusic/maps/" )
    StrCat(kvFilePath, sizeof kvFilePath, mapName);
    StrCat(kvFilePath, sizeof kvFilePath, ".kv");
    PrintToServer("AdaptiveMusic SourceMod Plugin - Opening KeyValues files at %s", kvFilePath);
    KeyValues kv = new KeyValues("not_found");
    kv.ImportFromFile(kvFilePath);
    ParseKeyValues(kv);
}

int thinkPeriod = 10;
bool knownPausedState = false; 

public void OnGameFrame()
{
    bool isServerProcessing = IsServerProcessing()
    // Handle if the Adaptive Music should be paused or not
    if (isServerProcessing && (knownPausedState == true)) {
        SetFMODPausedState(0);
        knownPausedState = false;
    } else if (!isServerProcessing && (knownPausedState == false)) {
        SetFMODPausedState(1);
        knownPausedState = true;
    }

    // Think the watchers
    int gameTick = GetGameTickCount();
    if (isServerProcessing && Modulo(gameTick, thinkPeriod) == 0) {
        Think();
    }
}
/**
 * Run all the watchers' thinking system
 */
public void Think() {
    //float fTimestamp = GetEngineTime();
    //Command_GetHealth(0, 0)
    //Command_GetChasedCount(0, 0);
    //Command_GetPos(0,0);
    //PrintToServer("Thinking the watchers took %.4f ms", 1000*(GetEngineTime()-fTimestamp));
}

void ParseKeyValues(KeyValues kv)
{
    do
    {
        // You can read the section/key name by using kv.GetSectionName here.
        char sectionName[64];
        kv.GetSectionName(sectionName, sizeof sectionName),
        PrintToServer("Section Name: %s", sectionName);
        if (kv.GotoFirstSubKey(false))
        {
            PrintToServer("Section");
            // Current key is a section. Browse it recursively.
            ParseKeyValues(kv);
            kv.GoBack();
        }
        else
        {
            // Current key is a regular key, or an empty section.
            PrintToServer("Key");
            if (kv.GetDataType(NULL_STRING) != KvData_None)
            {
                // Read value of key here (use NULL_STRING as key name). You can
                // also get the key name by using kv.GetSectionName here.
                char value[128];
                kv.GetSectionName(sectionName, sizeof sectionName);
                kv.GetString(NULL_STRING, value, sizeof value);
                PrintToServer("%s = %s", sectionName, value);

            }
            else
            {
                // Found an empty sub section. It can be handled here if necessary.
            }
        }
    } while (kv.GotoNextKey(false));
}
