local currentGameSpeed = 100
local GameSpeed=currentGameSpeed
local performanceHistory = {}
local calibrationPhase = true
local calibrationRounds = 3
local Level =1
local GameStop= false;
local performanceThresholds = {
    {minRatio = 0.7, speed = 120, label = "HARD (High Performance)"},
    {minRatio = 0.5, speed = 100, label = "NORMAL (Average Performance)"},
    {minRatio = 0.0, speed = 80, label = "EASY (Low Performance)"}
}

local modeAddress = 0x05FE
local roundAddress = 0x00B2
local missesAddress = 0x00B3

function calculatePerformanceRatio()
    local misses = memory.readbyte(missesAddress)
    
    local remainingLife = 9 - misses
    local performanceRatio = remainingLife / 9.0
    return performanceRatio
end

function drawDDAHUD()
    local mode = memory.readbyte(modeAddress)
    local round = memory.readbyte(roundAddress)
    local misses = memory.readbyte(missesAddress)
    local performanceRatio = calculatePerformanceRatio()
	      GameSpeed = currentGameSpeed
	local x = 10
    local y = 10
    
    gui.text(x, y,      string.format("Mode: %03d", mode), "white", "black")
    gui.text(x, y + 15, string.format("Round: %03d", round), "white", "black")
    gui.text(x, y + 30, string.format("Misses: %03d", misses), "white", "black")
    gui.text(x, y + 45, string.format("Performance: %.2f", performanceRatio), "white", "black")
    gui.text(x, y + 60, string.format("Speed: %d", currentGameSpeed), "white", "black")
    gui.text(x, y + 75, string.format("Level: %d", Level), "white", "black")
  

 if (round > 3) and ((round % 9) == 0) then
  
	if misses < 6 then
        memory.writebyte(missesAddress, 0)
        misses = memory.readbyte(missesAddress)
		memory.writebyte(roundAddress, 0)
		Level=Level+1
	else
		GameStop = true
    end

end

    if round > calibrationRounds then
        if performanceRatio > 0.7 and GameSpeed~=120 then
            client.pause() 
            GameSpeed = 120
            client.speedmode(GameSpeed)
            client.unpause()
        elseif performanceRatio < 0.5 and GameSpeed~=70 then
            client.pause() 
            GameSpeed = 70
            client.speedmode(GameSpeed)
            client.unpause()
        elseif performanceRatio <= 0.7 and performanceRatio >= 0.5 and GameSpeed~=100 then
            client.pause() 
            GameSpeed = 100
            client.speedmode(GameSpeed)
            client.unpause()
        end
        currentGameSpeed = GameSpeed
    end
    
    local x = 10
    local y = 10
    local color = 0xFFFFFFFF
    local bgcolor = 0xFF000000
    
    gui.text(x, y,      string.format("Mode: %03d", mode), color, bgcolor)
    gui.text(x, y + 15, string.format("Round: %03d", round), color, bgcolor)
    gui.text(x, y + 30, string.format("Misses: %03d", misses), color, bgcolor)
    gui.text(x, y + 45, string.format("Performance: %.2f", performanceRatio), color, bgcolor)
    gui.text(x, y + 60, string.format("Speed: %d", currentGameSpeed), color, bgcolor)
	gui.text(x, y + 75, string.format("Level: %d", Level), color, bgcolor)
end

while GameStop==false do
    drawDDAHUD()
    emu.frameadvance()
end
if(GameStop==true) then
	print("You lost! Game Over")	
	client.pause()
    
end