# Optionally set board_part. Part alone is enough for this repo:
# constraints come from xdc, MIG from mig_<board>.prj (Custom).
# Digilent/Xilinx board files are nice-to-have, not required.
proc sy_set_board_part {boardName} {
    if {$boardName eq ""} {
        puts "INFO: XILINX_BOARD empty — using part only"
        return
    }
    if {[catch {set_property board_part $boardName [current_project]} err]} {
        puts "WARNING: board_part '$boardName' unavailable ($err); continuing with part only"
    }
}
