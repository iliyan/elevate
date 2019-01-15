# elevate
A Windows script to run commands with elevated permissions (ala sudo)

Requirements:
* Run other windows commands in elevated mode, using UAC
* No external dependencies apart from windows
* Strive for running under Windows 7

Decisions:
* Chose to use `cmd.exe` as shell, to begin with

