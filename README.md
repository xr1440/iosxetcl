# iosxetcl

* Cisco: IOS-XE: TCL script that saves `running-config` and additional audit settings to flash and USB drive

> [!NOTE]
> [**what each TCL script does: 01-BF-tclscript.tcl / 02-AF-tclscript.tcl**](https://github.com/xr1440/iosxetcl):
> 1. [**automatically detects which USB drive is used**](https://github.com/xr1440/iosxetcl)
>    * if no USB drive detected:
>      * will save config and audit file only to device flash (useful for remote access)
> 2. [**detects automatically device's flash type**: `bootflash:` or `flash:`](https://github.com/xr1440/iosxetcl)
> 3. [**detects automatically (recognizable/not recognizable) specific Cisco device commands: router/switch**](https://github.com/xr1440/iosxetcl)
> 4. [**saves the `running-config` only = as .cfg file**](https://github.com/xr1440/iosxetcl)
>    * to: Cisco router/switch `internal flash` 
>    * to `an external USB drive` (only if detected)
>      * before changes: as files: Hostname-YYYYMMDD-HHMMSS-BF.cfg
>      * after changes: as file: Hostname-YYYYMMDD-HHMMSS-AF.cfg
> 5. [**saves the `additional settings` (Cisco commands) + `running-config` = `audit settings` = as .txt file**](https://github.com/xr1440/iosxetcl)
>    * to: Cisco router/switch `internal flash` 
>    * to `an external USB drive` (only if detected)
>      * before changes: as files: Hostname-YYYYMMDD-HHMMSS-BF.txt
>      * after changes: as file: Hostname-YYYYMMDD-HHMMSS-AF.txt
>    * **both generated `*.txt` files (BF/AF) can be used to:**
>    * **fast compare any abnormal changes before/after changes**

> [!IMPORTANT]
> [**Additional, what the after (AF) Tcl script: `02-AF-tclscript.tcl` does**](https://github.com/xr1440/iosxetcl):
> 1. [**detects the before changes saved configuration to flash**](https://github.com/xr1440/iosxetcl)
> 2. [**perform live DIFF of the before changes saved configuration with the actual running-config**](https://github.com/xr1440/iosxetcl)
>    * using Cisco standard diff command: `show archive config differences ...` 
> 3. [**printout the DIFF on the Cisco CLI**](https://github.com/xr1440/iosxetcl)
> 4. [**saves the DIFF output to a .txt file**](https://github.com/xr1440/iosxetcl)
>    * to: Cisco router/switch `internal flash` 
>    * to `an external USB drive` (only if detected)
>      * as file: Hostname-YYYYMMDD-HHMMSS-AF-DIFF.txt
