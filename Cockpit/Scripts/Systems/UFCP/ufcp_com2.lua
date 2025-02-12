-- Constants

local SEL_IDS = {
    MAN_FREQUENCY = 0,
    CHANNEL = 1,
    PRST_FREQUENCY = 2,
    NEXT_FREQUENCY = 3,
    POWER = 4,
    MODULATION = 5,
    SQL = 6,
    FORMAT = 7,
    MODE = 8,
    ECCM = 9
}

local NET_SEL_IDS = {
    FORMAT = 0,
    NET = 1,
    MASTER = 2,
    SYNC = 3,
    DATE = 4,
    TIME = 5,
    DATASET = 6,
    ERASE = 7,
}

local UFCP_COM2_ECCM_IDS = {
    PLAIN = 1,
    COMSEC = 2,
    TRANSEC = 3,
    HAILING = 4,
}

UFCP_COM2_ECCM_IDS[1] = "P"
UFCP_COM2_ECCM_IDS[2] = "C"
UFCP_COM2_ECCM_IDS[3] = "T"
UFCP_COM2_ECCM_IDS[4] = "H"

local UFCP_COM2_DTC_READ = get_param_handle("UFCP_COM2_DTC_READ")
UFCP_COM2_DTC_READ:set("")

-- Variables
ufcp_com2_max_channel = 79
ufcp_com2_frequency_manual = 118.0
ufcp_com2_frequency_next = 136.0
ufcp_com2_sync = false
ufcp_com2_por = false
ufcp_com2_data = false
ufcp_com2_eccm = UFCP_COM2_ECCM_IDS.PLAIN

ufcp_com2_net = 0
ufcp_com2_net_master = false
ufcp_com2_net_date = "01/01/00"
ufcp_com2_net_time = "00:00:00"
ufcp_com2_net_dataset = 1

ufcp_com2_erase = false

local allow_erase_at = -1.0
local show_sync_message_until = -1.0
local cancel_erase_at = -1.0

-- Dataset 1
ufcp_com2_nets1 = {}
ufcp_com2_eccms1 = {}

-- Dataset 2
ufcp_com2_nets2 = {}
ufcp_com2_eccms2 = {}

for i = 1,ufcp_com2_max_channel+1 do ufcp_com2_nets1[i] = 0 end
for i = 1,ufcp_com2_max_channel+1 do ufcp_com2_nets2[i] = 0 end
for i = 1,ufcp_com2_max_channel+1 do ufcp_com2_eccms1[i] = 1 end
for i = 1,ufcp_com2_max_channel+1 do ufcp_com2_eccms2[i] = 1 end

ufcp_com2_memory = {
    frequency_last = 0,
    tx_last = false,
    rx_last = false,
    modulation_last = 0,
    sql_last = 0, 
}
-- Methods

function ufcp_com2_select_channel(channel)
    -- Set NET and ECCM
    if ufcp_com2_net_dataset == 1 then
        ufcp_com2_net = ufcp_com2_nets1[channel + 1]
        ufcp_com2_eccm = ufcp_com2_eccms1[channel + 1]
    elseif ufcp_com2_net_dataset == 2 then
        ufcp_com2_net = ufcp_com2_nets2[channel + 1]
        ufcp_com2_eccm = ufcp_com2_eccms2[channel + 1]
    end

    ufcp_com2_net_master = false
end

local function ufcp_com2_channel_validate(text, save)
    if text:len() >= ufcp_edit_lim or save then
        local number = tonumber(text)
        local radio = GetDevice(devices.VUHF2_RADIO)
        if number ~= nil and radio:is_channel_in_range(number) then
            if radio:get_channel_mode() then
                ufcp_com2_select_channel(number)
                radio:set_channel(number)
            else
                local freq = radio:get_frequency()
                radio:set_channel(number)
                radio:set_frequency(freq)
            end

            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local function ufcp_com2_frequency_man_validate(text, save)
    if text:len() == 3 then
        text = text .. "."
    end

    -- If enter is pressed before there are three digits.
    if save then 
        for i = 1,3-ufcp_edit_pos do text = text .. "0" end
    end

    if text:len() >= ufcp_edit_lim or save then
        local number = tonumber(text)
        if number ~= nil and is_com_frequency(number) then
            ufcp_com2_frequency_manual = number
            local radio = GetDevice(devices.VUHF2_RADIO)
            if not radio:get_channel_mode() then
                radio:set_frequency(ufcp_com2_frequency_manual * 1e6)
            end

            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local function ufcp_com2_frequency_prst_validate(text, save)
    if text:len() == 3 then
        text = text .. "."
    end

    -- If enter is pressed before there are three digits.
    if save then 
        for i = 1,3-ufcp_edit_pos do text = text .. "0" end
    end

    if text:len() >= ufcp_edit_lim or save then
        local number = tonumber(text)
        local radio = GetDevice(devices.VUHF2_RADIO)
        if number ~= nil and radio:is_frequency_in_range(number * 1e6) then
            radio:set_channel_frequency(radio:get_channel(), number * 1e6)

            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local function ufcp_com2_frequency_next_validate(text, save)
    if text:len() == 3 then
        text = text .. "."
    end

    -- If enter is pressed before there are three digits.
    if save then 
        for i = 1,3-ufcp_edit_pos do text = text .. "0" end
    end

    if text:len() >= ufcp_edit_lim or save then
        local number = tonumber(text)
        local radio = GetDevice(devices.VUHF2_RADIO)
        if number ~= nil and radio:is_frequency_in_range(number * 1e6) then
            ufcp_com2_frequency_next = number

            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local function ufcp_com2_net_validate(text, save)
    if text:len() >= ufcp_edit_lim or save then
        local number = tonumber(text)
        local radio = GetDevice(devices.VUHF2_RADIO)
        if number ~= nil and radio:is_channel_in_range(number) then
            ufcp_com2_net = number

            if radio:get_channel_mode() then
                if ufcp_com2_net_dataset == 1 then
                    ufcp_com2_nets1[radio:get_channel() + 1] = number
                elseif ufcp_com2_net_dataset == 2 then
                    ufcp_com2_nets2[radio:get_channel() + 1] = number
                end
            end

            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local function ufcp_com2_net_date_validate(text, save)
    if text:len() == 2 or text:len() == 5 then
        text = text .. "/"
    end

    if text:len() >= ufcp_edit_lim or save then
        if text:len() >= ufcp_edit_lim and tonumber(text:sub(1,2)) > 0 and tonumber(text:sub(1,2)) <= 31 and tonumber(text:sub(4,5)) > 0 and tonumber(text:sub(4,5)) <= 12 then
            -- TODO check if the day exists in the month (heads up for february and leap years)
            ufcp_com2_net_date = text
            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local function ufcp_com2_net_time_validate(text, save)
    if text:len() == 2 or text:len() == 5 then
        text = text .. ":"
    end

    if text:len() >= ufcp_edit_lim or save then
        if text:len() >= ufcp_edit_lim and tonumber(text:sub(1,2)) < 24 and tonumber(text:sub(4,5)) < 60 and tonumber(text:sub(7,8)) < 60 then
            ufcp_com2_net_time = text

            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

-- Reads data from a DTC, when DB or ALL is selected in CMFD DTE
function ufcp_com2_load_dtc()
    if UFCP_COM2_DTC_READ:get() ~= "" then
        dofile(UFCP_COM2_DTC_READ:get())

        for _, value in pairs(COMM2) 
        do
            radio:set_channel_frequency(value.ID, value.Freq.Mhz * 1e6 + value.Freq.Khz * 1000)
        end
        
        UFCP_COM2_DTC_READ:set("")
    end
end

local FIELD_INFO = {
    [SEL_IDS.CHANNEL] = {2, ufcp_com2_channel_validate},
    [SEL_IDS.MAN_FREQUENCY] = {7, ufcp_com2_frequency_man_validate},
    [SEL_IDS.PRST_FREQUENCY] = {7, ufcp_com2_frequency_prst_validate},
    [SEL_IDS.NEXT_FREQUENCY] = {7, ufcp_com2_frequency_next_validate},
}

local NET_FIELD_INFO = {
    [NET_SEL_IDS.NET] = {2, ufcp_com2_net_validate},
    [NET_SEL_IDS.DATE] = {8, ufcp_com2_net_date_validate},
    [NET_SEL_IDS.TIME] = {8, ufcp_com2_net_time_validate},
}

local sel = 0
local max_sel = 10
local net_sel = 0
local net_max_sel = 8
function update_com2()
    local text = ""

    local radio = GetDevice(devices["VUHF2_RADIO"])


    if ufcp_sel_format == UFCP_FORMAT_IDS.COM2 then
        -- Line 1

        -- Format
        text = text .. "  "
        if sel == SEL_IDS.FORMAT then text = text .. "*" else text = text .. " " end
        text = text .. "COM2"
        if sel == SEL_IDS.FORMAT then text = text .. "*" else text = text .. " " end
        text = text .. " "

        -- Data
        if ufcp_com2_data then text = text .. "DATA " else text = text .. "VOICE" end

        -- Mode
        if sel == SEL_IDS.MODE then text = text .. "*" else text = text .. " " end
        if radio:is_on() then
            if radio:get_guard_on_off() then
                text = text .. "TR+G"
            else 
                text = text .. "TR  "
            end
        else
            text = text .. "OFF "
        end
        if sel == SEL_IDS.MODE then text = text .. "*" else text = text .. " " end

        -- ECCM
        if sel == SEL_IDS.ECCM then text = text .. "*" else text = text .. " " end
        text = text .. UFCP_COM2_ECCM_IDS[ufcp_com2_eccm]
        if sel == SEL_IDS.ECCM then text = text .. "*" else text = text .. " " end
        text = text .. "   \n"

        -- Line 2
        text = text .. " MAN  "
        if sel == SEL_IDS.MAN_FREQUENCY then text = text .. "*" else text = text .. " " end
        if sel == SEL_IDS.MAN_FREQUENCY and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. string.format("%07.3f", ufcp_com2_frequency_manual) end
        if sel == SEL_IDS.MAN_FREQUENCY then text = text .. "*" else text = text .. " " end
        text = text .. "     "
        
        -- SOK
        if ufcp_com2_sync then text = text .. "SOK" else text = text .. "   " end
        text = text .. " \n"
   
        -- Line 3
        text = text .. " PRST "
        if sel == SEL_IDS.CHANNEL then text = text .. "*" else text = text .. " " end
        if sel == SEL_IDS.CHANNEL and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. string.format("%02.0f", radio:get_channel()) end
        text = text .. "^"
        if sel == SEL_IDS.CHANNEL or sel == SEL_IDS.PRST_FREQUENCY then text = text .. "*" else text = text .. " " end
        if sel == SEL_IDS.PRST_FREQUENCY and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. string.format("%07.3f", radio:get_channel_frequency(radio:get_channel()) / 1e6 ) end
        if sel == SEL_IDS.PRST_FREQUENCY then text = text .. "*" else text = text .. " " end
        text = text .. "  "
        if radio:is_transmitting() then text = text .. "TX" else text = text .. "  " end
        text = text .. " "
        text = text .. "\n"
    
        -- Line 4
        text = text .. " NEXT "
        if sel == SEL_IDS.NEXT_FREQUENCY then text = text .. "*" else text = text .. " " end
        if sel == SEL_IDS.NEXT_FREQUENCY and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. string.format("%07.3f", ufcp_com2_frequency_next) end
        if sel == SEL_IDS.NEXT_FREQUENCY then text = text .. "*" else text = text .. " " end
        text = text .. "     "
        text = text .. " "
        if radio:is_receiving() then text = text .. "RX" else text = text .. "  " end
        text = text .. " "
        text = text .. "\n"
  
        -- Line 5
        text = text .. " POWER"
        if sel == SEL_IDS.POWER then text = text .. "*" else text = text .. " " end
        local power = radio:get_transmitter_power()
        if power > 7 then
            text = text .. "HIGH"
        elseif power > 3 then
            text = text .. "MED "
        else 
            text = text .. "LOW "
        end
        if sel == SEL_IDS.POWER then text = text .. "*" else text = text .. " " end
        text = text .. " "
        if sel == SEL_IDS.MODULATION then text = text .. "*" else text = text .. " " end
        if radio:get_modulation() == UFCP_COM_MODULATION_IDS.FM then
            text = text .. "FM"
        else
            text = text .. "AM"
        end
        if sel == SEL_IDS.MODULATION then text = text .. "*" else text = text .. " " end

        text = text .. "  "
        
        if sel == SEL_IDS.SQL then text = text .. "*" else text = text .. " " end
        text = text .. "SQL"
        if sel == SEL_IDS.SQL then text = text .. "*" else text = text .. " " end

        if not radio:get_channel_mode() then 
            text = replace_pos(text, 28)
            text = replace_pos(text, 32)
        else
            text = replace_pos(text, 53)
            text = replace_pos(text, 58)
        end
    
        if radio:get_squelch() then
            text = replace_pos(text, 122)
            text = replace_pos(text, 126)
        end
   
        if sel == SEL_IDS.CHANNEL and ufcp_edit_pos > 0 then
            text = replace_pos(text, 59)
            text = replace_pos(text, 63)
        elseif sel == SEL_IDS.MAN_FREQUENCY and ufcp_edit_pos > 0 then
            text = replace_pos(text, 34)
            text = replace_pos(text, 42)
        elseif sel == SEL_IDS.PRST_FREQUENCY and ufcp_edit_pos > 0 then
            text = replace_pos(text, 64)
            text = replace_pos(text, 72)
        elseif sel == SEL_IDS.NEXT_FREQUENCY and ufcp_edit_pos > 0 then
            text = replace_pos(text, 84)
            text = replace_pos(text, 92)
        end
    elseif ufcp_sel_format == UFCP_FORMAT_IDS.COM2_NET then
        text = text .. " "
        if net_sel == NET_SEL_IDS.FORMAT then text = text .. "*" else text = text .. " " end
        text = text .. "COM2-NET"
        if net_sel == NET_SEL_IDS.FORMAT or net_sel == NET_SEL_IDS.NET then text = text .. "*" else text = text .. " " end

        -- NET
        if net_sel == NET_SEL_IDS.NET and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. string.format("%02d", ufcp_com2_net) end
        if net_sel == NET_SEL_IDS.NET then text = text .. "*" else text = text .. " " end
        text = text .. "  "

        -- Master
        if net_sel == NET_SEL_IDS.MASTER then text = text .. "*" else text = text .. " " end
        if ufcp_com2_net_master then
            text = text .. "MSTR"
        else
            text = text .. "SLV "
        end
        if net_sel == NET_SEL_IDS.MASTER then text = text .. "*" else text = text .. " " end

        text = text .. "  \n"

        -- Sync
        if net_sel == NET_SEL_IDS.SYNC then text = text .. "*" else text = text .. " " end
        text = text .. "SYNC"
        if net_sel == NET_SEL_IDS.SYNC then text = text .. "*" else text = text .. " " end

        if ufcp_time < show_sync_message_until then
            if ufcp_com2_sync then
                text = text .. "OK  "
            else
                text = text .. "FAIL"
            end
        else
            text = text .. "    "
            show_sync_message_until = -1.0
        end

        text = text .. "          "

        -- SOK
        if ufcp_com2_sync then text = text .. "SOK" else text = text .. "   " end
        text = text .. " \n"

        -- Date
        text = text .. " DATE"
        if net_sel == NET_SEL_IDS.DATE then text = text .. "*" else text = text .. " " end
        if net_sel == NET_SEL_IDS.DATE and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. ufcp_com2_net_date end
        if net_sel == NET_SEL_IDS.DATE then text = text .. "*" else text = text .. " " end
        text = text .. "         \n"

        -- Time
        text = text .. " TIME"
        if net_sel == NET_SEL_IDS.TIME then text = text .. "*" else text = text .. " " end
        if net_sel == NET_SEL_IDS.TIME and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. ufcp_com2_net_time end
        if net_sel == NET_SEL_IDS.TIME then text = text .. "*" else text = text .. " " end
        text = text .. "         \n"

        -- Dataset
        if net_sel == NET_SEL_IDS.DATASET then text = text .. "*" else text = text .. " " end
        text = text .. "DATASET" .. ufcp_com2_net_dataset
        if net_sel == NET_SEL_IDS.DATASET then text = text .. "*" else text = text .. " " end
        text = text .. "       "

        -- Erase
        if ufcp_time > cancel_erase_at then
            ufcp_com2_erase = false
            allow_erase_at = -1.0
            cancel_erase_at = -1.0
        end
        if net_sel == NET_SEL_IDS.ERASE then text = text .. "*" else text = text .. " " end
        if ufcp_com2_erase then text = text .. blink_text("ERASE",1,5) else text = text .. "ERASE" end
        if net_sel == NET_SEL_IDS.ERASE then text = text .. "*" else text = text .. " " end



        if net_sel == NET_SEL_IDS.NET and ufcp_edit_pos > 0 then
            text = replace_pos(text, 11)
            text = replace_pos(text, 14)
        elseif net_sel == NET_SEL_IDS.DATE and ufcp_edit_pos > 0 then
            text = replace_pos(text, 56)
            text = replace_pos(text, 65)
        elseif net_sel == NET_SEL_IDS.TIME and ufcp_edit_pos > 0 then
            text = replace_pos(text, 81)
            text = replace_pos(text, 90)
        end
    end

    UFCP_TEXT:set(text)
end

function SetCommandCom2(command,value)
    -- Move cursor
    if ufcp_sel_format == UFCP_FORMAT_IDS.COM2 then
        if command == device_commands.UFCP_JOY_DOWN and ufcp_edit_pos == 0 and value == 1 then
            sel = (sel + 1) % max_sel
        elseif command == device_commands.UFCP_JOY_UP and ufcp_edit_pos == 0 and value == 1 then
            sel = (sel - 1) % max_sel
        end
    elseif ufcp_sel_format == UFCP_FORMAT_IDS.COM2_NET then
        if command == device_commands.UFCP_JOY_DOWN and ufcp_edit_pos == 0 and value == 1 then
            net_sel = (net_sel + 1) % net_max_sel
        elseif command == device_commands.UFCP_JOY_UP and ufcp_edit_pos == 0 and value == 1 then
            net_sel = (net_sel - 1) % net_max_sel
        end
    end

    -- Cycle field
    if ufcp_sel_format == UFCP_FORMAT_IDS.COM2 then
        if command == device_commands.UFCP_JOY_RIGHT and value == 1 then
            if sel == SEL_IDS.FORMAT then
                ufcp_sel_format = UFCP_FORMAT_IDS.COM2_NET
            elseif sel == SEL_IDS.POWER then
                local radio = GetDevice(devices["VUHF2_RADIO"])
                local power = radio:get_transmitter_power()
                if power > 7 then
                    radio:set_transmitter_power(1)
                elseif power > 3 then
                    radio:set_transmitter_power(10)
                else 
                    radio:set_transmitter_power(5)
                end
            elseif sel == SEL_IDS.MODULATION and value == 1 then
                local radio = GetDevice(devices["VUHF2_RADIO"])
                radio:set_modulation((radio:get_modulation() + 1) % 2)
            elseif sel == SEL_IDS.MODE then
                local radio = GetDevice(devices["VUHF2_RADIO"])
                if radio:is_on() then
                    if radio:get_guard_on_off() then
                        radio:set_on_off(false)
                        radio:set_guard_on_off(false)
                    else 
                        radio:set_guard_on_off(true)
                    end
                else
                    radio:set_on_off(true)
                    radio:set_guard_on_off(false)
                end
            elseif sel == SEL_IDS.ECCM then
                ufcp_com2_eccm = ufcp_com2_eccm % 4 + 1;

                -- Save data
                local radio = GetDevice(devices["VUHF2_RADIO"])
                if radio:get_channel_mode() then
                    if ufcp_com2_net_dataset == 1 then
                        ufcp_com2_eccms1[radio:get_channel() + 1] = ufcp_com2_eccm
                    elseif ufcp_com2_net_dataset == 2 then
                        ufcp_com2_eccms2[radio:get_channel() + 1] = ufcp_com2_eccm
                    end
                end
            end
        end
    elseif ufcp_sel_format == UFCP_FORMAT_IDS.COM2_NET then
        if command == device_commands.UFCP_JOY_RIGHT and value == 1 then
            if net_sel == NET_SEL_IDS.FORMAT then
                ufcp_sel_format = UFCP_FORMAT_IDS.COM2
            elseif net_sel == NET_SEL_IDS.MASTER then
                ufcp_com2_net_master = not ufcp_com2_net_master
            elseif net_sel == NET_SEL_IDS.DATASET then
                ufcp_com2_net_dataset = 3 - ufcp_com2_net_dataset

                local radio = GetDevice(devices["VUHF2_RADIO"])
                if radio:get_channel_mode() then
                    ufcp_com2_select_channel(radio:get_channel())
                end
            end
        end
    end

    -- Activate field
    if ufcp_sel_format == UFCP_FORMAT_IDS.COM2 then
        if command == device_commands.UFCP_0 and value == 1 and ufcp_edit_pos <= 0 then
            local radio = GetDevice(devices["VUHF2_RADIO"])
            if sel == SEL_IDS.MAN_FREQUENCY then
                radio:set_frequency(ufcp_com2_frequency_manual * 1e6)
                ufcp_sel_format = UFCP_FORMAT_IDS.MAIN
            elseif sel == SEL_IDS.CHANNEL then
                radio:set_channel(radio:get_channel())
                ufcp_sel_format = UFCP_FORMAT_IDS.MAIN
            elseif sel == SEL_IDS.NEXT_FREQUENCY then
                local current_frequency_manual = ufcp_com2_frequency_manual
                ufcp_com2_frequency_manual = ufcp_com2_frequency_next
                ufcp_com2_frequency_next = current_frequency_manual
                radio:set_frequency(ufcp_com2_frequency_manual * 1e6)
                ufcp_sel_format = UFCP_FORMAT_IDS.MAIN
            elseif sel == SEL_IDS.SQL then
                radio:set_squelch(not radio:get_squelch())
            end
        elseif command == device_commands.UFCP_ENTR and value == 1 then
            if sel == SEL_IDS.MAN_FREQUENCY or sel == SEL_IDS.CHANNEL or sel == SEL_IDS.PRST_FREQUENCY or sel == SEL_IDS.NEXT_FREQUENCY then
                ufcp_continue_edit("", FIELD_INFO[sel], true)
            end
        end
    elseif ufcp_sel_format == UFCP_FORMAT_IDS.COM2_NET then
        if command == device_commands.UFCP_0 and value == 1 and ufcp_edit_pos <= 0 then
            if net_sel == NET_SEL_IDS.SYNC then
                -- TODO sync with MSTR
                show_sync_message_until = ufcp_time + 3
            elseif net_sel == NET_SEL_IDS.ERASE then
                -- TODO erase COM2 tables
                -- After 1 second, can press again to confirm erase, or clr to cancel.
                -- After 5 seconds, it cancels automatically.

                if not ufcp_com2_erase then
                    -- Request ERASE
                    ufcp_com2_erase = true

                    allow_erase_at = ufcp_time + 1
                    cancel_erase_at = ufcp_time + 6
                elseif ufcp_time > allow_erase_at then
                    local radio = GetDevice(devices["VUHF2_RADIO"])
                    -- Confirm ERASE
                    for i = 1,ufcp_com2_max_channel+1 do radio:set_channel_frequency(i,118 * 1e6) end
                    for i = 1,ufcp_com2_max_channel+1 do ufcp_com2_nets1[i] = 0 end
                    for i = 1,ufcp_com2_max_channel+1 do ufcp_com2_nets2[i] = 0 end
                    for i = 1,ufcp_com2_max_channel+1 do ufcp_com2_eccms1[i] = 1 end
                    for i = 1,ufcp_com2_max_channel+1 do ufcp_com2_eccms2[i] = 1 end

                    if radio:get_channel_mode() then
                        ufcp_com2_select_channel(radio:get_channel())
                        radio:set_channel(radio:get_channel())
                    end
                    ufcp_com2_erase = false
                    allow_erase_at = -1.0
                    cancel_erase_at = -1.0
                end
            end
        end
    end

    -- Increase/Decrease field
    if ufcp_sel_format == UFCP_FORMAT_IDS.COM2 then
        if command == device_commands.UFCP_UP and value == 1 then
            local radio = GetDevice(devices["VUHF2_RADIO"])
            if (sel == SEL_IDS.CHANNEL or sel == SEL_IDS.PRST_FREQUENCY) and ufcp_edit_pos == 0 and radio:is_channel_in_range(radio:get_channel() + 1) then
                if radio:get_channel_mode() then
                    radio:set_channel(radio:get_channel() + 1)
                    ufcp_com2_select_channel(radio:get_channel())
                else
                    local freq = radio:get_frequency()
                    radio:set_channel(radio:get_channel() + 1)
                    ufcp_com2_select_channel(radio:get_channel())
                    radio:set_frequency(freq)
                end
            end
        elseif command == device_commands.UFCP_DOWN and value == 1 then
            local radio = GetDevice(devices["VUHF2_RADIO"])
            if (sel == SEL_IDS.CHANNEL or sel == SEL_IDS.PRST_FREQUENCY) and ufcp_edit_pos == 0 and radio:get_channel() > 0 then
                if radio:get_channel_mode() then
                    radio:set_channel(radio:get_channel() - 1)
                    ufcp_com2_select_channel(radio:get_channel())
                else
                    local freq = radio:get_frequency()
                    radio:set_channel(radio:get_channel() - 1)
                    ufcp_com2_select_channel(radio:get_channel())
                    radio:set_frequency(freq)
                end
                end
        end
    elseif ufcp_sel_format == UFCP_FORMAT_IDS.COM2_NET then

    end

    -- Keypad
    if sel == SEL_IDS.MAN_FREQUENCY or sel == SEL_IDS.CHANNEL or sel == SEL_IDS.PRST_FREQUENCY or sel == SEL_IDS.NEXT_FREQUENCY then
        if command == device_commands.UFCP_1 and value == 1 then
            ufcp_continue_edit("1", FIELD_INFO[sel], false)
        elseif command == device_commands.UFCP_2 and value == 1 then
            ufcp_continue_edit("2", FIELD_INFO[sel], false)
        elseif command == device_commands.UFCP_3 and value == 1 then
            ufcp_continue_edit("3", FIELD_INFO[sel], false)
        elseif command == device_commands.UFCP_4 and value == 1 then
            ufcp_continue_edit("4", FIELD_INFO[sel], false)
        elseif command == device_commands.UFCP_5 and value == 1 then
            ufcp_continue_edit("5", FIELD_INFO[sel], false)
        elseif command == device_commands.UFCP_6 and value == 1 then
            ufcp_continue_edit("6", FIELD_INFO[sel], false)
        elseif command == device_commands.UFCP_7 and value == 1 then
            ufcp_continue_edit("7", FIELD_INFO[sel], false)
        elseif command == device_commands.UFCP_8 and value == 1 then
            ufcp_continue_edit("8", FIELD_INFO[sel], false)
        elseif command == device_commands.UFCP_9 and value == 1 then
            ufcp_continue_edit("9", FIELD_INFO[sel], false)
        elseif command == device_commands.UFCP_0 and value == 1 and ufcp_edit_pos > 0 then
            ufcp_continue_edit("0", FIELD_INFO[sel], false)
        end
    elseif ufcp_sel_format == UFCP_FORMAT_IDS.COM2_NET then
        if command == device_commands.UFCP_1 and value == 1 then
            ufcp_continue_edit("1", NET_FIELD_INFO[net_sel], false)
        elseif command == device_commands.UFCP_2 and value == 1 then
            ufcp_continue_edit("2", NET_FIELD_INFO[net_sel], false)
        elseif command == device_commands.UFCP_3 and value == 1 then
            ufcp_continue_edit("3", NET_FIELD_INFO[net_sel], false)
        elseif command == device_commands.UFCP_4 and value == 1 then
            ufcp_continue_edit("4", NET_FIELD_INFO[net_sel], false)
        elseif command == device_commands.UFCP_5 and value == 1 then
            ufcp_continue_edit("5", NET_FIELD_INFO[net_sel], false)
        elseif command == device_commands.UFCP_6 and value == 1 then
            ufcp_continue_edit("6", NET_FIELD_INFO[net_sel], false)
        elseif command == device_commands.UFCP_7 and value == 1 then
            ufcp_continue_edit("7", NET_FIELD_INFO[net_sel], false)
        elseif command == device_commands.UFCP_8 and value == 1 then
            ufcp_continue_edit("8", NET_FIELD_INFO[net_sel], false)
        elseif command == device_commands.UFCP_9 and value == 1 then
            ufcp_continue_edit("9", NET_FIELD_INFO[net_sel], false)
        elseif command == device_commands.UFCP_0 and value == 1 then
            ufcp_continue_edit("0", NET_FIELD_INFO[net_sel], false)
        end
    end

    -- Clear field
    if ufcp_sel_format == UFCP_FORMAT_IDS.COM2_NET then
        if net_sel == NET_SEL_IDS.ERASE and command == device_commands.UFCP_CLR and value == 1 then
            ufcp_com2_erase = false
        end
    end
end