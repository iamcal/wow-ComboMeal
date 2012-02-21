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

	-- update the main frame state here
	ComboMeal.Label:SetText(GetTime());
end


ComboMeal.EventFrame = CreateFrame("Frame");
ComboMeal.EventFrame:Show();
ComboMeal.EventFrame:SetScript("OnEvent", ComboMeal.OnEvent);
ComboMeal.EventFrame:SetScript("OnUpdate", ComboMeal.OnUpdate);
ComboMeal.EventFrame:RegisterEvent("ADDON_LOADED");
ComboMeal.EventFrame:RegisterEvent("PLAYER_LOGIN");
ComboMeal.EventFrame:RegisterEvent("PLAYER_LOGOUT");
