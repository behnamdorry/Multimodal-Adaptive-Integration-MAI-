local baseGameSpeed = 100
local currentGameSpeed = baseGameSpeed
local performanceHistory = {}
local calibrationPhase = true
local calibrationDuels = 3
local GameEnd=false
local Level=1
local performanceThresholds = {
    {minRatio = 0.7, speed = 120, label = "HARD (High Performance)"},    -- عالی: سرعت افزایش
    {minRatio = 0.5, speed = 100, label = "NORMAL (Average Performance)"}, -- متوسط: سرعت نرمال
    {minRatio = 0.0, speed = 70, label = "EASY (Low Performance)"}       -- ضعیف: سرعت کاهش
}
-- تابع برای تبدیل عدد دسیمال به هگز و برگرداندن به صورت رشته

-- تابع برای نوشتن مقدار دسیمال به حافظه (تبدیل خودکار به هگز)
function writeDecimalToMemory(address, decimalValue)
    memory.writebyte(address, decimalValue)
end

-- تابع برای خواندن مقدار از حافظه و برگرداندن به صورت دسیمال
function readDecimalFromMemory(address)
    return memory.readbyte(address)
end

function calculatePerformanceRatio()
    local lifeRemaining = readDecimalFromMemory(0x00C3)
    local performanceRatio = lifeRemaining / 10.0
    return performanceRatio
end

function drawDDAHUD()
    local duelsFought = readDecimalFromMemory(0x00C2)
    local lifeRemaining = readDecimalFromMemory(0x00C3)
    local performanceRatio = calculatePerformanceRatio()
    local GameSpeed = currentGameSpeed
    
    if (duelsFought == 1) then
        writeDecimalToMemory(0x00C3, 9)
        return 0  -- دوئل اول: هیچ امتیازی
    end
	
    if ((duelsFought > 8) and ((duelsFought % 9) == 0)) then
		if(lifeRemaining>5)then
			writeDecimalToMemory(0x00C3, 9)
			lifeRemaining = readDecimalFromMemory(0x00C3)
			Level=Level+1
			writeDecimalToMemory(0x00C2, 0)
			print("Start Next Level")
			
		else
			GameEnd=true
			print("You lost! Game Over")
		end
        
    end
    
    -- محاسبه میانگین عملکرد و تنظیم دشواری
    if duelsFought > calibrationDuels then
        if ((performanceRatio > 0.7) and (GameSpeed ~= 120)) then
            client.pause() 
            GameSpeed = 120
            client.speedmode(GameSpeed)
            client.unpause()
        elseif (performanceRatio < 0.5) and (GameSpeed ~= 70) then
            client.pause() 
            GameSpeed = 70
            client.speedmode(GameSpeed)
            client.unpause()
        elseif performanceRatio <= 0.7 and performanceRatio >= 0.5 and (GameSpeed ~= 100) then
            client.pause() 
            GameSpeed = 100
            client.speedmode(GameSpeed)
            client.unpause()
        end
        currentGameSpeed = GameSpeed
    end
    
    -- نمایش اطلاعات پایه
gui.text(10, 10, string.format("Duels: %d (0x%X)", duelsFought, duelsFought), "white", "black")
gui.text(10, 25, string.format("Life: %d/9 (0x%X)", lifeRemaining, lifeRemaining), "white", "black")
gui.text(10, 40, string.format("Performance: %.2f", performanceRatio), "white", "black")
gui.text(10, 55, string.format("Speed: %d", currentGameSpeed), "white", "black")
gui.text(10, 70, string.format("Level: %d", Level), "white", "black")
end

-- حلقه اصلی
while not GameEnd do
    drawDDAHUD()
    emu.frameadvance()
end

if GameEnd then
    client.pause() 
end