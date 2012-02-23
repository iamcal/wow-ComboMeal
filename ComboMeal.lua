-- only for rogues
if select(2, UnitClass('player')) ~= "ROGUE" then return end

ComboMeal = {};
ComboMeal.fully_loaded = false;
ComboMeal.default_options = {

	-- main frame position
	frameRef = "CENTER",
	frameX = 0,
	frameY = 0,
	hide = false,
};

ComboMeal.start_w = 200;
ComboMeal.start_h = 200;
ComboMeal.bleed_mobs = {};

ComboMeal.bleed_debuffs = {};
ComboMeal.bleed_debuffs["Mangle"]	= 1; -- bear/cat druid
ComboMeal.bleed_debuffs["Hemorrhage"]	= 1; -- sub rogue
ComboMeal.bleed_debuffs["Blood Frenzy"]	= 1; -- arms warrior
ComboMeal.bleed_debuffs["Tendon Rip"]	= 1; -- hyena pet
ComboMeal.bleed_debuffs["Gore"]		= 1; -- boar pet
ComboMeal.bleed_debuffs["Stampede"]	= 1; -- rhino pet

function ComboMeal.OnReady()

	-- set up default options
	_G.ComboMealPrefs = _G.ComboMealPrefs or {};

	for k,v in pairs(ComboMeal.default_options) do
		if (not _G.ComboMealPrefs[k]) then
			_G.ComboMealPrefs[k] = v;
		end
	end

	ComboMeal.CreateUIFrame();
end

function ComboMeal.OnSaving()

	if (ComboMeal.UIFrame) then
		local point, relativeTo, relativePoint, xOfs, yOfs = ComboMeal.UIFrame:GetPoint()
		_G.ComboMealPrefs.frameRef = relativePoint;
		_G.ComboMealPrefs.frameX = xOfs;
		_G.ComboMealPrefs.frameY = yOfs;
	end
end

function ComboMeal.OnUpdate()
	if (not ComboMeal.fully_loaded) then
		return;
	end

	-- hide if we're not a combat rogue
	local talentGroup = GetActiveTalentGroup(false, false);
	local _, _, _, _, combatPoints = GetTalentTabInfo(2, false, false, talentGroup);
	if (combatPoints <= 11) then
		ComboMeal.UIFrame:hide();
		return;
	end

	if (ComboMealPrefs.hide) then 
		return;
	end

	ComboMeal.UpdateFrame();
end

function ComboMeal.OnEvent(frame, event, ...)

	if (event == 'ADDON_LOADED') then
		local name = ...;
		if name == 'ComboMeal' then
			ComboMeal.OnReady();
		end
		return;
	end

	if (event == 'PLAYER_LOGIN') then

		ComboMeal.fully_loaded = true;
		return;
	end

	if (event == 'PLAYER_LOGOUT') then
		ComboMeal.OnSaving();
		return;
	end
end

function ComboMeal.CreateUIFrame()

	-- create the UI frame
	ComboMeal.UIFrame = CreateFrame("Frame",nil,UIParent);
	ComboMeal.UIFrame:SetFrameStrata("BACKGROUND")
	ComboMeal.UIFrame:SetWidth(ComboMeal.start_w);
	ComboMeal.UIFrame:SetHeight(ComboMeal.start_h);

	-- make it black
	ComboMeal.UIFrame.texture = ComboMeal.UIFrame:CreateTexture();
	ComboMeal.UIFrame.texture:SetAllPoints(ComboMeal.UIFrame);
	ComboMeal.UIFrame.texture:SetTexture(0, 0, 0);

	-- position it
	ComboMeal.UIFrame:SetPoint(_G.ComboMealPrefs.frameRef, _G.ComboMealPrefs.frameX, _G.ComboMealPrefs.frameY);

	-- make it draggable
	ComboMeal.UIFrame:SetMovable(true);
	ComboMeal.UIFrame:EnableMouse(true);

	-- create a button that covers the entire addon
	ComboMeal.Cover = CreateFrame("Button", nil, ComboMeal.UIFrame);
	ComboMeal.Cover:SetFrameLevel(128);
	ComboMeal.Cover:SetPoint("TOPLEFT", 0, 0);
	ComboMeal.Cover:SetWidth(ComboMeal.start_w);
	ComboMeal.Cover:SetHeight(ComboMeal.start_h);
	ComboMeal.Cover:EnableMouse(true);
	ComboMeal.Cover:RegisterForClicks("AnyUp");
	ComboMeal.Cover:RegisterForDrag("LeftButton");
	ComboMeal.Cover:SetScript("OnDragStart", ComboMeal.OnDragStart);
	ComboMeal.Cover:SetScript("OnDragStop", ComboMeal.OnDragStop);
	ComboMeal.Cover:SetScript("OnClick", ComboMeal.OnClick);

	-- add a main label - just so we can show something
	ComboMeal.Label = ComboMeal.Cover:CreateFontString(nil, "OVERLAY");
	ComboMeal.Label:SetPoint("CENTER", ComboMeal.UIFrame, "CENTER", 2, 0);
	ComboMeal.Label:SetJustifyH("LEFT");
	ComboMeal.Label:SetFont([[Fonts\FRIZQT__.TTF]], 12, "OUTLINE");
	ComboMeal.Label:SetText(" ");
	ComboMeal.Label:SetTextColor(1,1,1,1);
	ComboMeal.SetFontSize(ComboMeal.Label, 10);
end

function ComboMeal.SetFontSize(string, size)

	local Font, Height, Flags = string:GetFont()
	if (not (Height == size)) then
		string:SetFont(Font, size, Flags)
	end
end

function ComboMeal.OnDragStart(frame)
	ComboMeal.UIFrame:StartMoving();
	ComboMeal.UIFrame.isMoving = true;
	GameTooltip:Hide()
end

function ComboMeal.OnDragStop(frame)
	ComboMeal.UIFrame:StopMovingOrSizing();
	ComboMeal.UIFrame.isMoving = false;
end

function ComboMeal.OnClick(self, aButton)
	if (aButton == "RightButton") then
		print("show menu here!");
	end
end

function ComboMeal.UpdateFrame()

	-- if we're not in combat, dump our bleed list so it doesn't fill up forever
	if (not UnitAffectingCombat("player")) then
		ComboMeal.bleed_mobs = {};
	end




	local status = ComboMeal.GetShotStatus();

	local str_snd = ComboMeal.FormatShot("Slice and Dice", status.shots.snd);
	local str_rev = ComboMeal.FormatShot("Revealing Strike", status.shots.rev);
	local str_rup = ComboMeal.FormatShot("Rupture", status.shots.rup);
	local str_evi = ComboMeal.FormatShot("Eviscerate", status.shots.evi);

	ComboMeal.Label:SetText(str_snd.."\n"..str_rev.."\n"..str_rup.."\n"..str_evi);
end

function ComboMeal.FormatShot(name, state)

	if (state == "off") then
		return name..": no";
	end

	if (state == "next") then
		return name..": up next";
	end

	if (state == "now") then
		return name..": GO!";
	end

	return name..": ?"..state;
end

function ComboMeal.GetShotStatus()

	local out = {};

	-- figure out current target debuffs.
	-- we need to check if this target has ever had a bleed on it.

	local ruptureUp = false;
	local ruptureRemain = 0;

	local target_guid = UnitGUID("target");

	local index = 1
	while UnitDebuff("target", index) do
		local name, _, _, count, _, _, buffExpires, caster = UnitDebuff("target", index);
		if (ComboMeal.bleed_debuffs[name]) then
			ComboMeal.bleed_mobs[target_guid] = 1;
		end
		if ((name == "Rupture") and (caster == "player")) then
			ruptureUp = true;
			ruptureRemain = buffExpires - GetTime();
		end
		index = index + 1
	end


	-- check our own buffs

	local hasSnD = false;
	local remainSnD = 0;

	local index = 1;
	while UnitBuff("player", index) do
		local name, _, _, count, _, _, buffExpires, caster = UnitBuff("player", index)
		if (name == "Slice and Dice") then
			hasSnD = true;
			remainSnD = buffExpires - GetTime();
		end
		index = index + 1
	end


	-- combo points!

	local comboPoints = GetComboPoints('player', 'target');


	-- energy stuff

	local costs = {
		snd = ComboMeal.GetSpellCost("Slice and Dice"),
		rev = ComboMeal.GetSpellCost("Revealing Strike"),
		rup = ComboMeal.GetSpellCost("Rupture"),
		evi = ComboMeal.GetSpellCost("Eviscerate"),
	};
	local energy = UnitPower("player");


	-- main priority list
	-- if slice and dice is down, use with any combo points (1+)
	-- if slice and dice will fall off within X seconds, use 4-5 combo points on it
	-- if we have *exactly* 4 combo points, use revealing strike
	-- if target has bleed debuff
		-- if rupture will fall off within 1 second, wait
		-- if rupture is not active, 5 combo rupture
	-- 5 combo eviscerate
	-- sinister strike


	out.shots = {
		snd = "off",
		rev = "off",
		rup = "off",
		evi = "off",
	};

	if (not hasSnD) then

		if (comboPoints > 0) then
			if (energy < costs.snd) then
				out.shots.snd = "next-energy";
			else
				out.shots.snd = "now";
			end
		else
			out.shots.snd = "next-combo";
		end
		return out;
	end

	if (remainSnD < 5) then
		if (comboPoints > 3) then
			if (energy < costs.snd) then
				out.shots.snd = "next-energy";
			else
				out.shots.snd = "now";
			end
		else
			out.shots.snd = "next-combo";
		end
		return out;
	end

	if (comboPoints == 4) then
		if (energy < costs.rev) then
			out.shots.rev = "next-energy";
		else
			out.shots.rev = "now";
		end
		return out;
	end

	if (ruptureUp and (ruptureRemain < 2)) then
		out.shots.rup = "next-wait";
		return out;
	end

	if (not ruptureUp) then
		if (comboPoints == 5) then
			if (energy < costs.rup) then
				out.shots.rup = "next-energy";
			else
				out.shots.rup = "now";
			end
		else
			out.shots.rup = "next-combo";
		end
		return out;
	end

	if (comboPoints == 5) then
		if (energy < costs.evi) then
			out.shots.evi = "next-enrgy";
		else
			out.shots.evi = "now";
		end
	else
		out.shots.evi = "next-combo";
	end

	return out;
end

function ComboMeal.GetSpellCost(spellName)
	name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellName);
	return cost;
end


ComboMeal.EventFrame = CreateFrame("Frame");
ComboMeal.EventFrame:Show();
ComboMeal.EventFrame:SetScript("OnEvent", ComboMeal.OnEvent);
ComboMeal.EventFrame:SetScript("OnUpdate", ComboMeal.OnUpdate);
ComboMeal.EventFrame:RegisterEvent("ADDON_LOADED");
ComboMeal.EventFrame:RegisterEvent("PLAYER_LOGIN");
ComboMeal.EventFrame:RegisterEvent("PLAYER_LOGOUT");
