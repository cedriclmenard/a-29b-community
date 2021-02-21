dofile(LockOn_Options.common_script_path.."../../../Database/wsTypes.lua")

local count = -1
local function counter()
	count = count + 1
	return count
end

WPN_MASS_IDS = {
    SIM          = -1,
    SAFE         = 0,
    LIVE         = 1,
}

WPN_LATEARM_IDS = {
    GUARD        = -1,
    SAFE         = 0,
    ON           = 1,
}

WPN_AA_SIGHT_IDS = {
    SNAP         = 0,
    LCOS         = 1,
    SSLC         = 2,
}

WPN_AA_RR_SRC_IDS = {
    DL          = 0,
    MAN         = 1,
}

WPN_AA_SLV_SRC_IDS = {
    BST         = 0,
    DL          = 1,
}

WPN_AA_COOL_IDS = {
    COOL        = 0,
    WARM        = 1,
}

WPN_AA_SCAN_IDS = {
    SCAN        = 0,
    SPOT        = 1,
}

WPN_AA_LIMIT_IDS = {
    TD          = 0,
    BP          = 1,
}

WPN_MASS = get_param_handle("WPN_MASS")
WPN_LATEARM = get_param_handle("WPN_LATEARM")

WPN_STO_1_JET = get_param_handle("WPN_STO_1_JET")
WPN_STO_2_JET = get_param_handle("WPN_STO_2_JET")
WPN_STO_3_JET = get_param_handle("WPN_STO_3_JET")
WPN_STO_4_JET = get_param_handle("WPN_STO_4_JET")
WPN_STO_5_JET = get_param_handle("WPN_STO_5_JET")
WPN_AA_SEL = get_param_handle("WPN_AA_SEL")
WPN_AG_SEL = get_param_handle("WPN_AG_SEL")
WPN_READY = get_param_handle("WPN_READY")
WPN_GUNS_L = get_param_handle("WPN_GUNS_L")
WPN_GUNS_R = get_param_handle("WPN_GUNS_R")

WPN_RELEASE = get_param_handle("WPN_RELEASE")

function get_wpn_aa_sel()
    return WPN_AA_SEL:get()
end

function set_wpn_aa_sel(sto)
    return WPN_AA_SEL:set(sto)
end

function get_wpn_ag_sel()
    return WPN_AG_SEL:get()
end

function set_wpn_ag_sel(sto)
    return WPN_AG_SEL:set(sto)
end


function get_wpn_sto_jet(index)
    if index == 1 then return WPN_STO_1_JET:get()
    elseif index == 2 then return WPN_STO_2_JET:get()
    elseif index == 3 then return WPN_STO_3_JET:get()
    elseif index == 4 then return WPN_STO_4_JET:get()
    elseif index == 5 then return WPN_STO_5_JET:get()
    end
end

function set_wpn_sto_jet(index, value)
    if index == 1 then return WPN_STO_1_JET:set(value)
    elseif index == 2 then return WPN_STO_2_JET:set(value)
    elseif index == 3 then return WPN_STO_3_JET:set(value)
    elseif index == 4 then return WPN_STO_4_JET:set(value)
    elseif index == 5 then return WPN_STO_5_JET:set(value)
    end
end

function get_wpn_mass()
    return WPN_MASS:get()
end

function get_wpn_latearm()
    return WPN_LATEARM:get()
end

function set_wpn_selected_storage(pos)
    local wpn = GetDevice(devices.WEAPON_SYSTEM)
    if wpn then wpn:performClickableAction(device_commands.WPN_SELECT_STO, pos) end
end

local WEAPONS_NAMES = {}
WEAPONS_NAMES["{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}"] = "AIM9L"
WEAPONS_NAMES["{A-29B TANK}"]                           = "TANK"
WEAPONS_NAMES["{DB769D48-67D7-42ED-A2BE-108D566C8B1E}"] = "GBU12"
WEAPONS_NAMES["{00F5DAC4-0466-4122-998F-B1A298E34113}"] = "M117"
WEAPONS_NAMES["{FD90A1DC-9147-49FA-BF56-CB83EF0BD32B}"] = "LAU61"
WEAPONS_NAMES["{4F977A2A-CD25-44df-90EF-164BFA2AE72F}"] = "LAU68"
WEAPONS_NAMES["{0D33DDAE-524F-4A4E-B5B8-621754FE3ADE}"] = "GBU16"
WEAPONS_NAMES["{GBU_49}"] = "GBU49"
WEAPONS_NAMES["AGM114x2_OH_58"] = "AGM114"
WEAPONS_NAMES["{BCE4E030-38E9-423E-98ED-24BE3DA87C32}"] = "MK82"

function get_wpn_weapon_name(clsid)
    return WEAPONS_NAMES[clsid] or "NONAME"
end

function get_wpn_ag_ready()
    return get_avionics_master_mode_ag() and not get_avionics_onground() and (get_wpn_mass() == WPN_MASS_IDS.LIVE and get_wpn_latearm() == WPN_LATEARM_IDS.ON and WPN_AG_SEL:get() ~= 0)
end


function get_wpn_aa_msl_ready()
    return get_avionics_master_mode_aa() and get_wpn_aa_sel() > 0 and
        get_wpn_mass() == WPN_MASS_IDS.LIVE and get_wpn_latearm() == WPN_LATEARM_IDS.ON and not get_avionics_onground()
end

function get_wpn_aa_ready()
    return get_wpn_aa_msl_ready() or get_wpn_guns_ready()
end

function get_wpn_guns_ready()
    local master_mode = get_avionics_master_mode()
    return (master_mode == AVIONICS_MASTER_MODE_ID.DGFT_B or master_mode == AVIONICS_MASTER_MODE_ID.DGFT_L or
    master_mode == AVIONICS_MASTER_MODE_ID.GUN or master_mode == AVIONICS_MASTER_MODE_ID.GUN_R
    or master_mode == AVIONICS_MASTER_MODE_ID.CCIP -- quick fix
    ) and
    get_wpn_latearm() == WPN_LATEARM_IDS.ON and get_wpn_mass() == WPN_MASS_IDS.LIVE and (WPN_GUNS_L:get() + WPN_GUNS_R:get()) > 0
end