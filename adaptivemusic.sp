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
#include "suit-watcher.sp"
#include "chased-watcher.sp"
#include "zone-watcher.sp"
#include "trigger-watcher.sp"
#include "scripted-sequence-watcher.sp"
#include "entity-alive-watcher.sp"
#include "entity-sequence-watcher.sp"
#include "extension.sp"

enum struct AdaptiveMusicSettings {
    char bank[64];
    char event[64];
    HealthWatcher healthWatcher;
    SuitWatcher suitWatcher;
    ZoneWatcher zoneWatcher;
    TriggerWatcher triggerWatcher;
    ScriptedSequenceWatcher scriptedSequenceWatcher;
    ChasedWatcher chasedWatcher;
    EntityAliveWatcher entityAliveWatcher;
    EntitySequenceWatcher entitySequenceWatcher;
}

AdaptiveMusicSettings mapMusicSettings;

int musicPlayer = 0;

public void OnPluginStart()
{
    PrintToServer("AMM Plugin - Loaded");
    // Debug watcher commands
    RegAdminCmd("amm_gethealth", Command_GetHealth, ADMFLAG_GENERIC);
    RegAdminCmd("amm_getsuitstatus", Command_GetSuitStatus, ADMFLAG_GENERIC);
    RegAdminCmd("amm_getpos", Command_GetPos, ADMFLAG_GENERIC);
    RegAdminCmd("amm_gettriggerstatus", Command_GetTriggerStatus, ADMFLAG_GENERIC);
    RegAdminCmd("amm_getscriptedsequencestatus", Command_GetScriptedSequenceStatus, ADMFLAG_GENERIC);
    RegAdminCmd("amm_getchasedcount", Command_GetChasedCount, ADMFLAG_GENERIC);
    RegAdminCmd("amm_isentityalive", Command_IsEntityAlive, ADMFLAG_GENERIC);
    RegAdminCmd("amm_getentitysequence", Command_GetEntitySequence, ADMFLAG_GENERIC);
    // Debug FMOD commands
    RegAdminCmd("amm_loadbank", Command_LoadBank, ADMFLAG_GENERIC);
    RegAdminCmd("amm_startevent", Command_StartEvent, ADMFLAG_GENERIC);
    RegAdminCmd("amm_stopevent", Command_StopEvent, ADMFLAG_GENERIC);
    RegAdminCmd("amm_setglobalparameter", Command_SetGlobalParameter, ADMFLAG_GENERIC);
    // Hook events
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

int adaptiveMusicAvailable = false;

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast){
    musicPlayer = event.GetInt("userid");
    musicPlayer = FindEntityByClassname(-1, "player");
    PrintToServer("AMM Plugin - Player with entity no. %i spawned", musicPlayer);
    if (adaptiveMusicAvailable) {
        InitAdaptiveMusic();
    }
}

public void OnMapInit() {
    // Parse the KeyValues of the map
    char mapName[64];
    GetCurrentMap(mapName, sizeof mapName);
    char kvFilePath[256];
    BuildPath( Path_SM, kvFilePath, sizeof( kvFilePath ), "data/adaptivemusic/maps/" )
    StrCat(kvFilePath, sizeof kvFilePath, mapName);
    StrCat(kvFilePath, sizeof kvFilePath, ".kv");
    PrintToServer("AMM Plugin - Trying to open the KeyValues file at %s", kvFilePath);
    KeyValues kv = new KeyValues(NULL_STRING);
    kv.ImportFromFile(kvFilePath);
    // Check if we could find and load the KeyValues file
    char firstKey[64];
    kv.GetSectionName(firstKey, sizeof firstKey);
    if (strcmp(firstKey, NULL_STRING) == 0) {
        PrintToServer("AMM Plugin - Could not find or open the KeyValues file at %s", kvFilePath);
        adaptiveMusicAvailable = false;
        StopAdaptiveMusic();
    } else {
        PrintToServer("AMM Plugin - Successfully found and opened the KeyValues file at %s", kvFilePath);
        int parsingResult = ParseKeyValues(kv);
        if (parsingResult != 0 ) {
            PrintToServer("AMM Plugin - Could not parse the KeyValues file at %s, error: %i", kvFilePath, parsingResult);
            adaptiveMusicAvailable = false;
            StopAdaptiveMusic();
        } else {
            adaptiveMusicAvailable = true;
        }
    }
}

public void OnMapStart() {
    // If the player is already there (map load or else), launch the music right away 
    musicPlayer = FindEntityByClassname(-1, "player");
    PrintToServer("AMM Plugin - Player with entity no. %i found. Launching music", musicPlayer);
    if (adaptiveMusicAvailable) {
        InitAdaptiveMusic();
    }
}

int ParseKeyValues(KeyValues kv) {
    char sectionName[64];
    kv.GetSectionName(sectionName, sizeof sectionName);
    if (strcmp(sectionName, "adaptive_music") != 0) {
        PrintToServer("AMM Plugin - KeyValues file malformed. Got %s instead of \"adaptive_music\"", sectionName);
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
                                PrintToServer("AMM Plugin - Bank is %s", mapMusicSettings.bank);
                            } else {
                                PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"bank\" key");
                                return 1;
                            }
                        }
                        if (strcmp(sectionName, "event") == 0) {
                            // Step 1.2: Get the event
                            if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                char value[64];
                                kv.GetString(NULL_STRING, value, sizeof value);
                                mapMusicSettings.event = value;
                                PrintToServer("AMM Plugin - Event is %s", mapMusicSettings.event);
                            } else {
                                PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"event\" key");
                                return 1;
                            }
                        }
                    } while (kv.GotoNextKey(false));
                } else {
                    PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"globals\" section");
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
                                PrintToServer("AMM Plugin - Watcher type is %s", watcherType);
                            } else {
                                PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.type\" key");
                                return 1;
                            }
                        } else if (strcmp(sectionName, "parameter") == 0) {
                            // Step 1.2: Get the parameter
                            if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                char value[64];
                                kv.GetString(NULL_STRING, value, sizeof value);
                                if (strcmp(watcherType, "health") == 0) {
                                    mapMusicSettings.healthWatcher.parameter = value;
                                    PrintToServer("AMM Plugin - HealthWatcher parameter is %s", value);
                                } else if (strcmp(watcherType, "suit") == 0) {
                                    mapMusicSettings.suitWatcher.parameter = value;
                                    PrintToServer("AMM Plugin - SuitWatcher parameter is %s", value);
                                } else if (strcmp(watcherType, "chased") == 0) {
                                    mapMusicSettings.chasedWatcher.parameter = value;
                                    PrintToServer("AMM Plugin - ChasedWatcher parameter is %s", value);
                                } else if (strcmp(watcherType, "zone") == 0) {
                                    PrintToServer("AMM Plugin - KeyValues file malformed. Cannot assign a parameter (found %s) to a global ZoneWatcher: please assign to a zone sub-key", value);
                                    return 1;
                                } else if (strcmp(watcherType, "trigger") == 0) {
                                    PrintToServer("AMM Plugin - KeyValues file malformed. Cannot assign a parameter (found %s) to a global TriggerWatcher: please assign to a trigger sub-key", value);
                                    return 1;
                                } else if (strcmp(watcherType, "entity_alive") == 0) {
                                    mapMusicSettings.entityAliveWatcher.parameter = value;
                                    PrintToServer("AMM Plugin - EntityAlive parameter is %s", value);
                                } else if (strcmp(watcherType, "entity_sequence") == 0) {
                                    mapMusicSettings.entitySequenceWatcher.parameter = value;
                                    PrintToServer("AMM Plugin - EntitySequence parameter is %s", value);
                                }
                            } else {
                                PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.parameter\" key");
                                return 1;
                            }
                        } else if (strcmp(sectionName, "entity_classname") == 0) {
                            // Step 1.3: Get the entity_classname
                            if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                char value[64];
                                kv.GetString(NULL_STRING, value, sizeof value);
                                if (strcmp(watcherType, "entity_alive") == 0) {
                                    mapMusicSettings.entityAliveWatcher.entityClassname = value;
                                    PrintToServer("AMM Plugin - EntityAlive entity class name is %s", value);
                                } else if (strcmp(watcherType, "entity_sequence") == 0) {
                                    mapMusicSettings.entitySequenceWatcher.entityClassname = value;
                                    PrintToServer("AMM Plugin - EntitySequence entity class name is %s", value);
                                } else {
                                    PrintToServer("AMM Plugin - KeyValues file malformed. Got a \"watcher.entity_classname\" key for a watcher type that does not accept entity class names");
                                    return 1;                                    
                                }
                            } else {
                                PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.entity_classname\" key");
                                return 1;
                            }
                        } else if (strcmp(sectionName, "entity_name") == 0) {
                            // Step 1.4: Get the entity_name
                            if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                char value[64];
                                kv.GetString(NULL_STRING, value, sizeof value);
                                if (strcmp(watcherType, "entity_sequence") == 0) {
                                    mapMusicSettings.entitySequenceWatcher.entityName = value;
                                    PrintToServer("AMM Plugin - EntitySequence entity name is %s", value);
                                } else {
                                    PrintToServer("AMM Plugin - KeyValues file malformed. Got a \"watcher.entity_name\" key for a watcher type that does not accept entity class names");
                                    return 1;                                    
                                }
                            } else {
                                PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.entity_name\" key");
                                return 1;
                            }
                        } else if (strcmp(sectionName, "zones") == 0) {
                            mapMusicSettings.zoneWatcher.zoneCount = 0;
                            // Step 1.5 (for ZoneWatcher): Get the zones values
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
                                                        PrintToServer("AMM Plugin - Zone parameter is %s", zone.parameter);
                                                    } else {
                                                        PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.zones.zone.parameter\" key");
                                                        return 1;
                                                    }
                                                } else if (strcmp(sectionName, "min_origin") == 0) {
                                                    // Step 1.3.2: Get the zone minOrigin
                                                    if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                                        KvGetVector(kv, NULL_STRING, zone.minOrigin);
                                                        PrintToServer("AMM Plugin - Zone minOrigin is [%f,%f,%f]", zone.minOrigin[0], zone.minOrigin[1], zone.minOrigin[2]);
                                                    } else {
                                                        PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.zones.zone.min_origin\" key");
                                                        return 1;
                                                    }
                                                } else if (strcmp(sectionName, "max_origin") == 0) {
                                                    // Step 1.3.3: Get the zone maxOrigin
                                                    if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                                        KvGetVector(kv, NULL_STRING, zone.maxOrigin);
                                                        PrintToServer("AMM Plugin - Zone maxOrigin is [%f,%f,%f]", zone.maxOrigin[0], zone.maxOrigin[1], zone.maxOrigin[2]);
                                                    } else {
                                                        PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.zones.zone.max_origin\" key");
                                                        return 1;
                                                    }
                                                }
                                            } while (kv.GotoNextKey(false));
                                            zoneWatcherZones[mapMusicSettings.zoneWatcher.zoneCount] = zone;
                                            mapMusicSettings.zoneWatcher.zoneCount++;
                                        } else {
                                            PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watchers.zones.zone\" section");
                                            return 1;
                                        }
                                    }
                                    kv.GoBack();
                                } while (kv.GotoNextKey(false));
                                kv.GoBack();
                            } else {
                                PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watchers.zones\" section");
                                return 1;
                            }
                        } else if (strcmp(sectionName, "triggers") == 0) {
                            mapMusicSettings.triggerWatcher.triggerCount = 0;
                            // Step 1.5 (for TriggerWatcher): Get the triggers values
                            if (kv.GotoFirstSubKey(false)) {
                                do {
                                    kv.GetSectionName(sectionName, sizeof sectionName);
                                    if (strcmp(sectionName, "trigger") == 0) {
                                        Trigger trigger;
                                        if (kv.GotoFirstSubKey(false)) {
                                            do {
                                                kv.GetSectionName(sectionName, sizeof sectionName);
                                                if (strcmp(sectionName, "parameter") == 0) {
                                                    // Step 1.3.1: Get the trigger parameter
                                                    if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                                        char value[64];
                                                        kv.GetString(NULL_STRING, value, sizeof value);
                                                        trigger.parameter = value;
                                                        PrintToServer("AMM Plugin - Trigger parameter is %s", trigger.parameter);
                                                    } else {
                                                        PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.triggers.trigger.parameter\" key");
                                                        return 1;
                                                    }
                                                } else if (strcmp(sectionName, "entity_classname") == 0) {
                                                    // Step 1.3.3: Get the trigger entityClassname
                                                    if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                                        char value[64];
                                                        kv.GetString(NULL_STRING, value, sizeof value);
                                                        trigger.entityClassname = value;
                                                        PrintToServer("AMM Plugin - Trigger entityClassname %s", trigger.entityClassname);
                                                    } else {
                                                        PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.triggers.trigger.entity_classname\" key");
                                                        return 1;
                                                    }
                                                } else if (strcmp(sectionName, "entity_name") == 0) {
                                                    // Step 1.3.3: Get the trigger entityName
                                                    if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                                        char value[64];
                                                        kv.GetString(NULL_STRING, value, sizeof value);
                                                        trigger.entityName = value;
                                                        PrintToServer("AMM Plugin - Trigger entityName %s", trigger.entityName);
                                                    } else {
                                                        PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.triggers.trigger.entity_name\" key");
                                                        return 1;
                                                    }
                                                }
                                            } while (kv.GotoNextKey(false));
                                            triggerWatcherTriggers[mapMusicSettings.triggerWatcher.triggerCount] = trigger;
                                            mapMusicSettings.triggerWatcher.triggerCount++;
                                        } else {
                                            PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watchers.trigger.trigger\" section");
                                            return 1;
                                        }
                                    }
                                    kv.GoBack();
                                } while (kv.GotoNextKey(false));
                                kv.GoBack();
                            } else {
                                PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watchers.triggers\" section");
                                return 1;
                            }
                        } else if (strcmp(sectionName, "scripted_sequences") == 0) {
                            mapMusicSettings.scriptedSequenceWatcher.scriptedSequenceCount = 0;
                            // Step 1.5 (for ScriptedSequenceWatcher): Get the scripted_sequences values
                            if (kv.GotoFirstSubKey(false)) {
                                do {
                                    kv.GetSectionName(sectionName, sizeof sectionName);
                                    if (strcmp(sectionName, "scripted_sequence") == 0) {
                                        ScriptedSequence scriptedSequence;
                                        if (kv.GotoFirstSubKey(false)) {
                                            do {
                                                kv.GetSectionName(sectionName, sizeof sectionName);
                                                if (strcmp(sectionName, "parameter") == 0) {
                                                    // Step 1.3.1: Get the scripted_sequence parameter
                                                    if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                                        char value[64];
                                                        kv.GetString(NULL_STRING, value, sizeof value);
                                                        scriptedSequence.parameter = value;
                                                        PrintToServer("AMM Plugin - ScriptedSequence parameter is %s", scriptedSequence.parameter);
                                                    } else {
                                                        PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.scripted_sequences.scripted_sequence.parameter\" key");
                                                        return 1;
                                                    }
                                                } else if (strcmp(sectionName, "entity_name") == 0) {
                                                    // Step 1.3.3: Get the scripted_sequence entityName
                                                    if (kv.GetDataType(NULL_STRING) != KvData_None) {
                                                        char value[64];
                                                        kv.GetString(NULL_STRING, value, sizeof value);
                                                        scriptedSequence.entityName = value;
                                                        PrintToServer("AMM Plugin - ScriptedSequence entityName %s", scriptedSequence.entityName);
                                                    } else {
                                                        PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher.scripted_sequences.scripted_sequence.entity_name\" key");
                                                        return 1;
                                                    }
                                                }
                                            } while (kv.GotoNextKey(false));
                                            scriptedSequenceWatcherScriptedSequences[mapMusicSettings.scriptedSequenceWatcher.scriptedSequenceCount] = scriptedSequence;
                                            mapMusicSettings.scriptedSequenceWatcher.scriptedSequenceCount++;
                                        } else {
                                            PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watchers.scripted_sequences.scripted_sequence\" section");
                                            return 1;
                                        }
                                    }
                                    kv.GoBack();
                                } while (kv.GotoNextKey(false));
                                kv.GoBack();
                            } else {
                                PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watchers.scripted_sequences\" section");
                                return 1;
                            }
                        }
                    } while (kv.GotoNextKey(false));
                } else {
                    PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"watcher\" section");
                    return 1;
                }
            }
            kv.GoBack();
        } while (kv.GotoNextKey(false));
    } else {
        PrintToServer("AMM Plugin - KeyValues file malformed. Got an empty \"adaptive_music\" section");
        return 1;
    }
    return 0;
}

void InitAdaptiveMusic(){
    // Set the bank and event for the map
    LoadBank(mapMusicSettings.bank);
    StartEvent(mapMusicSettings.event);
    // Set the watchers
    if (strcmp(mapMusicSettings.healthWatcher.parameter, NULL_STRING) != 0) {
        mapMusicSettings.healthWatcher.active = true;
    } else {
        mapMusicSettings.healthWatcher.active = false;
    }
    if (strcmp(mapMusicSettings.suitWatcher.parameter, NULL_STRING) != 0) {
        mapMusicSettings.suitWatcher.active = true;
    } else {
        mapMusicSettings.suitWatcher.active = false;
    }
    if (strcmp(mapMusicSettings.chasedWatcher.parameter, NULL_STRING) != 0) {
        mapMusicSettings.chasedWatcher.active = true;
    } else {
        mapMusicSettings.chasedWatcher.active = false;
    }
    if (mapMusicSettings.zoneWatcher.zoneCount > 0) {
        mapMusicSettings.zoneWatcher.active = true;
    } else {
        mapMusicSettings.zoneWatcher.active = false;
    }
    if (mapMusicSettings.triggerWatcher.triggerCount > 0) {
        mapMusicSettings.triggerWatcher.active = true;
    } else {
        mapMusicSettings.triggerWatcher.active = false;
    }
    if (mapMusicSettings.scriptedSequenceWatcher.scriptedSequenceCount > 0) {
        mapMusicSettings.scriptedSequenceWatcher.active = true;
    } else {
        mapMusicSettings.scriptedSequenceWatcher.active = false;
    }
    if (strcmp(mapMusicSettings.entityAliveWatcher.parameter, NULL_STRING) != 0) { // TODO: Add a check for entityclassname too
        mapMusicSettings.entityAliveWatcher.active = true;
    } else {
        mapMusicSettings.entityAliveWatcher.active = false;
    }
    if (strcmp(mapMusicSettings.entitySequenceWatcher.parameter, NULL_STRING) != 0) { // TODO: Add a check for entityclassname and entityname too
        mapMusicSettings.entitySequenceWatcher.active = true;
    } else {
        mapMusicSettings.entitySequenceWatcher.active = false;
    }
}

void StopAdaptiveMusic(){
    // Reset the loaded bank for the map
    if (IsNullString(mapMusicSettings.bank)) {
        // TODO : Unload a bank
        mapMusicSettings.bank = NULL_STRING;
    }
    // Stop the playing event for the map
    if (IsNullString(mapMusicSettings.event)) {
        StopEvent(mapMusicSettings.event);
        mapMusicSettings.event = NULL_STRING;
    }
    // Reset the watchers
    mapMusicSettings.healthWatcher.active = false;
    mapMusicSettings.suitWatcher.active = false;
    mapMusicSettings.chasedWatcher.active = false;
    mapMusicSettings.zoneWatcher.active = false;
    mapMusicSettings.zoneWatcher.zoneCount = 0;
    mapMusicSettings.triggerWatcher.active = false;
    mapMusicSettings.triggerWatcher.triggerCount = 0;
    mapMusicSettings.scriptedSequenceWatcher.active = false;
    mapMusicSettings.scriptedSequenceWatcher.scriptedSequenceCount = 0;
    mapMusicSettings.entityAliveWatcher.active = false;
    mapMusicSettings.entitySequenceWatcher.active = false;
}

int thinkPeriod = 10;
bool knownPausedState = false; 

public void OnGameFrame() {
    if (adaptiveMusicAvailable && musicPlayer > 0) {
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
    float fTimestamp = GetEngineTime();
    if (mapMusicSettings.zoneWatcher.active) {
        // ZoneWatcher think
        for (int i = 0; i < mapMusicSettings.zoneWatcher.zoneCount; i++)
        {
            bool playerInZone = IsVectorWithinBounds(GetPlayerPos(musicPlayer), zoneWatcherZones[i].minOrigin, zoneWatcherZones[i].maxOrigin);
            if (playerInZone == true && zoneWatcherZones[i].lastKnownZoneStatus == false) {
                SetFMODGlobalParameter(zoneWatcherZones[i].parameter, 1.0);
                zoneWatcherZones[i].lastKnownZoneStatus = true;
            } else if (playerInZone == false && zoneWatcherZones[i].lastKnownZoneStatus == true) {
                SetFMODGlobalParameter(zoneWatcherZones[i].parameter, 0.0);
                zoneWatcherZones[i].lastKnownZoneStatus = false;
            }
        }
    }
    if (mapMusicSettings.triggerWatcher.active) {
        // TriggerWatcher think
        for (int i = 0; i < mapMusicSettings.triggerWatcher.triggerCount; i++)
        {
            bool triggerToggled = IsTriggerToggled(triggerWatcherTriggers[i].entityClassname, triggerWatcherTriggers[i].entityName);
            if (triggerToggled == true && triggerWatcherTriggers[i].lastKnownTriggerStatus == false) {
                SetFMODGlobalParameter(triggerWatcherTriggers[i].parameter, 1.0);
                triggerWatcherTriggers[i].lastKnownTriggerStatus = true;
            } else if (triggerToggled == false && triggerWatcherTriggers[i].lastKnownTriggerStatus == true) {
                //// Should triggers go from 1 to 0 or stay triggered ? Currently staying triggered.
                //SetFMODGlobalParameter(triggerWatcherTriggers[i].parameter, 0.0);
                //triggerWatcherTriggers[i].lastKnownTriggerStatus = false;
            }
        }
    }
    if (mapMusicSettings.scriptedSequenceWatcher.active) {
        // ScriptedSequenceWatcher think
        for (int i = 0; i < mapMusicSettings.scriptedSequenceWatcher.scriptedSequenceCount; i++)
        {
            bool scriptedSequenceWatcherPlaying = IsScriptedSequencePlaying(scriptedSequenceWatcherScriptedSequences[i].entityName);
            if (scriptedSequenceWatcherPlaying == true && scriptedSequenceWatcherScriptedSequences[i].lastKnownScriptedSequenceStatus == false) {
                SetFMODGlobalParameter(scriptedSequenceWatcherScriptedSequences[i].parameter, 1.0);
                scriptedSequenceWatcherScriptedSequences[i].lastKnownScriptedSequenceStatus = true;
            } else if (scriptedSequenceWatcherPlaying == false && scriptedSequenceWatcherScriptedSequences[i].lastKnownScriptedSequenceStatus == true) {
                SetFMODGlobalParameter(scriptedSequenceWatcherScriptedSequences[i].parameter, 0.0);
                scriptedSequenceWatcherScriptedSequences[i].lastKnownScriptedSequenceStatus = false;
            }
        }
    }
    if (mapMusicSettings.healthWatcher.active) {
        // HealthWatcher think
        int health = GetPlayerHealth(musicPlayer);
        if (health != mapMusicSettings.healthWatcher.lastKnownHealth) {
            SetFMODGlobalParameter(mapMusicSettings.healthWatcher.parameter, float(health));
            mapMusicSettings.healthWatcher.lastKnownHealth = health;
        }
    }
    if (mapMusicSettings.suitWatcher.active) {
        // SuitWatcher think
        int suitStatus = GetPlayerSuitStatus(musicPlayer);
        if (suitStatus != mapMusicSettings.suitWatcher.lastKnownSuitStatus) {
            SetFMODGlobalParameter(mapMusicSettings.suitWatcher.parameter, float(suitStatus));
            mapMusicSettings.suitWatcher.lastKnownSuitStatus = suitStatus;
        }
    }
    if (mapMusicSettings.chasedWatcher.active) {
        // ChasedWatcher think
        int chasedCount = GetPlayerChasedCount(musicPlayer);
        if (chasedCount != mapMusicSettings.chasedWatcher.lastKnownChasedCount) {
            SetFMODGlobalParameter(mapMusicSettings.chasedWatcher.parameter, float(chasedCount));
            mapMusicSettings.chasedWatcher.lastKnownChasedCount = chasedCount;
        }
    }
    if (mapMusicSettings.entityAliveWatcher.active) {
        // EntityAliveWatcher think
        bool isEntityAlive = IsEntityAlive(mapMusicSettings.entityAliveWatcher.entityClassname);
        if (isEntityAlive != mapMusicSettings.entityAliveWatcher.lastKnownEntityAliveStatus) {
            SetFMODGlobalParameter(mapMusicSettings.entityAliveWatcher.parameter, float(isEntityAlive));
            mapMusicSettings.entityAliveWatcher.lastKnownEntityAliveStatus = isEntityAlive;
        }
    }
    if (mapMusicSettings.entitySequenceWatcher.active) {
        // EntitySequenceWatcher think
        int entitySequence = GetEntitySequence(mapMusicSettings.entitySequenceWatcher.entityClassname, mapMusicSettings.entitySequenceWatcher.entityName);
        if (entitySequence != mapMusicSettings.entitySequenceWatcher.lastKnownEntitySequence) {
            SetFMODGlobalParameter(mapMusicSettings.entitySequenceWatcher.parameter, float(entitySequence));
            mapMusicSettings.entitySequenceWatcher.lastKnownEntitySequence = entitySequence;
        }
    }
    PrintToServer("Thinking the watchers took %.4f ms", 1000*(GetEngineTime()-fTimestamp));
}
