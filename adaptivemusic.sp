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
    char bank[64];
    char event[64];
    HealthWatcher healthWatcher;
    ZoneWatcher zoneWatcher;
    ChasedWatcher chasedWatcher;
}

AdaptiveMusicSettings mapMusicSettings;

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
    char sectionName[64];
    kv.GetSectionName(sectionName, sizeof sectionName);
    if (strcmp(sectionName, "adaptive_music") != 0) {
        PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got %s instead of \"adaptive_music\"", sectionName);
        return 1;
    }
    if (kv.GotoFirstSubKey(false)) {
        do {
            kv.GetSectionName(sectionName, sizeof sectionName);
            if (strcmp(sectionName, "globals") == 0) {
                // Step 1: Get the globals
                if (kv.GotoFirstSubKey(false)) {
                    do {
                        kv.GetSectionName(sectionName, sizeof sectionName);
                        if (strcmp(sectionName, "bank") == 0) {
                            // Step 1.1: Get the bank
                            if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                char value[64];
                                kv.GetString(NULL_STRING, value, sizeof value);
                                mapMusicSettings.bank = value;
                                PrintToServer("AdaptiveMusic SourceMod Plugin - Bank is %s", mapMusicSettings.bank);
                            } else {
                                PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"bank\" key");
                                return 1;
                            }
                        }
                        if (strcmp(sectionName, "event") == 0) {
                            // Step 1.2: Get the event
                            if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                char value[64];
                                kv.GetString(NULL_STRING, value, sizeof value);
                                mapMusicSettings.event = value;
                                PrintToServer("AdaptiveMusic SourceMod Plugin - Event is %s", mapMusicSettings.event);
                            } else {
                                PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"event\" key");
                                return 1;
                            }
                        }
                    } while (kv.GotoNextKey(false));
                } else {
                    PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"globals\" section");
                    return 1;
                }
            } else if (strcmp(sectionName, "watcher") == 0) {
                // Step 2: Get the watchers
                char watcherType[64];
                if (kv.GotoFirstSubKey(false)) {
                    do {
                        kv.GetSectionName(sectionName, sizeof sectionName);
                        if (strcmp(sectionName, "type") == 0) {
                            // Step 1.1: Get the watcher type
                            if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                char value[64];
                                kv.GetString(NULL_STRING, value, sizeof value);
                                watcherType = value;
                                PrintToServer("AdaptiveMusic SourceMod Plugin - Watcher type is %s", watcherType);
                            } else {
                                PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"watcher.type\" key");
                                return 1;
                            }
                        } else if (strcmp(sectionName, "parameter") == 0) {
                            // Step 1.2: Get the parameter
                            if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                char value[64];
                                kv.GetString(NULL_STRING, value, sizeof value);
                                if (strcmp(watcherType, "health")) {
                                    mapMusicSettings.healthWatcher.parameter = value;
                                    PrintToServer("AdaptiveMusic SourceMod Plugin - HealthWatcher parameter is %s", value);
                                } else if (strcmp(watcherType, "chased")) {
                                    mapMusicSettings.chasedWatcher.parameter = value;
                                    PrintToServer("AdaptiveMusic SourceMod Plugin - ChasedWatcher parameter is %s", value);
                                } else if (strcmp(watcherType, "zone")) {
                                    PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Cannot assign a parameter (found %s) to a global ZoneWatcher: please assign to a zone sub-key", value);
                                    return 1;
                                }
                            } else {
                                PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"watcher.parameter\" key");
                                return 1;
                            }
                        }else if (strcmp(sectionName, "zones") == 0) {
                            // Step 1.3 (for ZoneWatcher): Get the zones values
                            if (kv.GotoFirstSubKey(false)) {
                                do {
                                    kv.GetSectionName(sectionName, sizeof sectionName);
                                    if (strcmp(sectionName, "zone") == 0) {
                                        Zone zone;
                                        if (kv.GotoFirstSubKey(false)) {
                                            do {
                                                kv.GetSectionName(sectionName, sizeof sectionName);
                                                if (strcmp(sectionName, "parameter") == 0) {
                                                    // Step 1.3.1: Get the zone parameter
                                                    if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                                        char value[64];
                                                        kv.GetString(NULL_STRING, value, sizeof value);
                                                        zone.parameter = value;
                                                        PrintToServer("AdaptiveMusic SourceMod Plugin - Zone parameter is %s", zone.parameter);
                                                    } else {
                                                        PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"watcher.zones.zone.parameter\" key");
                                                        return 1;
                                                    }
                                                } else if (strcmp(sectionName, "min_origin") == 0) {
                                                    // Step 1.3.2: Get the zone minOrigin
                                                    if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                                        KvGetVector(kv, NULL_STRING, zone.minOrigin);
                                                        PrintToServer("AdaptiveMusic SourceMod Plugin - Zone minOrigin is [%f,%f,%f]", zone.minOrigin[0], zone.minOrigin[1], zone.minOrigin[2]);
                                                    } else {
                                                        PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"watcher.zones.zone.min_origin\" key");
                                                        return 1;
                                                    }
                                                } else if (strcmp(sectionName, "max_origin") == 0) {
                                                    // Step 1.3.3: Get the zone maxOrigin
                                                    if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                                        KvGetVector(kv, NULL_STRING, zone.maxOrigin);
                                                        PrintToServer("AdaptiveMusic SourceMod Plugin - Zone maxOrigin is [%f,%f,%f]", zone.maxOrigin[0], zone.maxOrigin[1], zone.maxOrigin[2]);
                                                    } else {
                                                        PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"watcher.zones.zone.max_origin\" key");
                                                        return 1;
                                                    }
                                                }
                                            } while (kv.GotoNextKey(false));
                                            mapMusicSettings.zoneWatcher.zones.PushArray(zone, sizeof(zone)); // TODO: Fix this
                                        } else {
                                            PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"watchers.zones.zone\" section");
                                            return 1;
                                        }
                                    }
                                } while (kv.GotoNextKey(false));
                            } else {
                                PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"watchers.zones\" section");
                                return 1;
                            }
                        }

                    } while (kv.GotoNextKey(false));
                } else {
                    PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"glowatcherbals\" section");
                    return 1;
                }
            }
            kv.GoBack();
        } while (kv.GotoNextKey(false));
    } else {
        PrintToServer("AdaptiveMusic SourceMod Plugin - KeyValues file malformed. Got an empty \"adaptive_music\" section");
        return 1;
    }
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
