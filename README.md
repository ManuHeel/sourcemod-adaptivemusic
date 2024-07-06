# sourcemod-adaptivemusic
SourceMod-based client-side plugin of the AdaptiveMusic plugin system for Source Engine

## About the files
- `docs` folder is a dump from HL2's datamaps and netprops variables for documentational purposes when scripting
- `maps` folder should be copied inside `./addons/sourcemod/data/adaptivemusic/` from the game's root folder. It contains the key/values files required to tell what music to play and what is the watched game behaviour to adapt the music to for each map.
- `sound` folder should be copied inside `./custom/adaptivemusic/` fomr the game's root folder. It contains empty sound files to override the game's default one and make the original music silent.