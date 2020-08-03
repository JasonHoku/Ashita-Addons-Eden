--[[
Copyright © 2016, Sammeh of Quetzalcoatl
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of JobChange nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Sammeh BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]



_addon.name = 'Ashita Job Change'
_addon.author = 'Sammeh - Ported to Ashita|Eden by PCP'
_addon.version = '0.2'


require 'windower.shim'
require 'common'
require 'ffxi.recast'
require 'logging'
require 'timer'
res = require 'resources'


jobQueue = { };  -- Table to hold commands queued for sending
jobDelay        = 1; -- The delay to prevent spamming packets.
jobTimer        = 0.1;    -- The current time used for delaying packets.

jobs_table =  {
    [0] = {id=0,en="None",ja="なし",ens="NON",jas=""},
    [1] = {id=1,en="Warrior",ja="戦士",ens="WAR",jas="戦"},
    [2] = {id=2,en="Monk",ja="モンク",ens="MNK",jas="モ"},
    [3] = {id=3,en="White Mage",ja="白魔道士",ens="WHM",jas="白"},
    [4] = {id=4,en="Black Mage",ja="黒魔道士",ens="BLM",jas="黒"},
    [5] = {id=5,en="Red Mage",ja="赤魔道士",ens="RDM",jas="赤"},
    [6] = {id=6,en="Thief",ja="シーフ",ens="THF",jas="シ"},
    [7] = {id=7,en="Paladin",ja="ナイト",ens="PLD",jas="ナ"},
    [8] = {id=8,en="Dark Knight",ja="暗黒騎士",ens="DRK",jas="暗"},
    [9] = {id=9,en="Beastmaster",ja="獣使い",ens="BST",jas="獣"},
    [10] = {id=10,en="Bard",ja="吟遊詩人",ens="BRD",jas="詩"},
    [11] = {id=11,en="Ranger",ja="狩人",ens="RNG",jas="狩"},
    [12] = {id=12,en="Samurai",ja="侍",ens="SAM",jas="侍"},
    [13] = {id=13,en="Ninja",ja="忍者",ens="NIN",jas="忍"},
    [14] = {id=14,en="Dragoon",ja="竜騎士",ens="DRG",jas="竜"},
    [15] = {id=15,en="Summoner",ja="召喚士",ens="SMN",jas="召"},
    [16] = {id=16,en="Blue Mage",ja="青魔道士",ens="BLU",jas="青"},
    [17] = {id=17,en="Corsair",ja="コルセア",ens="COR",jas="コ"},
    [18] = {id=18,en="Puppetmaster",ja="からくり士",ens="PUP",jas="か"},
    [19] = {id=19,en="Dancer",ja="踊り子",ens="DNC",jas="踊"},
    [20] = {id=20,en="Scholar",ja="学者",ens="SCH",jas="学"},
    [21] = {id=21,en="Geomancer",ja="風水士",ens="GEO",jas="風"},
    [22] = {id=22,en="Rune Fencer",ja="魔導剣士",ens="RUN",jas="剣"},
    [23] = {id=23,en="Monipulator",ja="モンストロス",ens="MON",jas="MON"},
}

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local NOMAD_POINTER         = 0x00;
local ZONE_FLAGS_OFFSET1    = 0x09;
local ZONE_FLAGS_OFFSET2    = 0x17;
local ZONE_FLAGS_OFFSET3    = 0x00;
local ZONE_FLAGS_POINTER    = 0x00;

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Locate the mog house check pointer..
    local pointer = ashita.memory.findpattern('FFXiMain.dll', 0, '0544FE00000FBF2925FFFF00003BC5????4283C10283FA04', 0x00, 0x00);
    if (pointer == 0) then
        err('Failed to find required pointer. (1)');
        return;
    end
    NOMAD_POINTER = pointer;

    -- Locate the zone flags pointer..
    pointer = ashita.memory.findpattern('FFXiMain.dll', 0, '8B8C24040100008B90????????0BD18990????????8B15????????8B82', 0x00, 0x00);
    if (pointer == 0) then
        err('Failed to find required pointer. (2)');
        return;
    end

    -- Obtain the offset from the function..
    local offset = ashita.memory.read_uint32(pointer + ZONE_FLAGS_OFFSET1);
    if (offset == 0) then
        err('Failed to read required offset. (2)');
        return;
    end
    ZONE_FLAGS_OFFSET3 = offset;

    -- Obtain the pointer to the zone flags..
    pointer = ashita.memory.read_uint32(pointer + ZONE_FLAGS_OFFSET2);
    if (pointer == 0) then
        err('Failed to read required pointer. (2)');
        return;
    end
    ZONE_FLAGS_POINTER = pointer;
end);


function jobchange(job,main_sub)
	
	print("DEBUG INFO by PCP: Job:"..job.." JobID:nil")
	   
	if job and main_sub then 
		if main_sub == 'main' then 
			local packet = struct.pack('I2I2BBBB', 0x100, 0, job, 0, 0, 0):totable()
			table.insert(jobQueue, { 0x100, packet})

			print("JobChange: Success")
		elseif main_sub == 'sub' then
			local packet = struct.pack('I2I2BBBB', 0x100, 0, 0, job, 0, 0):totable()
			table.insert(jobQueue, { 0x100, packet})
			print("JobChange: Success")
		end
	end
end


function process_queue()
    if  (os.clock() >= (jobTimer + jobDelay)) then
        jobTimer = os.clock();
		
        -- Ensure the queue has something to process..
        if (#jobQueue > 0) then
            -- Obtain the first queue entry..
            local data = table.remove(jobQueue, 1);

            -- Send the queued object..
			print("Sending packet #"..(#jobQueue + 1))
			AddOutgoingPacket(data[1], data[2]);
			
        end
    end
end

ashita.register_event('render', function()
    -- Process the objectives packet queue..
    process_queue();
end);


ashita.register_event('command', function(command, ntype)
   -- Get the arguments of the command..
   local args = command:args();

   if (args[1] ~= '/jobchange' and args[1] ~= '/jc') then
	   return false;
   end
   
   if (args[1] == '/jc' and args[2] == 'test') then
	   moghouse = ashita.memory.read_uint8(NOMAD_POINTER + 0x0F)
	   print(string.format("0x%X", moghouse))
   end

   local main_sub = ''
   local job = ''

   if (#args >= 2 and (args[1] == '/jobchange' or args[1] == '/jc')) then
	if (#args >= 2 and args[2] == 'main') then
			job = args[3]:lower()
			main_sub = 'main'
		elseif (#args >= 2 and args[2] == 'sub') then
			job = args[3]:lower()
			main_sub = 'sub'
		elseif (#args >= 2 and args[2] == 'reset') then
			main_sub = 'sub'
			print("Reseting job")
			main_sub = 'sub'
			local SubJob = AshitaCore:GetDataManager():GetPlayer():GetSubJob();
			local subjobstring = jobs_table[SubJob].ens
			job = subjobstring:lower()
		else
			print("Usage: /jc main|sub job (ie /jc main whm)")
		end
		
		local conflict = find_conflict(job)
		
		
		
			jobid = find_job(job)
			
			if jobid == (nil)
			then
		   
		   -------------------------
		   print("DEBUG INFO by PCP: Job:"..job.." JobID:tablev")
	   
			else
		print("JobChange:Set1 jobid success!")
		if jobid then 
		--	local npc = find_job_change_npc()
			print("JobChange:Set2")
			if jobid then
				if not conflict then 
					print("JobChange:Set3")
					jobchange(jobid,main_sub)
				else
					local temp_job = find_temp_job()			
					print("JobChange: Conflict with "..conflict)
					if main_sub == conflict then 
						print("JobChange:Set4")
						jobchange(temp_job,main_sub)
						jobchange(jobid,main_sub)
					else
						jobchange(temp_job,conflict)
						jobchange(jobid,main_sub)
					end
				end
			else
				print("JobChange: Not close enough to a Moogle!")
			end		
		else
			print("JobChange: Could not change "..command.." to "..job:upper().."")
		end end
	else
		print("Usage: /jc main|sub job (ie /jc main whm)")
	end

    return false;
	
end);

function find_conflict(job)
	local MainJob = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
	local SubJob = AshitaCore:GetDataManager():GetPlayer():GetSubJob();

	local mainjobstring = jobs_table[MainJob].ens
	local subjobstring = jobs_table[SubJob].ens

	if mainjobstring == job:upper() then
		return "main"
	end
	if subjobstring == job:upper() then
		return "sub"
	end
end

function find_temp_job()
	local starting_jobs = {
	-- WAR, MNK, WHM, BLM, THF, RDM - main starting jobs.
		["WAR"] = 1,
		["MNK"] = 2,
		["WHM"] = 3,
		["BLM"] = 4,
		["RDM"] = 5,
		["THF"] = 6,
	}
	for index,value in pairs(starting_jobs) do
		if not find_conflict(index) then 
			return value
		end
	end
end


function find_job(job)

	for index,value in pairs(jobs_table) do
		if value.ens:lower() == job then 
			local jobid = index
			return index	
		end 	
-- DEBUG INFO by PCP
	end 
	--[[
		Small rant/request/can't figure out a better way.
		windower.ffxi.get_player().jobs includes all jobs regardless if you have it unlocked.  I expected self.jobs["GEO"] to be nil if I didn't have it.  For now going to use a list of the KI's for 
		Job emotes to see which jobs are unlocked. 
	
	local job_gesture_ids = {
		-- Pulled from resources. 12/26/2016
		["WAR"] = 1738,
		["MNK"] = 1739,
		["WHM"] = 1740,
		["BLM"] = 1741,
		["RDM"] = 1742,
		["THF"] = 1743,
		["PLD"] = 1744,
		["DRK"] = 1745,
		["BST"] = 1746,
		["BRD"] = 1747,
		["RNG"] = 1748,
		["SAM"] = 1749,
		["NIN"] = 1750,
		["DRG"] = 1751,
		["SMN"] = 1752,
		["BLU"] = 1753,
		["COR"] = 1754,
		["PUP"] = 1755,
		["DNC"] = 1756,
		["SCH"] = 1757,
		["GEO"] = 2963,
		["RUN"] = 2964,
	}
--	local job_gesture = job_gesture_ids[job:upper()]
	
			]]
		
	print("Warn: No Ki Detect")
end

function find_job_change_npc()
	found = nil
	local valid_zones = { 
		-- Zones with a nomad moogle / green thumb moogle, taken from Resources
		-- All other zones check if mog_house
		[26] = {id=26,en="Tavnazian Safehold",ja="タブナジア地下壕",search="TavSafehld"},
		[53] = {id=53,en="Nashmau",ja="ナシュモ",search="Nashmau"},
		[247] = {id=247,en="Rabao",ja="ラバオ",search="Rabao"},
		[248] = {id=248,en="Selbina",ja="セルビナ",search="Selbina"},
		[249] = {id=249,en="Mhaura",ja="マウラ",search="Mhaura"},
		[250] = {id=250,en="Kazham",ja="カザム",search="Kazham"},
		[252] = {id=252,en="Norg",ja="ノーグ",search="Norg"},	
	}
	local zone = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
	local moghouse = ashita.memory.read_uint8(NOMAD_POINTER + 0x0F)
	if not (valid_zones[zone]) and moghouse == 0x74 then 
		print('JobChange: Not in a zone with a Change NPC')
		return
	end

	for x = 0, 2303 do
		local e = GetEntity(x);
		if (e ~= nil and e.WarpPointer ~= 0) then
			if e.Name == 'Moogle' or e.Name == 'Nomad Moogle' or e.Name == 'Green Thumb Moogle' then
			distance = e.Distance
			found = 1
				if math.sqrt(distance)<6 then 
					return found
				end
			end;
		end
	end
end