# --- 1. INITIALIZATION ---
set suffix "AF"

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

# --- 10. AUTO-DETECTION FOR DIFF (TIMESTAMP BASED & HOSTNAME AGNOSTIC) ---
puts "--- STEP 10: Searching for the LATEST 'Before' (-BF.cfg) file ---"

# Search broadly for any -BF.cfg file
set search_pattern "${flash_type}*-BF.cfg"
set found_files [glob -nocomplain $search_pattern]

# Fallback for some IOS-XE versions
if {[llength $found_files] == 0} {
    set search_pattern "${flash_type}/*-BF.cfg"
    set found_files [glob -nocomplain $search_pattern]
}

if {[llength $found_files] == 0} {
    puts ">> NOTICE: No 'Before' file found on $flash_type. Skipping Diff."
} else {
    set latest_time 0
    set before_file ""

    # Loop through all found BF files and pick the one with the newest hardware timestamp
    foreach bfile $found_files {
        set mtime [file mtime $bfile]
        if {$mtime > $latest_time} {
            set latest_time $mtime
            set before_file $bfile
        }
    }

    set bf_human_time [clock format $latest_time -format {%Y-%m-%d %H:%M:%S}]
    puts "--- --- STEP 10.1: SUCCESS! Found latest file: $before_file"
    puts "--- --- STEP 10.2: File Creation Time: $bf_human_time"

# --- 11. DIFF EXECUTION & FILTERING ---
    # Prepare the "After" human time for the report
    set af_human_time [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]

    # Clean up the Before filename path (remove the extra slash if it exists)
    set before_file_clean [string map {"bootflash:/" "bootflash:" "flash:/" "flash:"} $before_file]

    puts "\n--- STEP 11: LIVE CONFIGURATION DIFF REPORT ---"
    set header_sep "--- --- --- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = ="
    
    puts $header_sep
    puts "--- --- ---"
    puts "--- --- --- ### !COMPARING Config: ###"
    puts "--- --- ---"
    puts "--- --- --- Before: $before_file_clean ($bf_human_time)"
    puts "--- --- --- After:  $config_primary ($af_human_time)"
    puts "--- --- ---"
    puts "--- --- --- ------------------------------------------------------------"
    puts "--- --- ---"
    puts "--- --- --- ### !CONTEXTUAL Config Diffs starts now: ###"
    puts "--- --- ---"

    set diff_cmd "show archive config differences $before_file system:running-config"
    
    if {[catch {exec $diff_cmd} raw_diff]} {
        set filtered_diff "Error executing Cisco diff command."
    } else {
        set filtered_diff ""
        set skip_crypto 0
        set skip_banner 0
        
        foreach line [split $raw_diff "\n"] {
            # --- FILTER 1: Crypto Certificates ---
            if {[string match "*crypto pki certificate chain*" $line]} { set skip_crypto 1; continue }
            if {$skip_crypto == 1 && [string match "*quit*" $line]} { set skip_crypto 0; continue }

            # --- FILTER 2: Banners (Catches +banner and -banner) ---
            if {[string match "*banner login*" $line]} { set skip_banner 1; continue }
            if {$skip_banner == 1 && [string match "*^C*" $line]} { set skip_banner 0; continue }

            # --- FILTER 3: System Headers ---
            if {[string match "*Building configuration*" $line]} { continue }
            if {[string match "*Current configuration*" $line]} { continue }
            
            # --- FILTER 4: Redundant Cisco Title ---
            if {[string match "*!Contextual Config Diffs*" $line]} { continue }
            
            # --- APPEND IF NOT SKIPPING ---
            if {$skip_crypto == 0 && $skip_banner == 0} { 
                # Print to CLI live with the triple-dash prefix
                puts "--- --- --- $line"
                append filtered_diff "--- --- --- $line\n" 
            }
        }
    }

    # Check if we actually found any changes
    set clean_check [string trim $filtered_diff]
    if {[string length $clean_check] == 0} {
        puts "--- --- --- No functional differences detected (excluding certificates/banners)."
    }

    puts "--- --- ---"
    puts $header_sep

    # --- 12. SAVE DIFF TO STORAGE ---
    puts "\n--- STEP 12: SAVE DIFF TO STORAGE ---"
    set diff_filename_primary "${flash_type}${file_base}-DIFF.txt"

    # Save to Primary Flash
    if {![catch {open "$diff_filename_primary" w+} df]} {
        puts $df "--- CONFIG DIFF AUDIT ---"
        puts $df $header_sep
        puts $df "--- --- ---"
        puts $df "--- --- --- ### !COMPARING Config: ###"
        puts $df "--- --- ---"
        puts $df "--- --- --- Before: $before_file_clean ($bf_human_time)"
        puts $df "--- --- --- After:  $config_primary ($af_human_time)"
        puts $df "--- --- ---"
        puts $df "--- --- --- ------------------------------------------------------------"
        puts $df "--- --- ---"
        puts $df "--- --- --- ### !CONTEXTUAL Config Diffs starts now: ###"
        puts $df "--- --- ---"
        puts $df $filtered_diff
        puts $df "--- --- ---"
        puts $df $header_sep
        close $df
        puts "--- --- STEP 12.1: Diff results saved to $diff_filename_primary"
    }

    # Save to Secondary USB (if detected in Step 3)
    if {$usb_found == 1} {
        set diff_filename_secondary "${usb_path}${file_base}-DIFF.txt"
        if {![catch {open "$diff_filename_secondary" w+} df_usb]} {
            puts $df_usb "--- CONFIG DIFF AUDIT ---"
            puts $df_usb $header_sep
            puts $df_usb "--- --- ---"
            puts $df_usb "--- --- --- ### !COMPARING Config: ###"
            puts $df_usb "--- --- ---"
            puts $df_usb "--- --- --- Before: $before_file_clean ($bf_human_time)"
            puts $df_usb "--- --- --- After:  $config_primary ($af_human_time)"
            puts $df_usb "--- --- ---"
            puts $df_usb "--- --- --- ------------------------------------------------------------"
            puts $df_usb "--- --- ---"
            puts $df_usb "--- --- --- ### !CONTEXTUAL Config Diffs starts now: ###"
            puts $df_usb "--- --- ---"
            puts $df_usb $filtered_diff
            puts $df_usb "--- --- ---"
            puts $df_usb $header_sep
            close $df_usb
            puts "--- --- STEP 12.2: Diff results saved to $diff_filename_secondary"
        }
    }
}

# --- 13. SCRIPT COMPLETED ---
puts "\n--- STEP 13: SCRIPT COMPLETED ---"
puts "------------------------------------------------------------\n"
