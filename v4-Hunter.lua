-- This script is ONLY for use with Doormat (DiceBot V4)  It will NOT work with diceBot V3
huntBet = 100 -- Use whole numbers
minbet = 1 -- Use whole numbers
maxbet =  0 -- Use whole numbers

huntMult = 5
maxLossCount = 0 -- Max number of Payout X rolls before aborting

seekChance = 98 -- Change for the site's max chance
lowChance = 0.0001 -- lowest chance the site can go down to

-- minChance = 2.50
chanceInc = 0.010 -- How much to increase chance on a bad run
incDivisor = 1000000 -- When to start raising winMult (12.5 million seems safe so far)
siteMaxProfit = 0.0000000 -- Set to the max profit of the site.  Set to 0 to disable.  This will make sure the profit of the bet will never go above this value if set

isTokens = false -- Set to true for Bitvest tokens
useANSI = true -- Set to false for silent output
toggleHiLo = false -- Auto toggle high / low hunting
startHigh = false -- Start high or low
abortHuntFlag = false

simSkip = 1 -- Set higher for long-term simulation testing
resetCount = 1
-- ***************** IMPORTANT TO CHANGE THESE SETTINGS BEFORE ENABLING OR YOU WILL TIP ME ***********************
autotip = false -- If the isTokens is true, tipping is automatically turned off
-- With auto tip enabled, It will auto tip to your named 
-- alt account when your balance is above bankroll + tipamount 
-- On BitVest, minimum 10k BTC, 50k ETH, and 100k LTC
bankroll = 0.00-- Minimum you want to keep rolling with.  Set to 0 to use your current balance 
tipamount = 0.001 -- How much to tip
bankappend = 0.10 -- How much of your tip amount to add to your bankroll over time in %.  0.10 = 10% Set to 0 for no addition to the bankroll 
receiver = "BlaksBank" -- Who gets the tip? **** CHANGE THIS ****
-- ^^^^^^ CHANGE THE ABOVE VALUE!!!!! ^^^^^^

-- ANSI codes 

esc = string.format("%c[", 27)
clrscr = string.format("%c[2J", 27)
black =  string.format("%c[30m", 27)
red = string.format("%c[31m", 27)
green = string.format("%c[32m", 27)
yellow = string.format("%c[33m", 27)
blue = string.format("%c[34m", 27)
magenta = string.format("%c[35m", 27)
cyan = string.format("%c[36m", 27)
white = string.format("%c[37m", 27)
colorReset = string.format("%c[0m", 27)

-- Initialize rutime variables
firstRun = true
roundCount = 0
rollCount = 0
runProfit = 0
biggestArray = {}
isHunting = false
startHunt = 24.42
stopHunt = 42.27
abortHunt = 4.27
abortLoss = 10000
huntCount = 0
basebet = huntBet
basechance = seekChance
baseHuntMult = huntMult
roundLowest = 99.9999
-- targetAverage = 100 -- starting value

winCount = 0
spent = 0
roundSpent = 0
housePercent = 1
winMult = 1
maxWinMult = 1024 -- Balance * 0.002 -- 512 -- Max multiplier to hit.  siteMaxProfit can lower this value Set to 0 to disable
lossCount = 0
highLowLossCount = 0
highLowAverage = {}
averageCount = 0
averageIndex = 0
averageMax = 8 -- High / Low average switching. 

lastStoredBet = 0

rollHistory = {}
rollHistoryCount = 7 -- How many to store / show
rollHistoryLoc = 0

rollAverage = {}
rollAverageCount = 64
rollAverageIndex = 0 

runState = 0 -- Starting state 
totalWager = 0
oldBaseChance = 0
chanceMult = 1.6666
chanceMax = 1.5
-- tempWinMult = 0
tempCalc = Balance
tippedOut = 0
totalTipped = 0
pct = 0
toTip = 0
lastUpdate = false
if(isTokens == false) then
	tempCalc = tempCalc * 100000000
	minbet = minbet * 0.00000001
	basebet = basebet * 0.00000001
	maxbet = maxbet * 0.00000001
	-- minWinAmount = minWinAmount * 0.00000001
end

-- Initialize the array
for i=0, averageMax do
	highLowAverage[i] = basechance
end

for i=0, rollAverageCount do
	rollAverage[i] = 100
end

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

function drawScreen()
	if(firstRun == true) then
		print(clrscr)
		print(string.format("%s0;0H+--------------------------------------------------------------------------------------+", esc))
		-- print("+------------------------------------------------------------------------------+")
		print("| Time   :                         The Hunter            Site:                         |")
		print("| Round #:        State:                   Balance:                                    |")
		print("| Roll # :                              Run Profit:                                    |")
		print("|                                                                  ID     Rolls        |")
		print("| Result :                             Biggest Bet:                                    |")
		print("| Amount :                             Biggest Win:                                    |")
		print("| Chance :                          Biggest Profit:                                    |")
		print("| Hi / Lo:                            Biggest Loss:                                    |")
		print("| Profit :                                Last Win:                                    |")
		print("| RollAvg:                             Lowest Roll:                                    |")
		print("| Win Count :                 Most / Current Spent:                                    |")
		print("| Strk Count:                          Total Wager:                                    |")
		print("|                                                                                      |")
		print("|       ID       Amount    Roll      Target  Profit          Tip:                      |")
		print("|                                                          % Tip:                      |")
		print("|                                                             BR:                      |")
		print("|                                                           Last:                      |")
		print("|                                                          Total:                      |")
		print("|                                                          Rcver:                      |")
		print("|                                                          Amt >:                      |")
		print("|                                                                                      |")
		print("|                                                                                      |")
		print("+--------------------------------------------------------------------------------------+")
		print("Running...")
	end
	firstRun = false
end

function printLoc(color, Yloc, Xloc, message)
	print(string.format("%s%s%d;%df%s ", color, esc, Yloc, Xloc, message))
end

function commas (num)
  assert (type (num) == "number" or
          type (num) == "string")
  
  local result = ""

  -- split number into 3 parts, eg. -1234.545e22
  -- sign = + or -
  -- before = 1234
  -- after = .545e22

  local sign, before, after =
    string.match (tostring (num), "^([%+%-]?)(%d*)(%.?.*)$")

  -- pull out batches of 3 digits from the end, put a comma before them

  while string.len (before) > 3 do
    result = "," .. string.sub (before, -3, -1) .. result
    before = string.sub (before, 1, -4)  -- remove last 3 digits
  end -- while

  -- we want the original sign, any left-over digits, the comma part,
  -- and the stuff after the decimal point, if any
  return sign .. before .. result .. after

end -- function commas

function updateScreen(lastBet, Stats, Site)
	if useANSI == true and lastBet.Currency != "simulation" or (lastBet.Currency == "simulation" and rollCount % simSkip == 0) or (lastBet.Currency == "simulation" and rollCount == 1) or lastUpdate == true then
	-- if useANSI == true then
		targetAverage = 0
		for i=0, rollAverageCount do
			targetAverage = targetAverage + rollAverage[i]
		end
		targetAverage = targetAverage / rollAverageCount

		drawScreen()
		printLoc(white, 3, 12, roundCount)
		printLoc(white, 4, 12, commas(rollCount))
		printLoc(white, 3, 26, (isHunting and 'Hunting  ' or 'Searching '))
		printLoc(white, 2, 12, os.date("%Y-%m-%d %H:%M:%S", lastBet.Date))
		printLoc(white, 7, 12, string.format("%4.8f   ", lastBet.TotalAmount))
		printLoc(white, 8, 12, string.format("%02.4f   ", lastBet.Chance))
		printLoc(white, 10, 12, string.format("% -4.8f   ", lastBet.Profit))
		-- printLoc(white, 11, 12, string.format("% -4.4f   ", tempWinMult))
		printLoc(white, 11, 12, string.format("%.4f ", targetAverage))
		printLoc(white, 12, 15, string.format("%s   ", commas(winCount)))
		printLoc(white, 13, 15, string.format("%s / %s     ", commas(lossCount), commas(biggestArray[7][0])))
		printLoc(white, 13, 52, string.format("% -4.8f   ", totalWager))
		-- printLoc(white, 2, 52, string.format("%s   ", Site.name))
		printLoc(white, 3, 52, string.format("% -4.8f %s   ", Balance, lastBet.Currency))
		printLoc(white, 2, 64, string.format("%s   ", Site.name))
		printLoc(white, 6, 52, string.format("% -4.8f %d %s  ", biggestArray[0][0], biggestArray[0][1], commas(biggestArray[0][2])))
		printLoc(white, 7, 52, string.format("% -4.8f %d %s  ", biggestArray[1][0], biggestArray[1][1], commas(biggestArray[1][2])))
		printLoc(white, 8, 52, string.format("% -4.8f %d %s  ", biggestArray[5][0], biggestArray[5][1], commas(biggestArray[5][2])))
		printLoc(white, 9, 52, string.format("% -4.8f %d %s  ", biggestArray[2][0], biggestArray[2][1], commas(biggestArray[2][2])))
		-- if(biggestArray[3][0] < 10) then tempspace = " " else tempspace = "" end
		printLoc(white, 10, 52, string.format(" %.8f %d %s %02.4f ", biggestArray[3][0], biggestArray[3][1], commas(biggestArray[3][2]), biggestArray[3][3]))
		if(biggestArray[4][0] < 10) then tempspace = " " else tempspace = "" end
		printLoc(white, 11, 52, string.format(" %s%.4f    %d   ", tempspace, biggestArray[4][0], biggestArray[4][1]))
		printLoc(white, 12, 52, string.format(" %.8f / %.8f ", biggestArray[6][0], spent))
		printLoc(white, 15, 66, string.format(" %s  ", (autotip and 'true' or 'false')))
		printLoc(white, 16, 66, string.format(" %.4f ", pct))
		printLoc(white, 17, 66, string.format(" %.8f ", bankroll))
		printLoc(white, 18, 66, string.format(" %.8f ", toTip))
		printLoc(white, 19, 66, string.format(" %.8f ", totalTipped))
		printLoc(white, 20, 66, string.format(" %s  ", receiver))
		printLoc(white, 21, 66, string.format(" %.8f ", tipamount))
		if(runProfit > 0) then
			printLoc(green, 4, 52, string.format("%- 4.8f   ", runProfit))
		else
			printLoc(red, 4, 52, string.format("%- 4.8f   ", runProfit))
		end
		
		if(lastBet.High == true) then
			printLoc(white, 9, 12, "High")
		else
			printLoc(white, 9, 12, "Low ")
		end

		if(lastBet.Roll < 10) then tempspace = " " else tempspace = "" end
		if(lastBet.Profit > 0) then 
			printLoc(green, 6, 12, string.format("Win! %s%.4f", tempspace, lastBet.Roll))
		else
			printLoc(red, 6, 12, string.format("Lose %s%.4f", tempspace, lastBet.Roll))
		end
		
		tempLoc = rollHistoryLoc
		for i = 0, rollHistoryCount do
			lineColor = white
			if(rollHistory[tempLoc][4] > 0) then lineColor = green end
			-- if(rollHistory[tempLoc][4] < 0) then lineColor = red end
			if(rollHistory[tempLoc][3] == true) then  
				highStr = ">" 
				target = 100 - rollHistory[tempLoc][2]
			else 
				highStr = "<" 
				target = rollHistory[tempLoc][2]
			end
			if(rollHistory[tempLoc][4] < 0 and highStr == ">" and rollHistory[tempLoc][5] < rollHistory[tempLoc][2]) then lineColor = red end
			if(rollHistory[tempLoc][4] < 0 and highStr == "<" and rollHistory[tempLoc][5] > 100 - rollHistory[tempLoc][2]) then lineColor = red end
			if(rollHistory[tempLoc][5] < 10) then rollSpace = " " else rollSpace = "" end
			if(target < 10) then chanceSpace = " " else chanceSpace = "" end
			printLoc(lineColor, 23 - i, 3, string.format("% 12d %.8f %s%02.4f %s %s%02.4f % -.8f ", rollHistory[tempLoc][0], rollHistory[tempLoc][1], rollSpace, rollHistory[tempLoc][5], highStr, chanceSpace, target, rollHistory[tempLoc][4]))
			tempLoc = tempLoc + 1
			if(tempLoc > rollHistoryCount) then tempLoc = 0 end
		end

		print(string.format("%s25;1f%s", esc, colorReset)) -- Set cursor location under box
	end
end

function updateRoundStats(PreviousBet)

	if(PreviousBet.Profit + PreviousBet.TotalAmount >= biggestArray[1][0] and isHunting == true) then  
		biggestArray[1][0] = PreviousBet.Profit + PreviousBet.TotalAmount
		if(PreviousBet.Currency != "simulation") then biggestArray[1][1] = PreviousBet.BetID end
		biggestArray[1][2] = lossCount
--		biggestArray[1][1] = PreviousBet.BetID 
	end

	if(PreviousBet.TotalAmount >= biggestArray[0][0] and isHunting == true) then  
		biggestArray[0][0] = PreviousBet.TotalAmount
		if(PreviousBet.Currency != "simulation") then biggestArray[0][1] = PreviousBet.BetID end
		biggestArray[0][2] = lossCount
--		biggestArray[0][1] = PreviousBet.BetID
	end

	if(PreviousBet.Profit <= biggestArray[2][0] and isHunting == true) then  
		biggestArray[2][0] = PreviousBet.Profit
		if(PreviousBet.Currency != "simulation") then biggestArray[2][1] = PreviousBet.BetID end
		biggestArray[2][2] = lossCount
--		biggestArray[2][1] = PreviousBet.BetID
	end
	
	if(PreviousBet.Profit > 0 and isHunting == true) then  
		biggestArray[3][0] = PreviousBet.Profit + PreviousBet.TotalAmount
		if(PreviousBet.Currency != "simulation") then biggestArray[3][1] = PreviousBet.BetID end
		biggestArray[3][2] = lossCount
		biggestArray[3][3] = PreviousBet.Chance
	end

	if(PreviousBet.Roll <= biggestArray[4][0] and isHunting == true) then  
		biggestArray[4][0] = PreviousBet.Roll
		if(PreviousBet.Currency != "simulation") then biggestArray[4][1] = PreviousBet.BetID end
		biggestArray[4][2] = lossCount
--		biggestArray[4][1] = PreviousBet.BetID
	end

	if(PreviousBet.Profit >= biggestArray[5][0] and isHunting == true) then  
		biggestArray[5][0] = PreviousBet.Profit
		if(PreviousBet.Currency != "simulation") then biggestArray[5][1] = PreviousBet.BetID end
		biggestArray[5][2] = lossCount
--		biggestArray[5][1] = PreviousBet.BetID
	end

	if(roundSpent >= biggestArray[6][0]) then  
		biggestArray[6][0] = roundSpent
	end
	
	if(lossCount >= biggestArray[7][0]) then
		biggestArray[7][0] = lossCount
	end
	
	if(PreviousBet.Roll < roundLowest) then
		roundLowest = PreviousBet.Roll
	end
end

function autoTune(NextBet, PreviousBet, Win)
	-- winAmount = (100 - (100 * (housePercent / 100))) / basechance -- how much you will win for a 1 bet
	winAmount = (100 - (100 * (housePercent / 100))) / NextBet.Chance -- how much you will win for a 1 bet
	winWhole = winAmount
	
	if(PreviousBet.Roll >= 50) then 
		target = 100 - PreviousBet.Roll
	else
		target = PreviousBet.Roll
	end

	rollAverage[rollAverageIndex] = target
	rollAverageIndex = rollAverageIndex + 1
	if(rollAverageIndex >= rollAverageCount) then rollAverageIndex = 0 end
	
	targetAverage = 0
	for i=0, rollAverageCount do
		targetAverage = targetAverage + rollAverage[i]
	end
	targetAverage = targetAverage / rollAverageCount
	
	-- targetAverage = (targetAverage + target ) / 2
	
	if(isTokens == false) then
		winAmount = winAmount * 0.00000001
	end
	if(isHunting == false) then
		-- sleep(0.125)
		if(Win == false) then
			tempcalc = 1 + ((NextBet.Chance / 100) * ((100 - housePercent) / ((100 - housePercent) / 2)))
			needed = (winAmount * 1) + (NextBet.Amount * tempcalc) + spent -- No need to go by balance for next bet. 
			nextMult = needed / winAmount
			
			-- Uncomment below to Change bet amount 
			-- if(nextMult < 1) then nextMult = 1 end
			-- NextBet.Amount =  basebet * (nextMult * 0.1)
			-- NextBet.Amount =  NextBet.Amount + (basebet * nextMult) / (seekChance * 0.75)
			-- NextBet.Amount =  NextBet.Amount * seekChance
			if(NextBet.Amount >= Balance) then 
				resetCount = resetCount * 2
				NextBet.Amount = basebet * resetCount
				print(string.format("Seek bet too large!  resetting. ResetCount: %d", resetCount))
				-- sleep(10)
			end
		else
			-- Add code to determine if it is time to start the hunt, or go back to seeking
			-- printLoc(white, 28, 1, string.format("targetAverage: %.4f ", targetAverage))
			if(targetAverage < startHunt) then
				-- if(runProfit > 0) then -- Make sure we are in profit before actually starting the hunt
					tempcalc = startHunt / lowChance
					NextBet.Chance = targetAverage / startHunt / tempcalc * (abortHunt * 80) -- 5000 -- Use average to determine how big of a hunt chance
					NextBet.Chance = roundLowest -- biggestArray[4][0]
					if(NextBet.Chance < lowChance) then NextBet.Chance = lowChance end
					-- NextBet.Chance = 0.0001
					-- printLoc(white, 28, 1, string.format("Chance: %.8f ", NextBet.Chance))
					-- huntMult 
					NextBet.Amount = minbet * huntMult
					-- print(string.format("starting hunt - huntMult: %d               ", huntMult))
					isHunting = true
					spent = 0
					huntCount = 0
					-- print(string.format("Starting hunt with bet of: %.8f                        ", NextBet.Amount))
					-- sleep(1)
				-- end
				-- roundSpent = 0
			else
				NextBet.Chance = seekChance
				-- NextBet.Amount = basebet
				huntCount = 0
				
			end
			if(isHunting == false) then NextBet.Amount = basebet * resetCount end
			
			
		end
	else
		-- printLoc(white, 29, 1, string.format("Next bet: %.8f ", NextBet.Amount))
		-- printLoc(white, 28, 1, string.format("targetAverage: %.4f ", targetAverage))
		-- sleep(0.25)
		resetCount = 1
		if(Win == true) then -- reset? 
			isHunting = false
			roundCount = roundCount + 1
			for i=0, rollAverageCount do
				rollAverage[i] = 100
			end
			NextBet.Amount = basebet * resetCount
			NextBet.Chance = seekChance
			roundCount = roundCount + 1
			roundLowest = 99.999 -- reset for next round
			if(PreviousBet.TotalAmount == minbet * huntMult) then
				-- huntMult = huntMult + 1
			else
				-- huntMult = baseHuntMult
			end
			-- print(string.format("huntMult: %d               ", huntMult))
			
		else
			-- Add code to not dig too deep before trying to hunt again 
			winTemp = (100 - (100 * (housePercent / 100))) / NextBet.Chance -- how much you will win for a 1 bet
			winTemp = winTemp * minbet -- * huntMult
			if(spent >= winTemp * maxLossCount and maxLossCount != 0 and abortHuntFlag == true) then
				isHunting = false
				for i=0, rollAverageCount do
					rollAverage[i] = 100
				end
				huntCount = 0
				NextBet.Chance = seekChance
				NextBet.Amount = basebet * resetCount
				roundCount = roundCount + 1
				print("Aborting hunt roll count               ")
				sleep(10)
			end
			if(targetAverage >= stopHunt and isHunting == true and abortHuntFlag == true) then -- reset to seeking
				NextBet.Chance = seekChance
				NextBet.Amount = basebet * resetCount
				isHunting = false
				for i=0, rollAverageCount do
					rollAverage[i] = 100
				end
				huntCount = 0
				roundCount = roundCount + 1
				print("Aborting hunt: target average               ")
				sleep(10)
			else
				huntCount = huntCount + 1
				huntAmount = huntCount / winWhole
				-- huntWhole = huntAmount
				if(huntAmount > abortHunt and abortHuntFlag == true) then
					NextBet.Chance = seekChance
					NextBet.Amount = basebet * resetCount
					isHunting = false
					for i=0, rollAverageCount do
						rollAverage[i] = 100
					end
					huntCount = 0
					print("Aborting hunt: huntAmount               ")
					sleep(10)
				else
					-- print(string.format("winTemp: %.8f           ", winTemp))
					tempBet = spent / winTemp * 0.25
					if(tempBet < 1) then tempBet = 1 end
					if(isTokens == false) then huntAmount = huntAmount * 0.00000001 end
					if(huntAmount < minbet) then huntAmount = minbet end
					-- huntAmount = huntAmount * abortHunt -- change later
					huntAmount = minbet * tempBet * huntMult
					NextBet.Amount = huntAmount --  * huntMult -- change later?
					-- NextBet.Amount = minbet * lossCount
					--if(lastStoredBet != string.format("%.8f", huntAmount)) then
						--lastStoredBet = string.format("%.8f", huntAmount)
						-- NextBet.Chance = NextBet.Chance - lowChance
						-- printLoc(white, 29, 1, string.format("Last Stored Bet: %.12f ", lastStoredBet))
					--end
					-- lastStoredBet = string.format("%.8f", NextBet.Amount)
					if(NextBet.Chance <= lowChance) then 
						NextBet.Chance = lowChance
						-- Possibly add abort code here
					end
					-- if(huntAmount >= maxbet * huntMult and maxbet != 0) then 
					if(huntAmount >= maxbet and maxbet != 0) then 
						NextBet.Chance = seekChance
						NextBet.Amount = basebet * resetCount
						isHunting = false
						for i=0, rollAverageCount do
							rollAverage[i] = 100
						end
						huntCount = 0
						print("Aborting hunt: Max Bet               ")
						-- sleep(10)
					end
					-- if(string.format("%.8f", huntAmount) != string.format("%.8f", PreviousBet.TotalAmount)) then
					-- if(huntAmount != minbet) then
						NextBet.Chance = NextBet.Chance + 0.0001 -- May tweak this later.
					-- end
				end
			end
			-- printLoc(white, 29, 1, string.format("Next bet: %.8f ", NextBet.Amount))
			-- sleep(1)
			-- change bet / chance? need to think on this one
		end
	end
	-- printLoc(white, 29, 1, string.format(""))
--	if((winWhole * NextBet.Amount) - NextBet.Amount > siteMaxProfit and siteMaxProfit != 0) then
	if((winWhole * NextBet.Amount) > siteMaxProfit and siteMaxProfit != 0) then
		NextBet.Amount = siteMaxProfit / winWhole
		--printLoc(white, 27, 1, string.format("Max Profit: %.8f ", siteMaxProfit))
		--printLoc(white, 28, 1, string.format("Next Bet: %.8f ", NextBet.Amount))
		--printLoc(white, 29, 1, string.format("winProfit: %.8f ", NextBet.Amount * winWhole))
	end
	if NextBet.Amount > maxbet and maxbet != 0 and isHunting == true then
		NextBet.Amount = maxbet
	end
	if NextBet.Amount > Balance then
		lastUpdate = true
		updateScreen(PreviousBet, Stats, SiteDetails)
		Stop = true
	end
	-- sleep(0.125) -- need to slow it down for testing
	-- print(string.format("Amount: %.8f Chance: %.4f", NextBet.Amount, NextBet.Chance))
	-- printLoc(white, 2, 52, string.format("% -4.8f   ", nextMult))
	-- print(string.format("%s25;1f%s", esc, colorReset)) -- Set cursor location under box
end

function calcChance(NextBet, PreviousBet, Win)
--	if(oldBaseChance == 0) then oldBaseChance = basechance end
--	if(Win) then
--		if(PreviousBet.Roll >= 50) then 
--			target = 100 - PreviousBet.Roll
--		else
--			target = PreviousBet.Roll
--		end
--		highLowAverage[averageCount] = target
--		averageCount = averageCount + 1
--		if(averageCount >= averageMax) then averageCount = 0 end
--		tempAverage = 0
--		for i=0, averageMax do
--			tempAverage = tempAverage + highLowAverage[i]
--		end
--		tempAverage = tempAverage / averageMax
--		NextBet.Chance = tempAverage * chanceMult 
--		if(NextBet.Chance > (oldBaseChance * chanceMax)) then NextBet.Chance = oldBaseChance * chanceMax end
--		tempcalc = string.format("Temp Average: %.4f / chance: %.4f", tempAverage, NextBet.Chance)
--		-- print(tempcalc)
--	else
--		winAmount = (100 - (100 * (housePercent / 100))) / NextBet.Chance -- how much you will win for a 1 bet
--		if(lossCount > winAmount) then
--			NextBet.Chance = NextBet.Chance + chanceInc
--			tempcalc = string.format("New chance: %.4f", NextBet.Chance)
--			-- print(tempcalc)
--		end
--	end
end

function storeBet(PreviousBet, Stats, SiteDetails)
	if(PreviousBet.Currency != "simulation") then rollHistory[rollHistoryLoc][0] = PreviousBet.BetID end-- Roll ID
	rollHistory[rollHistoryLoc][1] = PreviousBet.TotalAmount -- Roll Amount
	rollHistory[rollHistoryLoc][2] = PreviousBet.Chance -- Roll Chance
	rollHistory[rollHistoryLoc][3] = PreviousBet.High -- Roll High
	rollHistory[rollHistoryLoc][4] = PreviousBet.Profit -- Roll Profit
	rollHistory[rollHistoryLoc][5] = PreviousBet.Roll -- Roll Result
	rollHistoryLoc = rollHistoryLoc + 1
	if(rollHistoryLoc > rollHistoryCount) then rollHistoryLoc = 0 end

end

function checkTip(PreviousBet, Stats, Site)
	if(Site.name == "Bitvest") then
		autotip = false
		if(PreviousBet.Currency == "btc") then
			tipamount = 0.0001
		end
		if(PreviousBet.Currency == "ltc") then
			tipamount = 0.001
		end
	end
	if(bankroll == 0 or tippedOut == 1) then 
		tippedOut = 0
		bankroll = Balance 
		tempstr = string.format("\r\nNew bankroll set to: %.8f", bankroll)
		print(tempstr)
	end
	if(autotip == true and isTokens == false and bankroll != 0) then
		if(Balance > bankroll + tipamount + (tipamount * bankappend)) then
			toTip = Balance - bankroll - (tipamount * bankappend)
			totalTipped = totalTipped + toTip
			preTipBalance = Balance
			Tip(receiver, toTip)
 			-- sleep(5)
			postTipBalance = Balance
			bankroll = bankroll + (tipamount * bankappend)
			-- tempstr = string.format("\r\n\r\nTipped %.8f to %s!  New bankroll set to: %.8f\r\nBefore: %.8f\r\nAfter:  %.8f", toTip, receiver, bankroll,preTipBalance, postTipBalance)
			tempstr = string.format("\r\n\r\nWould have Tipped %.8f to %s!\r\nTotal Tipped: %.8f", toTip, receiver, totalTipped)
			-- print(tempstr)
--			tempstr = "\r\nNew Bankroll: banker"
--			tempstr = string.gsub(tempstr, "banker", bankroll)
--			print(tempstr)
--			print("Tipped out!")
			tippedOut = 1
		end 
		tipvalue = bankroll + tipamount + (tipamount * bankappend)
		pct = ((Balance - bankroll) / (tipvalue - bankroll)) * 100
	end
end

function DoDiceBet(PreviousBet, Win, NextBet)

	-- print("Inside DoDiceBet()")
	storeBet(PreviousBet, Stats, SiteDetails)
	spent = spent + PreviousBet.TotalAmount
	roundSpent = roundSpent + PreviousBet.TotalAmount
	runProfit = runProfit + PreviousBet.Profit
	totalWager = totalWager + PreviousBet.TotalAmount
	updateRoundStats(PreviousBet)

	if Win then -- Process a win
		
--		NextBet.Chance = basechance
--		NextBet.Amount = basebet
		-- Reset counters
		if(isHunting == true) then
			-- roundSpent = 0
		else
			roundSpent = 0 
			-- roundSpent = roundSpent - PreviousBet.Profit - PreviousBet.TotalAmount
		end

		spent = 0
		winCount = winCount + 1
		lossCount = 0
		startBalance = Balance
--		tempCalc = Balance
--		if(isTokens == false) then
--			tempCalc = tempCalc * 100000000
--		end
--		tempMult = tempCalc / incDivisor
--
--		if(tempMult < 1) then tempMult = 1 end		
--		winMult = tempMult
--		if(winMult > maxWinMult and maxWinMult != 0) then winMult = maxWinMult end
--		if(tempWinMult != winMult) then
--			-- print(string.format("\r\nNew Win Multiplier: %.2f", winMult))
--			tempWinMult = winMult
--		end
	
	else -- Process a loss
		lossCount = lossCount + 1
		highLowLossCount = highLowLossCount + 1

		-- Toggle high/low code
		if(toggleHiLo == true) then
			highLowAverage[averageCount] = PreviousBet.Roll
			averageCount = averageCount + 1
			if(averageCount >= averageMax) then averageCount = 0 end
			tempAverage = 0
			for i=0, averageMax do
				tempAverage = tempAverage + highLowAverage[i]
			end
			tempAverage = tempAverage / averageMax
			-- winTemp = (100 - (100 * (housePercent / 100))) / NextBet.Chance -- how much you will win for a 1 bet
			-- if(highLowLossCount >= winTemp) then
			if(tempAverage > 50) then
				NextBet.High = true
			else
				NextBet.High = false
			end
--				if(NextBet.High == true) then
--					NextBet.High = false
--				else
--					NextBet.High = true
--				end
--			if(lossCount >= winTemp * 2) then
			-- if(tempWinMult > 1) then
				-- tempWinMult = tempWinMult - 1
				-- tempWinMult = tempWinMult / 2
--				if(tempWinMult > 1) then
--					tempWinMult = 1 -- Abort the high value, and go minimum for now
--					if(tempWinMult < 1) then tempWinMult = 1 end
					-- print(string.format("New Win Multiplier: %.2f", tempWinMult))
--				end
--			end
-- 			highLowLossCount = 0
-- 			end
		end
	end
	
	rollCount = rollCount + 1
	updateScreen(PreviousBet, Stats, SiteDetails)
	checkTip(PreviousBet, Stats, SiteDetails)
	-- sleep(6)
	-- print("\r\n\r\n\r\n")
-- 	calcChance(NextBet, PreviousBet, Win)
	autoTune(NextBet, PreviousBet, Win)
	
	
end

function ResetDice(NextBet)
	if(useANSI == true) then print(clrscr) end
	print("Initializing the bot.  Please wait.")
	
	-- Array Layout
	-- 0 = Biggest Bet
	-- 1 = Biggest Win
	-- 2 = Biggest Loss
	-- 3 = Highest roll
	-- 4 = Lowest roll
	-- 5 = Biggest Profit
	-- 6 = Most Spent
	-- 7 = Worst streak
	for i=0, 7 do
		biggestArray[i] = {}
		biggestArray[i][0] = 0 -- Biggest Win Amount
		biggestArray[i][1] = 0 -- Biggest Win Bet ID
		biggestArray[i][2] = 0 -- Biggest Win roll Count
		biggestArray[i][3] = 0 -- Last win Chance
		if(i == 4) then biggestArray[i][0] = 99.9999 end
	end
	
	for i = 0, rollHistoryCount do
		rollHistory[i] = {}
		rollHistory[i][0] = 0 -- Roll ID
		rollHistory[i][1] = 0 -- Roll Amount
		rollHistory[i][2] = 0 -- Roll Chance
		rollHistory[i][3] = 0 -- Roll High
		rollHistory[i][4] = 0 -- Roll Profit
		rollHistory[i][5] = 0 -- Roll Result
	end
	
	NextBet.Amount=basebet
	NextBet.Chance=basechance
	NextBet.High=startHigh
	print("Init done.")
	if(useANSI == true) then print(clrscr) end
	if(useANSI == true) then print(string.format("%s24;1f%s", esc, colorReset)) end
	print(string.format("Amount: %.8f Chance: %.4f", NextBet.Amount, NextBet.Chance))
end

if(useANSI == true) then print(string.format("%s25;1f%s", esc, colorReset)) end
-- print("End of run")
-- print("")
-- print("")
-- print("")
