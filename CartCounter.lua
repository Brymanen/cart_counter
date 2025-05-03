local sdk = sdk
local log = log
local imgui = imgui
local re = re
local json = json

local cart_data_path = "cart_counter.json"

local cart_count = 0
local session_cart_count = 0
local show_floating_overlay = true
local last_hunter_health = nil

-- Load data from file
local function load_cart_data()
    local loaded = json.load_file(cart_data_path)
    if loaded then
        if type(loaded.count) == "number" then
            cart_count = loaded.count
        end
        if type(loaded.show_floating_overlay) == "boolean" then
            show_floating_overlay = loaded.show_floating_overlay
        end
        log.info("[CART MOD] Loaded config")
    else
        log.info("[CART MOD] No previous data found.")
    end
end

-- Save data to file
local function save_cart_data()
    json.dump_file(cart_data_path, {
        count = cart_count,
        show_floating_overlay = show_floating_overlay
    })
    log.info("[CART MOD] Saved config")
end

load_cart_data()

-- Hook into update to track deaths and cache hunter health
sdk.hook(
    sdk.find_type_definition("app.cHunterHealth"):get_method("update(System.Single, System.Boolean)"),
    function(args)
        local this = sdk.to_managed_object(args[2])
        if not this then return end
        last_hunter_health = this

        if this:get_field("_DieTrg") then
            cart_count = cart_count + 1
            session_cart_count = session_cart_count + 1
            save_cart_data()
            log.info("[CART MOD] Carted! Total: " .. tostring(cart_count) .. " | Session: " .. tostring(session_cart_count))
        end
    end,
    nil
)

-- UI
re.on_draw_ui(function()
    if imgui.tree_node("Cart Counter") then
        imgui.text("Carts Total: " .. tostring(cart_count))
        if imgui.button("Reset Total") then
            cart_count = 0
            save_cart_data()
            log.info("[CART MOD] Total cart count reset.")
        end

        imgui.text("Carts Session: " .. tostring(session_cart_count))
        if imgui.button("Reset Session") then
            session_cart_count = 0
            log.info("[CART MOD] Session cart count reset.")
        end

        local changed, new_state = imgui.checkbox("Show Floating Overlay", show_floating_overlay)
        if changed then
            show_floating_overlay = new_state
            save_cart_data()
        end

        if last_hunter_health then
            if imgui.tree_node("Debug: cHunterHealth Fields") then
                local function print_field(label)
                    local val = last_hunter_health:get_field(label)
                    imgui.text(label .. ": " .. tostring(val))
                end

                print_field("_DieTrg")
                print_field("_IsDeadPrev")
                print_field("_ExtraMaxHealth")
                print_field("_SkillExtraMaxHealth")
                print_field("_RedHealth")
                print_field("_RequestedTotalDamage")
                print_field("_RequestedTotalHealValue")
                print_field("_IsForceDie")
                print_field("_IsNoDamage")
                print_field("_RedRecoverTimer")
                print_field("_RedRecoverTimeRate")

                imgui.tree_pop()
            end
        end

        imgui.tree_pop()
    end
end)

-- Floating overlay
re.on_frame(function()
    if show_floating_overlay then
        imgui.set_next_window_pos(10, 10, imgui.Cond.Always)
        imgui.begin_window("Cart Overlay", nil,
            imgui.WindowFlags.NoTitleBar |
            imgui.WindowFlags.AlwaysAutoResize |
            imgui.WindowFlags.NoMove |
            imgui.WindowFlags.NoScrollbar |
            imgui.WindowFlags.NoSavedSettings)

        imgui.text("Carts Total: " .. tostring(cart_count))
        imgui.text("Carts Session: " .. tostring(session_cart_count))

        imgui.end_window()
    end
end)
