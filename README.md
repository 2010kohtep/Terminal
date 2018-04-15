# Terminal
Another yet GoldSource Engine protector.

# What is this?

**Terminal** is protector for the GoldSource engine, written in Borland Assembler (**BASM**).

This is one of my old projects, designed to raise knowledge in the assembly language. At that time I was not quite ready to completely abandon the higher programming language, so the project was written in BASM using the Delphi language functionality (functions declaration, structures, etc.).

On the other hand, this project is completely independent of the files that come with the Borland Delphi environment. It's enough to just download this project and run the script, as a result of which you will have a compiled **Terminal** file.

# Functions

* Blocking malicious commands (svc_stufftext, svc_director, dem-files);
* SteamID spoofing;
* 47 to 48 protocol converting;
* MOTD block;
* Provides simple (and poor) API for custom plugins, see ***MemSearch.pas*** file;
* Ability to load other libraries via game console.

This project doesn't have a lot of functionality, because it had slow development, and was eventually abandoned. Some functions may also work unstable.

# Configuring

Protector has some console command and variables.

* inject <name> // Inject DLL in game process
* cl_steamid_value <value> // Set SteamID value; 0 - disable spoofer
* cl_steamid_emu <0..2> // Set spoofer emulator (0 - OldRevEmu, 1 - SteamEmu, 2 - AVSMP)
* dem_filtercmd <0/1> // Toggle dem-files console commands filter
* cl_disablemotd <0/1> // Toggle MOTD show
* http_open <url/html> // Open URL or HTML code in MOTD window

# How to compile?

Just download the project and run **compile.bat** file, then **Terminal.asi** will appear in the project folder, which can be copied to the game folder. Then you can run the game, and ASI will be injected automatically.