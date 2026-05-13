# --- 1. INITIALIZATION ---
set suffix "BF"

set hostname [info hostname]
set current_date [clock format [clock seconds] -format {%Y%m%d}]
set current_time [clock format [clock seconds] -format {%H%M%S}]
set log_filter [clock format [clock seconds] -format {%b %e}]

puts "\n\n--- STEP 1: $current_date, $current_time: Running script $suffix changes ---"
puts "--- --- STEP 1.1: Script initialization: set hostname, date/time, log filter ---"

# --- 2. INTERNAL PLATFORM DETECTION (Always Primary) ---
puts "--- STEP 2: Detecting Internal Flash Type ---"
if {[catch {exec "dir bootflash:"} result] == 0} {
    set flash_type "bootflash:"
} else {
    set flash_type "flash:"
}
puts "--- --- STEP 2.1: Primary Storage set to: $flash_type"

# --- 3. USB AUTO-DETECTION (Always Secondary) ---
puts "--- STEP 3: Physical USB Auto-Detection ---"
set usb_found 0
set usb_path ""

foreach drive {usbflash0: usbflash1: usb0: usb1:} {
    if {[catch {exec "dir $drive"} result] == 0} {
        set usb_path $drive
        set usb_found 1
        puts "--- --- STEP 3.1: USB detected at $usb_path (Secondary Backup Enabled)"
        break
    }
}

if {$usb_found == 0} {
    puts ">> NOTICE: No USB detected. Proceeding with Internal Flash only."
}

# --- 4. FILENAME GENERATION ---
puts "--- STEP 4: Filename generation: hostname-YYYYMMDD-HHMMSS-$suffix ---"
set file_base      "${hostname}-${current_date}-${current_time}-${suffix}"

# Primary (Internal Flash)
puts "--- --- STEP 4.1: Generates filename for internal flash"
set config_primary "${flash_type}${file_base}.cfg"
set audit_primary  "${flash_type}${file_base}.txt"

# Secondary (USB - used only if found)
if {$usb_found == 1} {
    puts "--- --- STEP 4.2: Generates filename for USB ---"
    set config_secondary "${usb_path}${file_base}.cfg"
    set audit_secondary  "${usb_path}${file_base}.txt"
}

# --- 5. CISCO TERMINAL PREPARATION ---
puts "--- STEP 5: Setting terminal length 0 ---"
exec "terminal length 0"

# --- 6. CONFIG BACKUP ---
puts "--- STEP 6: Saving Config Backups ---"
puts "--- --- STEP 6.1: Saving to Primary ($flash_type)..."
catch {exec "sh running-config | redirect $config_primary"}

if {$usb_found == 1} {
    puts "--- --- STEP 6.2: Saving to Secondary ($usb_path)..."
    catch {exec "sh running-config | redirect $config_secondary"}
}

# --- 7. LOADING COMMANDS FROM EXTERNAL FILE OR MANUAL ENTRY ---
puts "--- STEP 7: Initializing Cisco command list for the audit file ---"
set commands {}
set cmd_filename "commands.txt"

# Define paths to check: Flash first, then USB
set flash_path "${flash_type}${cmd_filename}"
set usb_path_file "${usb_path}${cmd_filename}"

if {[file exists $flash_path]} {
    set cmd_source $flash_path
} elseif {$usb_found == 1 && [file exists $usb_path_file]} {
    set cmd_source $usb_path_file
} else {
    set cmd_source "MANUAL"
}

if {$cmd_source ne "MANUAL"} {
    # --- OPTION A: Load from File ---
    if {![catch {open "$cmd_source" r} cf]} {
        while {[gets $cf line] >= 0} {
            set line [string trim $line]
            if {$line ne "" && ![string match "#*" $line]} { 
                lappend commands $line 
            }
        }
        close $cf
        puts "--- --- SUCCESS: Loaded [llength $commands] commands from $cmd_source"
        foreach c $commands { puts "--- --- --- Found: $c" }
    }
} else {
    # --- OPTION B: Manual Entry Mode ---
    puts "--- --- WARNING: 'commands.txt' not found on Flash or USB."
    puts "--- --- MANUAL MODE: Enter/Paste your 'show' commands below."
    puts "--- --- SAFETY TIP: Paste no more than 20 lines at a time to protect VTY."
    puts "--- --- Type 'DONE' or press Enter on an empty line when finished."
    puts "------------------------------------------------------------"
    
    while {1} {
        puts -nonewline "Enter Command: "
        flush stdout
        gets stdin manual_cmd
        set manual_cmd [string trim $manual_cmd]
        
        if {$manual_cmd eq "" || [string toupper $manual_cmd] eq "DONE"} { break }
        
        lappend commands $manual_cmd
    }
    puts "------------------------------------------------------------"
    puts "--- --- SUCCESS: Manual entry complete ([llength $commands] commands captured)."
}

# Add dynamic log command at the end
lappend commands "sh logging | include $log_filter"

# --- 8. AUDIT SNAPSHOT EXECUTION ---
puts "--- STEP 8: Starting Audit Snapshot ---"
# Fixed the dynamic string here to prevent Tcl errors
if {$usb_found == 1} {
    puts "--- --- STEP 8.1: Writing commands to $flash_type and $usb_path ---"
} else {
    puts "--- --- STEP 8.1: Writing commands to $flash_type ---"
}

foreach cmd $commands {
    set timestamp [clock format [clock seconds] -format {%H:%M:%S}]
    puts "--- --- --- Executing: $cmd..."

    # Execution Logic
    if {[catch {exec $cmd} result]} {
        set final_output "Command not recognizable on this platform\n($result)"
    } elseif {[string trim $result] == ""} {
        set final_output "Command recognized but returned no data / Not applicable"
    } else {
        set final_output $result
    }

    # WRITE TO PRIMARY (Internal Flash)
    set f [open $audit_primary a+]
    puts $f "\n!\n--- HOST: $hostname | CMD: $cmd | TIME: $timestamp ---\n!\n$final_output\n!"
    close $f

    # WRITE TO SECONDARY (USB) - Only if detected
    if {$usb_found == 1} {
        set f_usb [open $audit_secondary a+]
        puts $f_usb "\n!\n--- HOST: $hostname | CMD: $cmd | TIME: $timestamp ---\n!\n$final_output\n!"
        close $f_usb
    }
}

# --- 9. SUMMARY ---
puts "--- STEP 9: SUMMARY ---"
puts "--- --- STEP 9.1: Saved running-config as .cfg and audit as .txt"
puts "--- --- >> to Primary:"
puts "--- --- >> >> config: $config_primary"
puts "--- --- >> >> audit:  $audit_primary"

if {$usb_found == 1} {
    puts "--- --- STEP 9.2: Saved running-config as .cfg and audit as .txt"
    puts "--- --- >> to Secondary:"
    puts "--- --- >> >> config: $config_secondary"
    puts "--- --- >> >> audit:  $audit_secondary"
}
puts "------------------------------------------------------------\n"
