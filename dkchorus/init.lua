-- Donkey Kong Chorus by Jon Wilson (10yard)
--
-- Tested with latest MAME versions 0.235 and 0.196
-- Compatible with MAME versions from 0.196
--
-- DK sounds are replaced with chorus singers.  The sounds were taken from this video:
-- https://youtu.be/BsfkXoJHyKc
--
-- External sounds were realised using "sounder" by Eli Fulkerston:
-- https://download.elifulkerson.com/files/sounder/
--
-- Minimum start up arguments:
--   mame dkong -plugin dkchorus
-----------------------------------------------------------------------------------------

local exports = {}
exports.name = "dkchorus"
exports.version = "0.1"
exports.description = "Donkey Kong Chorus"
exports.license = "GNU GPLv3"
exports.author = { name = "Jon Wilson (10yard)" }
local dkchorus = exports

function dkchorus.startplugin()
	local last_jump,last_bonus,last_bg,last_dead,last_walk,last_hammer,last_smash = 0,0,0,0,0,0,0
	local sounder_path = "plugins/dkchorus/bin/sounder.exe"
	
	function initialize()
		mame_version = tonumber(emu.app_version())
		if mame_version >= 0.227 then
			cpu = manager.machine.devices[":maincpu"]
			soundcpu = manager.machine.devices[":soundcpu"]
		elseif mame_version >= 0.196 then
			cpu = manager:machine().devices[":maincpu"]
			soundcpu = manager:machine().devices[":soundcpu"]
		else
			print("------------------------------------------------------------")
			print("The dkchorus plugin requires MAME version 0.196 or greater.")
			print("------------------------------------------------------------")
		end
		if cpu ~= nil then
			play("donkeykong")
			mem = cpu.spaces["program"]
			soundmem = soundcpu.spaces["data"]
		end
	end

	function main()
		if cpu ~= nil then
			mode1 = mem:read_u8(0x6005)  -- 1-attract mode, 2-credits entered waiting to start, 3-when playing game
			mode2 = mem:read_u8(0x600a)  -- Status of note: 7-climb scene, 10-how high, 15-dead, 16-game over
			stage = mem:read_u8(0x6227)  -- 1-girders, 2-pie, 3-elevator, 4-rivets, 5-extra/bonus
			clock = os.clock()			
			
			clear_sounds()	

			if mode1 == 2 then
				climbing, howhigh = false, false
			end

			if mode2 == 7 and not climbing then
				climbing = true
				stop()
				play("climb")
			end
						
			if mode2 == 10 and not howhigh then
				howhigh = true
				play("howhigh")
				dead, complete = false, false
			end

			if mode2 == 0xc then
				hammer2 = hammer
				hammer = mem:read_u8(0x6217)
				
				if hammer == 0 and clock - last_bg > 1.25 then
					last_bg = play("background")
				end
				if mem:read_u8(0x6080) ~= 0 and clock - last_walk > 0.35 then
					last_walk = play("walk", 40)
				end
				if mem:read_u8(0x6214) == 1 and clock - last_jump > 0.5 then 
					last_jump = play("jump")
				end
				if (mem:read_u8(0x6225) == 1 or mem:read_u8(0x6340) == 1) and clock - last_bonus > 0.5 then
					last_bonus = play("bonus")
				end
				if hammer == 1 and clock - last_hammer > 2.5 then
					last_hammer = play("hammer")
				end				
				if mem:read_u8(0x6350) == 1 and clock - last_smash > 2 then
					last_smash = play("smash")
				end				
				if stage == 3 and mem:read_u8(0x6396) == 3 then
					play("spring")
				end				
				if hammer == 0 and hammer2 == 1 then
					--stop sounds when hammer expires
					stop()
				end
			end			
			
			if mode2 == 0xd then
				if mem:read_u8(0x639d) == 1 and not dead then
					dead = true
					play("dead")
					howhigh = false
				end
			end

			if mode2 == 22 then
				-- stage is complete
				if not complete then
					if stage == 4 then
						play("level_complete")
					else
						play("stage_complete")
					end
					complete = true
				end
				howhigh = false
			end
		end
	end

	function play(sound, volume)
		volume = volume or 100
		io.popen("start "..sounder_path.." /volume "..tostring(volume).." /id "..sound.." /stopbyid "..sound.." plugins/dkchorus/sounds/"..sound..".wav")
		return os.clock()
	end
	
	function stop()
		io.popen("start "..sounder_path.." /stop")
	end
	
	function clear_sounds()
		-- clear music on soundcpu
		for key=0, 32 do
			soundmem:write_u8(0x0 + key, 0x00)
		end
				
		-- clear soundfx buffer (retain the walking 0x6080 sound)
		for key=0, 11 do
			mem:write_u8(0x6081 + key, 0x00)
		end
	end
	
	emu.register_start(function()
		initialize()
	end)

	emu.register_stop(function()
		stop()
	end)


	emu.register_frame_done(main, "frame")

end
return exports