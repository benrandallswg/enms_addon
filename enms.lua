--[[
* Addons - Copyright (c) 2021 Ashita Development Team
* Contact: https://www.ashitaxi.com/
* Contact: https://discord.gg/Ashita
*
* This file is part of Ashita.
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.

--]]

addon.author   = 'Lorinth';
addon.name     = 'enms';
addon.desc     = 'Tracks when key items are picked up and when they can next be picked up.';
addon.version  = '0.1';

require ('common');
local chat = require('chat');
local imgui = require('imgui');
local settings = require('settings');

enms = T{
    data = nil,
};

local trackedEnmItems = {
    { name="Cosmo%-Cleanse", delayInHours=(3*24) },
    { name="Monarch Beard", delayInHours=(5*24) },
    { name="Miasma Filter", delayInHours=(5*24) },
    { name="Astral Covenant", delayInHours=(5*24) },
    { name="Censer of Antipathy", delayInHours=(5*24) },
    { name="Censer of Animus", delayInHours=(5*24) },
    { name="Censer of Abandonment", delayInHours=(5*24) },
    { name="Censer of Acrimony", delayInHours=(5*24) },
    { name="Zephyr Fan", delayInHours=(5*24) },
    { name="Shaft Gate Operating Dial", delayInHours=(5*24) },
};

local rarityColor = {
	Ready=79,
	Soon=88, -- < 1 day
	OnCooldown=85
}

local defaultConfig = T{
	lastPickedUp={}
}
enms.data = settings.load(defaultConfig);

function pickupItem(keyItem) 
	local now = os.time(os.date('*t'));
	
	for idx,item in ipairs(trackedEnmItems) do
		if string.find(string.lower(keyItem), string.lower(item.name)) then
			print('[ENMs]: Now Tracking ' .. keyItem);
			enms.data.lastPickedUp[item.name] = now;
			settings.save();
			return;
		end
	end
end

function listItems()
	local now = os.time(os.date('*t'));
	
	local tracking = 0;
	for idx,item in ipairs(trackedEnmItems) do
		if enms.data.lastPickedUp[item.name] ~= nil then
			local lastPickedUp = enms.data.lastPickedUp[item.name];
			local timeRemaining = math.max(lastPickedUp + (item.delayInHours * 60 * 60), 0);
			timeRemaining = math.max(timeRemaining - now, 0);
			local seconds = timeRemaining;
			local minutes = math.floor(timeRemaining / 60);
			local hours = math.floor(minutes / 60);
			local days = math.floor(hours / 24);
			
			local color = rarityColor.OnCooldown;
			if (timeRemaining == 0) then
				color = rarityColor.Ready;
				print('- ' .. item.name .. ' -> ' .. chat.color1(rarityColor.Ready, 'READY'));
				tracking = tracking + 1;
				goto continue
			elseif (days == 0) then
				color = rarityColor.Soon;
			end
			
			hours = hours % 24;
			minutes = minutes % 60;
			seconds = seconds % 60;
			
			local dateString = '';
			if (days > 0) then
				dateString = dateString + days .. ' day(s), '; 
			end
			
			if (hours > 0) then
				dateString = dateString + hours .. ' hour(s), ';
			end
			
			if (minutes > 0) then
				dateString = dateString + minutes .. ' minute(s), ';
			end
			
			if (seconds > 0) then
				dateString = dateString + seconds .. ' second(s)';
			end
			
			print('- ' .. item.name .. ' -> ' .. chat.color1(color, dateString));
			tracking = tracking + 1;
			
			::continue::
			
		end
	end
	
	if (tracking == 0)
	then
		print('No items being tracked yet');
	end
end

function all_trim(s)
   return s:match( "^%s*(.-)%s*$" )
end

--[[
* Registers a callback for the settings to monitor for character switches.
--]]
settings.register('settings', 'settings_update', function (s)
    if (s ~= nil) then
        enms.data = s;
    end

    -- Save the current settings..
    settings.save();
end);

--------------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()
	
end);

--------------------------------------------------------------------
ashita.events.register('unload', 'unload_cb', function()

end);

--------------------------------------------------------------------
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/enms')) then
        return;
    end

    -- Block all related commands..
    e.blocked = true;
	
	if (#args == 1 and args[1]:any('/enms')) then
		print('ENM Commands');
		print('/enms list - Lists all enm items and current status for your character.');
        return;
	end

	if (#args == 2 and args[2]:any('list')) then --manually empty the bucket
		listItems();
        return;
    end
end);

--------------------------------------------------------------------
ashita.events.register('text_in', 'ENMS_HandleText', function (e)
    if (e.injected == true) then
        return;
    end
	
	if (string.match(e.message, "Obtained key item:")) then
		local keyItem = all_trim(string.sub(e.message, string.len("Obtained key item:") + 1));
		pickupItem(keyItem);
	end
end);