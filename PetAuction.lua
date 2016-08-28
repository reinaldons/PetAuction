
local addonName, addonTable = ...

local TAB_NAME = "Pets"

local PET_AUCTION_RED = "cffff0000"
local PET_AUCTION_BLUE = "cff3498db"
local PET_AUCTION_YELLOW = "cfff4D03f"

local PET_AUCTION_DEBUG = true
local PET_AUCTION_TAB_INDEX
local PET_AUCTION_BUTTON_CREATED = false

local active_auction
local active_button

-- Initialization
function PetAuction_OnLoad(self)
    PetAuction_Debug("_OnLoad")

    self:RegisterEvent("AUCTION_HOUSE_SHOW");
    self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE");
    self:RegisterEvent("AUCTION_HOUSE_CLOSED");
end

function PetAuction_OnEvent(self, event, ...)
    PetAuction_Debug("_OnEvent: "..event)
    if ( event == "AUCTION_HOUSE_SHOW" ) then
        PetAuction_AddTab(TAB_NAME)
    end
    if ( event == "AUCTION_ITEM_LIST_UPDATE" ) then
        PetAuction_Update()
    end
end

function PetAuction_OnShow()
    PetAuction_Debug("_OnShow")
end

function PetAuction_Update()
    local numBatchAuctions, totalAuctions = GetNumAuctionItems("list");
    local name, texture, count, quality, canUse, level, levelColHeader, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo

    PetAuction_Debug("_Update: "..NUM_BROWSE_TO_DISPLAY.." "..NUM_AUCTION_ITEMS_PER_PAGE)

    for i=1, totalAuctions do
        name, texture, count, quality, canUse, level, levelColHeader, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo =  GetAuctionItemInfo("list", i)
    end
end

function PetAuction_AddTab(tabText)
    PetAuction_Debug("_AddTab: "..tabText)

    if PET_AUCTION_BUTTON_CREATED then
        PetAuction_Debug("Tab already exists")
        return true
    end

    local n = AuctionFrame.numTabs + 1;
    local framename = "AuctionFrameTab"..n;
    local frame = CreateFrame("Button", framename, AuctionFrame, "AuctionTabTemplate");

    frame:SetID(n);
    frame:SetText(tabText);
    frame:SetNormalFontObject(_G["AtrFontOrange"]);
    frame:SetPoint("LEFT", _G["AuctionFrameTab"..n - 1], "RIGHT", -8, 0);

    frame:SetScript("OnClick", function(self, _, _)
        PetAuction_AuctionFrameTab_OnClick(self)
    end)

    PanelTemplates_SetNumTabs(AuctionFrame, n)
    PanelTemplates_EnableTab(AuctionFrame, n)

    PET_AUCTION_TAB_INDEX = n
    PET_AUCTION_BUTTON_CREATED = true
end

function PetAuction_AuctionFrameTab_OnClick(button)
    PetAuction_Debug(button:GetText().." "..PET_AUCTION_TAB_INDEX)

    AuctionFrameAuctions:Hide ()
    AuctionFrameBrowse:Hide ()
    AuctionFrameBid:Hide ()
    PlaySound ("igCharacterInfoTab")

    AuctionFrame.type = "pets";
    SetAuctionsTabShowing(false);

    AuctionFrameTopLeft:SetTexture ("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopLeft")
    AuctionFrameTop:SetTexture ("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Top")
    AuctionFrameTopRight:SetTexture ("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-TopRight")
    AuctionFrameBotLeft:SetTexture ("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft")
    AuctionFrameBot:SetTexture ("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot")
    AuctionFrameBotRight:SetTexture ("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight")

    PanelTemplates_SetTab(AuctionFrame, PET_AUCTION_TAB_INDEX)

    for _, child in pairs ({AuctionFrame:GetChildren ()}) do
        if child:GetName ():match ("AuctionFrameTab") == nil then
            child:Hide ()
        end
    end

    AuctionFrameCloseButton:Show ()
    AuctionFrameMoneyFrame:Show ()

    PetAuction_CreateFrame()

    PetAuctionScroll:Show()
    PetAuctionStatus:Show()
    PetAuctionScan:Show()
    PetAuctionBid:Show()
    PetAuctionBuyout:Show()
    PetAuctionShow:Show()

    PetAuction_QueryPetList()
    --PetAuction_UpdatePetList()
end

function PetAuction_CreateFrame()
    if PetAuctionScan == nil then
        CreateFrame ("Button", "PetAuctionScan", AuctionFrame, "UIPanelButtonTemplate")
        PetAuctionScan:SetPoint ("TOPLEFT", 100, -45)
        PetAuctionScan:SetWidth (150)
        PetAuctionScan:SetText ("Scan Action House")
        PetAuctionScan:SetScript ("OnClick", function ()
            self:RegisterEvent ("AUCTION_ITEM_LIST_UPDATE")
            QueryAuctionItems ("", 0, 0, 0, 11, 0, 0, 0, 0, 0)
        end)
    end

    if PetAuctionStatus == nil then
        AuctionFrame:CreateFontString ("PetAuctionStatus", "ARTWORK", "ChatFontNormal")
        PetAuctionStatus:SetPoint ("TOP", 0, -47)
    end

    if PetAuctionScroll == nil then
        CreateFrame ("ScrollFrame", "PetAuctionScroll", AuctionFrame, "UIPanelScrollFrameTemplate")
        CreateFrame ("Frame", "PetAuctionScrollChild")

        PetAuctionScroll:SetScrollChild (PetAuctionScrollChild)
        PetAuctionScroll:SetPoint ("TOPLEFT", 20, -80)
        PetAuctionScroll:SetPoint ("BOTTOMRIGHT", -38, 45)
        PetAuctionScrollChild:SetWidth (PetAuctionScroll:GetWidth ())
    end

    if PetAuctionBid == nil then
        CreateFrame ("Button", "PetAuctionBid", AuctionFrame, "UIPanelButtonTemplate")
        PetAuctionBid:SetPoint ("BOTTOMRIGHT", -168, 14)
        PetAuctionBid:SetSize (80, 22)
        PetAuctionBid:SetText ("Bid")
        PetAuctionBid:SetScript ("OnClick", function ()
            self:ShowConfirmDialog ("BID")
        end)
        PetAuctionBid:Disable ()
    end

    if PetAuctionBuyout == nil then
        CreateFrame ("Button", "PetAuctionBuyout", AuctionFrame, "UIPanelButtonTemplate")
        PetAuctionBuyout:SetPoint ("BOTTOMRIGHT", -88, 14)
        PetAuctionBuyout:SetSize (80, 22)
        PetAuctionBuyout:SetText ("Buyout")
        PetAuctionBuyout:SetScript ("OnClick", function ()
            self:ShowConfirmDialog ("BUYOUT")
        end)
        PetAuctionBuyout:Disable ()
    end

    if PetAuctionShow == nil then
        CreateFrame ("Button", "PetAuctionShow", AuctionFrame, "UIPanelButtonTemplate")
        PetAuctionShow:SetPoint ("BOTTOMRIGHT", -8, 14)
        PetAuctionShow:SetSize (80, 22)
        PetAuctionShow:SetText ("Show")
        PetAuctionShow:SetScript ("OnClick", function ()
            SortAuctionClearSort ("list")
            SortAuctionSetSort ("list", "buyout")
            SortAuctionApplySort ("list")
            QueryAuctionItems (active_auction["name"])

            self:HideUi ()
            PlaySound ("igCharacterInfoTab")
            PanelTemplates_SetTab (AuctionFrame, 1)
            AuctionFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopLeft");
            AuctionFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Top");
            AuctionFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopRight");
            AuctionFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotLeft");
            AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot");
            AuctionFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight");
            AuctionFrameBrowse:Show();
            AuctionFrame.type = "list";
            SetAuctionsTabShowing(false);
        end)
        PetAuctionShow:Disable ()
    end
end

function PetAuction_CreateEntries(pets)
    PetAuction_Debug(PetAuction_Yellow("Num of Entries "..table.getn(pets)))

    for _, child in pairs({PetAuctionScrollChild:GetChildren()}) do
        child:Hide()
    end

    for i, pet in ipairs(pets) do
        PetAuction_CreateEntry(i, pet)
    end

    PetAuctionScrollChild:SetHeight(#pets*37)
    PetAuctionStatus:SetText(#pets.." items found")
end

function PetAuction_CreateEntry(index, pet)
    local buttonName = "PetAuctiontEntry"..index
    local click, highlight, pushed, link, icon, text

    if _G[buttonName] == nil then
        local entry = CreateFrame ("CheckButton", buttonName, PetAuctionScrollChild)
        entry:SetPoint ("LEFT", 0, 0)
        entry:SetPoint ("RIGHT", 0, 0)
        if index > 1 then
            entry:SetPoint ("TOP", "PetAuctiontEntry"..(index - 1), "BOTTOM", 0, -2)
        else
            entry:SetPoint ("TOP", 0, 0)
        end
        entry:SetHeight (35)
        click = function (self)
            entry:SetChecked (true)
            active_auction = pet
            if active_button ~= nil then
                active_button:SetChecked (false)
            end
            active_button = entry
            PetMarketBuyout:Enable ()
            PetMarketBid:Enable ()
            PetMarketShow:Enable ()
        end
        entry:SetScript ("OnClick", click)

        highlight = entry:CreateTexture()
        highlight:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
        highlight:SetTexCoord(0.035, 0.04, 0.2, 0.25)
        highlight:SetAllPoints()
        entry:SetHighlightTexture(highlight)

        pushed = entry:CreateTexture()
        pushed:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
        pushed:SetTexCoord(0, 1, 0.0, 0.55)
        pushed:SetAllPoints()
        entry:SetCheckedTexture(pushed)

        link = CreateFrame("Button", buttonName.."Link", entry)
        link:SetScript ("OnClick", click)

        icon = link:CreateTexture(buttonName.."Icon")
        icon:SetPoint ("TOPLEFT", 0, 0)
        icon:SetPoint ("BOTTOM", 0, 0)
        icon:SetWidth (entry:GetHeight ())

        text = link:CreateFontString (buttonName.."Text", "ARTWORK", "ChatFontNormal")
        text:SetPoint ("LEFT", icon, "RIGHT", 10, 0)

        link:SetPoint ("TOPLEFT", 0, 0)
        link:SetPoint ("BOTTOM", 0, 0)
        link:SetScript ("OnLeave", function ()
            entry:UnlockHighlight ()
            GameTooltip:Hide ()
            BattlePetTooltip:Hide ()
        end)

        local bid = CreateFrame ("Frame", buttonName.."Bid", entry, "SmallMoneyFrameTemplate")
        MoneyFrame_SetType (bid, "AUCTION")
        bid:SetPoint ("TOPRIGHT", 0, -5)

        local buyout = CreateFrame ("Frame", buttonName.."Buyout", entry, "SmallMoneyFrameTemplate")
        MoneyFrame_SetType (buyout, "AUCTION")
        buyout:SetPoint ("TOP", bid, "BOTTOM", 0, -2)

        local label = entry:CreateFontString (nil, "OVERLAY", "GameFontNormal")
        label:SetText ("Buyout")
        label:SetPoint ("BOTTOMRIGHT", -150, 5)
    end

    _G[buttonName.."Icon"]:SetTexture(pet["icon"])
    --_G[buttonName.."Text"]:SetText(pet["link"]:gsub("[%[%]]", ""))
    _G[buttonName.."Text"]:SetText(pet["name"])
    _G[buttonName.."Link"]:SetWidth(_G[buttonName.."Text"]:GetWidth () + _G[buttonName.."Icon"]:GetWidth ())
    _G[buttonName.."Link"]:SetScript ("OnEnter", function()
        _G[buttonName]:LockHighlight ()
        GameTooltip:Show ()
        GameTooltip:SetOwner (_G[buttonName.."Link"])
        if string.match (value["link"], "|Hbattlepet:") then
            local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit(":", pet["link"])
            BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality), tonumber(maxHealth), tonumber(power), tonumber(speed), nil)
        else
            GameTooltip:SetHyperlink(pet["link"])
        end
    end)
    MoneyFrame_Update(_G[buttonName.."Bid"], pet["bid"])
    MoneyFrame_Update(_G[buttonName.."Buyout"], pet["buyout"])
    _G[buttonName]:Show()
end

function PetAuction_UpdatePetList()
    local pets = { }
    local numPets, numOwned = C_PetJournal.GetNumPets();

    PetAuction_Debug("numPets: "..numPets.." numOwned: "..numOwned)

    for i = 1,numPets do
        local petID, speciesID, isOwned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i);
        if isTradeable then
            table.insert(pets, {name = speciesName, icon = icon, buyout = 0, bid = 0, link = "", id = petID })
            --PetAuction_Debug(PetAuction_Yellow(speciesName).." "..PetAuction_Boolean_Color("isOwned", isOwned).." "..PetAuction_Boolean_Color("isTradeable", isTradeable))
        end
    end

    PetAuction_Debug("Pet Count: "..table.getn(pets))
    PetAuction_CreateEntries(pets)
end

function PetAuction_QueryPetList()
    PetAuction_Debug("Item Class: "..PetAuction_Yellow(AUCTION_CATEGORY_BATTLE_PETS).." "..LE_ITEM_CLASS_BATTLEPET)

    --QueryAuctionItems("name", minLevel, maxLevel, page, isUsable, qualityIndex, getAll, exactMatch, filterData)
    QueryAuctionItems("", 0, 0, 0, 0, 0, true, nil, LE_ITEM_CLASS_BATTLEPET);
end

-- Utils

function PetAuction_ChatMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PetAuction_Blue(addonName).." "..msg, .9, .9, .9)
end

function PetAuction_Debug(msg)
    if PET_AUCTION_DEBUG then
        PetAuction_ChatMessage(msg)
    end
end

function PetAuction_Red(msg)
    return "|"..PET_AUCTION_RED..msg.."|r"
end

function PetAuction_Blue(msg)
    return "|"..PET_AUCTION_BLUE..msg.."|r"
end

function PetAuction_Yellow(msg)
    return "|"..PET_AUCTION_YELLOW..msg.."|r"
end

function PetAuction_Boolean_Color(msg, bool)
    if bool then
        return "|"..PET_AUCTION_BLUE..msg.."|r"
    end

    return "|"..PET_AUCTION_RED..msg.."|r"
end
