local sdk = sdk
local log = log

sdk.hook(
    sdk.find_type_definition("app.cHunterHealth"):get_method("update(System.Single, System.Boolean)"),
    function(args)
        local this = sdk.to_managed_object(args[2])
        if not this then
            log.info("No object found.")
            return
        end

        -- Check _DieTrg field
        local dieTrg = this:get_field("_DieTrg")
        if dieTrg == true then
            log.info("[MOD] _DieTrg is TRUE - Hunter is marked as dead.")
        end
    end,
    nil
)

