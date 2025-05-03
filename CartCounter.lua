local sdk = sdk
local log = log
local imgui = imgui
local re = re
local json = json  -- REFramework provides this globally

local cart_data_path = "cart_counter.json"

local cart_count = 0
local session_cart_count = 0  -- Session-specific counter

-- Load persistent cart count from file
local function load_cart_count()
    local loaded_data = json.load_file(cart_data_path)
    if loaded_data and type(loaded_data.count) == "number" then
        cart_count = loaded_data.count
        log.info("[CART MOD] Loaded cart count: " .. tostring(cart_count))
    else
        log.info("[CART MOD] No previous data found or failed to parse.")
    end
end

-- Save persistent cart count to file
local function save_cart_count()
    json.dump_file(cart_data_path, { count = cart_count })
    log.info("[CART MOD] Saved cart count: " .. tostring(cart_count))
end

load_cart_count()

-- Hook into cHunterHealth update to track deaths
sdk.hook(
    sdk.find_type_definition("app.cHunterHealth"):get_method("update(System.Single, System.Boolean)"),
    function(args)
        local this = sdk.to_managed_object(args[2])
        if not this then return end

        local dieTrg = this:get_field("_DieTrg")
        if dieTrg == true then
            cart_count = cart_count + 1
            session_cart_count = session_cart_count + 1
            save_cart_count()
            log.info("[CART MOD] Carted! Total: " .. tostring(cart_count) .. " | Session: " .. tostring(session_cart_count))
        end
    end,
    nil
)

-- Draw UI to show and reset cart stats
re.on_draw_ui(function()
    if imgui.tree_node("Cart Counter") then
        imgui.text("Total Carts: " .. tostring(cart_count))
        imgui.same_line()
        if imgui.button("Reset Total") then
            cart_count = 0
            save_cart_count()
            log.info("[CART MOD] Total cart count reset.")
        end

        imgui.text("Carts This Session: " .. tostring(session_cart_count))
        imgui.same_line()
        if imgui.button("Reset Session") then
            session_cart_count = 0
            log.info("[CART MOD] Session cart count reset.")
        end

        imgui.tree_pop()
    end
end)
