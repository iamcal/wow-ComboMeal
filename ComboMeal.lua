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
ComboMeal.start_h = 143;
ComboMeal.bleed_mobs = {};
ComboMeal.misc_counter = 1;
ComboMeal.cd_buttons_max = 10;

ComboMeal.btn_text = {
	ss = "2",
	snd = "7",
	rev = "1",
	rup = "4",
	evi = "3",
	ar = "ALT-1",
	ks = "ALT-2",
	bf = "ALT-3",
};

ComboMeal.cooldown_spells = {
	"Lifeblood",		-- herbalists
	"Rocket Barrage",	-- goblins
	"Blood Fury",		-- orcs
	"War Stomp",		-- tauren
	"Berserking",		-- trolls
};

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

	local k,v;
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

	ComboMeal.buttons.ar  = ComboMeal.CreateButton(ComboMeal.UIFrame, 41*1, 62, 40, 40, [[Interface\Icons\spell_shadow_shadowworddominate]]);
	ComboMeal.buttons.ks  = ComboMeal.CreateButton(ComboMeal.UIFrame, 41*2, 62, 40, 40, [[Interface\Icons\ability_rogue_murderspree]]);
	ComboMeal.buttons.bf  = ComboMeal.CreateButton(ComboMeal.UIFrame, 41*3, 62, 40, 40, [[Interface\Icons\ability_warrior_punishingblow]]);

	local k, btn;
	for k,btn in pairs(ComboMeal.buttons) do
		btn.label:SetText(ComboMeal.btn_text[k]);
	end

	ComboMeal.PointBoxes = {};
	ComboMeal.PointBoxes[1] = ComboMeal.CreateComboBox(ComboMeal.UIFrame, 41*0, 41, 40, 20);
	ComboMeal.PointBoxes[2] = ComboMeal.CreateComboBox(ComboMeal.UIFrame, 41*1, 41, 40, 20);
	ComboMeal.PointBoxes[3] = ComboMeal.CreateComboBox(ComboMeal.UIFrame, 41*2, 41, 40, 20);
	ComboMeal.PointBoxes[4] = ComboMeal.CreateComboBox(ComboMeal.UIFrame, 41*3, 41, 40, 20);
	ComboMeal.PointBoxes[5] = ComboMeal.CreateComboBox(ComboMeal.UIFrame, 41*4, 41, 40, 20);

	ComboMeal.cd_buttons = {};
	local i;
	for i=1,ComboMeal.cd_buttons_max do
		ComboMeal.cd_buttons[i] = ComboMeal.CreateButton(ComboMeal.UIFrame, 0, 103, 40, 40, [[Interface\Icons\spell_shadow_shadowworddominate]]);
	end

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

	function b:SetStateColor(col)
		local tex = self:GetNormalTexture();
		if (col == 'blue') then
			tex:SetVertexColor(0.5, 0.5, 1.0);
		elseif (col == 'off') then
			tex:SetVertexColor(0.3, 0.3, 0.3);
		else
			tex:SetVertexColor(1.0, 1.0, 1.0);
		end
	end

	function b:SetSpellState(spellName)
		self:SetCooldown(true, spellName);
		local isUsable, notEnoughMana = IsUsableSpell(spellName);
		if (isUsable) then
			self:SetStateColor('normal');
		elseif (notEnoughMana) then
			self:SetStateColor('blue');
		else
			self:SetStateColor('off');
		end
	end


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

	function b:SetCooldown(enable, spellName)

		if (not enable) then
			return self:SetCooldownManual(false);
		end

		local start, duration, enabledToo = GetSpellCooldown(spellName);

		self:SetCooldownManual(enabledToo, start, duration);
	end

	function b:SetCooldownManual(enable, start, duration)

		if (not enable) then
			self.cooldown:Hide();
			self.cd_start = 0;
			self.cd_duration = 0;
			return;
		end

		if (start == self.cd_start and duration == self.cd_duration) then
			return;
		end

		self.cooldown:SetCooldown(start, duration);
		self.cooldown:Show();
		self.cd_start = start;
		self.cd_duration = duration;
	end


	-- the glow overlay - used to show next shot
	b.glow = CreateFrame("Frame", name.."_glow", UIParent, "ActionBarButtonSpellActivationAlert");
	b.glow:SetParent(b);
	b.glow:ClearAllPoints();
	b.glow:SetPoint("TOPLEFT", b, "TOPLEFT", -w * 0.2, h * 0.2);
	b.glow:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", w * 0.2, -h*0.2);
	b.glow:Hide();
	b.is_glowing = false;

	function b:SetGlow(is_glowing)
		if (is_glowing) then
			if (not self.is_glowing) then
				self.glow.animOut:Stop();
				self.glow.animIn:Play();
				self.is_glowing = true;
			end
			self.glow:Show();
		else
			if (self.is_glowing) then
				self.glow.animIn:Stop();
				self.glow.animOut:Play();
				self.is_glowing = false;
			end
		end
	end



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


	-- set up buttons and boxes

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


	-- blade flurry

	local btn = ComboMeal.buttons.bf;
	if (status.bladeFlurry) then
		btn:SetStateColor('normal');
		btn:SetAlpha(1);
		btn:SetGlow(true);
	else
		btn:SetStateColor('off');
		btn:SetAlpha(1);
		btn:SetGlow(false);
	end
	btn:SetCooldown(true, "Blade Flurry");


	-- adrenaline rush

	local btn = ComboMeal.buttons.ar;
	if (status.ksActive) then
		btn:SetAlpha(0.2);
		btn:SetGlow(false);
		btn:SetSpellState("Adrenaline Rush");
	else
		btn:SetAlpha(1);
		if (status.arActive) then
			btn:SetGlow(true);
			btn:SetCooldownManual(true, status.arStart, status.arDuration);
		else
			btn:SetGlow(false);
			btn:SetSpellState("Adrenaline Rush");
		end
	end


	-- killing spree

	local btn = ComboMeal.buttons.ks;
	if (status.arActive or status.energy > 40) then
		btn:SetAlpha(0.2);
		btn:SetGlow(false);
		btn:SetSpellState("Killing Spree");
	else
		btn:SetAlpha(1);
		if (status.ksActive) then
			btn:SetGlow(true);
			btn:SetCooldownManual(true, status.ksStart, status.ksDuration);
		else
			btn:SetGlow(false);
			btn:SetSpellState("Killing Spree");
		end
	end


	-- trinkets & other cooldowns

	local cooldowns = {};	
	local cooldowns_count = 0;

	local t1_item = GetInventoryItemID("player", 13);
	local t2_item = GetInventoryItemID("player", 14);
	local t1_spell = nil;
	local t2_spell = nil;
	if (t1_item) then t1_spell = GetItemSpell(t1_item); end
	if (t2_item) then t2_spell = GetItemSpell(t2_item); end

	if (t1_spell) then
		table.insert(cooldowns, {
			type = "item",
			id = t1_item,
		});
		cooldowns_count = cooldowns_count + 1;
	end
	if (t2_spell) then
		table.insert(cooldowns, {
			type = "item",
			id = t2_item,
		});
		cooldowns_count = cooldowns_count + 1;
	end

	local k,v
	for k,v in pairs(ComboMeal.cooldown_spells) do
		local count = GetSpellCount(v);
		if (count) then
			table.insert(cooldowns, {
				type = "spell",
				id = v,
			});
			cooldowns_count = cooldowns_count + 1;
		end
	end

	local cd_width = (41 * cooldowns_count) - 1;
	local cd_left = (102 - (cd_width / 2)) - 41;

	for i=1,ComboMeal.cd_buttons_max do
		local btn = ComboMeal.cd_buttons[i];
		if (i <= cooldowns_count) then
			local info = cooldowns[i];

			local texture, start, duration, enable;

			if (info.type == 'item') then
				_, _, _, _, _, _, _, _, _, texture, _ = GetItemInfo(info.id);
				start, duration, enable = GetItemCooldown(info.id);
			else
				texture = GetSpellTexture(info.id);
				start, duration, enable = GetSpellCooldown(info.id);
			end

			btn:SetPoint("TOPLEFT", cd_left + (i * 41), 0-103);
			btn:Show();
			btn:SetNormalTexture(texture);
			btn:SetCooldownManual(enable, start, duration);
		else
			btn:Hide();
		end
	end

	ComboMeal.Label:SetText(" ");
end

function ComboMeal.SetButtonState(btn, state, spellName)

	-- energy state overlay
	local isUsable, notEnoughMana = IsUsableSpell(spellName);
	if (isUsable) then
		btn:SetStateColor('normal');
	elseif (notEnoughMana) then
		btn:SetStateColor('blue');
	else
		btn:SetStateColor('normal');
	end

	-- glow & cooldown
	if (state == "now") then
		btn:SetGlow(true);
		btn:SetCooldown(true, spellName);		
	else
		btn:SetGlow(false);
		btn:SetCooldown(false);
	end

	-- transparency
	if (state == "off") then
		btn:SetAlpha(0.2);
	else
		btn:SetAlpha(1);
	end

end

function ComboMeal.GetShotStatus()

	local out = {};

	out.label = "";
	out.comboPoints = 0;
	out.bladeFlurry = false;
	out.arActive = false;
	out.ksActive = false;
	out.energy = UnitPower("player");
	out.shots = {
		ss = "off",
		snd = "off",
		rev = "off",
		rup = "off",
		evi = "off",
	};

	-- test auras first
	local test = UnitAura("Player", "Blade Flurry");
	if (test) then
		out.bladeFlurry = true;
	end

	local test,_,_,_,_,duration,expires = UnitAura("Player", "Adrenaline Rush");
	if (test) then
		out.arActive= true;
		out.arStart = expires - duration;
		out.arDuration = duration;
	end

	local test,_,_,_,_,duration,expires = UnitAura("Player", "Killing Spree");
	if (test) then
		out.ksActive= true;
		out.ksStart = expires - duration;
		out.ksDuration = duration;
	end


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


	-- should we use Rupture?
	-- not if we have blade flurry up!

	local useRupture = true;

	if (out.bladeFlurry) then
		useRupture = false;
	end


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
			if (out.energy < costs.snd) then
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
			if (out.energy < costs.snd) then
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
		if (out.energy < costs.rev) then
			out.shots.rev = "next";
		else
			out.shots.rev = "now";
		end
		return out;
	end

	if (useRupture) then

		if (ruptureUp and (ruptureRemain < 2)) then
			out.shots.rup = "next";
			return out;
		end

		if (not ruptureUp) then
			if (comboPoints == 5) then
				if (out.energy < costs.rup) then
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
	end

	if (comboPoints == 5) then
		if (out.energy < costs.evi) then
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
	local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellName);
	return cost;
end


ComboMeal.EventFrame = CreateFrame("Frame");
ComboMeal.EventFrame:Show();
ComboMeal.EventFrame:SetScript("OnEvent", ComboMeal.OnEvent);
ComboMeal.EventFrame:SetScript("OnUpdate", ComboMeal.OnUpdate);
ComboMeal.EventFrame:RegisterEvent("ADDON_LOADED");
ComboMeal.EventFrame:RegisterEvent("PLAYER_LOGIN");
ComboMeal.EventFrame:RegisterEvent("PLAYER_LOGOUT");
