#include <sourcemod>
#include <sdktools>

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

#include "../adaptivemusic/helpers.sp"
#include "../adaptivemusic/health-watcher.sp"
#include "../adaptivemusic/chased-watcher.sp"
#include "../adaptivemusic/zone-watcher.sp"

public void OnPluginStart()
{
    PrintToServer("AdaptiveMusic SourceMod Plugin - Loaded");
    // Init watchers
    ChasedWatcher_Init();
    // Register Commands
    RegAdminCmd("am_getpos", Command_GetPos, ADMFLAG_GENERIC);
    RegAdminCmd("am_gethealth", Command_GetHealth, ADMFLAG_GENERIC);
    RegAdminCmd("am_getchasedcount", Command_GetChasedCount, ADMFLAG_GENERIC);
}

int lastThinkedTick = 0;
int thinkPeriod = 10;

public void OnGameFrame()
{
    int gameTick = GetGameTickCount();
    // Think
    if (gameTick != lastThinkedTick && Modulo(gameTick, thinkPeriod) == 0) {
        lastThinkedTick = gameTick;
        Think();
    }
}
/**
 * Run all the watchers' thinking system
 */
public void Think() {
    Command_GetHealth(0, 0)
    Command_GetChasedCount(0, 0);
    Command_GetPos(0,0);
}

