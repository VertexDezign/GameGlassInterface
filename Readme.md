# GameGlassInterface

The main focus of this mod is to provide integration with [GameGlass](https://gameglass.gg/).
To achieve this the mods exports current game state into an xml file and provides some additional action events for
accessing more stuff with direct key bindings

**Integration into GameGlass still pending**

Link to Discord Post: [GameGlass Discord](https://discord.com/channels/522506741213167617/1308554695958204588)

## Action Events

| Name              | Key              | Description                                                   |
|-------------------|------------------|---------------------------------------------------------------|
| GG_LOWER_FRONT    | KEY_lshift KEY_v | Toggle lower state of all implements attached at the front    |
| GG_LOWER_BACK     | KEY_lalt KEY_v   | Toggle lower state of all implements attached at the back     |
| GG_FOLD_FRONT     | KEY_lshift KEY_x | Toggle folding state off all implements attached at the front | 
| GG_FOLD_BACK      | KEY_lalt KEY_x   | Toggle folding state off all implements attached at the back  |
| GG_ACTIVATE_FRONT | KEY_lshift KEY_b | Toggle activation state all implements attached at the front  |
| GG_ACTIVATE_BACK  | KEY_lalt KEY_b   | Toggle activation state all implements attached at the back   |

## XML

The xml is written directly into the farming simulator directory in the user folder, right besides your mod folder.
Windows: `%USERPROFILE%\Documents\My Games\FarmingSimulator2025\gameGlassInterface.xml`

The schema for the currently written xml looks like this [GameGlassInterfaceSchema](./gameGlassInterfaceSchema.xsd)

## Configuration

The mod has a configuration file named `gameGlassInterfaceSettings.xml` in the modSettings folder. The folder is located
at the same place where your mod folder is.

````xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<GGS version="1">
    <!-- Disable the xml export, useful for multiplayer where only one person has GameGlass to reduce load on the client -->
    <exportEnabled>true</exportEnabled>
    <logging>
        <!-- Configure log levels for debugging purposes -->
        <level>INFO</level>
        <specLevel>INFO</specLevel>
    </logging>
</GGS>

````

### Supported Mods

* [EnhancedVehicle](https://github.com/ZhooL/FS25_EnhancedVehicle)
    * Differential
    * AWD
    * Parking Prake