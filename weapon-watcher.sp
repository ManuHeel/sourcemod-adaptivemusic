#include <sourcemod>
#include <sdktools>

enum struct WeaponWatcher {
    bool active;
    char weaponEntityClassname[128];
    char parameter[64];
    bool lastKnownWeaponStatus;
}

/**
 * Console command to get if the player has a weapon
 * @param client  Client launching the command (0 for console)
 * @param args    Console args
 * @return  Plugin return code
 */
public Action Command_DoesPlayerHaveWeapon(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "Usage: amm_doesplayerhaveweapon <weapon_classname>");
        return Plugin_Handled;	
    }
    char weaponEntityClassname[128];
    GetCmdArgString(weaponEntityClassname, sizeof(weaponEntityClassname));
    int player = 1; // Player is usually 1 in singleplayer
    bool doesPlayerHaveWeapon = DoesPlayerHaveWeapon(player, weaponEntityClassname);
    if (doesPlayerHaveWeapon) {
        PrintToServer("AMM Plugin - Player has weapon %s", weaponEntityClassname);
    } else {
        PrintToServer("AMM Plugin - Player does not have weapon %s", weaponEntityClassname);
    }
    return Plugin_Handled;
}

/**
 * Get if the player has a weapon
 * @param weaponEntityClassname  Weapon classname
 * @return  True if the player has the weapon, false if not
 */
bool DoesPlayerHaveWeapon(int player, char[] weaponEntityClassname) {
    int entity = FindEntityByClassname(-1, weaponEntityClassname);
    while (entity != -1) {
        if (HasEntProp(entity, Prop_Data, "m_hOwnerEntity")) {
            int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
            if (owner == player) {
                return true;
            }
        }
        entity = FindEntityByClassname(entity, weaponEntityClassname);
    }
    return false;
}
