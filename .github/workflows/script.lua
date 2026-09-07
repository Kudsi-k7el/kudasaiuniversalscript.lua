local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({

   Name = "🔫[FPS] One Tap🔫",

   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).

   LoadingTitle = "kudasai is testing",

   LoadingSubtitle = "by kudasai",

   ShowText = "Rayfield", -- for mobile users to unhide Rayfield, change if you'd like

   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,

   DisableBuildWarnings = false, -- Prevents Rayfield from emitting warnings when the script has a version mismatch with the interface.

   -- ScriptID = "sid_xxxxxxxxxxxx", -- Your Script ID from developer.sirius.menu — enables analytics, managed keys, and script hosting

   ConfigurationSaving = {

      Enabled = true,

      FolderName = nil, -- Create a custom folder for your hub/game

      FileName = "kudasai"

   },

   Discord = {

      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it

      Invite = "noinvitelink", -- The Discord invite code, do not include Discord.gg/. E.g. Discord.gg/ABCD would be ABCD

      RememberJoins = true -- Set this to false to make them join the Discord every time they load it up

   },

   KeySystem = false, -- Set this to true to use our key system

   KeySettings = {

      Title = "Untitled",

      Subtitle = "Key System",

      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key

      FileName = "Key", -- It is recommended to use something unique, as other scripts using Rayfield may overwrite your key file

      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script

      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from

      Key = {"Hello"} -- List of keys that the system will accept, can be RAW file links (pastebin, github, etc.) or simple strings ("hello", "key22")

   }

})

local MainTab = Window:CreateTab("home", 4483362458) -- Title, Image

local MainSection = MainTab:CreateSection("Main")

Rayfield:Notify({

   Title = "the script has been executed!",

   Content = "Ahmed gay",

   Duration = 6.5,

   Image = nil,

})

local Button = MainTab:CreateButton({

   Name = "Infinite jump",

   Callback = function()

--[[

2022 WeAreDevs | The WeAreDevs Infinite Jump script

Created and distributed by https://wearedevs.net/scripts

March 9, 2022

Step 1: Inject this script into any game using a Lua injector like JJSploit

Step 2: When you get the ready notification, spam the space bar to jump as many times as you want

Controls:

Reinject the script to toggle the infinite jump script on or off.

Excute Lua "G.infinjump = true" to explicity turn the infinite jump script on

Excute Lua "G.infinjump = false" to explicity turn the infinite jump script off

]]

--Toggles the infinite jump between on or off on every script run

_G.infinjump = not _G.infinjump

if _G.infinJumpStarted == nil then

    --Ensures this only runs once to save resources

    _G.infinJumpStarted = true

    --The actual infinite jump

    local plr = game:GetService('Players').LocalPlayer

    function doJump()

        if _G.infinjump then

            humanoid = game:GetService'Players'.LocalPlayer.Character:FindFirstChildOfClass('Humanoid')

            humanoid:ChangeState('Jumping')

            wait()

            humanoid:ChangeState('Seated')

        end

    end

    --PC Support

    local m = plr:GetMouse()

    m.KeyDown:connect(function(k)

        if k:byte() == 32 then

            doJump()

        end

    end)

    --Mobile support

    local uis = game:GetService("UserInputService")

    task.spawn(function()

        local pg = plr:WaitForChild("PlayerGui")

        local btn = pg:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton", 3)

        if btn then

            btn.MouseButton1Down:Connect(doJump)

        else

            uis.JumpRequest:Connect(doJump)

        end

    end)

end

   end,

})

local Slider = MainTab:CreateSlider({

   Name = "WalkSpeed Slider",

   Range = {1, 350},

   Increment = 1,

   Suffix = "Speed",

   CurrentValue = 16,

   Flag = "sliderws", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps

   Callback = function(Value)

        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = (Value)

   end,

})

local Slider = MainTab:CreateSlider({

   Name = "JumpPower Slider",

   Range = {1, 350},

   Increment = 1,

   Suffix = "Speed",

   CurrentValue = 16,

   Flag = "sliderjp", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps

   Callback = function(Value)

        game.Players.LocalPlayer.Character.Humanoid.JumpPower = (Value)

   end,

})
