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

enum struct AdaptiveMusicSettings {
    char bankName[64];
    char eventPath[64];
}

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

int adaptiveMusicAvailable = false;

public void OnMapInit() {
    // Parse the KeyValues of the map
    char mapName[64];
    GetCurrentMap(mapName, sizeof mapName);
    char kvFilePath[256];
    BuildPath( Path_SM, kvFilePath, sizeof( kvFilePath ), "data/adaptivemusic/maps/" )
    StrCat(kvFilePath, sizeof kvFilePath, mapName);
    StrCat(kvFilePath, sizeof kvFilePath, ".kv");
    PrintToServer("AdaptiveMusic SourceMod Plugin - Trying to open the KeyValues file at %s", kvFilePath);
    KeyValues kv = new KeyValues(NULL_STRING);
    kv.ImportFromFile(kvFilePath);
    // Check if we could find and load the KeyValues file
    char firstKey[64];
    kv.GetSectionName(firstKey, sizeof firstKey);
    if (strcmp(firstKey, NULL_STRING) == 0) {
        PrintToServer("AdaptiveMusic SourceMod Plugin - Could not find or open the KeyValues file at %s", kvFilePath);
        adaptiveMusicAvailable = false;
    } else {
        PrintToServer("AdaptiveMusic SourceMod Plugin - Successfully found and opened the KeyValues file at %s", kvFilePath);
        int parsingResult = ParseKeyValues(kv);
        if (parsingResult != 0 ) {
            PrintToServer("AdaptiveMusic SourceMod Plugin - Could not parse the KeyValues file at %s, error: %i", kvFilePath, parsingResult);
            adaptiveMusicAvailable = false;
        } else {
            adaptiveMusicAvailable = true;
        }
    }
}

int ParseKeyValues(KeyValues kv) {
    do
    {
        char sectionName[64];
        kv.GetSectionName(sectionName, sizeof sectionName);
        if (strcmp(sectionName, "adaptive_music") != 0) {
            PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got %s instead of \"adaptive_music\"");
            return 1;
        }
        if (kv.GotoFirstSubKey(false))
        {
            // Current key is a section. Browse it recursively.
            ParseKeyValues(kv);
            kv.GoBack();
        }
        else
        {
            // Current key is a regular key, or an empty section.
            PrintToServer("Key");
            PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"adaptive_music\" section");
            return 1;
        }
    } while (kv.GotoNextKey(false));
    return 0;
}

// COPYPAAASTE
/*
void ParseKeyValuesSandbox(KeyValues kv)
{
    do
    {
        char sectionName[64];
        kv.GetSectionName(sectionName, sizeof sectionName);
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
*/

int thinkPeriod = 10;
bool knownPausedState = false; 

public void OnGameFrame() {
    if (adaptiveMusicAvailable) {
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
