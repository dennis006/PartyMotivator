--[[
    PartyMotivatorMythicPlus - World of Warcraft Addon
    Extension for automatic chat messages on Mythic+ dungeon completion
    Sends different messages depending on the success of the run
]]

-- Create the event frame for Mythic+ completion functionality
local PM_MythicPlus = CreateFrame("Frame")

-- Flag for double posts - reset when starting a dungeon
PM_MythicPlus.endPosted = false

--[[
    Sends a completion message based on the Mythic+ run result
    This function is called when a Mythic+ run is completed
]]
local function sendMythicPlusCompletionMessage()
    -- Check if a message was already sent
    if PM_MythicPlus.endPosted then
        return
    end
    
    -- Get the Challenge Mode completion information
    local info = C_ChallengeMode.GetChallengeCompletionInfo()
    if not info then
        return
    end
    
    -- Determine the chat channel
    local channel = PM.profile.useInstanceChat and "INSTANCE_CHAT" or "PARTY"
    
    -- Check if the run was on time and if there is a keystone upgrade
    if info.onTime and info.keystoneUpgradeLevels and info.keystoneUpgradeLevels > 0 then
        -- Run was on time and there is an upgrade
        local successMessages = PM.profile.mythicPlusMessages.success or {}
        if #successMessages > 0 then
            local successMsg = successMessages[math.random(#successMessages)]
            C_ChatInfo.SendChatMessage(successMsg, channel)
        else
            C_ChatInfo.SendChatMessage("GG! We timed it and upgraded the key 🎉", channel)
        end
    else
        -- Run was not on time
        local failureMessages = PM.profile.mythicPlusMessages.failure or {}
        if #failureMessages > 0 then
            local failureMsg = failureMessages[math.random(#failureMessages)]
            C_ChatInfo.SendChatMessage(failureMsg, channel)
        else
            C_ChatInfo.SendChatMessage("Thanks for the key! We'll get it next time.", channel)
        end
    end
    
    -- Mark that the message was sent
    PM_MythicPlus.endPosted = true
end

--[[
    Event handler for Mythic+ specific events
]]
local function onMythicPlusEvent(self, event, ...)
    if event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_COMPLETED_REWARDS" then
        -- Mythic+ run completed - send completion message
        sendMythicPlusCompletionMessage()
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Reset flag when entering/leaving an instance
        PM_MythicPlus.endPosted = false
        
    elseif event == "CHALLENGE_MODE_START" then
        -- Reset flag when a new Mythic+ run starts
        PM_MythicPlus.endPosted = false
    end
end

-- Register events for Mythic+ completion functionality
PM_MythicPlus:RegisterEvent("CHALLENGE_MODE_COMPLETED")
PM_MythicPlus:RegisterEvent("CHALLENGE_MODE_COMPLETED_REWARDS")
PM_MythicPlus:RegisterEvent("PLAYER_ENTERING_WORLD")
PM_MythicPlus:RegisterEvent("CHALLENGE_MODE_START")

-- Set the event handler
PM_MythicPlus:SetScript("OnEvent", onMythicPlusEvent)

--[[
    EVENT EXPLANATIONS:
    
    CHALLENGE_MODE_COMPLETED: Fired when a Mythic+ run is completed
    (older game versions). Here we send the corresponding completion message.
    
    CHALLENGE_MODE_COMPLETED_REWARDS: Fired when the loot chest appears at the end
    of a Mythic+ run (since patch 11.2). This is the preferred event
    for the completion message, as it is guaranteed to fire when the run
    is actually completed.
    
    PLAYER_ENTERING_WORLD: Fired when the player enters the world
    or a new zone/instance. Here we reset the endPosted flag,
    so that a message can be sent again for each new run.
    
    CHALLENGE_MODE_START: Fired when a new Mythic+ run starts.
    Here we reset the endPosted flag to ensure that the
    completion message can be sent for the new run.
    
    FUNCTIONALITY:
    - The addon monitors both Challenge Mode events (COMPLETED and COMPLETED_REWARDS)
    - It uses C_ChallengeMode.GetChallengeCompletionInfo() to check:
      * info.onTime: Boolean, whether the run was on time
      * info.keystoneUpgradeLevels: Number of keystone level upgrades
    - Depending on the result, an appropriate message is sent:
      * "GG! We timed it and upgraded the key 🎉" - for successful run with upgrade
      * "Thanks for the key! We'll get it next time." - for untimely run
    - The endPosted flag prevents double posts, even if both events fire
    - The flag is reset on instance change and run start
]]
