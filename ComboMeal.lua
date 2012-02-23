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

ComboMeal.start_w = 204;
ComboMeal.start_h = 200;
ComboMeal.bleed_mobs = {};
ComboMeal.misc_counter = 1;

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
	--ComboMeal.UIFrame.texture = ComboMeal.UIFrame:CreateTexture();
	--ComboMeal.UIFrame.texture:SetAllPoints(ComboMeal.UIFrame);
	--ComboMeal.UIFrame.texture:SetTexture(0, 0, 0);

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

	ComboMeal.buttons = {};
	ComboMeal.buttons.ss  = ComboMeal.CreateButton(ComboMeal.UIFrame, 41*0, 0, 40, 40, [[Interface\Icons\spell_shadow_ritualofsacrifice]]);
	ComboMeal.buttons.snd = ComboMeal.CreateButton(ComboMeal.UIFrame, 41*1, 0, 40, 40, [[Interface\Icons\ability_rogue_slicedice]]);
	ComboMeal.buttons.rev = ComboMeal.CreateButton(ComboMeal.UIFrame, 41*2, 0, 40, 40, [[Interface\Icons\inv_sword_97]]);
	ComboMeal.buttons.rup = ComboMeal.CreateButton(ComboMeal.UIFrame, 41*3, 0, 40, 40, [[Interface\Icons\ability_rogue_rupture]]);
	ComboMeal.buttons.evi = ComboMeal.CreateButton(ComboMeal.UIFrame, 41*4, 0, 40, 40, [[Interface\Icons\ability_rogue_eviscerate]]);

	ComboMeal.buttons.ss.label:SetText("2");
	ComboMeal.buttons.snd.label:SetText("7");
	ComboMeal.buttons.rev.label:SetText("1");
	ComboMeal.buttons.rup.label:SetText("4");
	ComboMeal.buttons.evi.label:SetText("3");

	ComboMeal.PointBoxes = {};
	ComboMeal.PointBoxes[1] = ComboMeal.CreateComboBox(ComboMeal.UIFrame, 41*0, 41, 40, 20);
	ComboMeal.PointBoxes[2] = ComboMeal.CreateComboBox(ComboMeal.UIFrame, 41*1, 41, 40, 20);
	ComboMeal.PointBoxes[3] = ComboMeal.CreateComboBox(ComboMeal.UIFrame, 41*2, 41, 40, 20);
	ComboMeal.PointBoxes[4] = ComboMeal.CreateComboBox(ComboMeal.UIFrame, 41*3, 41, 40, 20);
	ComboMeal.PointBoxes[5] = ComboMeal.CreateComboBox(ComboMeal.UIFrame, 41*4, 41, 40, 20);



end

function ComboMeal.CreateButton(parent, x, y, w, h, texture)

	ComboMeal.misc_counter = ComboMeal.misc_counter + 1;
	local name = "ComboMealBtn"..ComboMeal.misc_counter;

	-- the actual button
	local b = CreateFrame("Button", name, parent);
	b:SetPoint("TOPLEFT", x, 0-y)
	b:SetWidth(w)
	b:SetHeight(h)
	b:SetNormalTexture(texture);

	-- the text label - use to show key binds
	b.label = b:CreateFontString(nil, "OVERLAY");
	b.label:Show()
	b.label:ClearAllPoints()
	b.label:SetTextColor(1, 1, 1, 1);
	b.label:SetFont([[Fonts\FRIZQT__.TTF]], 12, "OUTLINE");
	b.label:SetPoint("CENTER", b, "CENTER", 0, 0);
	b.label:SetText(" ");

	-- the cooldown timer
	b.cooldown = CreateFrame("Cooldown", name.."_cooldown", b, "CooldownFrameTemplate");
	b.cooldown:SetAllPoints(b);
	b.cooldown:Hide();
	b.cd_start = 0;
	b.cd_duration = 0;

	-- the glow overlay - used to show next shot
	b.glow = CreateFrame("Frame", name.."_glow", UIParent, "ActionBarButtonSpellActivationAlert");
	b.glow:SetParent(b);
	b.glow:ClearAllPoints();
	b.glow:SetPoint("TOPLEFT", b, "TOPLEFT", -w * 0.2, h * 0.2);
	b.glow:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", w * 0.2, -h*0.2);
	b.glow:Hide();
	b.is_glowing = false;

	return b;
end

function ComboMeal.CreateComboBox(parent, x, y, w, h)

	local b = CreateFrame("Button", nil, parent);
	b:SetPoint("TOPLEFT", x, 0-y);
	b:SetWidth(w);
	b:SetHeight(h);

	b:SetBackdrop({
		bgFile		= "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile	= "Interface/Tooltips/UI-Tooltip-Border",
		tile		= false,
		tileSize	= 16,
		edgeSize	= 8,
		insets		= {
			left	= 3,
			right	= 3,
			top	= 3,
			bottom	= 3,
		},
	});

	function b:SetState(is_on)

		if (b.is_on == is_on) then
			return;
		end
		b.is_on = is_on;

		if (is_on) then
			self:SetBackdropColor(0,1,0);
			self:SetBackdropBorderColor(1,1,1);
		else
			self:SetBackdropColor(0,0,0,0.2);
			self:SetBackdropBorderColor(1,1,1,0.2);
		end
	end

	b.is_on = true;
	b:SetState(false);

	return b;
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

	local str_ss = ComboMeal.FormatShot("Sinister Shot", status.shots.ss);
	local str_snd = ComboMeal.FormatShot("Slice and Dice", status.shots.snd);
	local str_rev = ComboMeal.FormatShot("Revealing Strike", status.shots.rev);
	local str_rup = ComboMeal.FormatShot("Rupture", status.shots.rup);
	local str_evi = ComboMeal.FormatShot("Eviscerate", status.shots.evi);

	ComboMeal.SetButtonState(ComboMeal.buttons.ss,  status.shots.ss,  "Sinister Strike");
	ComboMeal.SetButtonState(ComboMeal.buttons.snd, status.shots.snd, "Slice and Dice");
	ComboMeal.SetButtonState(ComboMeal.buttons.rev, status.shots.rev, "Revealing Strike");
	ComboMeal.SetButtonState(ComboMeal.buttons.rup, status.shots.rup, "Rupture");
	ComboMeal.SetButtonState(ComboMeal.buttons.evi, status.shots.evi, "Eviscerate");

	ComboMeal.PointBoxes[1]:SetState(status.comboPoints >= 1);
	ComboMeal.PointBoxes[2]:SetState(status.comboPoints >= 2);
	ComboMeal.PointBoxes[3]:SetState(status.comboPoints >= 3);
	ComboMeal.PointBoxes[4]:SetState(status.comboPoints >= 4);
	ComboMeal.PointBoxes[5]:SetState(status.comboPoints >= 5);


	ComboMeal.Label:SetText(status.label.."\n"..str_ss.."\n"..str_snd.."\n"..str_rev.."\n"..str_rup.."\n"..str_evi);
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

function ComboMeal.SetButtonState(btn, state, spellName)

	-- mana overlay
	local tex = btn:GetNormalTexture();
	local isUsable, notEnoughMana = IsUsableSpell(spellName);
	if ( isUsable ) then
		tex:SetVertexColor(1.0, 1.0, 1.0);
	elseif ( notEnoughMana ) then
		tex:SetVertexColor(0.5, 0.5, 1.0);
	else
		tex:SetVertexColor(1.0, 1.0, 1.0);
	end



	if (state == "now") then
		if (not btn.is_glowing) then
			btn.glow.animOut:Stop();
			btn.glow.animIn:Play();
			btn.is_glowing = true;
		end
		btn.glow:Show();

		-- set cooldown
		local start, duration, enabled = GetSpellCooldown(spellName);
		ComboMeal.SetButtonCooldown(btn, true, start, duration);

		-- set energy overlay
		

	else
		if (btn.is_glowing) then
			btn.glow.animIn:Stop();
			btn.glow.animOut:Play();
			btn.is_glowing = false;
		end
		ComboMeal.SetButtonCooldown(btn, false);
	end

	if (state == "off") then
		btn:SetAlpha(0.2);
	else
		btn:SetAlpha(1);
	end

end

function ComboMeal.SetButtonCooldown(btn, enable, start, duration)

	if (not enable) then
		btn.cooldown:Hide();
		btn.cd_start = 0;
		btn.cd_duration = 0;
		return;
	end

	if (start == btn.cd_start and duration == btn.cd_duration) then
		return;
	end

	btn.cooldown:SetCooldown(start, duration);
	btn.cooldown:Show();
	btn.cd_start = start;
	btn.cd_duration = duration;
end

function ComboMeal.GetShotStatus()

	local out = {};

	out.label = "";
	out.comboPoints = 0;
	out.shots = {
		ss = "off",
		snd = "off",
		rev = "off",
		rup = "off",
		evi = "off",
	};

	-- can we attack anything?
	local can_attack = UnitCanAttack("player", "target");
	if (can_attack and UnitIsDeadOrGhost("target")) then
		can_attack = false;
	end
	if (not can_attack) then
		return out;	
	end

	--are we within range of target?
	local in_range = IsSpellInRange("Sinister Strike");
	if (in_range == 0) then
		out.label = "Too Far";
		out.label_mode = "Warning";
		return out;	
	end


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
	out.comboPoints = comboPoints;


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
		-- if rupture will fall off within 2 seconds, wait
		-- if rupture is not active, 5 combo rupture
	-- 5 combo eviscerate
	-- sinister strike


	if (not hasSnD) then

		if (comboPoints > 0) then
			if (energy < costs.snd) then
				out.shots.snd = "next";
			else
				out.shots.snd = "now";
			end
		else
			out.shots.snd = "next";
			out.shots.ss = "now";
		end
		return out;
	end

	if (remainSnD < 5) then
		if (comboPoints > 3) then
			if (energy < costs.snd) then
				out.shots.snd = "next";
			else
				out.shots.snd = "now";
			end
		else
			out.shots.snd = "next";
			out.shots.ss = "now";
		end
		return out;
	end

	if (comboPoints == 4) then
		if (energy < costs.rev) then
			out.shots.rev = "next";
		else
			out.shots.rev = "now";
		end
		return out;
	end

	if (ruptureUp and (ruptureRemain < 2)) then
		out.shots.rup = "next";
		return out;
	end

	if (not ruptureUp) then
		if (comboPoints == 5) then
			if (energy < costs.rup) then
				out.shots.rup = "next";
			else
				out.shots.rup = "now";
			end
		else
			out.shots.rup = "next";
			out.shots.ss = "now";
		end
		return out;
	end

	if (comboPoints == 5) then
		if (energy < costs.evi) then
			out.shots.evi = "next";
		else
			out.shots.evi = "now";
		end
	else
		out.shots.evi = "next";
		out.shots.ss = "now";
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
