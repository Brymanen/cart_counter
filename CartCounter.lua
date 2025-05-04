local sdk = sdk
local log = log
local imgui = imgui
local re = re
local json = json

local cart_data_path = "cart_counter.json"

local cart_count = 0
local session_cart_count = 0
local overlay_open = true  -- Now persistent

-- Load data from JSON file
local function load_cart_count()
    local loaded_data = json.load_file(cart_data_path)
    if loaded_data then
        if type(loaded_data.count) == "number" then
            cart_count = loaded_data.count
        end
        if type(loaded_data.overlay_open) == "boolean" then
            overlay_open = loaded_data.overlay_open
        end
        log.info("[CART MOD] Loaded data: carts=" .. tostring(cart_count) .. ", overlay=" .. tostring(overlay_open))
    else
        log.info("[CART MOD] No previous data found or failed to parse.")
    end
end

-- Save data to JSON file
local function save_cart_count()
    json.dump_file(cart_data_path, {
        count = cart_count,
        overlay_open = overlay_open
    })
    log.info("[CART MOD] Saved cart count and overlay setting.")
end

load_cart_count()

-- Hook into cHunterHealth update to track deaths
sdk.hook(
    sdk.find_type_definition("app.cHunterHealth"):get_method("update(System.Single, System.Boolean)"),
    function(args)
        local this = sdk.to_managed_object(args[2])
        if not this then return end

        local dieTrg = this:get_field("_DieTrg")
        local redHealth = this:get_field("_RedHealth")

        if dieTrg == true and redHealth == 0.0 then
            cart_count = cart_count + 1
            session_cart_count = session_cart_count + 1
            save_cart_count()
            log.info("[CART MOD] Carted! Total: " .. tostring(cart_count) .. " | Session: " .. tostring(session_cart_count))
        end
    end,
    nil
)

-- Floating overlay window
re.on_frame(function()
    if not overlay_open then return end

    imgui.set_next_window_pos(20, 100)
    imgui.begin_window("Cart Overlay", true)
    imgui.text("Carts Total: " .. tostring(cart_count))
    imgui.text("Carts Session: " .. tostring(session_cart_count))
    imgui.end_window()
end)

-- UI settings menu
re.on_draw_ui(function()
    if imgui.tree_node("Cart Counter") then
        imgui.text("Carts Total: " .. tostring(cart_count))
        if imgui.button("Reset Total") then
            cart_count = 0
            save_cart_count()
            log.info("[CART MOD] Total cart count reset.")
        end

        imgui.text("Carts Session: " .. tostring(session_cart_count))
        if imgui.button("Reset Session") then
            session_cart_count = 0
            log.info("[CART MOD] Session cart count reset.")
        end

        local changed
        changed, overlay_open = imgui.checkbox("Show Floating Overlay", overlay_open)
        if changed then
            save_cart_count()
        end

        imgui.tree_pop()
    end
end)
