ROUTER# tclsh flash:01-BF-tclscript.tcl


--- STEP 1: 20260512, 230501: Running script BF changes ---
--- --- STEP 1.1: Script initialization: set hostname, date/time, log filter ---

--- STEP 2: Detecting Internal Flash Type ---
--- --- STEP 2.1: Primary Storage set to: bootflash:

--- STEP 3: Physical USB Auto-Detection ---
--- --- STEP 3.1: USB detected at usbflash0: (Secondary Backup Enabled)

--- STEP 4: Filename generation: hostname-YYYYMMDD-HHMMSS-BF ---
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
--- --- --- Found: sh interface status
... [Truncated for brevity] ...
--- --- --- Found: sh hardware
--- --- --- Found: sh controllers

--- STEP 8: Starting Audit Snapshot ---
--- --- STEP 8.1: Writing commands to bootflash: and usbflash0: ---
--- --- --- Executing: sh version...
--- --- --- Executing: sh ip interface brief...
--- --- --- Executing: sh interface status...
... [Commands execute one by one] ...
--- --- --- Executing: sh logging | include May 12...

--- STEP 9: FINISHED ---
--- --- STEP 9.1: Saved running-config as .cfg and audit as .txt
--- --- >> to Primary:
--- --- >> >> config: bootflash:ROUTER-20260512-230501-BF.cfg
--- --- >> >> audit:  bootflash:ROUTER-20260512-230501-BF.txt
--- --- STEP 9.2: Saved running-config as .cfg and audit as .txt
--- --- >> to Secondary:
--- --- >> >> config: usbflash0:ROUTER-20260512-230501-BF.cfg
--- --- >> >> audit:  usbflash0:ROUTER-20260512-230501-BF.txt
------------------------------------------------------------

ROUTER#
