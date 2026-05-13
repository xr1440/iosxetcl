ROUTER# tclsh flash:02-AF-tclscript.tcl

--- STEP 1: 20260512, 234510: Running script AF changes ---
--- --- STEP 1.1: Script initialization: set hostname, date/time, log filter ---

--- STEP 2: Detecting Internal Flash Type ---
--- --- STEP 2.1: Primary Storage set to: bootflash:

--- STEP 3: Physical USB Auto-Detection ---
--- --- STEP 3.1: USB detected at usbflash0: (Secondary Backup Enabled)

--- STEP 4: Filename generation: hostname-YYYYMMDD-HHMMSS-AF ---
--- --- STEP 4.1: Generates filename for internal flash
--- --- STEP 4.2: Generates filename for USB ---

--- STEP 5: Setting terminal length 0 ---

--- STEP 6: Saving Config Backups ---
--- --- STEP 6.1: Saving to Primary (bootflash:)...
--- --- STEP 6.2: Saving to Secondary (usbflash0:)...

--- STEP 7: LOADING AUDIT COMMAND LIST ---
--- --- SUCCESS: Loaded 37 commands from bootflash:commands.txt
--- --- --- Found: sh version
--- --- --- Found: sh ip interface brief
... [Truncated for brevity] ...

--- STEP 8: Starting Audit Snapshot ---
--- --- STEP 8.1: Writing commands to bootflash: and usbflash0: ---
--- --- --- Executing: sh version...
... [Commands execute] ...
--- --- --- Executing: sh logging | include May 12...

--- STEP 9: FINISHED ---
--- --- STEP 9.1: Saved running-config as .cfg and audit as .txt
--- --- >> to Primary:
--- --- >> >> config: bootflash:ROUTER-20260512-234510-AF.cfg
--- --- >> >> audit:  bootflash:ROUTER-20260512-234510-AF.txt
--- --- STEP 9.2: Saved running-config as .cfg and audit as .txt
--- --- >> to Secondary:
--- --- >> >> config: usbflash0:ROUTER-20260512-234510-AF.cfg
--- --- >> >> audit:  usbflash0:ROUTER-20260512-234510-AF.txt

--- STEP 10: Searching for the LATEST 'Before' (-BF.cfg) file ---
--- --- STEP 10.1: SUCCESS! Found latest file: bootflash:ROUTER-20260512-230501-BF.cfg
--- --- STEP 10.2: File Creation Time: 2026-05-12 23:05:01

--- STEP 11: LIVE CONFIGURATION DIFF REPORT ---
--- --- --- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
--- --- ---
--- --- --- ### !COMPARING Config: ###
--- --- ---
--- --- --- Before: bootflash:ROUTER-20260512-230501-BF.cfg (2026-05-12 23:05:01)
--- --- --- After:  bootflash:ROUTER-20260512-234510-AF.cfg (2026-05-12 23:45:10)
--- --- ---
--- --- --- ------------------------------------------------------------
--- --- ---
--- --- --- ### !CONTEXTUAL Config Diffs starts now: ###
--- --- ---
--- --- --- interface GigabitEthernet1/0/1
--- --- ---  +description Uplink to Core_02
--- --- ---  -description Uplink to Core_01
--- --- --- router ospf 1
--- --- ---  +network 10.1.1.0 0.0.0.255 area 0
--- --- ---
--- --- --- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

--- STEP 12: SAVE DIFF TO STORAGE ---
--- --- STEP 12.1: Diff results saved to bootflash:ROUTER-20260512-234510-AF-DIFF.txt
--- --- STEP 12.2: Diff results saved to usbflash0:ROUTER-20260512-234510-AF-DIFF.txt

--- STEP 13: SCRIPT COMPLETED ---

ROUTER#
