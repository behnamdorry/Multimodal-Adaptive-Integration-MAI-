--local created_targets = 0
local Number_of_all_targets = -1  -- Total birds counted
local last_target1_state = 0  -- Previous state of target 1
local last_target2_state = 0  -- Previous state of target 2
local last_Number_of_all_targets = 0  -- Previous target count for stage detection
local hit_ratio = 0
local GameSpeed=100
local Game_Mode = memory.readbyte(0x05FE)
local Number_of_successful_shots = memory.readbyte(0x00AA)
function count_birds()
    -- Read target states and target count
    local target1_state = memory.readbyte(0x0301)
    local target2_state = memory.readbyte(0x0351)
	Number_of_successful_shots = memory.readbyte(0x00AA)
    -- Detect stage start (when 0x00AA becomes 10)
    if Number_of_successful_shots == 10 and last_Number_of_all_targets ~= 10 then
        last_Number_of_all_targets = 0  -- Reset last_Number_of_all_targets to 0
    else
        last_Number_of_all_targets = Number_of_successful_shots  -- Update last_Number_of_all_targets normally
    end
    -- Count target 1 if state changes from 0x00 to any non-zero value
    if target1_state ~= 0 and last_target1_state == 0 then
        Number_of_all_targets = Number_of_all_targets + 1
    end
    -- Count target 2 if state changes from 0x00 to any non-zero value
    if target2_state ~= 0 and last_target2_state == 0 then
        Number_of_all_targets = Number_of_all_targets + 1
    end
    if Number_of_all_targets >= 10 then
		Number_of_all_targets = -1  -- Total birds counted
		last_target1_state = 0  -- Previous state of target 1
		last_target2_state = 0  -- Previous state of target 2
		last_Number_of_all_targets = 0  -- Previous target count for stage detection
		hit_ratio = 0
		GameSpeed=100
		if Game_Mode == 0 then
			Number_of_all_targets = 1
		end
		if Game_Mode == 1 then
			Number_of_all_targets = 2
		end
		if Game_Mode == 2 then
			Number_of_all_targets = 2
		end
    end
    last_target1_state = target1_state
    last_target2_state = target2_state
	hit_ratio=calculate_hit_ratio();
	
	draw_info()
    return Number_of_all_targets
end
function B_print()
    print("Game_Mode:"..Game_Mode)
	print("Number_of_successful_shots:"..Number_of_successful_shots)
	print("Number_of_all_targets:"..Number_of_all_targets)
end
function calculate_hit_ratio()
    if Number_of_all_targets > 0 then
		local tp_ratio=(Number_of_successful_shots / Number_of_all_targets)
		if(tp_ratio>1)then
			tp_ratio=1
		end
		
		return tp_ratio
    else
        return 0
    end
end

function draw_info()
    -- Display the information on the screen
    gui.text(10, 90, "GameSpeed: " .. GameSpeed, "white", "black")
    gui.text(10, 10, "Game Mode: " .. Game_Mode, "white", "black")
    gui.text(10, 30, "Successful Shots: " .. Number_of_successful_shots, "white", "black")
    gui.text(10, 50, "Number of all targets: " .. Number_of_all_targets, "white", "black")
    gui.text(10, 70, "Hit Ratio: " .. string.format("%.2f", hit_ratio), "white", "black")
end
while true do
	 Game_Mode = memory.readbyte(0x05FE)
	count_birds()
    emu.frameadvance()
	if(Number_of_all_targets<=1) then
		client.speedmode(100)
	end
	if(Number_of_all_targets>=3)then
    if(hit_ratio<=0.5)then
		client.pause() 
		GameSpeed=70
        client.speedmode(GameSpeed)
		client.unpause()
    end
    if(hit_ratio>0.5)and(hit_ratio<0.7)then  -- Also fixed the && to 'and' (Lua uses 'and' not &&)
        client.pause() 
		GameSpeed=100
		client.speedmode(GameSpeed)
		client.unpause()
    end
    if(hit_ratio>=0.7)then           -- Changed => to >=
		client.pause() 
		GameSpeed=120
        client.speedmode(GameSpeed)
		client.unpause()
    end
end
	
end