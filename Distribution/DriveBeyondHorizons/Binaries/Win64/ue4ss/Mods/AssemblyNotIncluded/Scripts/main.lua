local MOD = "[Assembly Not Included]"
local MENU_ASSET = "/Game/Mods/AssemblyNotIncluded/WBP_AssemblyNotIncluded"
local SPEEDOMETER_ASSET =
    "/Game/Mods/AssemblyNotIncluded/WBP_AssemblyNotIncludedSpeedometer"
local ITEM_MENU_ASSET = "/Game/UI/ItemSpawnerMenu/ItemSpawnerMenu"
local ITEM_CATALOG_TILE_WIDTH = 220
local ITEM_CATALOG_GRID_X_OFFSET = -24
local PAINT_MENU_ASSET = "/Game/UI/PaintBombMenu/SprayCanSpawnMenu"
local PAINT_CAN_ASSET = "/Game/BP/Items/Movable/PaintBomb/PaintBomb"
local UEHelpers = require("UEHelpers")

local menu_widget = nil
local asset_class_cache = {}
local cached_player_controller = nil
local item_widget = nil
local paint_widget = nil
local speedometer_widget = nil
local speedometer_owner = nil
local speedometer_last_text = nil
local speedometer_last_error = nil
local speedometer_tick_hooked = false
local speedometer_elapsed = 0.0
local speedometer_visible = false
local vehicle_tick_source = nil
local vehicle_hook_elapsed = 0.0
local vehicle_tuning_baselines = {}
local vehicle_tuning_elapsed = 0.0
local vehicle_tuning_last_error = nil
local vehicle_tuning_saved = {}
local vehicle_tuning_dirty = false
local vehicle_tuning_save_elapsed = 0.0
local vehicle_tank_maximums = {}
local sync_vehicle_tuning_controls = nil
local flush_vehicle_tunes = nil
local finalize_spawned_vehicle = nil
local menu_open = false
local speed_enabled = false
local jump_enabled = false
local vehicle_invulnerability = {}
local player_modifier_baseline = nil
local player_modifier_loop_token = 0
local surface_action_running = false
local surface_action_token = 0
local menu_actions = {}
local item_click_hooked = false
local item_layout_hooked = false
local paint_infinite_next = false
local paint_watch_token = 0
local expanded_section = nil
local input_restore_token = 0
ANI_ToolState = {
    infinite_brushes_enabled = false,
    paint_swatches = {},
    paint_swatch_limit = 8,
    paint_studio_opening = false,
}

local VEHICLES = {
    C18 = "/Game/BP/CarsV2/C18New",
    Caddie = "/Game/BP/CarsV2/CaddieCar",
    Escada = "/Game/BP/CarsV2/Escada",
    P51 = "/Game/BP/CarsV2/FrenchUtility",
    Loft = "/Game/BP/CarsV2/GermanCompact",
    Golf = "/Game/BP/CarsV2/GolfCar",
    GTR = "/Game/BP/CarsV2/HorizonGTCar",
    IFA = "/Game/BP/CarsV2/IFACar",
    Kage = "/Game/BP/CarsV2/JapaneseSporty",
    Dada = "/Game/BP/CarsV2/LadaCarNew",
    Tomahawk = "/Game/BP/CarsV2/MuscleCar",
    Musgoat = "/Game/BP/CarsV2/MusgoatCar",
    Peak = "/Game/BP/CarsV2/NewPoyopa",
    Bonphiac = "/Game/BP/CarsV2/PontiacCar",
    Poyopa = "/Game/BP/CarsV2/PoyopaCar",
    Speedle = "/Game/BP/CarsV2/SpeedleCar",
    TriClops = "/Game/BP/CarsV2/TriClopsCar",
    UAZ = "/Game/BP/CarsV2/UAZCar",
    Toilet = "/Game/BP/CarsV2/ToiletCar",
    HotDog = "/Game/BP/CarsV2/HotDog_Trailer",
    Trailer = "/Game/BP/CarsV2/Vehicle_Trailer",
}

local function log(message)
    print(MOD .. " " .. tostring(message))
end

local function valid(object)
    if not object then return false end
    local ok, result = pcall(function() return object:IsValid() end)
    return ok and result == true
end

local function get_pc()
    if valid(cached_player_controller) then
        return cached_player_controller
    end
    local pc = FindFirstOf("PlayerControllerBase_C")
    if valid(pc) then
        cached_player_controller = pc
        return pc
    end
    pc = FindFirstOf("PlayerController")
    if valid(pc) then
        cached_player_controller = pc
        return pc
    end
    return nil
end

local function get_pawn()
    local pc = get_pc()
    if valid(pc) and valid(pc.Pawn) then return pc.Pawn end
    return nil
end

local function has_property(object, name)
    if not valid(object) then return false end
    local ok, value = pcall(function() return object[name] end)
    return ok and value ~= nil
end

local function set_if_present(object, name, value)
    if not has_property(object, name) then return false end
    return pcall(function() object[name] = value end)
end

local function call_if_present(object, name, ...)
    if not valid(object) then return false, nil end
    local ok, fn = pcall(function() return object[name] end)
    if not ok or not fn or not fn:IsValid() then return false, nil end
    return pcall(fn, ...)
end

local function call_member_with_context(object, name, ...)
    if not valid(object) then return false, nil end
    local ok, fn = pcall(function() return object[name] end)
    if not ok or not fn or not fn:IsValid() then
        return false, "Function unavailable: " .. tostring(name)
    end
    return pcall(fn, object, ...)
end

local function show_message(message)
    log(message)
    local pc = get_pc()
    if not valid(pc) then return end
    pcall(function()
        local chat = {}
        chat.Time_8_DF6F279248745BE38C2E40835DE88631 = 0
        chat.User_6_4A6B517E45F066403FD3C4B4AA7C0FA3 = "[Assembly Not Included]"
        chat.Mesage_7_79981D7A424DFD8E6876D888E700B202 = tostring(message)
        chat.IsInfoMessage_10_CD41743F409EA1DC4DD22CAC94591338 = true
        pc:ServerSendChatMessage(chat)
    end)
end

local function class_from_asset(path)
    local cached = asset_class_cache[path]
    if valid(cached) then return cached end
    local name = path:match("([^/]+)$")
    local function find_class()
        local class = StaticFindObject(path .. "." .. name .. "_C")
        if valid(class) then return class end
        class = StaticFindObject(
            "WidgetBlueprintGeneratedClass " .. path .. "." .. name .. "_C")
        if valid(class) then return class end
        class = StaticFindObject(
            "BlueprintGeneratedClass " .. path .. "." .. name .. "_C")
        if valid(class) then return class end
        return nil
    end

    local class = find_class()
    if valid(class) then
        asset_class_cache[path] = class
        return class
    end

    LoadAsset(path)
    class = find_class()
    if valid(class) then
        asset_class_cache[path] = class
        return class
    end

    local helpers = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryHelpers")
    if valid(helpers) then
        local ok, loaded_class = pcall(function()
            return helpers:GetAsset({
                PackageName = UEHelpers.FindOrAddFName(path),
                AssetName = UEHelpers.FindOrAddFName(name .. "_C"),
            })
        end)
        if ok and valid(loaded_class) then
            asset_class_cache[path] = loaded_class
            return loaded_class
        end
    end
    log("Class load failed: " .. path)
    return nil
end

local function create_widget(path)
    local pc = get_pc()
    if not valid(pc) then return nil end
    local class = class_from_asset(path)
    if not valid(class) then return nil end
    local library = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    if not valid(library) then return nil end
    local ok, widget = pcall(function()
        return library:Create(pc, class, pc)
    end)
    if ok and valid(widget) then return widget end
    log("Widget creation failed: " .. tostring(widget))
    return nil
end

local function apply_game_input()
    local pc = get_pc()
    if not valid(pc) then return end
    pc.bShowMouseCursor = false
    local library = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    if valid(library) then
        pcall(function() library:SetInputMode_GameOnly(pc, true) end)
        pcall(function() library:SetFocusToGameViewport() end)
    end
    pcall(function() pc:FlushPressedKeys() end)
    pcall(function() pc:ResetIgnoreMoveInput() end)
    pcall(function() pc:ResetIgnoreLookInput() end)
end

local function restore_game_input()
    input_restore_token = input_restore_token + 1
    local token = input_restore_token
    apply_game_input()
    ExecuteWithDelay(75, function()
        ExecuteInGameThread(function()
            if token ~= input_restore_token then return end
            if menu_open or valid(item_widget) or valid(paint_widget) then return end
            apply_game_input()
        end)
    end)
end

local function close_menu()
    if flush_vehicle_tunes then
        pcall(flush_vehicle_tunes)
    end
    if valid(menu_widget) then
        pcall(function() menu_widget:RemoveFromParent() end)
    end
    menu_widget = nil
    menu_open = false
    restore_game_input()
end

local function find_named_widget(widget, name)
    local ok, child = pcall(function()
        return widget:GetWidgetFromName(UEHelpers.FindOrAddFName(name))
    end)
    if ok and valid(child) then return child end

    ok, child = pcall(function() return widget[name] end)
    if ok and valid(child) then return child end
    return nil
end

local SECTION_PANELS = {
    Paint = "Panel_Paint",
    Vehicles = "Panel_Vehicles",
    VehicleTools = "Panel_VehicleTools",
    Player = "Panel_Player",
    World = "Panel_World",
}

local function update_paint_mode_buttons()
    if not valid(menu_widget) then return end
    local standard = find_named_widget(menu_widget, "Btn_PaintStandard")
    local infinite = find_named_widget(menu_widget, "Btn_PaintInfinite")
    local active = {R = 0.76, G = 0.012, B = 0.30, A = 1.0}
    local inactive = {R = 0.13, G = 0.018, B = 0.075, A = 1.0}
    if valid(standard) then
        pcall(function()
            standard:SetBackgroundColor(
                paint_infinite_next and inactive or active)
        end)
    end
    if valid(infinite) then
        pcall(function()
            infinite:SetBackgroundColor(
                paint_infinite_next and active or inactive)
        end)
    end
end

function ANI_ToolState.sync_paint_swatch_buttons()
    if not valid(menu_widget) then return end
    local mixer = find_named_widget(
        menu_widget, "Btn_OpenPaintStudio")
    local mixer_label = find_named_widget(
        menu_widget, "Btn_OpenPaintStudio_Label")
    if not valid(mixer_label) and valid(mixer) then
        pcall(function() mixer_label = mixer:GetChildAt(0) end)
        if not valid(mixer_label) then
            pcall(function() mixer_label = mixer:GetContent() end)
        end
    end
    if valid(mixer_label) then
        pcall(function()
            mixer_label:SetText(FText(
                "CHOOSE COLOR & SPAWN  |  AUTO-SAVES"))
        end)
    end

    for index = 1, ANI_ToolState.paint_swatch_limit do
        local button = find_named_widget(
            menu_widget, "Btn_PaintSwatch" .. tostring(index))
        local label = find_named_widget(
            menu_widget, "Btn_PaintSwatch" .. tostring(index) .. "_Label")
        if not valid(label) and valid(button) then
            pcall(function() label = button:GetChildAt(0) end)
            if not valid(label) then
                pcall(function() label = button:GetContent() end)
            end
        end
        local swatch = ANI_ToolState.paint_swatches[index]
        if valid(button) then
            pcall(function()
                button:SetVisibility(swatch and 0 or 1)
            end)
            if swatch then
                pcall(function()
                    button:SetBackgroundColor({
                        R = 0.05 + 0.55 * swatch.r,
                        G = 0.05 + 0.55 * swatch.g,
                        B = 0.05 + 0.55 * swatch.b,
                        A = 1.0,
                    })
                end)
            else
                pcall(function()
                    button:SetBackgroundColor({
                        R = 0.055, G = 0.035, B = 0.05, A = 1.0,
                    })
                end)
            end
        end
        if valid(label) then
            local finish = swatch and
                (swatch.metallic >= 0.5 and "METALLIC" or "STANDARD") or
                "EMPTY"
            pcall(function()
                label:SetText(FText(
                    "SAVED " .. tostring(index) .. "  |  " .. finish))
            end)
        end
    end
    local clear = find_named_widget(
        menu_widget, "Btn_ClearPaintSwatches")
    if valid(clear) then
        pcall(function()
            clear:SetVisibility(
                #ANI_ToolState.paint_swatches > 0 and 0 or 1)
        end)
    end
end

local function set_expanded_section(section)
    expanded_section = expanded_section == section and nil or section
    for key, panel_name in pairs(SECTION_PANELS) do
        local panel = find_named_widget(menu_widget, panel_name)
        if valid(panel) then
            pcall(function()
                panel:SetVisibility(key == expanded_section and 0 or 1)
            end)
        end
    end
end

local function bind_menu_buttons(widget)
    local indexed = 0
    local missing = {}

    for action, _ in pairs(menu_actions) do
        local button_name = "Btn_" .. action
        local button = find_named_widget(widget, button_name)
        if valid(button) then
            indexed = indexed + 1
        else
            table.insert(missing, button_name)
        end
    end

    log("Indexed " .. tostring(indexed) .. " Assembly Not Included button action(s).")
    if #missing > 0 then
        log("Widget buttons not found: " .. table.concat(missing, ", "))
    end
    return indexed
end

local function open_menu()
    log("Menu open requested.")
    if menu_open then
        close_menu()
        return
    end
    if valid(paint_widget) then
        pcall(function() paint_widget:RemoveFromParent() end)
        paint_widget = nil
    end
    log("Resolving main menu widget.")
    menu_widget = create_widget(MENU_ASSET)
    if not valid(menu_widget) then
        show_message("Menu asset was not loaded. Check Assembly Not Included package installation.")
        return
    end
    log("Main menu widget created.")
    local indexed = bind_menu_buttons(menu_widget)
    if indexed == 0 then
        show_message("Menu buttons could not be connected to the Assembly Not Included bridge.")
    end
    local subtitle = find_named_widget(menu_widget, "Subtitle")
    if valid(subtitle) then
        pcall(function() subtitle:SetText(FText("F7")) end)
    end
    update_paint_mode_buttons()
    ANI_ToolState.sync_paint_swatch_buttons()
    expanded_section = nil
    for _, panel_name in pairs(SECTION_PANELS) do
        local panel = find_named_widget(menu_widget, panel_name)
        if valid(panel) then
            pcall(function() panel:SetVisibility(1) end)
        end
    end
    menu_widget:AddToViewport(10000)
    local pc = get_pc()
    pc.bShowMouseCursor = true
    local library = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    if valid(library) then
        pcall(function() library:SetInputMode_UIOnlyEx(pc, menu_widget, 0, false) end)
    end
    menu_open = true
    if sync_vehicle_tuning_controls then
        pcall(sync_vehicle_tuning_controls)
    end
    log("Assembly Not Included opened successfully.")
end

local function fit_item_catalog_to_viewport(widget)
    if not valid(widget) then return 1 end
    local layout = StaticFindObject("/Script/UMG.Default__WidgetLayoutLibrary")
    if not valid(layout) then return 1 end

    local ok, viewport = pcall(function() return layout:GetViewportSize(widget) end)
    if not ok or not viewport or type(viewport.X) ~= "number" or type(viewport.Y) ~= "number" then
        return 1
    end

    local root_ok, root = pcall(function() return widget.WidgetTree.RootWidget end)
    if root_ok and valid(root) then
        pcall(function() root:SetRenderTransformPivot({X = 0.5, Y = 0.5}) end)
        pcall(function() root:SetRenderScale({X = 1.0, Y = 1.0}) end)
    end

    -- The native catalog is a fixed 2400x1200 panel. Scale that actual panel
    -- around its center, leaving the viewport widget itself in the native
    -- centered layout. This keeps both edges inside the screen even when the
    -- viewport is narrower than the panel.
    local scale = math.min(0.94, (viewport.X - 100.0) / 2400.0, (viewport.Y - 100.0) / 1200.0)
    scale = scale * 0.97
    scale = math.max(0.35, scale)
    local border = find_named_widget(widget, "Border_0")
    if valid(border) then
        pcall(function() border:SetRenderTransformPivot({X = 0.5, Y = 0.5}) end)
        pcall(function() border:SetRenderScale({X = scale, Y = scale}) end)
    end

    -- ItemSpawnerElement's Blueprint has a wider fixed desired size than its
    -- public Size value suggests. Nine 200-unit entries therefore overflow
    -- the native panel's clipping rect; eight is the actual maximum that fits.
    local columns = 8
    log(string.format(
        "Item catalog layout: %d columns at %.2f scale (%.0fx%.0f viewport)",
        columns,
        scale,
        viewport.X,
        viewport.Y
    ))
    return columns
end

local function configure_native_item_catalog_layout(widget)
    if not valid(widget) then return false end
    local size_ok = set_if_present(widget, "SizeButton", ITEM_CATALOG_TILE_WIDTH)
    local grid_ok, grid = pcall(function() return widget.Grid end)
    if grid_ok and valid(grid) then
        pcall(function()
            grid:SetRenderTranslation({X = ITEM_CATALOG_GRID_X_OFFSET, Y = 0.0})
        end)
    end
    return size_ok
end

local function ensure_item_catalog_layout_hook()
    if item_layout_hooked then return end
    local ok, hook_id = pcall(function()
        return RegisterHook(
            "/Game/UI/ItemSpawnerMenu/ItemSpawnerMenu.ItemSpawnerMenu_C:Process",
            function(context)
                local widget_ok, widget = pcall(function() return context:get() end)
                if widget_ok and valid(widget) then
                    configure_native_item_catalog_layout(widget)
                end
            end
        )
    end)
    if ok and hook_id then
        item_layout_hooked = true
        log("Native item catalog tile-width layout hook installed.")
    else
        log("Native item catalog tile-width layout hook was unavailable.")
    end
end

local function close_item_catalog()
    if valid(item_widget) then
        pcall(function() item_widget:RemoveFromParent() end)
    end
    item_widget = nil
    restore_game_input()
end

local function ensure_item_click_hook()
    if item_click_hooked then return end
    local click_function =
        "/Game/UI/ItemSpawnerMenu/ItemSpawnerElement.ItemSpawnerElement_C:" ..
        "BndEvt__ItemSpawnerElement_Button_0_K2Node_ComponentBoundEvent_0_" ..
        "OnButtonClickedEvent__DelegateSignature"
    local ok, hook_id = pcall(function()
        return RegisterHook(click_function, function()
            ExecuteWithDelay(125, function()
                ExecuteInGameThread(close_item_catalog)
            end)
            ExecuteWithDelay(250, function()
                ExecuteInGameThread(function()
                    local changed =
                        ANI_ToolState.service_brush_durability()
                    if changed > 0 then
                        log("Normalized " .. tostring(changed) ..
                            " brush object(s) after item spawn.")
                    end
                end)
            end)
        end)
    end)
    if ok and hook_id then
        item_click_hooked = true
        log("Item spawn input-release hook installed.")
    else
        log("Item spawn input-release hook was unavailable.")
    end
end

local function open_item_catalog()
    close_menu()
    item_widget = create_widget(ITEM_MENU_ASSET)
    if not valid(item_widget) then
        show_message("The game's item catalog could not be opened.")
        return
    end
    ensure_item_catalog_layout_hook()
    configure_native_item_catalog_layout(item_widget)
    ensure_item_click_hook()
    item_widget:AddToViewport(10001)
    local pc = get_pc()
    if valid(pc) then
        pc.bShowMouseCursor = true
    end
    local library = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    if valid(library) and valid(pc) then
        pcall(function() library:SetInputMode_UIOnlyEx(pc, item_widget, 0, false) end)
    end
    ExecuteWithDelay(150, function()
        ExecuteInGameThread(function()
            if valid(item_widget) then
                configure_native_item_catalog_layout(item_widget)
                pcall(function() fit_item_catalog_to_viewport(item_widget) end)
            end
        end)
    end)
    log("Native item catalog opened without registry preload.")
end

local function close_paint_studio()
    paint_watch_token = paint_watch_token + 1
    ANI_ToolState.paint_studio_opening = false
    if valid(paint_widget) then
        pcall(function() paint_widget:RemoveFromParent() end)
    end
    paint_widget = nil
    restore_game_input()
end

local function loaded_paint_can_ids()
    local seen = {}
    local ok, objects = pcall(function() return FindAllOf("PaintBomb_C") end)
    if not ok or not objects then return seen end
    for _, object in ipairs(objects) do
        if valid(object) then
            local id_ok, id = pcall(function() return object:GetFullName() end)
            if id_ok then seen[tostring(id)] = true end
        end
    end
    return seen
end

function ANI_ToolState.positive_number_property(object, name)
    if not valid(object) then return nil end
    local ok, value = pcall(function() return object[name] end)
    if not ok then return nil end
    value = tonumber(value)
    if value and value > 0 then return value end
    return nil
end

function ANI_ToolState.stock_tool_capacity(object, fallback)
    local stock = nil
    local class_ok, class =
        pcall(function() return object:GetClass() end)
    if class_ok and valid(class) then
        local cdo_ok, cdo =
            pcall(function() return class:GetCDO() end)
        if cdo_ok and valid(cdo) then
            stock = ANI_ToolState.positive_number_property(
                cdo, "MaxQuantity")
            if not stock then
                stock = ANI_ToolState.positive_number_property(
                    cdo, "Quantity")
            end
        end
    end
    if not stock or stock >= 999999 then
        stock = fallback
    end
    return stock
end

function ANI_ToolState.apply_paint_capacity(object, make_infinite)
    if not valid(object) then return false end
    local stock = ANI_ToolState.stock_tool_capacity(object, 100)
    local target = make_infinite and 999999 or stock
    local changed = false
    if set_if_present(object, "MaxQuantity", target) then
        changed = true
    end
    if set_if_present(object, "Quantity", target) then
        changed = true
    end
    call_if_present(object, "OnRep_Quantity")
    return changed
end

function ANI_ToolState.stabilize_paint_capacity(object, make_infinite)
    ANI_ToolState.apply_paint_capacity(object, make_infinite)
    for _, delay in ipairs({150, 500, 1000}) do
        ExecuteWithDelay(delay, function()
            ExecuteInGameThread(function()
                ANI_ToolState.apply_paint_capacity(
                    object, make_infinite)
            end)
        end)
    end
end

function ANI_ToolState.paint_swatch_path()
    if not os or not os.getenv then return nil end
    local local_app_data = os.getenv("LOCALAPPDATA")
    if not local_app_data or local_app_data == "" then return nil end
    return local_app_data ..
        "\\DriveBeyondHorizons\\Saved\\AssemblyNotIncludedPaintSwatches.ini"
end

function ANI_ToolState.paint_number(value)
    if value == nil then return nil end
    local number = tonumber(value)
    if number then return number end
    local ok, unwrapped = pcall(function() return value:get() end)
    if ok then return tonumber(unwrapped) end
    return nil
end

function ANI_ToolState.paint_component(color, name)
    if color == nil then return nil end
    local ok, value = pcall(function() return color[name] end)
    if ok then
        local number = ANI_ToolState.paint_number(value)
        if number then return number end
    end
    ok, color = pcall(function() return color:get() end)
    if not ok or color == nil then return nil end
    ok, value = pcall(function() return color[name] end)
    if not ok then return nil end
    return ANI_ToolState.paint_number(value)
end

function ANI_ToolState.normalize_paint_swatch(
    red, green, blue, alpha, metallic)
    local function limited(value, fallback)
        value = tonumber(value)
        if value == nil then value = fallback end
        return math.max(0.0, math.min(1.0, value))
    end
    return {
        r = limited(red, 0.0),
        g = limited(green, 0.0),
        b = limited(blue, 0.0),
        a = limited(alpha, 1.0),
        metallic = limited(metallic, 0.0),
    }
end

function ANI_ToolState.paint_swatch_key(swatch)
    return string.format(
        "%.4f|%.4f|%.4f|%.4f|%.4f",
        swatch.r, swatch.g, swatch.b, swatch.a, swatch.metallic)
end

function ANI_ToolState.flush_paint_swatches()
    if not io or not io.open then return false end
    local path = ANI_ToolState.paint_swatch_path()
    if not path then return false end
    local file, error_message = io.open(path, "w")
    if not file then
        log("Paint swatch persistence error: " .. tostring(error_message))
        return false
    end
    for index = 1, math.min(
        #ANI_ToolState.paint_swatches,
        ANI_ToolState.paint_swatch_limit) do
        local swatch = ANI_ToolState.paint_swatches[index]
        file:write(string.format(
            "%.9f|%.9f|%.9f|%.9f|%.9f\n",
            swatch.r,
            swatch.g,
            swatch.b,
            swatch.a,
            swatch.metallic))
    end
    file:close()
    return true
end

function ANI_ToolState.load_paint_swatches()
    if not io or not io.open then return end
    local path = ANI_ToolState.paint_swatch_path()
    if not path then return end
    local file = io.open(path, "r")
    if not file then return end
    ANI_ToolState.paint_swatches = {}
    for line in file:lines() do
        local red, green, blue, alpha, metallic =
            line:match(
                "^([%d%.%-]+)|([%d%.%-]+)|([%d%.%-]+)|" ..
                "([%d%.%-]+)|([%d%.%-]+)$")
        if red then
            table.insert(
                ANI_ToolState.paint_swatches,
                ANI_ToolState.normalize_paint_swatch(
                    red, green, blue, alpha, metallic))
            if #ANI_ToolState.paint_swatches >=
                ANI_ToolState.paint_swatch_limit then
                break
            end
        end
    end
    file:close()
    if #ANI_ToolState.paint_swatches > 0 then
        log("Loaded " .. tostring(#ANI_ToolState.paint_swatches) ..
            " persistent paint swatch(es).")
    end
end

function ANI_ToolState.remember_paint_swatch(swatch)
    if not swatch then return false end
    local key = ANI_ToolState.paint_swatch_key(swatch)
    for index = #ANI_ToolState.paint_swatches, 1, -1 do
        if ANI_ToolState.paint_swatch_key(
            ANI_ToolState.paint_swatches[index]) == key then
            table.remove(ANI_ToolState.paint_swatches, index)
        end
    end
    table.insert(ANI_ToolState.paint_swatches, 1, swatch)
    while #ANI_ToolState.paint_swatches >
        ANI_ToolState.paint_swatch_limit do
        table.remove(ANI_ToolState.paint_swatches)
    end
    ANI_ToolState.flush_paint_swatches()
    ANI_ToolState.sync_paint_swatch_buttons()
    return true
end

function ANI_ToolState.paint_swatch_from_can(object)
    if not valid(object) then return nil end
    local use_custom = false
    pcall(function()
        local value = object.UseCustomColor
        local ok, unwrapped = pcall(function() return value:get() end)
        use_custom = (ok and unwrapped or value) == true
    end)

    local color = nil
    local color_names = use_custom and
        {"CustomColor", "Color"} or {"Color", "CustomColor"}
    for _, name in ipairs(color_names) do
        local ok, candidate = pcall(function() return object[name] end)
        if ok and candidate ~= nil and
            ANI_ToolState.paint_component(candidate, "R") ~= nil then
            color = candidate
            break
        end
    end
    if color == nil then return nil end

    local metallic = nil
    local metallic_names = use_custom and
        {"CustomMetallic", "Metallic"} or {"Metallic", "CustomMetallic"}
    for _, name in ipairs(metallic_names) do
        local ok, value = pcall(function() return object[name] end)
        if ok then
            metallic = ANI_ToolState.paint_number(value)
            if metallic ~= nil then break end
        end
    end
    return ANI_ToolState.normalize_paint_swatch(
        ANI_ToolState.paint_component(color, "R"),
        ANI_ToolState.paint_component(color, "G"),
        ANI_ToolState.paint_component(color, "B"),
        ANI_ToolState.paint_component(color, "A"),
        metallic)
end

function ANI_ToolState.capture_paint_can_swatch(object)
    local swatch = ANI_ToolState.paint_swatch_from_can(object)
    if swatch then
        ANI_ToolState.remember_paint_swatch(swatch)
    end
end

function ANI_ToolState.clear_paint_swatches()
    ANI_ToolState.paint_swatches = {}
    ANI_ToolState.flush_paint_swatches()
    ANI_ToolState.sync_paint_swatch_buttons()
    show_message("Saved paint swatches cleared.")
end

ANI_ToolState.load_paint_swatches()

local function process_new_paint_cans(existing, make_infinite)
    local changed = 0
    local ok, objects = pcall(function() return FindAllOf("PaintBomb_C") end)
    if not ok or not objects then return changed end
    for _, object in ipairs(objects) do
        if valid(object) then
            local id_ok, id = pcall(function() return object:GetFullName() end)
            if id_ok and not existing[tostring(id)] then
                ANI_ToolState.stabilize_paint_capacity(
                    object, make_infinite)
                ANI_ToolState.capture_paint_can_swatch(object)
                changed = changed + 1
            end
        end
    end
    return changed
end

local function watch_paint_studio(token, existing, remaining)
    ExecuteWithDelay(100, function()
        ExecuteInGameThread(function()
            if token ~= paint_watch_token then return end

            local spawned = process_new_paint_cans(
                existing, paint_infinite_next)
            if spawned > 0 then
                if paint_infinite_next then
                    log("Infinite paint applied to " ..
                        tostring(spawned) .. " newly spawned can(s).")
                end
                log("Custom paint can spawned; returning input to the game.")
                close_paint_studio()
                return
            end

            local in_viewport = false
            if valid(paint_widget) then
                local ok, result =
                    pcall(function() return paint_widget:IsInViewport() end)
                in_viewport = not ok or result
            end
            if not in_viewport then
                close_paint_studio()
                return
            end

            if remaining > 0 then
                watch_paint_studio(token, existing, remaining - 1)
            end
        end)
    end)
end

local function open_paint_studio()
    if ANI_ToolState.paint_studio_opening or valid(paint_widget) then
        log("Ignored duplicate paint studio open request.")
        return
    end
    ANI_ToolState.paint_studio_opening = true
    close_menu()
    log("Paint studio open scheduled.")
    ExecuteWithDelay(125, function()
        ExecuteInGameThread(function()
            if not ANI_ToolState.paint_studio_opening then return end
            local existing = loaded_paint_can_ids()
            paint_widget = create_widget(PAINT_MENU_ASSET)
            if not valid(paint_widget) then
                ANI_ToolState.paint_studio_opening = false
                show_message(
                    "The game's paint color mixer could not be opened.")
                restore_game_input()
                return
            end
            paint_widget:AddToViewport(10001)
            local pc = get_pc()
            if valid(pc) then
                pc.bShowMouseCursor = true
            end
            local library =
                StaticFindObject(
                    "/Script/UMG.Default__WidgetBlueprintLibrary")
            if valid(library) and valid(pc) then
                pcall(function()
                    library:SetInputMode_UIOnlyEx(
                        pc, paint_widget, 0, false)
                end)
            end
            ANI_ToolState.paint_studio_opening = false
            paint_watch_token = paint_watch_token + 1
            watch_paint_studio(
                paint_watch_token, existing, 36000)
            log(
                "Native paint color and finish mixer opened successfully.")
        end)
    end)
end

local function get_spawn_transform(distance)
    local pawn = get_pawn()
    if not valid(pawn) then return nil, nil, nil end
    local location = pawn:K2_GetActorLocation()
    local rotation = pawn:K2_GetActorRotation()
    local yaw = rotation.Yaw or 0
    local radians = yaw * math.pi / 180.0
    local spawn = {
        X = location.X + math.cos(radians) * (distance or 650),
        Y = location.Y + math.sin(radians) * (distance or 650),
        Z = location.Z + 100,
    }
    return pawn:GetWorld(), spawn, {Pitch = 0, Yaw = yaw, Roll = 0}
end

local function spawn_saved_paint_swatch(index)
    local swatch = ANI_ToolState.paint_swatches[index]
    if not swatch then
        log("Ignored empty paint swatch " .. tostring(index) .. ".")
        return
    end

    close_menu()
    local class = asset_class_cache[PAINT_CAN_ASSET]
    if not valid(class) then
        local existing = FindFirstOf("PaintBomb_C")
        if valid(existing) then
            local class_ok, loaded_class =
                pcall(function() return existing:GetClass() end)
            if class_ok and valid(loaded_class) then
                class = loaded_class
                asset_class_cache[PAINT_CAN_ASSET] = class
            end
        end
    end
    if not valid(class) then
        class = class_from_asset(PAINT_CAN_ASSET)
    end
    local world, position, rotation = get_spawn_transform(180)
    if not valid(class) then
        show_message("The saved paint can class is unavailable.")
        return
    end
    if not valid(world) then
        show_message("The gameplay world is unavailable.")
        return
    end

    local ok, can = pcall(function()
        return world:SpawnActor(class, position, rotation)
    end)
    if not ok or not valid(can) then
        show_message("The saved paint can could not be spawned.")
        return
    end

    local color = {
        R = swatch.r,
        G = swatch.g,
        B = swatch.b,
        A = swatch.a,
    }
    local metallic = swatch.metallic >= 0.5 and 1.0 or 0.0
    local color_written =
        set_if_present(can, "Color", color)
    color_written =
        set_if_present(can, "CustomColor", color) or color_written
    set_if_present(can, "UseCustomColor", true)
    set_if_present(can, "Metallic", metallic)
    set_if_present(can, "CustomMetallic", metallic)
    call_if_present(can, "OnRep_Color")
    call_if_present(can, "OnRep_Metallic")
    ANI_ToolState.stabilize_paint_capacity(can, paint_infinite_next)

    if color_written then
        show_message(string.format(
            "Spawned saved paint %d (%s).",
            index,
            metallic >= 0.5 and "metallic" or "standard"))
    else
        show_message("The paint can spawned, but its color property was unavailable.")
    end
end

local function spawn_complete_vehicle(key)
    local path = VEHICLES[key]
    if not path then
        show_message("Unknown vehicle: " .. tostring(key))
        return
    end
    local class = class_from_asset(path)
    local world, position, rotation = get_spawn_transform(800)
    if not valid(class) or not valid(world) then
        show_message("Vehicle class or gameplay world is unavailable.")
        return
    end

    local cdo = class:GetCDO()
    local old_complete = nil
    if valid(cdo) and has_property(cdo, "SpawnWithOriginalPart") then
        old_complete = cdo.SpawnWithOriginalPart
        cdo.SpawnWithOriginalPart = true
    end

    local ok, vehicle = pcall(function()
        return world:SpawnActor(class, position, rotation)
    end)

    if valid(cdo) and old_complete ~= nil then
        cdo.SpawnWithOriginalPart = old_complete
    end

    if ok and valid(vehicle) then
        show_message("Spawned complete vehicle: " .. key)
        if finalize_spawned_vehicle then
            ExecuteWithDelay(500, function()
                ExecuteInGameThread(function()
                    finalize_spawned_vehicle(vehicle)
                end)
            end)
            ExecuteWithDelay(1500, function()
                ExecuteInGameThread(function()
                    finalize_spawned_vehicle(vehicle)
                end)
            end)
        end
    else
        show_message("Could not spawn vehicle: " .. key)
    end
end

local function spawn_item(path, label)
    local class = class_from_asset(path)
    local world, position, rotation = get_spawn_transform(180)
    if not valid(class) or not valid(world) then
        show_message("Could not load " .. label)
        return nil
    end
    local pc = get_pc()
    if valid(pc) then
        local transform = {
            Translation = position,
            Rotation = {X = 0, Y = 0, Z = 0, W = 1},
            Scale3D = {X = 1, Y = 1, Z = 1},
        }
        local server_ok = pcall(function() pc:ServerSpawnItem(class, transform) end)
        if server_ok then
            show_message("Spawned " .. label)
            return true
        end
    end
    local ok, actor = pcall(function() return world:SpawnActor(class, position, rotation) end)
    if ok and valid(actor) then
        show_message("Spawned " .. label)
        return actor
    end
    show_message("Could not spawn " .. label)
    return nil
end

local function modify_loaded(class_names, callback)
    local count = 0
    for _, class_name in ipairs(class_names) do
        local ok, objects = pcall(function() return FindAllOf(class_name) end)
        if ok and objects then
            for _, object in ipairs(objects) do
                if valid(object) then
                    local changed = callback(object)
                    if changed then count = count + 1 end
                end
            end
        end
    end
    return count
end

local function set_unlimited_tools(mode)
    local names
    if mode == "paint" then
        names = {"PaintBomb_C"}
    else
        names = {"AkWeapon_C"}
    end
    local count = modify_loaded(names, function(object)
        local changed = false
        if set_if_present(object, "Quantity", 999999) then changed = true end
        set_if_present(object, "MaxQuantity", 999999)
        set_if_present(object, "NbBullet", 999999)
        set_if_present(object, "NbBulletMax", 999999)
        call_if_present(object, "OnRep_Quantity")
        call_if_present(object, "OnRep_NbBullet")
        return changed
    end)
    show_message("Updated " .. tostring(count) .. " loaded " .. mode .. " object(s).")
end

function ANI_ToolState.distance_to_player(object)
    local pawn = get_pawn()
    if not valid(object) or not valid(pawn) then return nil end
    local ok, distance =
        pcall(function() return object:GetDistanceTo(pawn) end)
    if ok then
        distance = tonumber(distance)
        if distance then return distance end
    end
    return nil
end

function ANI_ToolState.service_brush_durability()
    local repaired = 0
    for _, class_name in ipairs({"RustBrush_C", "PolishBrush_C"}) do
        local ok, objects =
            pcall(function() return FindAllOf(class_name) end)
        if ok and objects then
            for _, object in ipairs(objects) do
                if valid(object) then
                    local stock =
                        ANI_ToolState.stock_tool_capacity(object, 100)
                    local maximum =
                        ANI_ToolState.positive_number_property(
                            object, "MaxQuantity")
                    local quantity =
                        ANI_ToolState.positive_number_property(
                            object, "Quantity") or 0
                    local changed = false
                    local make_infinite = false
                    if ANI_ToolState.infinite_brushes_enabled then
                        local distance =
                            ANI_ToolState.distance_to_player(object)
                        make_infinite =
                            distance ~= nil and distance <= 175.0
                    end

                    -- Only the brush currently carried by the player becomes
                    -- effectively unlimited. The large quantity persists on
                    -- that object, so no recurring global object scan is
                    -- required while the player is moving.
                    if make_infinite then
                        if set_if_present(
                            object, "MaxQuantity", 999999) then
                            changed = true
                        end
                        if set_if_present(
                            object, "Quantity", 999999) then
                            changed = true
                        end
                    elseif maximum and maximum > stock then
                        if set_if_present(object, "MaxQuantity", stock) then
                            changed = true
                        end
                        if quantity > stock and
                            set_if_present(object, "Quantity", stock) then
                            changed = true
                        end
                    elseif quantity > stock then
                        if set_if_present(object, "Quantity", stock) then
                            changed = true
                        end
                    end

                    if changed then
                        call_if_present(object, "OnRep_Quantity")
                        repaired = repaired + 1
                    end
                end
            end
        end
    end
    return repaired
end

function ANI_ToolState.toggle_infinite_brushes()
    ANI_ToolState.infinite_brushes_enabled =
        not ANI_ToolState.infinite_brushes_enabled
    ANI_ToolState.service_brush_durability()
    if ANI_ToolState.infinite_brushes_enabled then
        show_message(
            "Infinite brushes enabled for the brush you are carrying.")
    else
        show_message(
            "Infinite brushes disabled; normal durability restored.")
    end
end

local function get_current_vehicle()
    local pc = get_pc()
    if valid(pc) and valid(pc.Vehicle) then return pc.Vehicle end
    local pawn = get_pawn()
    local ok, vehicles = pcall(function() return FindAllOf("AVS_Template_Vehicle_C") end)
    if not ok or not vehicles then return nil end
    for _, vehicle in ipairs(vehicles) do
        if valid(vehicle) then
            local driver_ok, driver = pcall(function() return vehicle.Driver end)
            if driver_ok and driver == pawn then return vehicle end
        end
    end
    return nil
end

local function speedometer_player_id()
    local pc = get_pc()
    if not valid(pc) then return nil end
    local ok, name = pcall(function() return pc:GetFullName() end)
    return ok and tostring(name) or nil
end

local function hide_speedometer()
    if speedometer_visible and valid(speedometer_widget) then
        pcall(function() speedometer_widget:SetVisibility(1) end)
    end
    speedometer_visible = false
end

local function get_speedometer_vehicle()
    local pc = get_pc()
    if not valid(pc) then return nil end
    local ok, vehicle = pcall(function() return pc.Vehicle end)
    if ok and valid(vehicle) then return vehicle end
    return nil
end

local function ensure_speedometer_widget()
    local owner = speedometer_player_id()
    if not owner then return nil end

    if speedometer_owner ~= owner then
        if valid(speedometer_widget) then
            pcall(function() speedometer_widget:RemoveFromParent() end)
        end
        speedometer_widget = nil
        speedometer_owner = owner
        speedometer_last_text = nil
        speedometer_visible = false
    end

    if not valid(speedometer_widget) then
        speedometer_widget = create_widget(SPEEDOMETER_ASSET)
        if not valid(speedometer_widget) then return nil end
        speedometer_widget:AddToViewport(9000)
        pcall(function() speedometer_widget:SetVisibility(3) end)
        speedometer_last_text = nil
        log("Automatic vehicle speedometer loaded.")
    end
    return speedometer_widget
end

local function widget_is_in_viewport(widget)
    if not valid(widget) then return false end
    local ok, result = pcall(function() return widget:IsInViewport() end)
    return ok and result == true
end

local function update_speedometer_once(vehicle)
    if menu_open or widget_is_in_viewport(item_widget) or
        widget_is_in_viewport(paint_widget) then
        hide_speedometer()
        return
    end

    if not valid(vehicle) then
        hide_speedometer()
        return
    end

    local widget = ensure_speedometer_widget()
    if not valid(widget) then return end

    local velocity_ok, velocity =
        pcall(function() return vehicle:GetVelocity() end)
    if not velocity_ok or not velocity then
        hide_speedometer()
        return
    end

    local x = tonumber(velocity.X) or 0.0
    local y = tonumber(velocity.Y) or 0.0
    local z = tonumber(velocity.Z) or 0.0
    local centimeters_per_second = math.sqrt(x * x + y * y + z * z)
    local kilometers_per_hour =
        math.max(0, math.floor(centimeters_per_second * 0.036 + 0.5))
    local display = string.format("%03d  KM/H", kilometers_per_hour)

    if display ~= speedometer_last_text then
        local value = find_named_widget(widget, "SpeedValue")
        if valid(value) then
            value:SetText(FText(display))
            speedometer_last_text = display
        end
    end
    pcall(function() widget:SetVisibility(3) end)
    speedometer_visible = true
end

local function unwrap_hook_value(value)
    if value == nil then return nil end
    local ok, unwrapped = pcall(function() return value:get() end)
    return ok and unwrapped or value
end

local function unreal_object_id(object)
    object = unwrap_hook_value(object)
    if not object then return nil end
    local ok, name = pcall(function() return object:GetFullName() end)
    return ok and tostring(name) or nil
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function grip_multiplier_from_position(position)
    return 2.0 ^ (2.0 * clamp(position, 0.0, 1.0) - 1.0)
end

local function numeric_property(object, name)
    local ok, value = pcall(function() return object[name] end)
    if not ok then return nil end
    return tonumber(value)
end

local function vehicle_persistent_id(vehicle)
    if not valid(vehicle) then return nil end

    local guid_ok, guid = pcall(function() return vehicle.GuidGarage end)
    if guid_ok and guid then
        local parts = {}
        local any_nonzero = false
        for _, name in ipairs({"A", "B", "C", "D"}) do
            local part_ok, part = pcall(function() return guid[name] end)
            local number = part_ok and tonumber(unwrap_hook_value(part)) or nil
            if number == nil then
                parts = {}
                break
            end
            number = math.floor(number)
            any_nonzero = any_nonzero or number ~= 0
            table.insert(parts, tostring(number))
        end
        if #parts == 4 and any_nonzero then
            return "garage-guid:" .. table.concat(parts, ":")
        end
    end

    local seed = numeric_property(vehicle, "Seed")
    if seed ~= nil and seed ~= 0 then
        local class_name = "vehicle"
        pcall(function() class_name = tostring(vehicle:GetClass():GetFullName()) end)
        return "seed:" .. class_name .. ":" .. tostring(math.floor(seed))
    end
    return nil
end

local function load_vehicle_tunes()
    if not io or not io.open or not os or not os.getenv then return end
    local local_app_data = os.getenv("LOCALAPPDATA")
    if not local_app_data or local_app_data == "" then return end
    local path = local_app_data ..
        "\\DriveBeyondHorizons\\Saved\\AssemblyNotIncludedVehicleTunes.ini"
    local file = io.open(path, "r")
    if not file then return end

    local loaded = 0
    for line in file:lines() do
        local identity, power, grip =
            line:match("^([^|]+)|([%d%.%-]+)|([%d%.%-]+)$")
        if identity then
            grip = tonumber(grip)
        else
            identity, grip =
                line:match("^([^|]+)|([%d%.%-]+)$")
            grip = tonumber(grip)
        end
        if identity and grip then
            vehicle_tuning_saved[identity] = {
                grip_position = clamp(grip, 0.0, 1.0),
            }
            loaded = loaded + 1
        end
    end
    file:close()
    if loaded > 0 then
        log("Loaded persistent tunes for " .. tostring(loaded) .. " vehicle(s).")
    end
end

flush_vehicle_tunes = function()
    if not vehicle_tuning_dirty then return true end
    if not io or not io.open or not os or not os.getenv then return false end
    local local_app_data = os.getenv("LOCALAPPDATA")
    if not local_app_data or local_app_data == "" then return false end
    local path = local_app_data ..
        "\\DriveBeyondHorizons\\Saved\\AssemblyNotIncludedVehicleTunes.ini"
    local file, error_message = io.open(path, "w")
    if not file then
        log("Vehicle tune persistence error: " .. tostring(error_message))
        return false
    end

    local identities = {}
    for identity, _ in pairs(vehicle_tuning_saved) do
        table.insert(identities, identity)
    end
    table.sort(identities)
    for _, identity in ipairs(identities) do
        local tune = vehicle_tuning_saved[identity]
        file:write(string.format(
            "%s|%.6f\n",
            identity,
            tune.grip_position))
    end
    file:close()
    vehicle_tuning_dirty = false
    vehicle_tuning_save_elapsed = 0.0
    return true
end

local function tuning_baseline_for(vehicle)
    local identity = unreal_object_id(vehicle)
    if not identity then return nil end

    local baseline = vehicle_tuning_baselines[identity]
    if baseline then return baseline end

    baseline = {
        identity = identity,
        persistent_identity = vehicle_persistent_id(vehicle),
        grip_position = 0.5,
        friction = {
            BaseTireFriction = numeric_property(vehicle, "BaseTireFriction"),
            BaseYFriction = numeric_property(vehicle, "BaseYFriction"),
            BaseYFrictionDrift = numeric_property(vehicle, "BaseYFrictionDrift"),
            TorqueTireFriction = numeric_property(vehicle, "TorqueTireFriction"),
        },
    }
    local saved = baseline.persistent_identity and
        vehicle_tuning_saved[baseline.persistent_identity] or nil
    if saved then
        baseline.grip_position = saved.grip_position
    end
    vehicle_tuning_baselines[identity] = baseline
    return baseline
end

local function update_tuning_label(grip_multiplier)
    if not valid(menu_widget) then return end
    local grip_value = find_named_widget(menu_widget, "TireGripValue")
    if valid(grip_value) then
        pcall(function()
            grip_value:SetText(FText(string.format("%.2fx", grip_multiplier)))
        end)
    end
end

local function apply_vehicle_tune(vehicle, baseline, force)
    if not valid(vehicle) or not baseline then return false end

    local grip_multiplier =
        grip_multiplier_from_position(baseline.grip_position)
    local grip_changed = force == true

    for property, stock in pairs(baseline.friction) do
        if stock ~= nil then
            local target = stock * grip_multiplier
            local current = numeric_property(vehicle, property)
            if force == true or current == nil or
                math.abs(current - target) > 0.0001 then
                vehicle[property] = target
                grip_changed = true
            end
        end
    end

    if grip_changed then
        pcall(function() vehicle:SetWheelFrictionBasedOnTire() end)
    end

    update_tuning_label(grip_multiplier)
    return grip_changed
end

sync_vehicle_tuning_controls = function()
    if not valid(menu_widget) then return end

    local grip_position = 0.5
    local vehicle = get_current_vehicle()
    if valid(vehicle) then
        local baseline = tuning_baseline_for(vehicle)
        if baseline then
            grip_position = baseline.grip_position
        end
    end

    local grip_slider = find_named_widget(menu_widget, "Slider_TireGrip")
    if valid(grip_slider) then
        pcall(function() grip_slider:SetValue(grip_position) end)
    end
    update_tuning_label(grip_multiplier_from_position(grip_position))
end

local function update_vehicle_tuning_from_ui(vehicle)
    if not menu_open or not valid(menu_widget) or not valid(vehicle) then return end

    local grip_slider = find_named_widget(menu_widget, "Slider_TireGrip")
    if not valid(grip_slider) then return end

    local baseline = tuning_baseline_for(vehicle)
    if not baseline then return end

    local grip_ok, grip_position =
        pcall(function() return grip_slider:GetValue() end)
    if not grip_ok then return end

    local new_grip =
        clamp(tonumber(grip_position) or baseline.grip_position, 0.0, 1.0)
    local position_changed =
        math.abs(new_grip - baseline.grip_position) > 0.0001
    baseline.grip_position = new_grip
    if position_changed and baseline.persistent_identity then
        vehicle_tuning_saved[baseline.persistent_identity] = {
            grip_position = new_grip,
        }
        vehicle_tuning_dirty = true
        vehicle_tuning_save_elapsed = 0.0
    end
    apply_vehicle_tune(vehicle, baseline, false)
end

local function reset_active_vehicle_tune()
    local vehicle = get_current_vehicle()
    if not valid(vehicle) then
        show_message("Enter the driver's seat before resetting the tune.")
        return
    end

    local baseline = tuning_baseline_for(vehicle)
    if not baseline then
        show_message("The active vehicle tune could not be read.")
        return
    end

    baseline.grip_position = 0.5
    if baseline.persistent_identity then
        vehicle_tuning_saved[baseline.persistent_identity] = nil
        vehicle_tuning_dirty = true
    end
    sync_vehicle_tuning_controls()
    apply_vehicle_tune(vehicle, baseline, true)
    flush_vehicle_tunes()
    show_message("Active vehicle tire grip restored to stock.")
end

local function on_vehicle_tick(context, delta_seconds)
    context = unwrap_hook_value(context)
    if valid(context) then
        if not valid(vehicle_tick_source) then
            vehicle_tick_source = context
            vehicle_hook_elapsed = 0.0
        elseif unreal_object_id(context) ~=
            unreal_object_id(vehicle_tick_source) then
            return
        end
    end

    local frame_delta =
        tonumber(unwrap_hook_value(delta_seconds)) or 0.016
    vehicle_hook_elapsed =
        vehicle_hook_elapsed + math.max(0.0, frame_delta)
    if vehicle_hook_elapsed < 0.05 then return end
    local delta = vehicle_hook_elapsed
    vehicle_hook_elapsed = 0.0

    local vehicle = get_speedometer_vehicle()
    if not valid(vehicle) then
        hide_speedometer()
        return
    end

    if vehicle_tuning_dirty then
        vehicle_tuning_save_elapsed =
            vehicle_tuning_save_elapsed + math.max(0.0, delta)
        if vehicle_tuning_save_elapsed >= 0.5 then
            pcall(flush_vehicle_tunes)
        end
    end

    vehicle_tuning_elapsed =
        vehicle_tuning_elapsed + math.max(0.0, delta)
    if menu_open then
        hide_speedometer()
        if vehicle_tuning_elapsed >= 0.05 then
            vehicle_tuning_elapsed = 0.0
            local tune_ok, tune_err =
                pcall(update_vehicle_tuning_from_ui, vehicle)
            if not tune_ok then
                local message = tostring(tune_err)
                if message ~= vehicle_tuning_last_error then
                    vehicle_tuning_last_error = message
                    log("Vehicle tuning update error: " .. message)
                end
            else
                vehicle_tuning_last_error = nil
            end
        end
        return
    end

    if vehicle_tuning_elapsed >= 0.1 then
        vehicle_tuning_elapsed = 0.0
        local tune_ok, tune_err = pcall(function()
            local baseline = tuning_baseline_for(vehicle)
            apply_vehicle_tune(vehicle, baseline, false)
        end)
        if not tune_ok then
            local message = tostring(tune_err)
            if message ~= vehicle_tuning_last_error then
                vehicle_tuning_last_error = message
                log("Vehicle tuning persistence error: " .. message)
            end
        else
            vehicle_tuning_last_error = nil
        end
    end

    if widget_is_in_viewport(item_widget) or
        widget_is_in_viewport(paint_widget) then
        hide_speedometer()
        return
    end

    speedometer_elapsed = speedometer_elapsed + math.max(0.0, delta)
    if speedometer_elapsed < 0.1 then return end
    speedometer_elapsed = 0.0

    local ok, err = pcall(update_speedometer_once, vehicle)
    if not ok then
        local message = tostring(err)
        if message ~= speedometer_last_error then
            speedometer_last_error = message
            log("Speedometer update error: " .. message)
        end
    else
        speedometer_last_error = nil
    end
end

load_vehicle_tunes()

local function install_speedometer_tick_hook()
    if speedometer_tick_hooked then return end
    LoadAsset("/Game/AVS_Template/Template/AVS_Template_Vehicle")
    local tick_event =
        "/Game/AVS_Template/Template/AVS_Template_Vehicle." ..
        "AVS_Template_Vehicle_C:ReceiveTick"
    local ok, hook_id = pcall(function()
        return RegisterHook(tick_event, on_vehicle_tick)
    end)
    if ok and hook_id then
        speedometer_tick_hooked = true
        log("Vehicle-driven speedometer hook installed.")
    else
        log("Vehicle-driven speedometer hook was unavailable.")
    end
end

local function toggle_vehicle_invulnerability()
    local vehicle = get_current_vehicle()
    if not valid(vehicle) then show_message("Enter the driver's seat first.") return end
    local identity = unreal_object_id(vehicle)
    local current = identity and vehicle_invulnerability[identity] == true
    if not current then
        local property_ok, property_value =
            pcall(function() return vehicle.Industrictible end)
        current = property_ok and property_value == true
    end
    local enabled = not current
    local called = call_if_present(
        vehicle, "DebugIndestructibleCar", enabled)
    local written = set_if_present(
        vehicle, "Industrictible", enabled)
    if identity then
        vehicle_invulnerability[identity] = enabled or nil
    end
    if called or written then
        show_message(
            "Vehicle invulnerability " ..
            (enabled and "enabled." or "disabled."))
    else
        show_message(
            "This vehicle does not expose an invulnerability control.")
    end
end

local function add_unique_object(list, seen, candidate)
    candidate = unwrap_hook_value(candidate)
    if not valid(candidate) then return false end
    local identity = unreal_object_id(candidate)
    if not identity or seen[identity] then return false end
    seen[identity] = true
    table.insert(list, candidate)
    return true
end

local function collect_unreal_container(container, list, seen)
    if not container then return end
    pcall(function()
        container:ForEach(function(key, value)
            add_unique_object(list, seen, key)
            add_unique_object(list, seen, value)
        end)
    end)
end

local function vehicle_parts(vehicle)
    local parts = {}
    local seen = {}

    for _, property in ipairs({
        "ItemAttached",
        "AttachedActors",
        "SaveActorAttached",
        "CarEquipableComponents",
        "MapEquipable",
        "MapComponentEquipable",
    }) do
        local ok, container = pcall(function() return vehicle[property] end)
        if ok then collect_unreal_container(container, parts, seen) end
    end

    local direct_surface_terms = {
        "body",
        "frame",
        "chassis",
        "base",
        "seat",
        "steer",
        "wheel",
        "interior",
        "dash",
        "door",
        "window",
        "glass",
        "mirror",
        "panel",
        "trim",
        "carpet",
        "floor",
        "console",
        "roof",
        "hood",
        "bonnet",
        "trunk",
        "boot",
        "bumper",
        "fender",
        "grill",
        "grille",
        "pillar",
        "liner",
        "gauge",
        "cluster",
    }
    local class_ok, class = pcall(function() return vehicle:GetClass() end)
    local depth = 0
    while class_ok and valid(class) and depth < 5 do
        pcall(function()
            class:ForEachProperty(function(property)
                local full_name = tostring(property:GetFullName())
                local field_name = full_name:match(":([^:]+)$")
                if not field_name then return end
                local lower_name = string.lower(field_name)
                local relevant = false
                for _, term in ipairs(direct_surface_terms) do
                    if string.find(lower_name, term, 1, true) then
                        relevant = true
                        break
                    end
                end
                if not relevant then return end
                local ok, value = pcall(function()
                    return vehicle[field_name]
                end)
                if ok then
                    add_unique_object(parts, seen, value)
                    collect_unreal_container(value, parts, seen)
                end
            end)
        end)
        class_ok, class = pcall(function() return class:GetSuperStruct() end)
        depth = depth + 1
    end

    for _, function_name in ipairs({
        "GetCarEquipableComponent",
        "GetMapComponentEquipable",
        "GetRadiator",
        "GetMotor",
    }) do
        local output = {}
        local ok = call_if_present(vehicle, function_name, output)
        if ok then
            for _, value in pairs(output) do
                add_unique_object(parts, seen, value)
                collect_unreal_container(value, parts, seen)
            end
        end
    end

    local cursor = 1
    while cursor <= #parts and cursor <= 512 do
        local part = parts[cursor]
        cursor = cursor + 1
        local attached_ok, attached =
            pcall(function() return part.AttachedCarEquipableActor end)
        if attached_ok then
            add_unique_object(parts, seen, attached)
        end
        for _, property in ipairs({
            "AttachedActors",
            "SaveActorAttached",
            "CarEquipableComponents",
            "MapEquipable",
            "MapComponentEquipable",
            "Meshs",
        }) do
            local child_ok, child_container =
                pcall(function() return part[property] end)
            if child_ok then
                collect_unreal_container(child_container, parts, seen)
            end
        end
    end

    return parts
end

local function vehicle_batteries(vehicle)
    local batteries = {}
    local seen = {}

    local output = {}
    pcall(function() vehicle:GetBattery(output) end)
    for _, value in pairs(output) do
        add_unique_object(batteries, seen, value)
    end

    local car_battery_ok, car_battery =
        pcall(function() return vehicle.CarBattery end)
    if car_battery_ok then
        add_unique_object(batteries, seen, car_battery)
    end

    for _, item in ipairs(vehicle_parts(vehicle)) do
        local identity = string.lower(unreal_object_id(item) or "")
        if string.find(identity, "battery", 1, true) then
            add_unique_object(batteries, seen, item)
        end
    end
    return batteries
end

local function linked_to_vehicle(object, vehicle)
    local queue = {object}
    local visited = {}
    local cursor = 1
    local vehicle_identity = unreal_object_id(vehicle)
    while cursor <= #queue and cursor <= 24 do
        local candidate = unwrap_hook_value(queue[cursor])
        cursor = cursor + 1
        if valid(candidate) then
            local identity = unreal_object_id(candidate)
            if identity and not visited[identity] then
                visited[identity] = true
                if identity == vehicle_identity then return true end
                for _, property in ipairs({
                    "ParentCarEquipableV2",
                    "LastVehicle",
                    "VehicleAttached",
                    "LastParentCarEquipable",
                }) do
                    local ok, value =
                        pcall(function() return candidate[property] end)
                    if ok and valid(unwrap_hook_value(value)) then
                        table.insert(queue, value)
                    end
                end
                for _, function_name in ipairs({
                    "GetOwner",
                    "GetAttachParentActor",
                    "GetOuter",
                }) do
                    local ok, value =
                        pcall(function() return candidate[function_name]() end)
                    if ok and valid(unwrap_hook_value(value)) then
                        table.insert(queue, value)
                    end
                end
            end
        end
    end
    return false
end

local function object_near_vehicle(object, vehicle, maximum_distance)
    if not valid(object) or not valid(vehicle) then return false end
    local target = object
    local owner_ok, owner = pcall(function() return object:GetOwner() end)
    if owner_ok and valid(owner) then target = owner end
    local object_ok, object_location =
        pcall(function() return target:GetActorLocation() end)
    local vehicle_ok, vehicle_location =
        pcall(function() return vehicle:GetActorLocation() end)
    if not object_ok or not vehicle_ok or
        not object_location or not vehicle_location then
        return false
    end
    local dx = (tonumber(object_location.X) or 0.0) -
        (tonumber(vehicle_location.X) or 0.0)
    local dy = (tonumber(object_location.Y) or 0.0) -
        (tonumber(vehicle_location.Y) or 0.0)
    local dz = (tonumber(object_location.Z) or 0.0) -
        (tonumber(vehicle_location.Z) or 0.0)
    local limit = tonumber(maximum_distance) or 1000.0
    return dx * dx + dy * dy + dz * dz <= limit * limit
end

local function vehicle_tanks(vehicle)
    local tanks = {}
    local seen = {}

    local components_ok, components =
        pcall(function() return FindAllOf("ItemTankComponent_C") end)
    if components_ok and components then
        for _, component in ipairs(components) do
            component = unwrap_hook_value(component)
            local owner_ok, owner =
                pcall(function() return component:GetOwner() end)
            owner = owner_ok and unwrap_hook_value(owner) or nil
            if valid(component) and
                (linked_to_vehicle(component, vehicle) or
                object_near_vehicle(owner, vehicle, 800.0)) then
                local identity = unreal_object_id(component)
                if identity and not seen[identity] then
                    seen[identity] = true
                    table.insert(tanks, {
                        actor = valid(owner) and owner or component,
                        component = component,
                    })
                end
            end
        end
    end

    for _, item in ipairs(vehicle_parts(vehicle)) do
        local component_ok, component =
            pcall(function() return item.ItemTankComponent end)
        if component_ok and valid(component) then
            local identity = unreal_object_id(component)
            if identity and not seen[identity] then
                seen[identity] = true
                table.insert(tanks, {
                    actor = item,
                    component = component,
                })
            end
        end
    end
    return tanks
end

local function vehicle_surface_actors(vehicle)
    local actors = {}
    local seen = {}
    add_unique_object(actors, seen, vehicle)

    -- Read only containers that belong to this exact vehicle instance. Different
    -- vehicle classes place installed panels/interior actors in different ones.
    -- Do not restore the old class-reflection recursion or any world/proximity
    -- scan: those were the paths capable of crossing into unrelated vehicles.
    local source_counts = {}
    for _, property in ipairs({
        "ItemAttached",
        "AttachedActors",
        "SaveActorAttached",
        "CarEquipableComponents",
        "MapEquipable",
        "MapComponentEquipable",
    }) do
        local before = #actors
        local ok, container = pcall(function() return vehicle[property] end)
        if ok then
            collect_unreal_container(container, actors, seen)
        end
        source_counts[property] = #actors - before
    end

    -- Restore the complete per-vehicle set used by the working Rust/Remove Rust
    -- implementation. Follow only the explicit visible-actor pointer and keep
    -- the old reflection recursion/world scans disabled.
    local direct_count = #actors
    for index = 2, direct_count do
        local part = actors[index]
        local attached_ok, attached =
            pcall(function() return part.AttachedCarEquipableActor end)
        if attached_ok then add_unique_object(actors, seen, attached) end
    end

    log(string.format(
        "Active vehicle surface sources: ItemAttached=%d, AttachedActors=%d, " ..
        "SaveActorAttached=%d, CarEquipableComponents=%d, MapEquipable=%d, " ..
        "MapComponentEquipable=%d, resolved=%d.",
        source_counts.ItemAttached or 0,
        source_counts.AttachedActors or 0,
        source_counts.SaveActorAttached or 0,
        source_counts.CarEquipableComponents or 0,
        source_counts.MapEquipable or 0,
        source_counts.MapComponentEquipable or 0,
        #actors))

    return actors
end

finalize_spawned_vehicle = function(vehicle)
    if not valid(vehicle) then return end
    local actors = vehicle_surface_actors(vehicle)
    local index = 2
    local updated = 0

    local function process_batch()
        if not valid(vehicle) then return end
        local last = math.min(index + 7, #actors)
        while index <= last do
            local actor = actors[index]
            local offset_ok =
                call_if_present(actor, "UpdateOffsetTransform")
            local collision_ok =
                call_if_present(actor, "UpdateCollisionParent")
            if offset_ok or collision_ok then
                updated = updated + 1
            end
            index = index + 1
        end
        if index <= #actors then
            ExecuteWithDelay(10, function()
                ExecuteInGameThread(process_batch)
            end)
        else
            log("Refreshed transform/collision state on " ..
                tostring(updated) ..
                " attached actor(s) for the spawned vehicle.")
        end
    end

    process_batch()
end

local function fill_tank_component(actor, component, infinite)
    if not valid(component) then return false end
    local identity = unreal_object_id(component)
    local stock_maximum = identity and vehicle_tank_maximums[identity] or nil
    if stock_maximum == nil then
        stock_maximum = numeric_property(component, "MaxQuantity")
        if identity and stock_maximum and stock_maximum > 0 then
            vehicle_tank_maximums[identity] = stock_maximum
        end
    end
    if infinite then
        set_if_present(component, "MaxQuantity", 999999.0)
    elseif stock_maximum and stock_maximum > 0 then
        set_if_present(component, "MaxQuantity", stock_maximum)
    end

    local target = infinite and 999999.0 or stock_maximum
    if type(target) ~= "number" or target <= 0 then return false end

    local changed = false
    local map_ok, fluid_map =
        pcall(function() return component.FluidMap end)
    if map_ok and fluid_map then
        pcall(function()
            fluid_map:ForEach(function(_, value)
                value:set(target)
                changed = true
            end)
        end)
        if not changed then
            local accepted_ok, accepted =
                pcall(function() return component.FluidAccepted end)
            if accepted_ok and accepted then
                local added = false
                pcall(function()
                    accepted:ForEach(function(_, entry)
                        if not added then
                            fluid_map:Add(
                                unwrap_hook_value(entry), target)
                            added = true
                            changed = true
                        end
                        return true
                    end)
                end)
            end
        end
    end

    if changed then
        set_if_present(component, "ActualQuantity", target)
        call_if_present(component, "UpdateFluidList")
        call_if_present(component, "OnRep_FluidList")
        call_if_present(component, "OnRep_ActualQuantity")
    end
    return changed
end

local function refill_vehicle(infinite)
    local vehicle = get_current_vehicle()
    if not valid(vehicle) then show_message("Enter the driver's seat first.") return end
    local touched = 0
    local tanks = vehicle_tanks(vehicle)
    for _, tank in ipairs(tanks) do
        local ok, changed = pcall(
            fill_tank_component,
            tank.actor,
            tank.component,
            infinite)
        if ok and changed then
            touched = touched + 1
        end
    end
    if #tanks == 0 then
        show_message("No attached vehicle fluid tanks were detected.")
    else
        show_message(
            (infinite and "Unlimited " or "Filled ") ..
            tostring(touched) .. " of " ..
            tostring(#tanks) .. " vehicle tank(s).")
    end
end

local function recharge_batteries()
    local vehicle = get_current_vehicle()
    if not valid(vehicle) then show_message("Enter the driver's seat first.") return end
    local batteries = vehicle_batteries(vehicle)
    local count = 0
    for _, object in ipairs(batteries) do
        local changed = false
        local refill_ok = call_if_present(object, "Refill")
        if refill_ok then changed = true end
        local maximum = numeric_property(object, "CapacityMax")
        if maximum and maximum > 0 then
            if set_if_present(object, "Capacity", maximum) then changed = true end
            if set_if_present(object, "CapacityLeft", maximum) then changed = true end
        end
        set_if_present(object, "CapacityUsed", 0.0)
        call_if_present(object, "UpdateCapacityLeft")
        call_if_present(object, "UpdateLightsAndMaterials")
        if changed then count = count + 1 end
    end
    if #batteries == 0 then
        show_message("No battery was detected in the active vehicle.")
    else
        show_message(
            "Recharged " .. tostring(count) .. " of " ..
            tostring(#batteries) .. " active vehicle battery object(s).")
    end
end

local function material_key(name)
    local ok, key = pcall(function() return UEHelpers.FindOrAddFName(name) end)
    return ok and key or name
end

local function has_unreal_function(object, name)
    if not valid(object) then return false end
    local ok, fn = pcall(function() return object[name] end)
    if not ok or not fn then return false end
    local fn_ok, fn_valid = pcall(function() return fn:IsValid() end)
    return fn_ok and fn_valid == true
end

local function collect_surface_dyn_components(actor, dyns, seen)
    dyns = dyns or {}
    seen = seen or {}

    local function add(candidate, resolve_nested)
        candidate = unwrap_hook_value(candidate)
        if not valid(candidate) then return end

        if resolve_nested then
            local nested_ok, nested =
                pcall(function() return candidate.MaterialDynComponent end)
            if nested_ok and valid(nested) then
                candidate = unwrap_hook_value(nested)
            end
        end

        if not has_unreal_function(candidate, "UpdateDynParam") then
            return
        end

        local identity = unreal_object_id(candidate)
        if not identity or seen[identity] then return end
        seen[identity] = true
        table.insert(dyns, candidate)
    end

    -- Each installed part is already present in vehicle_surface_actors. Only
    -- accept that part's explicit material controller; scanning arbitrary
    -- component/maps can yield non-UObject wrappers that pass IsValid but crash
    -- UE4SS when invoked.
    add(actor, true)
    for _, property in ipairs({
        "MaterialDynComponent",
        "DynComponent",
    }) do
        local ok, value = pcall(function() return actor[property] end)
        if ok then add(value, false) end
    end

    return dyns
end

local function object_text(value)
    if value == nil then return "" end
    local ok, text = pcall(function() return value:ToString() end)
    if ok and type(text) == "string" then return text end
    return tostring(value)
end

local function normalized_material_key(value)
    return string.lower(object_text(value)):gsub("%s+", ""):gsub("_", "")
end

local dyn_param_log_budget = 8

local function make_dyn_scalar_param(key, scalar)
    return {
        Key_2_9A8C438B4224A6B1657E3997CF43EB5B = material_key(key),
        VectorParameter_12_33A11DA14457E338EF9919B9B47CA282 = {
            R = 0.0,
            G = 0.0,
            B = 0.0,
            A = 1.0,
        },
        ScalarParameter_8_52C9880A475C4002B11BC8A2E153EE81 = scalar,
        IsScalarParameter_11_EA81612E4CFE7ABB1E2351A611997EA1 = true,
    }
end

local function set_dyn_param_scalar(dyn, key, scalar, add_to_value)
    if not valid(dyn) then return false end
    local parameter = make_dyn_scalar_param(key, scalar)
    local changed = false
    local update_ok, update_error = pcall(function()
        dyn:UpdateDynParam(parameter, add_to_value == true)
    end)
    if update_ok then
        changed = true
    elseif dyn_param_log_budget > 0 then
        log("Dyn surface parameter update failed for " ..
            tostring(key) .. ": " .. tostring(update_error))
        dyn_param_log_budget = dyn_param_log_budget - 1
    end

    if changed then
        -- UpdateDynParam is the owning Blueprint's committed update path. Do
        -- not invoke its internal processing/replication callbacks a second
        -- time; doing so can invalidate controller state during this batch.
    end

    if changed and dyn_param_log_budget > 0 then
        log("Dyn surface parameter " .. tostring(key) ..
            " set to " .. tostring(scalar) .. ".")
        dyn_param_log_budget = dyn_param_log_budget - 1
    end

    return changed
end

local function dyn_has_material_parameter(dyn, wanted_key)
    if not valid(dyn) then return false end
    local wanted = normalized_material_key(wanted_key)
    local found = false

    local function matches(value)
        value = unwrap_hook_value(value)
        if value == nil or type(value) == "number" then return false end
        return normalized_material_key(value) == wanted
    end

    local function entry_matches(key, entry)
        if matches(key) then return true end
        local function embedded_key_matches(value)
            value = unwrap_hook_value(value)
            if value ~= nil then
                for _, field in ipairs({
                    "Key_2_9A8C438B4224A6B1657E3997CF43EB5B",
                    "Key",
                    "ParameterName",
                }) do
                    local ok, candidate =
                        pcall(function() return value[field] end)
                    if ok and matches(candidate) then return true end
                end
            end
            return false
        end
        return embedded_key_matches(entry) or embedded_key_matches(key)
    end

    for _, property in ipairs({"MapDynParam", "ListDynParam"}) do
        local ok, container = pcall(function() return dyn[property] end)
        if ok and container ~= nil then
            pcall(function()
                container:ForEach(function(key, entry)
                    if not found and entry_matches(key, entry) then
                        found = true
                    end
                end)
            end)
        end
        if found then break end
    end

    return found
end

local function update_surface_dyn_component(dyn, mode)
    if not valid(dyn) or
        not has_unreal_function(dyn, "UpdateDynParam") then
        return false
    end
    local changed = false
    if mode == "rust" then
        if dyn_has_material_parameter(dyn, "Rust and wear") then
            local duration = numeric_property(dyn, "RustCurveDuration")
            if duration and duration > 0 then
                set_if_present(dyn, "RustTimer", duration)
            end
            if set_dyn_param_scalar(dyn, "Rust and wear", 1.0) then
                changed = true
            end
        end
    elseif mode == "remove_rust" then
        if dyn_has_material_parameter(dyn, "Rust and wear") then
            set_if_present(dyn, "RustTimer", 0.0)
            if set_dyn_param_scalar(dyn, "Rust and wear", 0.0) then
                changed = true
            end
        end
    elseif mode == "polish" then
        -- A before/after capture of the game's PolishBrush confirmed its
        -- committed state: Polish changes from 0 to 1 and BurnAmount is
        -- initialized to 0. Only components that already define Polish
        -- can safely accept these updates.
        if dyn_has_material_parameter(dyn, "Polish") then
            if set_dyn_param_scalar(dyn, "Polish", 1.0, false) then
                changed = true
            end
            if set_dyn_param_scalar(dyn, "BurnAmount", 0.0, false) then
                changed = true
            end
        end
    end
    return changed
end

local function set_vehicle_surface(mode)
    local vehicle = get_current_vehicle()
    if not valid(vehicle) then show_message("Enter the driver's seat first.") return end
    if surface_action_running then
        show_message("A vehicle surface action is already in progress.")
        return
    end

    local actors = vehicle_surface_actors(vehicle)
    local dyn_components = {}
    local dyn_seen = {}
    for _, actor in ipairs(actors) do
        collect_surface_dyn_components(
            actor,
            dyn_components,
            dyn_seen)
    end

    surface_action_running = true
    surface_action_token = surface_action_token + 1
    local token = surface_action_token
    local dyn_index = 1
    local dyn_batch_size = 2
    local parts = 0

    local label = "Vehicle surface updated"
    if mode == "polish" then
        label = "Vehicle polished"
    elseif mode == "remove_rust" then
        label = "Vehicle rust removed"
    elseif mode == "rust" then
        label = "Vehicle rust applied"
    end

    local function finish_surface_action()
        if token ~= surface_action_token then return end
        if mode == "polish" then
            call_if_present(vehicle, "PlayAnimCleanning")
        end
        surface_action_running = false
        if parts > 0 then
            show_message(label .. " on the occupied vehicle.")
        else
            show_message("No compatible vehicle surface controls were detected.")
        end
        log(label .. " using " .. tostring(#actors) ..
            " active-vehicle actor(s) and " ..
            tostring(#dyn_components) ..
            " explicit material controller(s).")
    end

    local function process_dyn_batch()
        if token ~= surface_action_token then return end
        local last =
            math.min(dyn_index + dyn_batch_size - 1, #dyn_components)
        while dyn_index <= last do
            local ok, changed = pcall(
                update_surface_dyn_component,
                dyn_components[dyn_index],
                mode)
            if ok and changed then parts = parts + 1 end
            dyn_index = dyn_index + 1
        end
        if dyn_index <= #dyn_components then
            ExecuteWithDelay(10, function()
                ExecuteInGameThread(process_dyn_batch)
            end)
        else
            finish_surface_action()
        end
    end

    show_message("Updating the occupied vehicle surface...")
    process_dyn_batch()
end

local function get_stats()
    local stats = FindFirstOf("BP_PlayerStats_C")
    if valid(stats) then return stats end
    local pawn = get_pawn()
    if valid(pawn) and valid(pawn.BP_PlayerStats) then return pawn.BP_PlayerStats end
    return nil
end

local function set_stat(kind, full)
    local stats = get_stats()
    if not valid(stats) then show_message("Player stats are unavailable.") return end
    local changed = false
    if kind == "Health" then
        local maximum = stats.MaximumLife or 100.0
        changed = set_if_present(stats, "Life", maximum)
        call_if_present(stats, "OnRep_Life")
    elseif kind == "Hunger" then
        local maximum = stats.MaximumHunger or 100.0
        changed = set_if_present(stats, "Hunger", maximum)
        set_if_present(stats, "LastHunger", maximum)
        call_if_present(stats, "OnRep_Hunger")
    elseif kind == "Thirst" then
        local maximum = stats.MaximumThirst or 100.0
        changed = set_if_present(stats, "Thirst", maximum)
        set_if_present(stats, "LastThirst", maximum)
        call_if_present(stats, "SetPlayerThirsty", false)
        call_if_present(stats, "OnRep_Thirst")
    elseif kind == "Piss" then
        local value = full and (stats.MaximumUrine or 100.0) or 0.0
        changed = set_if_present(stats, "Urine", value)
        call_if_present(stats, "OnRep_Urine")
    end
    show_message(changed and (kind .. " updated.") or (kind .. " property was not found."))
end

local function get_player_movement(pawn)
    if not valid(pawn) then return nil end
    local ok, movement = pcall(function() return pawn:GetCharacterMovement() end)
    if ok and valid(movement) then return movement end
    ok, movement = pcall(function() return pawn.CharacterMovement end)
    if ok and valid(movement) then return movement end
    ok, movement = pcall(function() return pawn.MovementComponent end)
    if ok and valid(movement) then return movement end
    return nil
end

local function capture_player_modifier_baseline(pawn)
    local identity = unreal_object_id(pawn)
    if player_modifier_baseline and
        player_modifier_baseline.identity == identity then
        return player_modifier_baseline
    end

    local movement = get_player_movement(pawn)
    local stats = get_stats()
    player_modifier_baseline = {
        identity = identity,
        max_walk_speed = numeric_property(movement, "MaxWalkSpeed"),
        max_walk_speed_crouched =
            numeric_property(movement, "MaxWalkSpeedCrouched"),
        max_acceleration = numeric_property(movement, "MaxAcceleration"),
        jump_velocity = numeric_property(movement, "JumpZVelocity"),
        gravity_scale = numeric_property(movement, "GravityScale"),
        jump_hold_time = numeric_property(pawn, "JumpMaxHoldTime"),
        debug_speed_multiplier =
            numeric_property(pawn, "DebugSpeedMultiplier"),
        speed_boost = numeric_property(stats, "SpeedBoost"),
    }
    log(string.format(
        "Player modifier baseline: walk=%s, acceleration=%s, jump=%s, " ..
        "gravity=%s, debug multiplier=%s, native boost=%s.",
        tostring(player_modifier_baseline.max_walk_speed),
        tostring(player_modifier_baseline.max_acceleration),
        tostring(player_modifier_baseline.jump_velocity),
        tostring(player_modifier_baseline.gravity_scale),
        tostring(player_modifier_baseline.debug_speed_multiplier),
        tostring(player_modifier_baseline.speed_boost)))
    return player_modifier_baseline
end

local function restore_numeric(object, name, value)
    if value == nil then return false end
    return set_if_present(object, name, value)
end

local function apply_player_modifiers()
    local pawn = get_pawn()
    if not valid(pawn) then return false end
    local movement = get_player_movement(pawn)
    if not valid(movement) then return false end
    local baseline = capture_player_modifier_baseline(pawn)
    local stats = get_stats()
    local changed = false

    if speed_enabled then
        changed = set_if_present(movement, "MaxWalkSpeed", 3000.0) or changed
        changed =
            set_if_present(movement, "MaxWalkSpeedCrouched", 1500.0) or changed
        changed = set_if_present(movement, "MaxAcceleration", 8192.0) or changed
        changed =
            set_if_present(pawn, "DebugSpeedMultiplier", 4.0) or changed
        -- The ALS player Blueprint checks this native stat before applying its
        -- own movement boost. Keep it positive because ALS rewrites movement
        -- settings while changing gait.
        if valid(stats) then
            changed = set_if_present(stats, "SpeedBoost", 3600.0) or changed
        end
    else
        changed =
            restore_numeric(movement, "MaxWalkSpeed",
                baseline.max_walk_speed) or changed
        changed =
            restore_numeric(movement, "MaxWalkSpeedCrouched",
                baseline.max_walk_speed_crouched) or changed
        changed =
            restore_numeric(movement, "MaxAcceleration",
                baseline.max_acceleration) or changed
        changed =
            restore_numeric(pawn, "DebugSpeedMultiplier",
                baseline.debug_speed_multiplier) or changed
        if valid(stats) then
            changed =
                restore_numeric(stats, "SpeedBoost",
                    baseline.speed_boost) or changed
        end
    end

    if jump_enabled then
        changed = set_if_present(movement, "JumpZVelocity", 1800.0) or changed
        changed = set_if_present(movement, "GravityScale", 0.55) or changed
        changed = set_if_present(pawn, "JumpMaxHoldTime", 0.35) or changed
    else
        changed =
            restore_numeric(movement, "JumpZVelocity",
                baseline.jump_velocity) or changed
        changed =
            restore_numeric(movement, "GravityScale",
                baseline.gravity_scale) or changed
        changed =
            restore_numeric(pawn, "JumpMaxHoldTime",
                baseline.jump_hold_time) or changed
    end

    return changed
end

local function restart_player_modifier_loop()
    player_modifier_loop_token = player_modifier_loop_token + 1
    local token = player_modifier_loop_token
    local function schedule_next()
        ExecuteWithDelay(50, function()
            ExecuteInGameThread(function()
                if token ~= player_modifier_loop_token then return end
                pcall(apply_player_modifiers)
                if speed_enabled or jump_enabled then schedule_next() end
            end)
        end)
    end
    if speed_enabled or jump_enabled then schedule_next() end
end

local function toggle_speed()
    local pawn = get_pawn()
    if not valid(pawn) then return end
    speed_enabled = not speed_enabled
    capture_player_modifier_baseline(pawn)
    local changed = apply_player_modifiers()
    restart_player_modifier_loop()
    show_message("Roadrunner speed " ..
        (speed_enabled and "enabled" or "disabled") ..
        (changed and "." or " (movement controls unavailable)."))
end

local function toggle_jump()
    local pawn = get_pawn()
    if not valid(pawn) then return end
    jump_enabled = not jump_enabled
    capture_player_modifier_baseline(pawn)
    local changed = apply_player_modifiers()
    restart_player_modifier_loop()
    show_message("Moon jump " ..
        (jump_enabled and "enabled" or "disabled") ..
        (changed and "." or " (movement controls unavailable)."))
end

local function spawn_zombie()
    spawn_item("/Game/BP/Player/Zombies/BP_Zombie", "zombie")
end

local function set_many_if_present(object, entries)
    local changed = false
    if not valid(object) then return false end
    for _, entry in ipairs(entries) do
        if set_if_present(object, entry[1], entry[2]) then
            changed = true
        end
    end
    return changed
end

local function set_time(hour)
    local sky = FindFirstOf("Ultra_Dynamic_Sky_C")
    if not valid(sky) then show_message("Dynamic sky is unavailable.") return end
    local display_hour = hour % 24.0
    local target = display_hour * 100.0

    if display_hour == 6.0 then
        local sunrise = numeric_property(sky, "Simulated Sunrise Time") or
            numeric_property(sky, "Dawn Time")
        if sunrise and sunrise > 0.0 then
            target = sunrise <= 24.0 and sunrise * 100.0 or sunrise
            target = math.min(2399.0, target + 30.0)
        else
            target = 800.0
        end
    elseif display_hour == 18.0 then
        local sunset = numeric_property(sky, "Simulated Sunset Time") or
            numeric_property(sky, "Dusk Time")
        if sunset and sunset > 0.0 then
            target = sunset <= 24.0 and sunset * 100.0 or sunset
            target = math.max(0.0, target - 30.0)
        else
            target = 1600.0
        end
    end

    local changed, transition_error = call_member_with_context(
        sky,
        "Transition Time of Day",
        target,
        0.25,
        0,
        1.0,
        true)

    if not changed then
        log("Time transition error: " .. tostring(transition_error))
        changed = set_many_if_present(sky, {
            {"Time of Day", target},
            {"Internal Time of Day", target},
            {"Replicated Time of Day", target},
            {"Last Frame Time of Day", target},
        })
    end

    show_message(changed and
        ("Time set to " .. tostring(display_hour) .. ":00") or
        "Time control was unavailable.")
end

local WEATHER_PRESET_ROOT =
    "/Game/UltraDynamicSky/Blueprints/Weather_Effects/Weather_Presets/"
local SNOW_PARTICLE_ASSET = "/Game/UltraDynamicSky/Particles/Snow"
local WEATHER_PRESETS = {
    clear = WEATHER_PRESET_ROOT .. "Clear_Skies",
    storm = WEATHER_PRESET_ROOT .. "Rain_Thunderstorm",
    rain = WEATHER_PRESET_ROOT .. "Snow",
    snow = WEATHER_PRESET_ROOT .. "Snow_Blizzard",
}

local function load_object_asset(path)
    local name = path:match("([^/]+)$")
    local object_path = path .. "." .. name
    local ok, asset = pcall(function() return LoadAsset(object_path) end)
    if ok and valid(asset) then return asset end

    asset = StaticFindObject(object_path)
    if valid(asset) then return asset end
    return nil
end

local function get_dynamic_weather()
    local gameplay_world = nil
    local pawn = get_pawn()
    if valid(pawn) then
        pcall(function() gameplay_world = pawn:GetWorld() end)
    end

    for _, class_name in ipairs({
        "Ultra_Dynamic_Weather_Nory_C",
        "Ultra_Dynamic_Weather_C",
    }) do
        local ok, objects = pcall(function() return FindAllOf(class_name) end)
        if ok and objects then
            for _, object in ipairs(objects) do
                if valid(object) then
                    local full_name = ""
                    pcall(function() full_name = tostring(object:GetFullName()) end)
                    if not string.find(full_name, "Default__", 1, true) and
                        not string.find(full_name, "REINST_", 1, true) and
                        not string.find(full_name, "SKEL_", 1, true) then
                        local object_world = nil
                        pcall(function() object_world = object:GetWorld() end)
                        if not valid(gameplay_world) or object_world == gameplay_world then
                            return object
                        end
                    end
                end
            end
        end
    end

    local weather = FindFirstOf("Ultra_Dynamic_Weather_Nory_C")
    if valid(weather) then return weather end
    weather = FindFirstOf("Ultra_Dynamic_Weather_C")
    return valid(weather) and weather or nil
end

local function set_weather_component_active(weather, property, active)
    local ok, component = pcall(function() return weather[property] end)
    if not ok or not valid(component) then return false end

    if active then
        local activated = call_member_with_context(component, "Activate", true)
        local set_active = call_member_with_context(
            component,
            "SetActive",
            true,
            true)
        return activated or set_active
    end

    local deactivated = call_member_with_context(component, "Deactivate")
    local set_inactive = call_member_with_context(
        component,
        "SetActive",
        false,
        true)
    return deactivated or set_inactive
end

local function force_snow_state(object)
    if not valid(object) then return false end
    return set_many_if_present(object, {
        {"Rain", 0.0},
        {"Snow", 1.0},
        {"Cloud Coverage", 1.0},
        {"fog", 0.25},
        {"Wind Intensity", 0.5},
        {"Thunder/Lightning", 0.0},
        {"Dust", 0.0},
        {"Material Wetness", 0.0},
        {"Material Snow Coverage", 1.0},
    })
end

local function force_snow_state_objects(weather)
    local changed = false
    for _, property in ipairs({
        "Global Weather State",
        "Local Weather State",
        "Manual Weather State",
        "Last Local Weather State",
    }) do
        local ok, state = pcall(function() return weather[property] end)
        if ok and valid(state) then
            changed = force_snow_state(state) or changed
        end
    end
    return changed
end

local function set_snow_niagara_parameters(component)
    if not valid(component) then return 0 end
    local writes = 0
    for _, name in ipairs({
        "Spawn Rate",
        "SpawnRate",
        "User.Spawn Rate",
        "User.SpawnRate",
        "Snow Spawn Rate",
        "User.Snow Spawn Rate",
    }) do
        local ok = call_member_with_context(
            component,
            "SetVariableFloat",
            UEHelpers.FindOrAddFName(name),
            5000.0)
        if ok then writes = writes + 1 end
        ok = call_member_with_context(
            component,
            "SetNiagaraVariableFloat",
            name,
            5000.0)
        if ok then writes = writes + 1 end
    end
    for _, name in ipairs({
        "Snow",
        "Snow Amount",
        "User.Snow",
        "User.Snow Amount",
        "Intensity",
        "User.Intensity",
    }) do
        local ok = call_member_with_context(
            component,
            "SetVariableFloat",
            UEHelpers.FindOrAddFName(name),
            1.0)
        if ok then writes = writes + 1 end
        ok = call_member_with_context(
            component,
            "SetNiagaraVariableFloat",
            name,
            1.0)
        if ok then writes = writes + 1 end
    end
    return writes
end

local function enforce_snow_particles()
    local weather = get_dynamic_weather()
    if not valid(weather) then return end

    call_member_with_context(weather, "Reset All Emitters")
    force_snow_state_objects(weather)
    set_many_if_present(weather, {
        {"Rain", 0.0},
        {"Old Rain", 0.0},
        {"Snow", 1.0},
        {"Old Snow", 1.0},
        {"Raining Factor", 0.0},
        {"Snowing Factor", 1.0},
        {"Enable Rain Particles", false},
        {"Enable Snow Particles", true},
        {"Max Snow Particle Spawn Rate", 5000.0},
        {"Snow GPU Particle Spawn Multiplier", 1.0},
        {"Snow Flakes Alpha", 1.0},
        {"Snow Flakes Scale", 1.0},
        {"Snow Particles Time Dilation", 1.0},
        {"Particle Collision Enabled", false},
        {"Rain System Spawning", false},
        {"Snow System Spawning", false},
        {"Lerp to Static Settings", 1.0},
        {"Old Lerp to Static Settings", 1.0},
    })

    call_member_with_context(weather, "Update Static Variables")
    force_snow_state_objects(weather)
    force_snow_state(weather)
    call_member_with_context(weather, "Update Active Variables")
    force_snow_state_objects(weather)
    force_snow_state(weather)
    set_many_if_present(weather, {
        {"Raining Factor", 0.0},
        {"Snowing Factor", 1.0},
        {"Enable Rain Particles", false},
        {"Enable Snow Particles", true},
        {"Rain System Spawning", false},
        {"Snow System Spawning", false},
    })
    call_member_with_context(weather, "Update Active Snow Parameters")
    set_weather_component_active(weather, "Rain_Particles", false)
    set_weather_component_active(weather, "Rain_X+", false)
    set_weather_component_active(weather, "Rain_X-", false)
    set_weather_component_active(weather, "Rain_Y+", false)
    set_weather_component_active(weather, "Rain_Y-", false)
    local component_ok, snow_component =
        pcall(function() return weather["Snow_Particles"] end)
    local parameter_writes = 0
    local asset_set = false
    local particle_asset_name = "unavailable"
    if component_ok and valid(snow_component) then
        local snow_asset = load_object_asset(SNOW_PARTICLE_ASSET)
        if valid(snow_asset) then
            asset_set = call_member_with_context(
                snow_component,
                "SetAsset",
                snow_asset)
        end
        parameter_writes = set_snow_niagara_parameters(snow_component)
        call_member_with_context(snow_component, "SetVisibility", true, true)
        call_member_with_context(snow_component, "SetHiddenInGame", false, true)
        call_member_with_context(snow_component, "SetComponentTickEnabled", true)
        call_member_with_context(snow_component, "SetPaused", false)
        call_member_with_context(snow_component, "ReinitializeSystem")
        local asset_ok, current_asset =
            call_member_with_context(snow_component, "GetAsset")
        if asset_ok and valid(current_asset) then
            pcall(function()
                particle_asset_name = tostring(current_asset:GetFullName())
            end)
        end
    end
    local activated =
        set_weather_component_active(weather, "Snow_Particles", true)
    set_if_present(weather, "Snow System Spawning", activated)
    call_member_with_context(weather, "Force Tick")
    local rain = numeric_property(weather, "Rain")
    local snow = numeric_property(weather, "Snow")
    local snow_factor = numeric_property(weather, "Snowing Factor")
    log("Snow particle emitter " .. (activated and "activated" or "was unavailable") ..
        "; asset_set=" .. tostring(asset_set) ..
        ", asset=" .. particle_asset_name ..
        "; Niagara writes=" .. tostring(parameter_writes) ..
        ", Rain=" .. tostring(rain) ..
        ", Snow=" .. tostring(snow) ..
        ", SnowFactor=" .. tostring(snow_factor) .. ".")
end

local function set_weather(mode)
    local weather = get_dynamic_weather()
    if not valid(weather) then show_message("Dynamic weather is unavailable.") return end
    local weather_name = ""
    pcall(function() weather_name = tostring(weather:GetFullName()) end)
    log("Using weather actor: " .. weather_name)
    local path = WEATHER_PRESETS[mode]
    if not path then return end

    local preset = load_object_asset(path)
    if not valid(preset) then
        show_message("Weather preset could not be loaded: " .. mode)
        return
    end

    local changed, transition_error = call_member_with_context(
        weather,
        "Change Weather",
        preset,
        0.25,
        true)
    if not changed then
        log("Weather transition error: " .. tostring(transition_error))
    elseif mode == "snow" then
        ExecuteWithDelay(500, function()
            ExecuteInGameThread(enforce_snow_particles)
        end)
        ExecuteWithDelay(1500, function()
            ExecuteInGameThread(enforce_snow_particles)
        end)
    end

    show_message(changed and
        ("Weather set to " .. mode) or
        "Weather transition was unavailable.")
end

local function adjust_money(amount)
    local pc = get_pc()
    if not valid(pc) then show_message("Player controller is unavailable.") return end
    local ok
    if amount >= 0 then
        ok = call_if_present(pc, "AddMoney", amount)
    else
        ok = call_if_present(pc, "RemoveMoney", math.abs(amount))
    end
    show_message(ok and ("Money adjusted by $" .. tostring(amount)) or "Money control was unavailable.")
end

local function toggle_vehicle_info()
    local vehicle = get_current_vehicle()
    if not valid(vehicle) then
        show_message("Enter the driver's seat before inspecting the vehicle.")
        return
    end
    local tanks = vehicle_tanks(vehicle)
    local batteries = vehicle_batteries(vehicle)
    local surface_actors = vehicle_surface_actors(vehicle)
    for _, tank in ipairs(tanks) do
        log(
            "Detected vehicle tank: actor=" ..
            (unreal_object_id(tank.actor) or "<unknown>") ..
            "; component=" ..
            (unreal_object_id(tank.component) or "<unknown>") ..
            "; max=" ..
            tostring(numeric_property(tank.component, "MaxQuantity")) ..
            "; actual=" ..
            tostring(numeric_property(tank.component, "ActualQuantity")))
    end
    for _, actor in ipairs(surface_actors) do
        local state_ok, state = pcall(function() return actor.StateItem end)
        log(
            "Detected vehicle surface actor: " ..
            (unreal_object_id(actor) or "<unknown>") ..
            "; state=" ..
            (state_ok and tostring(state) or "<unavailable>"))
    end
    local parts = vehicle_parts(vehicle)
    local invulnerable = false
    pcall(function() invulnerable = vehicle.Industrictible == true end)
    log("Vehicle inspection: " .. (unreal_object_id(vehicle) or "<unknown>"))
    show_message(
        "Vehicle inspection: " .. tostring(#parts) ..
        " parts, " .. tostring(#tanks) .. " tanks, " ..
        tostring(#batteries) .. " batteries, " ..
        tostring(#surface_actors) .. " surface actors; invulnerability " ..
        (invulnerable and "ON." or "OFF."))
end

local function destroy_look_target()
    local pc = get_pc()
    local pawn = get_pawn()
    if not valid(pc) or not valid(pawn) or not valid(pc.PlayerCameraManager) then
        show_message("Camera or player pawn is unavailable.")
        return
    end
    local system = UEHelpers.GetKismetSystemLibrary()
    local math_library = UEHelpers.GetKismetMathLibrary()
    if not valid(system) or not valid(math_library) then
        show_message("Line-trace libraries are unavailable.")
        return
    end

    local camera = pc.PlayerCameraManager
    local start_vector = camera:GetCameraLocation()
    local forward = math_library:GetForwardVector(camera:GetCameraRotation())
    local end_vector = math_library:Add_VectorVector(
        start_vector,
        math_library:Multiply_VectorInt(forward, 50000.0)
    )
    local hit_result = {}
    local clear = {R = 0, G = 0, B = 0, A = 0}
    local hit = system:LineTraceSingle(
        pawn,
        start_vector,
        end_vector,
        0,
        false,
        {},
        0,
        hit_result,
        true,
        clear,
        clear,
        0.0
    )
    if not hit then
        show_message("No destroyable target found.")
        return
    end

    local actor = hit_result.HitObjectHandle.Actor:Get()
    if not valid(actor) or actor == pawn or actor == get_current_vehicle() then
        show_message("That target is protected.")
        return
    end
    local name = actor:GetFullName()
    local ok = pcall(function() actor:K2_DestroyActor() end)
    show_message(ok and ("Destroyed " .. name) or "Target could not be destroyed.")
end

local function register(name, callback)
    menu_actions[name] = callback
    RegisterCustomEvent("ANI_" .. name, function()
        log("Action requested: " .. name)
        ExecuteInGameThread(function()
            local ok, err = pcall(callback)
            if not ok then show_message("Action failed: " .. tostring(err)) end
        end)
    end)
end

register("Close", close_menu)
register("OpenItemCatalog", open_item_catalog)
register("TogglePaint", function() set_expanded_section("Paint") end)
register("ToggleVehicles", function() set_expanded_section("Vehicles") end)
register("ToggleVehicleTools", function() set_expanded_section("VehicleTools") end)
register("TogglePlayer", function() set_expanded_section("Player") end)
register("ToggleWorld", function() set_expanded_section("World") end)
register("OpenPaintStudio", open_paint_studio)
register("PaintSwatch1", function()
    spawn_saved_paint_swatch(1)
end)
register("PaintSwatch2", function()
    spawn_saved_paint_swatch(2)
end)
register("PaintSwatch3", function()
    spawn_saved_paint_swatch(3)
end)
register("PaintSwatch4", function()
    spawn_saved_paint_swatch(4)
end)
register("PaintSwatch5", function()
    spawn_saved_paint_swatch(5)
end)
register("PaintSwatch6", function()
    spawn_saved_paint_swatch(6)
end)
register("PaintSwatch7", function()
    spawn_saved_paint_swatch(7)
end)
register("PaintSwatch8", function()
    spawn_saved_paint_swatch(8)
end)
register("ClearPaintSwatches", ANI_ToolState.clear_paint_swatches)
register("PaintStandard", function()
    paint_infinite_next = false
    update_paint_mode_buttons()
    show_message("The next custom paint can will use the selected amount.")
end)
register("PaintInfinite", function()
    paint_infinite_next = true
    update_paint_mode_buttons()
    show_message("The next custom paint can will have infinite paint.")
end)
register("InfiniteBrushes", ANI_ToolState.toggle_infinite_brushes)
register("InfinitePaint", function() set_unlimited_tools("paint") end)
register("InfiniteAmmo", function() set_unlimited_tools("ammo") end)
register("AddMoney", function() adjust_money(5000) end)
register("RemoveMoney", function() adjust_money(-5000) end)
register("VehicleInfo", toggle_vehicle_info)
register("VehicleInvulnerable", toggle_vehicle_invulnerability)
register("VehicleFill", function() refill_vehicle(false) end)
register("VehicleInfinite", function() refill_vehicle(true) end)
register("RechargeBatteries", recharge_batteries)
register("VehicleClean", function() set_vehicle_surface("polish") end)
register("VehicleRemoveRust", function() set_vehicle_surface("remove_rust") end)
register("VehicleRust", function() set_vehicle_surface("rust") end)
register("ResetVehicleTune", reset_active_vehicle_tune)
register("SuperSubwoofer", function()
    local count = modify_loaded({"CarItemRadioActor_C"}, function(object)
        local changed = false
        for _, name in ipairs({"Range", "MaxRange", "AttenuationRadius", "FalloffDistance"}) do
            if set_if_present(object, name, 999999.0) then changed = true end
        end
        return changed
    end)
    show_message("Extended " .. tostring(count) .. " loaded speaker(s).")
end)

for key, _ in pairs(VEHICLES) do
    local vehicle_key = key
    register("Car_" .. vehicle_key, function()
        spawn_complete_vehicle(vehicle_key)
        close_menu()
    end)
end

register("Speed", toggle_speed)
register("Jump", toggle_jump)
register("Health", function() set_stat("Health", true) end)
register("Hunger", function() set_stat("Hunger", true) end)
register("Thirst", function() set_stat("Thirst", true) end)
register("PissFull", function() set_stat("Piss", true) end)
register("PissEmpty", function() set_stat("Piss", false) end)
register("SpawnZombie", spawn_zombie)
register("TimeDawn", function() set_time(6.0) end)
register("TimeNoon", function() set_time(12.0) end)
register("TimeDusk", function() set_time(18.0) end)
register("TimeNight", function() set_time(0.0) end)
register("WeatherClear", function() set_weather("clear") end)
register("WeatherStorm", function() set_weather("storm") end)
register("WeatherSnow", function() set_weather("rain") end)
register("WeatherTrueSnow", function() set_weather("snow") end)
register("DestroyTarget", destroy_look_target)

local function activate_hovered_menu_button()
    if not menu_open or not valid(menu_widget) then return false end

    for action, callback in pairs(menu_actions) do
        local button = find_named_widget(menu_widget, "Btn_" .. action)
        if valid(button) then
            local ok, hovered = pcall(function() return button:IsHovered() end)
            if ok and hovered then
                log("Action requested by click: " .. action)
                local action_ok, action_err = pcall(callback)
                if not action_ok then
                    show_message("Action failed: " .. tostring(action_err))
                end
                return true
            end
        end
    end
    return false
end

RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, function()
    ExecuteInGameThread(activate_hovered_menu_button)
    return false
end)

RegisterKeyBind(Key.F7, function()
    ExecuteInGameThread(open_menu)
    return false
end)

RegisterConsoleCommandGlobalHandler("assemblynotincluded", function()
    ExecuteInGameThread(open_menu)
    return true
end)

ExecuteWithDelay(1500, function()
    ExecuteInGameThread(install_speedometer_tick_hook)
end)
for _, delay in ipairs({5000, 15000, 30000}) do
    ExecuteWithDelay(delay, function()
        ExecuteInGameThread(function()
            if not ANI_ToolState.infinite_brushes_enabled then
                ANI_ToolState.service_brush_durability()
            end
        end)
    end)
end
log("Assembly Not Included loaded. Press F7 to open or close.")
