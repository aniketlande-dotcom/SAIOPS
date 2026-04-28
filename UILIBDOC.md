> ## Documentation Index
> Fetch the complete documentation index at: https://docs.sirius.menu/llms.txt
> Use this file to discover all available pages before exploring further.

# Loading the library

> How to load Rayfield into your script and enable configuration saving.

## Load Rayfield

Add the following line at the top of your script to load the Rayfield library.

```lua  theme={null}
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
```

## Enable configuration saving

Configuration saving lets Rayfield automatically persist and restore element values across sessions.

<Steps>
  <Step title="Enable ConfigurationSaving in CreateWindow">
    Set `ConfigurationSaving.Enabled` to `true` and provide a `FileName` when calling `CreateWindow`.
  </Step>

  <Step title="Set a unique flag on each element">
    Every element that supports configuration saving has a `Flag` field. Make sure each flag is unique to avoid conflicts.
  </Step>

  <Step title="Call LoadConfiguration at the end of your script">
    Place `Rayfield:LoadConfiguration()` after all your elements have been created.

    ```lua  theme={null}
    Rayfield:LoadConfiguration()
    ```
  </Step>
</Steps>

Rayfield will now automatically save and restore your configuration on each load.


> ## Documentation Index
> Fetch the complete documentation index at: https://docs.sirius.menu/llms.txt
> Use this file to discover all available pages before exploring further.

# Windows

> How to create and manage windows, tabs, and sections in Rayfield.

## Create a window

`Rayfield:CreateWindow()` is the entry point for your UI. Call it once after loading the library.

```lua  theme={null}
local Window = Rayfield:CreateWindow({
   Name = "Rayfield Example Window",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Rayfield Interface Suite",
   LoadingSubtitle = "by Sirius",
   ShowText = "Rayfield", -- for mobile users to unhide Rayfield, change if you'd like
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from emitting warnings when the script has a version mismatch with the interface.

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
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
```

### Options

<ResponseField name="Name" type="string" required>
  The title displayed in the window header.
</ResponseField>

<ResponseField name="Icon" type="number | string">
  Icon shown in the topbar. Pass a Roblox image ID (number), a Lucide icon name (string), or `0` for no icon.
</ResponseField>

<ResponseField name="LoadingTitle" type="string">
  Title shown on the loading screen.
</ResponseField>

<ResponseField name="LoadingSubtitle" type="string">
  Subtitle shown on the loading screen.
</ResponseField>

<ResponseField name="ShowText" type="string">
  Text shown to mobile users to unhide the UI.
</ResponseField>

<ResponseField name="Theme" type="string | table">
  The theme to apply. Pass a theme identifier string or a custom theme table. See [Themes](/rayfield/themes).
</ResponseField>

<ResponseField name="ToggleUIKeybind" type="string | Enum.KeyCode">
  The key that toggles UI visibility.
</ResponseField>

<ResponseField name="DisableRayfieldPrompts" type="boolean">
  Suppresses built-in Rayfield prompts.
</ResponseField>

<ResponseField name="DisableBuildWarnings" type="boolean">
  Prevents Rayfield from emitting warnings when there is a version mismatch between your script and the interface.
</ResponseField>

<ResponseField name="ConfigurationSaving" type="object">
  Controls automatic configuration saving.

  <Expandable title="ConfigurationSaving options">
    <ResponseField name="Enabled" type="boolean">
      Enables configuration saving.
    </ResponseField>

    <ResponseField name="FolderName" type="string | nil">
      Custom folder name for saved config files. Leave `nil` to use the default.
    </ResponseField>

    <ResponseField name="FileName" type="string">
      The name of the saved config file.
    </ResponseField>
  </Expandable>
</ResponseField>

<ResponseField name="Discord" type="object">
  Prompts the user to join your Discord server on supported executors.

  <Expandable title="Discord options">
    <ResponseField name="Enabled" type="boolean">
      Enables the Discord join prompt.
    </ResponseField>

    <ResponseField name="Invite" type="string">
      Your Discord invite code, without `discord.gg/`. For example, `discord.gg/ABCD` → `"ABCD"`.
    </ResponseField>

    <ResponseField name="RememberJoins" type="boolean">
      When `true`, the user is only prompted once. When `false`, they are prompted every load.
    </ResponseField>
  </Expandable>
</ResponseField>

<Warning>
  The key system UI loads a detectable Roblox model. In [Secure Mode](/rayfield/secure-mode), the key UI is blocked entirely — users must have a saved key from a previous session or they won't be able to load the script.
</Warning>

<ResponseField name="KeySystem" type="boolean">
  Enables the key system. Configure it with `KeySettings`.
</ResponseField>

<ResponseField name="KeySettings" type="object">
  Settings for the key system. Only used when `KeySystem` is `true`.

  <Expandable title="KeySettings options">
    <ResponseField name="Title" type="string">
      Title displayed on the key prompt.
    </ResponseField>

    <ResponseField name="Subtitle" type="string">
      Subtitle displayed on the key prompt.
    </ResponseField>

    <ResponseField name="Note" type="string">
      Instructions for obtaining the key, shown to the user.
    </ResponseField>

    <ResponseField name="FileName" type="string">
      File name used to save the key locally. Use something unique to avoid conflicts with other Rayfield scripts.
    </ResponseField>

    <ResponseField name="SaveKey" type="boolean">
      When `true`, the user's key is saved so they don't need to re-enter it. Note: changing the key will invalidate saved keys.
    </ResponseField>

    <ResponseField name="GrabKeyFromSite" type="boolean">
      When `true`, Rayfield fetches the key from the URL specified in `Key`.
    </ResponseField>

    <ResponseField name="Key" type="table">
      A list of accepted keys (strings), or RAW file URLs (Pastebin, GitHub, etc.) when `GrabKeyFromSite` is `true`.
    </ResponseField>
  </Expandable>
</ResponseField>

***

## Create a tab

Tabs are the top-level sections inside a window. Each tab can hold its own elements.

```lua  theme={null}
local Tab = Window:CreateTab("Tab Example", 4483362458) -- Title, Image
```

### Lucide icon support

You can use a [Lucide icon](https://lucide.dev/icons/) name in place of a Roblox image ID.

```lua  theme={null}
local Tab = Window:CreateTab("Tab Example", "rewind")
```

<Note>
  Not all Lucide icons are supported. See the [full list of supported icons](https://github.com/latte-soft/lucide-roblox/tree/master/icons/compiled/48px). Credit to [Lucide](https://lucide.dev/) and [Latte Softworks](https://github.com/latte-soft/).
</Note>

<Warning>
  Lucide icons and Roblox image IDs are detectable by game anti-cheats. If you need your script to be undetectable, use `getcustomasset()` instead. See [Secure Mode](/rayfield/secure-mode) for details.
</Warning>

***

## Create a section

Sections add a labelled group header inside a tab.

```lua  theme={null}
local Section = Tab:CreateSection("Section Example")
```

### Update a section

```lua  theme={null}
Section:Set("Section Example")
```

***

## Create a divider

Dividers add a horizontal rule inside a tab to visually separate content.

```lua  theme={null}
local Divider = Tab:CreateDivider()
```

### Update a divider

```lua  theme={null}
Divider:Set(false) -- Whether the divider's visibility is to be set to true or false.
```

***

## Visibility

### Set visibility

```lua  theme={null}
Rayfield:SetVisibility(false)
```

### Get visibility

```lua  theme={null}
Rayfield:IsVisible()
```

***

## Destroy the interface

```lua  theme={null}
Rayfield:Destroy()
```


> ## Documentation Index
> Fetch the complete documentation index at: https://docs.sirius.menu/llms.txt
> Use this file to discover all available pages before exploring further.

# Notifications

> How to send notifications to the user in Rayfield.

## Send a notification

```lua  theme={null}
Rayfield:Notify({
   Title = "Notification Title",
   Content = "Notification Content",
   Duration = 6.5,
   Image = 4483362458,
})
```

### Lucide icon support

You can use a [Lucide icon](https://lucide.dev/icons/) name in place of a Roblox image ID.

```lua  theme={null}
Rayfield:Notify({
   Title = "Notification Title",
   Content = "Notification Content",
   Duration = 6.5,
   Image = "rewind",
})
```

<Note>
  Not all Lucide icons are supported. See the [full list of supported icons](https://github.com/latte-soft/lucide-roblox/tree/master/icons/compiled/48px). Credit to [Lucide](https://lucide.dev/) and [Latte Softworks](https://github.com/latte-soft/).
</Note>

<Warning>
  Lucide icons and Roblox image IDs are detectable by game anti-cheats. If you need your script to be undetectable, use `getcustomasset()` instead. See [Secure Mode](/rayfield/secure-mode) for details.
</Warning>

### Options

<ResponseField name="Title" type="string" required>
  The notification title.
</ResponseField>

<ResponseField name="Content" type="string" required>
  The notification body text.
</ResponseField>

<ResponseField name="Duration" type="number">
  How long the notification stays visible, in seconds.
</ResponseField>

<ResponseField name="Image" type="number | string">
  Icon for the notification. Pass a Roblox image ID (number) or a Lucide icon name (string).
</ResponseField>


> ## Documentation Index
> Fetch the complete documentation index at: https://docs.sirius.menu/llms.txt
> Use this file to discover all available pages before exploring further.

# Interactive elements

> How to create buttons, toggles, color pickers, sliders, inputs, and dropdowns.

## Button

```lua  theme={null}
local Button = Tab:CreateButton({
   Name = "Button Example",
   Callback = function()
   -- The function that takes place when the button is pressed
   end,
})
```

### Update a button

```lua  theme={null}
Button:Set("Button Example")
```

***

## Toggle

```lua  theme={null}
local Toggle = Tab:CreateToggle({
   Name = "Toggle Example",
   CurrentValue = false,
   Flag = "Toggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
   -- The function that takes place when the toggle is pressed
   -- The variable (Value) is a boolean on whether the toggle is true or false
   end,
})
```

### Update a toggle

```lua  theme={null}
Toggle:Set(false)
```

***

## Color picker

```lua  theme={null}
local ColorPicker = Tab:CreateColorPicker({
    Name = "Color Picker",
    Color = Color3.fromRGB(255,255,255),
    Flag = "ColorPicker1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        -- The function that takes place every time the color picker is moved/changed
        -- The variable (Value) is a Color3fromRGB value based on which color is selected
    end
})
```

### Update a color picker

```lua  theme={null}
ColorPicker:Set(Color3.fromRGB(255,255,255))
```

***

## Slider

```lua  theme={null}
local Slider = Tab:CreateSlider({
   Name = "Slider Example",
   Range = {0, 100},
   Increment = 10,
   Suffix = "Bananas",
   CurrentValue = 10,
   Flag = "Slider1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
   -- The function that takes place when the slider changes
   -- The variable (Value) is a number that correlates to the value the slider is currently at
   end,
})
```

### Update a slider

```lua  theme={null}
Slider:Set(10) -- The new slider integer value
```

***

## Input

```lua  theme={null}
local Input = Tab:CreateInput({
   Name = "Input Example",
   CurrentValue = "",
   PlaceholderText = "Input Placeholder",
   RemoveTextAfterFocusLost = false,
   Flag = "Input1",
   Callback = function(Text)
   -- The function that takes place when the input is changed
   -- The variable (Text) is a string for the value in the text box
   end,
})
```

### Update an input

```lua  theme={null}
Input:Set("New Text") -- The new input text value
```

***

## Dropdown

```lua  theme={null}
local Dropdown = Tab:CreateDropdown({
   Name = "Dropdown Example",
   Options = {"Option 1", "Option 2"},
   CurrentOption = {"Option 1"},
   MultipleOptions = false,
   Flag = "Dropdown1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Options)
   -- The function that takes place when the selected option is changed
   -- The variable (Options) is a table of strings for the current selected options
   end,
})
```

### Refresh the option list

```lua  theme={null}
Dropdown:Refresh({"New Option 1","New Option 2"}) -- The new list of options
```

### Set the selected option

The option table can include multiple strings if `MultipleOptions` is `true`.

```lua  theme={null}
Dropdown:Set({"Option 2"}) -- "Option 2" will now be selected
```

<Note>
  The dropdown's callback is triggered when you call `Dropdown:Set()`.
</Note>

***

## Reading element values

To read the current value of an element, use `ElementName.CurrentValue`. For keybinds and dropdowns, use `KeybindName.CurrentKeybind` or `DropdownName.CurrentOption` respectively.

You can also access values through the flags table:

```lua  theme={null}
Rayfield.Flags
```


> ## Documentation Index
> Fetch the complete documentation index at: https://docs.sirius.menu/llms.txt
> Use this file to discover all available pages before exploring further.

# Keybinds

> How to create and update keybinds in Rayfield.

## Create a keybind

```lua  theme={null}
local Keybind = Tab:CreateKeybind({
   Name = "Keybind Example",
   CurrentKeybind = "Q",
   HoldToInteract = false,
   Flag = "Keybind1", -- A flag is the identifier for the configuration file. Make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Keybind)
   -- The function that takes place when the keybind is pressed
   -- The variable (Keybind) is a boolean for whether the keybind is being held or not (HoldToInteract needs to be true)
   end,
})
```

### Update a keybind

```lua  theme={null}
Keybind:Set("RightCtrl") -- Keybind (string)
```


> ## Documentation Index
> Fetch the complete documentation index at: https://docs.sirius.menu/llms.txt
> Use this file to discover all available pages before exploring further.

# Text elements

> How to create labels, paragraphs, and dividers in Rayfield.

## Label

```lua  theme={null}
local Label = Tab:CreateLabel("Label Example", 4483362458, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme
```

### Lucide icon support

You can use a [Lucide icon](https://lucide.dev/icons/) name in place of a Roblox image ID.

```lua  theme={null}
local Label = Tab:CreateLabel("Label Example", "rewind")
```

<Note>
  Not all Lucide icons are supported. See the [full list of supported icons](https://github.com/latte-soft/lucide-roblox/tree/master/icons/compiled/48px). Credit to [Lucide](https://lucide.dev/) and [Latte Softworks](https://github.com/latte-soft/).
</Note>

<Warning>
  Lucide icons and Roblox image IDs are detectable by game anti-cheats. If you need your script to be undetectable, use `getcustomasset()` instead. See [Secure Mode](/rayfield/secure-mode) for details.
</Warning>

### Update a label

```lua  theme={null}
Label:Set("Label Example", 4483362458, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme
```

***

## Paragraph

```lua  theme={null}
local Paragraph = Tab:CreateParagraph({Title = "Paragraph Example", Content = "Paragraph Example"})
```

### Update a paragraph

```lua  theme={null}
Paragraph:Set({Title = "Paragraph Example", Content = "Paragraph Example"})
```

***

## Divider

```lua  theme={null}
local Divider = Tab:CreateDivider()
```

### Update a divider

Toggle the divider's visibility.

```lua  theme={null}
Divider:Set(false) -- Visible
```


> ## Documentation Index
> Fetch the complete documentation index at: https://docs.sirius.menu/llms.txt
> Use this file to discover all available pages before exploring further.

# Themes

> Built-in themes and custom theme support in Rayfield.

## Using a theme

Pass a theme identifier to `CreateWindow`, or call `Window.ModifyTheme()` at any time.

```lua  theme={null}
Window.ModifyTheme('Default')
```

Or set it during window creation:

```lua  theme={null}
local Window = Rayfield:CreateWindow({
   Theme = "Default",
   -- ...
})
```

***

## Available themes

| Theme name | Identifier  | Preview                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| ---------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Default    | `Default`   | <img src="https://mintcdn.com/sirius-b451bfde/i5Ltpj53aNl_8MQt/images/themes/Default.png?fit=max&auto=format&n=i5Ltpj53aNl_8MQt&q=85&s=0c952763a1ef9550ca9fc6fdeb68cfae" alt="Default" width="500" height="475" data-path="images/themes/Default.png" />                    |
| Amber Glow | `AmberGlow` | <img src="https://mintcdn.com/sirius-b451bfde/i5Ltpj53aNl_8MQt/images/themes/AmberGlow.png?fit=max&auto=format&n=i5Ltpj53aNl_8MQt&q=85&s=ca4587aea57938109019ab5021abae24" alt="Amber Glow" width="501" height="476" data-path="images/themes/AmberGlow.png" /> |
| Amethyst   | `Amethyst`  | <img src="https://mintcdn.com/sirius-b451bfde/i5Ltpj53aNl_8MQt/images/themes/Amethyst.png?fit=max&auto=format&n=i5Ltpj53aNl_8MQt&q=85&s=dfb53b624a52013052396a63379c1b45" alt="Amethyst" width="502" height="476" data-path="images/themes/Amethyst.png" />           |
| Bloom      | `Bloom`     | <img src="https://mintcdn.com/sirius-b451bfde/i5Ltpj53aNl_8MQt/images/themes/Bloom.png?fit=max&auto=format&n=i5Ltpj53aNl_8MQt&q=85&s=2a63f0277f973c70d3634285ebdcaede" alt="Bloom" width="502" height="477" data-path="images/themes/Bloom.png" />                                      |
| Dark Blue  | `DarkBlue`  | <img src="https://mintcdn.com/sirius-b451bfde/i5Ltpj53aNl_8MQt/images/themes/DarkBlue.png?fit=max&auto=format&n=i5Ltpj53aNl_8MQt&q=85&s=3c3edf311c4008daa7c96971c8103f5e" alt="Dark Blue" width="502" height="476" data-path="images/themes/DarkBlue.png" />          |
| Green      | `Green`     | <img src="https://mintcdn.com/sirius-b451bfde/i5Ltpj53aNl_8MQt/images/themes/Green.png?fit=max&auto=format&n=i5Ltpj53aNl_8MQt&q=85&s=d54828f716742782bfd1b31bee215f00" alt="Green" width="502" height="476" data-path="images/themes/Green.png" />                                      |
| Light      | `Light`     | <img src="https://mintcdn.com/sirius-b451bfde/i5Ltpj53aNl_8MQt/images/themes/Light.png?fit=max&auto=format&n=i5Ltpj53aNl_8MQt&q=85&s=0c8ce5820daa43364c1e551dcf3df34e" alt="Light" width="501" height="476" data-path="images/themes/Light.png" />                                      |
| Ocean      | `Ocean`     | <img src="https://mintcdn.com/sirius-b451bfde/i5Ltpj53aNl_8MQt/images/themes/Ocean.png?fit=max&auto=format&n=i5Ltpj53aNl_8MQt&q=85&s=169f046e109699b11f8a83dfcada3ddf" alt="Ocean" width="501" height="477" data-path="images/themes/Ocean.png" />                                      |
| Serenity   | `Serenity`  | <img src="https://mintcdn.com/sirius-b451bfde/i5Ltpj53aNl_8MQt/images/themes/Serenity.png?fit=max&auto=format&n=i5Ltpj53aNl_8MQt&q=85&s=042bf576db39b6a77a6b8183099719e9" alt="Serenity" width="505" height="478" data-path="images/themes/Serenity.png" />           |

***

## Custom themes

You can define your own theme as of Rayfield 1.53. Pass a theme table in place of a theme identifier string in either `ModifyTheme` or `CreateWindow`.

```lua  theme={null}
{
	TextColor = Color3.fromRGB(240, 240, 240),

	Background = Color3.fromRGB(25, 25, 25),
	Topbar = Color3.fromRGB(34, 34, 34),
	Shadow = Color3.fromRGB(20, 20, 20),

	NotificationBackground = Color3.fromRGB(20, 20, 20),
	NotificationActionsBackground = Color3.fromRGB(230, 230, 230),

	TabBackground = Color3.fromRGB(80, 80, 80),
	TabStroke = Color3.fromRGB(85, 85, 85),
	TabBackgroundSelected = Color3.fromRGB(210, 210, 210),
	TabTextColor = Color3.fromRGB(240, 240, 240),
	SelectedTabTextColor = Color3.fromRGB(50, 50, 50),

	ElementBackground = Color3.fromRGB(35, 35, 35),
	ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
	SecondaryElementBackground = Color3.fromRGB(25, 25, 25),
	ElementStroke = Color3.fromRGB(50, 50, 50),
	SecondaryElementStroke = Color3.fromRGB(40, 40, 40),

	SliderBackground = Color3.fromRGB(50, 138, 220),
	SliderProgress = Color3.fromRGB(50, 138, 220),
	SliderStroke = Color3.fromRGB(58, 163, 255),

	ToggleBackground = Color3.fromRGB(30, 30, 30),
	ToggleEnabled = Color3.fromRGB(0, 146, 214),
	ToggleDisabled = Color3.fromRGB(100, 100, 100),
	ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
	ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
	ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
	ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),

	DropdownSelected = Color3.fromRGB(40, 40, 40),
	DropdownUnselected = Color3.fromRGB(30, 30, 30),

	InputBackground = Color3.fromRGB(30, 30, 30),
	InputStroke = Color3.fromRGB(65, 65, 65),
	PlaceholderColor = Color3.fromRGB(178, 178, 178)
}
```


> ## Documentation Index
> Fetch the complete documentation index at: https://docs.sirius.menu/llms.txt
> Use this file to discover all available pages before exploring further.

# Anti-Detection

> How to use a custom asset ID to reduce Rayfield's detectability by game anti-cheats.

## How Rayfield gets detected

Rayfield loads its UI through `game:GetObjects` with a known asset ID. Most anti-cheats hook this function and check the ID against a blocklist — and since Rayfield's default ID (`10804731440`) is public, it's an easy flag.

The fix is simple: re-upload the UI model to your own account and point Rayfield at your copy. Now every script has its own unique asset ID that anti-cheats don't have on file.

<Note>
  This only removes the lowest-hanging detection vector. For full protection, enable [Secure Mode](/rayfield/secure-mode) which blocks all detectable Roblox assets at runtime.
</Note>

***

## Re-upload the UI model

<Steps>
  <Step title="Get the Rayfield model in Studio">
    Open Roblox Studio and grab the model however you prefer:

    * Get it from the [Creator Store](https://create.roblox.com/store/asset/10804731440) and insert it
    * Search **Rayfield** in the Toolbox
    * Run this in the command bar:

    ```lua  theme={null}
    game:GetObjects("rbxassetid://10804731440")[1].Parent = workspace
    ```
  </Step>

  <Step title="Upload it to your account">
    Right-click the model in Explorer → **Save to Roblox** → upload as a new model.
  </Step>

  <Step title="Enable distribution">
    Go to the asset's **Configure** page on the Roblox website and turn on **Distribute on Creator Store** — otherwise `GetObjects` won't be able to fetch it.
  </Step>

  <Step title="Copy the new asset ID">
    Grab the ID from the asset URL or Asset Manager.
  </Step>
</Steps>

***

## Set your custom asset ID

At the top of your script, **before** loading Rayfield:

```lua  theme={null}
getgenv().RAYFIELD_ASSET_ID = 123456789 -- your asset ID here
```
getgenv().RAYFIELD_ASSET_ID = 132249892549826 --my actual asset id use this 

If you don't set this, Rayfield just uses the default ID. Still works, just detectable.

***

## Full example

```lua  theme={null}
getgenv().RAYFIELD_ASSET_ID = 123456789

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "My Script",
    -- rest of your config
})
```

***

## Good to know

* **Don't touch the model structure.** Upload it as-is. If you rename or rearrange things inside the model, Rayfield won't be able to find what it needs.
* **Re-upload when Rayfield updates.** If we ship a new UI model, your old copy won't match anymore. Just re-upload the new one.
* **Try to keep your asset ID to yourself.** If it ends up on a blocklist you just re-upload a new one — not a big deal, just extra work you can avoid.
* **Key System UI is separate.** It has its own asset ID and only loads when key system is enabled, so it's less of a priority.


