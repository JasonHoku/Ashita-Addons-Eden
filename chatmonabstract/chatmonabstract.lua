--[[
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

_addon.author   = 'atom0s - Sounds by PCP';
_addon.name     = 'Chatmon ~Abstract~';
_addon.version  = '3.0.0';

require 'common'

----------------------------------------------------------------------------------------------------
-- Configurations
----------------------------------------------------------------------------------------------------
local default_config =
{
    alerts =
    {
        -- Settings for when an incoming tell happens..
        ['tell'] =
        {
            enabled         = true,
            sound           = 'incoming_tell.wav',
            repeat_delay    = 5
        },
        
        -- Settings for when an incoming GM tell happens..
        ['gmtell'] =
        {
            enabled         = true,
            sound           = 'GM_alert.wav',
            repeat_delay    = 5
        },
        
        -- Settings for when an incoming chat message contains your name..
        ['linkshell'] =
        {
            enabled         = true,
            sound           = 'talked_about.wav',
            repeat_delay    = 5
        },
        ['party'] =
        {
            enabled         = true,
            sound           = 'talked_about.wav',
            repeat_delay    = 5
        },
        ['say'] =
        {
            enabled         = true,
            sound           = 'talked_about.wav',
            repeat_delay    = 5
        },
        
        -- Settings for when an incoming party invite occurs..
        ['invite'] =
        {
            enabled         = true,
            sound           = 'party_invite.wav',
            repeat_delay    = 5
        },
        
        -- Settings for when you are mentioned in an emote..
        ['emote'] =
        {
            enabled         = true,
            sound           = 'incoming_emote.wav',
            repeat_delay    = 5
        },
        
        -- Settings for when you are examined..
        ['examined'] =
        {
            enabled         = true,
            sound           = 'you_have_been_examined.wav',
            repeat_delay    = 5
        },
        
        -- Settings for when you gain a skillup..
        ['skillup'] =
        {
            enabled         = true,
            sound           = 'skillup.wav',
            repeat_delay    = 5
        },
        
        -- Settings for when you have a full inventory..
        ['inventory'] =
        {
            enabled         = true,
            sound           = 'full_inventory.wav',
            repeat_delay    = 5
        },     
    }
};
local chatmon_config = default_config;

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local chatmon = 
{
    talk_gmtell_last_alert      = 0,
    talk_linkshell_last_alert   = 0,
    talk_party_last_alert       = 0,
    talk_say_last_alert         = 0,
    talk_tell_last_alert        = 0,
    invite_last_alert           = 0,
    emote_last_alert            = 0,
    examined_last_alert         = 0,
    skillup_last_alert          = 0,
    inventory_full_last_alert   = 0,
};

---------------------------------------------------------------------------------------------------
-- func: play_alert_sound
-- desc: Small wrapper to play a sound clip from a static location.
---------------------------------------------------------------------------------------------------
local function play_alert_sound(name)
    -- Ensure the main config table exists..
    if (chatmon_config == nil or type(chatmon_config) ~= 'table') then
        return false;
    end
    
    -- Ensure the alerts table exists..
    local t = chatmon_config.alerts;
    if (t == nil or type(t) ~= 'table') then
        return false;
    end
    
    -- Ensure the configuration table exists for the given name..
    t = t[name];
    if (t == nil or type(t) ~= 'table') then
        return false;
    end

    -- Play the sound file..
    local fullpath = string.format('%s\\sounds\\%s', _addon.path, t.sound);
    ashita.misc.play_sound(fullpath);
end

---------------------------------------------------------------------------------------------------
-- func: alert_enabled
-- desc: Determines if the given alert exists and is enabled.
---------------------------------------------------------------------------------------------------
local function alert_enabled(name)
    -- Ensure the main config table exists..
    if (chatmon_config == nil or type(chatmon_config) ~= 'table') then
        return false;
    end
    
    -- Ensure the alerts table exists..
    local t = chatmon_config.alerts;
    if (t == nil or type(t) ~= 'table') then
        return false;
    end
    
    -- Ensure the configuration table exists for the given name..
    t = t[name];
    if (t == nil or type(t) ~= 'table') then
        return false;
    end
    
    -- Attempt to obtain the enabled flag..
    local enabled = t.enabled;
    if (enabled == nil) then
        return false;
    end
    
    return enabled;
end

---------------------------------------------------------------------------------------------------
-- func: alert_delay
-- desc: Returns the alerts configured delay.
---------------------------------------------------------------------------------------------------
local function alert_delay(name)
    -- Ensure the main config table exists..
    if (chatmon_config == nil or type(chatmon_config) ~= 'table') then
        return 5;
    end
    
    -- Ensure the alerts table exists..
    local t = chatmon_config.alerts;
    if (t == nil or type(t) ~= 'table') then
        return 5;
    end
    
    -- Ensure the configuration table exists for the given name..
    t = t[name];
    if (t == nil or type(t) ~= 'table') then
        return 5;
    end
    
    -- Attempt to obtain the repeat_delay flag..
    local repeat_delay = t.repeat_delay;
    if (repeat_delay == nil) then
        return 5;
    end
    
    return tonumber(repeat_delay);
end

---------------------------------------------------------------------------------------------------
-- func: is_inventory_full
-- desc: Returns if the inventory is full.
---------------------------------------------------------------------------------------------------
local function is_inventory_full()
    local inventory = AshitaCore:GetDataManager():GetInventory();
    
    -- Obtain the current inventory count..
    local count = 0;
    for x = 1, 80 do
        local item = inventory:GetItem(0, x);
        if (item.Id ~= 0) then
            count = count + 1;
        end
    end
    
    -- Determine if we have a full inventory..
    if (count >= (inventory:GetContainerMax(0) - 1)) then
        return true;
    end
    
    return false;
end

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Load the configuration file..
    chatmon_config = ashita.settings.load_merged(_addon.path .. '/settings/chatmon.json', chatmon_config);
end);

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Save the configuration file..
    ashita.settings.save(_addon.path .. '/settings/chatmon.json', chatmon_config);
end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when the addon is asked to handle a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Ensure we should handle this command..
    local args = command:args();
    if (#args <= 1 or args[1] ~= '/chatmon') then
        return false;
    end
    
    -- We are handling a mute command..
    if (#args == 3 and args[2] == 'mute') then
        -- Ensure this alert exists to mute..
        if (chatmon_config['alerts'][args[3]] ~= nil) then
            -- Disable this alert..
            chatmon_config['alerts'][args[3]].enabled = false;
            print(string.format('ChatMon: Disabled alerts for: \'%s\'', args[3]));
            return true;
        end
        return true;
    end
    
    -- We are handling an enable command..
    if (#args == 3 and args[2] == 'enable') then
        -- Ensure this alert exists to enable..
        if (chatmon_config['alerts'][args[3]] ~= nil) then
            -- Enable this alert..
            chatmon_config['alerts'][args[3]].enabled = true;
            print(string.format('ChatMon: Enabled alerts for: \'%s\'', args[3]));
            return true;
        end
        return true;
    end
    
    return true;
end);
    
---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, chat)
    -- Obtain the current players name..
    local name = string.lower(AshitaCore:GetDataManager():GetParty():GetMemberName(0));
    
    -- /say - /shout - /yell
    if ((mode == 9 or mode == 10 or mode == 11) and alert_enabled('say') and chat:lower():contains(name)) then
        if ((os.time() - chatmon.talk_say_last_alert) >= alert_delay('say')) then
            chatmon.talk_say_last_alert = os.time();
            play_alert_sound('say');
        end
    end
            
    -- /party
    if (mode == 13 and alert_enabled('party') and chat:lower():contains(name)) then 
        if ((os.time() - chatmon.talk_party_last_alert) >= alert_delay('party')) then
            chatmon.talk_party_last_alert = os.time();
            play_alert_sound('party');
        end
    end
    
    -- /linkshell
    if (mode == 14 and alert_enabled('linkshell') and chat:lower():contains(name)) then 
        if ((os.time() - chatmon.talk_linkshell_last_alert) >= alert_delay('linkshell')) then
            chatmon.talk_linkshell_last_alert = os.time();
            play_alert_sound('linkshell');
        end
    end
    
 
    -- /emote
    if (mode == 15 and alert_enabled('emote') and chat:lower():contains(name)) then 
        if ((os.time() - chatmon.emote_last_alert) >= alert_delay('emote')) then
            chatmon.emote_last_alert = os.time();
            play_alert_sound('emote');
        end
    end
    
    -- /examined
    if (mode == 208 and alert_enabled('examined')) then
        if ((os.time() - chatmon.examined_last_alert) >= alert_delay('examined')) then
            chatmon.examined_last_alert = os.time();
            play_alert_sound('examined');
        end
    end
    
    -- Skill Gain
    if (mode == 129 and alert_enabled('skillup')) then 
        if ((os.time() - chatmon.skillup_last_alert) >= alert_delay('skillup')) then
            chatmon.skillup_last_alert = os.time();
            play_alert_sound('skillup');
        end
    end
    
    -- Party Invite
    if (mode == 391 and alert_enabled('invite')) then 
        if ((os.time() - chatmon.invite_last_alert) >= alert_delay('invite')) then
            chatmon.invite_last_alert = os.time();
            play_alert_sound('invite');
        end
    end
    
    -- Check if inventory is full..
    if (mode ~= 0 and alert_enabled('inventory') and is_inventory_full()) then
        if ((os.time() - chatmon.inventory_full_last_alert) >= alert_delay('inventory')) then
            chatmon.inventory_full_last_alert = os.time();
            play_alert_sound('inventory');
        end
    end
    
    return false;
end );

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
    -- Check for incoming tells..
    if (id == 0x17 and struct.unpack('b', packet, 0x04 + 1) == 0x03) then
        -- Is this a tell from a player..
        if (struct.unpack('b', packet, 0x05 + 1) == 0 and alert_enabled('tell')) then
            if ((os.time() - chatmon.talk_tell_last_alert) >= alert_delay('tell')) then
                chatmon.talk_tell_last_alert = os.time();
                play_alert_sound('tell');
            end
        end
    
        -- Is this a tell from a GM..
        if (struct.unpack('b', packet, 0x05 + 1) ~= 0 and alert_enabled('tell')) then
            if ((os.time() - chatmon.talk_gmtell_last_alert) >= alert_delay('gmtell')) then
                chatmon.talk_gmtell_last_alert = os.time();
                play_alert_sound('gmtell');
            end
        end
    end
    
    -- Incoming emote..
    if (id == 0x5A) then
        local target = struct.unpack('H', packet, 0x08 + 1);
        if (GetPlayerEntity().ServerID == target) then
            if ((os.time() - chatmon.emote_last_alert) >= alert_delay('emote')) then
                chatmon.emote_last_alert = os.time();
                play_alert_sound('emote');
            end
        end
    end
    
    return false;
end);