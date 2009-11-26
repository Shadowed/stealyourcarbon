	
local NUMROWS, NUMCOLS, ICONSIZE, ICONGAP, GAP, EDGEGAP = 5, 10, 32, 3, 8, 16
local tekcheck = LibStub("tekKonfig-Checkbox")
local rows, offset, scrollbar, tradeview, grouptext = {}, 0
local normaltext, tradetext = "These items are only restocked if you are NOT carrying a tradeskill bag.  They will also restock from the bank.", "These items are only restocked if you are carrying a tradeskill bag.  Bank restocking will not take place."


local frame = CreateFrame("Frame", "StealYourCarbonConfig", InterfaceOptionsFramePanelContainer)
frame.name = "Steal Your Carbon"
frame:SetScript("OnShow", function(frame)
	local tektab = LibStub("tekKonfig-TopTab")
	local StealYourCarbon = StealYourCarbon
	local title, subtitle = LibStub("tekKonfig-Heading").new(frame, "Steal Your Carbon", "To add an item drop it in the frame below or type '/carbon add [Item Link] 20'.  Shift-click to add/remove a full stack.  Set the quantity to 0 to remove the item.")


	local overstock = tekcheck.new(frame, nil, "Overstock items", "TOPLEFT", subtitle, "BOTTOMLEFT", -2, -GAP)
	overstock.tiptext = "Ensure that the quantity specified is always purchased (will buy extra items if vendor does not sell the exact quantity you need)."
	local checksound = overstock:GetScript("OnClick")
	overstock:SetScript("OnClick", function(self) checksound(self); StealYourCarbon.db.overstock = not StealYourCarbon.db.overstock end)
	overstock:SetChecked(StealYourCarbon.db.overstock)


	local chatter = tekcheck.new(frame, nil, "Chat feedback", "TOP", overstock, "TOP")
	chatter:SetPoint("LEFT", frame, "TOP", GAP, 0)
	chatter.tiptext = "Give chat feedback when purchasing items."
	chatter:SetScript("OnClick", function(self) checksound(self); StealYourCarbon.db.chatter = not StealYourCarbon.db.chatter end)
	chatter:SetChecked(StealYourCarbon.db.chatter)
	

	local upgradewater = tekcheck.new(frame, nil, "Upgrade water", "TOPLEFT", overstock, "BOTTOMLEFT", 0, -GAP)
	upgradewater.tiptext = "Automatically upgrade to better water as player levels."
	upgradewater:SetScript("OnClick", function(self) checksound(self); StealYourCarbon.db.upgradewater = not StealYourCarbon.db.upgradewater end)
	upgradewater:SetChecked(StealYourCarbon.db.upgradewater)


	local editbox = CreateFrame('EditBox', nil, frame)
	editbox:SetAutoFocus(false)
	editbox:SetHeight(32)
	editbox:SetWidth(120)
	editbox:SetFontObject('GameFontHighlightSmall')
	editbox:SetPoint("TOPLEFT", chatter, "BOTTOMLEFT", GAP, -GAP)
	editbox.tiptext = "Name of the guild that can be used to automatically restock reagents from.\n\nLeave blank to disable restocking from a guild bank."
	editbox:SetText(StealYourCarbon.db.autoGuild or "")
	editbox:SetScript("OnHide", function() GameTooltip:Hide() end)
	editbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end)
	
	
	local label = editbox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	label:SetText("Guild to restock from")
	label:SetPoint("BOTTOMLEFT", editbox, "TOPLEFT", 0, -2)
	
	local left = editbox:CreateTexture(nil, "BACKGROUND")
	left:SetWidth(8) left:SetHeight(20)
	left:SetPoint("LEFT", -5, 0)
	left:SetTexture("Interface\\Common\\Common-Input-Border")
	left:SetTexCoord(0, 0.0625, 0, 0.625)
	
	local right = editbox:CreateTexture(nil, "BACKGROUND")
	right:SetWidth(8) right:SetHeight(20)
	right:SetPoint("RIGHT", 0, 0)
	right:SetTexture("Interface\\Common\\Common-Input-Border")
	right:SetTexCoord(0.9375, 1, 0, 0.625)
	
	local center = editbox:CreateTexture(nil, "BACKGROUND")
	center:SetHeight(20)
	center:SetPoint("RIGHT", right, "LEFT", 0, 0)
	center:SetPoint("LEFT", left, "RIGHT", 0, 0)
	center:SetTexture("Interface\\Common\\Common-Input-Border")
	center:SetTexCoord(0.0625, 0.9375, 0, 0.625)
	
	editbox:SetScript("OnEscapePressed", editbox.ClearFocus)
	editbox:SetScript("OnEnterPressed", editbox.ClearFocus)
	editbox:SetScript("OnTextChanged", function(self)
		StealYourCarbon.db.autoGuild = self:GetText()
	end)


	local group = LibStub("tekKonfig-Group").new(frame, nil, "TOP", upgradewater, "BOTTOM", 0, -EDGEGAP-GAP)
	group:SetPoint("LEFT", EDGEGAP, 0)
	group:SetPoint("BOTTOMRIGHT", -EDGEGAP, EDGEGAP)

	local tab1 = tektab.new(frame, "Normal", "BOTTOMLEFT", group, "TOPLEFT", 0, -4)
	local tab2 = tektab.new(frame, "Tradeskill", "LEFT", tab1, "RIGHT", -15, 0)
	tab2:Deactivate()
	tab1:SetScript("OnClick", function(self)
		self:Activate()
		tab2:Deactivate()
		tradeview = false
		StealYourCarbon:UpdateConfigList()
	end)
	tab2:SetScript("OnClick", function(self)
		self:Activate()
		tab1:Deactivate()
		tradeview = true
		StealYourCarbon:UpdateConfigList()
	end)

	grouptext = group:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	grouptext:SetHeight(32)
	grouptext:SetPoint("TOPLEFT", group, "TOPLEFT", EDGEGAP, -EDGEGAP)
	grouptext:SetPoint("RIGHT", group, -EDGEGAP-16, 0)
	grouptext:SetNonSpaceWrap(true)
	grouptext:SetJustifyH("LEFT")
	grouptext:SetJustifyV("TOP")
	grouptext:SetText(normaltext)


	local function OnReceiveDrag()
		local infotype, itemid, itemlink = GetCursorInfo()
		local stocklist = tradeview and StealYourCarbon.db.tradestocklist or StealYourCarbon.db.stocklist
		if infotype == "item" then stocklist[itemid] = select(8, GetItemInfo(itemid))
		elseif infotype == "merchant" then
			local itemlink = GetMerchantItemLink(itemid)
			itemid = tonumber(itemlink:match("item:(%d+):"))
			stocklist[itemid] = select(8, GetItemInfo(itemid))
		end
		StealYourCarbon:UpdateConfigList()
		return ClearCursor()
	end
	local function OnClick(self)
		PlaySound("UChatScrollButton")
		local diff = (self.up and 1 or -1) * (IsShiftKeyDown() and select(8, GetItemInfo(self.row.id)) or 1)
		local stocklist = tradeview and StealYourCarbon.db.tradestocklist or StealYourCarbon.db.stocklist
		stocklist[self.row.id] = stocklist[self.row.id] + (diff)
		if stocklist[self.row.id] <= 0 then
			stocklist[self.row.id] = 0
			self.row.down:Disable()
		else self.row.down:Enable() end
		self.row.count:SetText(stocklist[self.row.id])
	end
	local function OnClick2() if CursorHasItem() then OnReceiveDrag() end end
	local function ShowTooltip(self)
		if not self.row.id then return end
		local _, link = GetItemInfo(self.row.id)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(link)
	end
	local function HideTooltip() GameTooltip:Hide() end
	for i=1,NUMROWS*2 do
		local row = CreateFrame("Frame", nil, group)
		if i == 1 then row:SetPoint("TOP", grouptext, "BOTTOM", 0, -GAP/2)
		elseif i%2 == 0 then row:SetPoint("TOP", rows[i-1], "TOP")
		else row:SetPoint("TOP", rows[i-1], "BOTTOM", 0, -6) end
		if i%2 == 1 then
			row:SetPoint("LEFT", group, EDGEGAP, 0)
			row:SetPoint("RIGHT", group, "CENTER", -GAP/2-16, 0)
		else
			row:SetPoint("LEFT", group, "CENTER", GAP/2-16, 0)
			row:SetPoint("RIGHT", group, -EDGEGAP-16, 0)
		end
		row:SetHeight(ICONSIZE)

		local iconbutton = CreateFrame("Button", nil, row)
		iconbutton:SetPoint("TOPLEFT")
		iconbutton:SetWidth(ICONSIZE)
		iconbutton:SetHeight(ICONSIZE)
		iconbutton.row = row
		iconbutton:SetScript("OnEnter", ShowTooltip)
		iconbutton:SetScript("OnLeave", HideTooltip)
		iconbutton:SetScript("OnReceiveDrag", OnReceiveDrag)
		iconbutton:SetScript("OnClick", OnClick2)

		local buttonback = iconbutton:CreateTexture(nil, "ARTWORK")
		buttonback:SetTexture("Interface\\Buttons\\UI-Quickslot2")
		buttonback:SetPoint("CENTER")
		buttonback:SetWidth(ICONSIZE*64/37) buttonback:SetHeight(ICONSIZE*64/37)

		local icon = iconbutton:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()

		local count = iconbutton:CreateFontString(nil, "ARTWORK", "NumberFontNormal")
		count:SetPoint("BOTTOMRIGHT", -2, 2)

		local up = CreateFrame("Button", nil, row)
		up:SetPoint("TOPLEFT", icon, "TOPRIGHT", -6, 7)
		up:SetWidth(ICONSIZE/2 + 12) up:SetHeight(ICONSIZE/2 + 14)
		up:SetHitRectInsets(6, 6, 7, 7)
		up:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollUpButton-Up")
		up:SetPushedTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollUpButton-Down")
		up:SetHighlightTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollUpButton-Highlight")
		up:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
		up:GetHighlightTexture():SetBlendMode("ADD")
		up.row = row
		up.up = true
		up:SetScript("OnClick", OnClick)

		local down = CreateFrame("Button", nil, row)
		down:SetPoint("TOPLEFT", up, "BOTTOMLEFT", 0, 14)
		down:SetWidth(ICONSIZE/2 + 12) down:SetHeight(ICONSIZE/2 + 14)
		down:SetHitRectInsets(6, 6, 7, 7)
		down:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollDownButton-Up")
		down:SetPushedTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollDownButton-Down")
		down:SetHighlightTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollDownButton-Highlight")
		down:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
		down:GetHighlightTexture():SetBlendMode("ADD")
		down.row = row
		down:SetScript("OnClick", OnClick)

		local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		name:SetPoint("TOPLEFT", up, "TOPRIGHT", GAP-6, -7)
		name:SetPoint("RIGHT", row)
		name:SetJustifyH("LEFT")

		local stack = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		stack:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
		stack:SetPoint("RIGHT", row)
		stack:SetJustifyH("LEFT")
		stack:SetText("Stack Size: 20")

		rows[i], row.icon, row.count, row.name, row.stack, row.down, row.up = row, icon, count, name, stack, down, up
	end

	scrollbar = LibStub("tekKonfig-Scroll").new(group, 6, 1)

	local f = scrollbar:GetScript("OnValueChanged")
	scrollbar:SetScript("OnValueChanged", function(self, value, ...)
		offset = math.floor(value)*2
		StealYourCarbon:UpdateConfigList()
		return f(self, value, ...)
	end)

	frame:EnableMouseWheel()
	frame:SetScript("OnMouseWheel", function(self, val) scrollbar:SetValue(scrollbar:GetValue() - val) end)
	frame:SetScript("OnShow", function() StealYourCarbon:UpdateConfigList() end)
	frame:SetScript("OnHide", function()
		local stocklist = tradeview and StealYourCarbon.db.tradestocklist or StealYourCarbon.db.stocklist
		for i,v in pairs(stocklist) do if v == 0 then stocklist[i] = nil end end
	end)
	StealYourCarbon:UpdateConfigList()
	scrollbar:SetValue(0)
end)


function StealYourCarbon:UpdateConfigList()
	grouptext:SetText(tradeview and tradetext or normaltext)
	local items = 0
	local stocklist = tradeview and StealYourCarbon.db.tradestocklist or StealYourCarbon.db.stocklist
	for i in pairs(stocklist) do items = items + 1 end
	local maxoffset = math.ceil((items - NUMROWS*2 + 1)/2)
	scrollbar:SetMinMaxValues(0, math.max(maxoffset, 0))

	local emptyshown = false
	local id, qty = next(stocklist)
	for i=1,offset do id, qty = next(stocklist, id) end


	for _,row in ipairs(rows) do
		if id then
			row.id = id
			local _, link, _, _, _, _, _, stack = GetItemInfo(id)
			local texture = GetItemIcon(id)
			row.icon:SetTexture(texture)
			row.up:Enable()
			if qty == 0 then row.down:Disable() else row.down:Enable() end
			row.count:SetText(qty)
			row.name:SetText(link)
			row.stack:SetText("Stack Size: "..(stack or "???"))
			row.icon:Show()
			row:Show()
			id, qty = next(stocklist, id)
		elseif not emptyshown then
			emptyshown = true
			row.id = nil
			row.icon:Hide()
			row.count:SetText()
			row.name:SetText()
			row.stack:SetText()
			row.up:Disable()
			row.down:Disable()
			row:Show()
		else
			row:Hide()
		end
	end
end


StealYourCarbon.configframe = frame
InterfaceOptions_AddCategory(frame)


LibStub("tekKonfig-AboutPanel").new("Steal Your Carbon", "StealYourCarbon")


local orig = IsOptionFrameOpen
function IsOptionFrameOpen(...)
	if not frame:IsVisible() then return orig(...) end
end
