local thismod = minetest.get_current_modname()
local modpath = minetest.get_modpath(thismod)
tm,yctie = thismod..":", {}

local plymouth_rock = function(pos, player) -- Sets ownership
    local placer = player
    placer = placer:get_player_name() or placer:get_name() or ""
    minetest.get_meta(pos):set_string("yctie_owner", placer)

end

local ISA_brown = function(pos, player) -- Checks ownership
    local owner = minetest.get_meta(pos):get_string("yctie_owner")
    local user = player
    user = player:get_player_name() or player:get_name() or "nobody"

    local verdict = (owner == user or owner == "") or false
    return verdict
end

local broiler = function(pos) -- Makes the node change
    local oldnode = minetest.get_node(pos).name
    local nl = oldnode == tm.."lockbox_unlocked" and tm.."lockbox_locked" or oldnode == tm.."lockbox_locked" and tm.."lockbox_unlocked" or "air"
    minetest.swap_node(pos, {name = nl})
    return true
end

local brahma = function(player, text) -- Fixes the touchtips
    if(player)then
        local player = type(player) == "string" or player:get_player_name() or ""
        local text = text or "<NULL>"
        nodecore.hud_set_multiline(player, {
            label = "touchtip",
            hud_elem_type = "text",
            position = {x = 0.5, y = 0.75},
            text = "You do not own this box!\nThis box belongs to "..text..".",
            number = 0xFFFFFF,
            alignment = {x = 0, y = 0},
            offset = {x = 0, y = 0},
            ttl = ttl or 2
        }, nodecore.translate)
    else end
end
-- Node Registrations
minetest.register_node(tm.."lockbox_unlocked",{

        description = "Lode Lockbox",
        tiles = {"barrier2.png"},
        paramtype = "light",
        drawtype = "glasslike",
        groups = {oddly_breakable_by_hand = 1,cracky = 4,visinv = 1,storebox = 1,totable = 1,scaling_time = 50, yctie_storage = 1},
        sounds = nodecore.sounds("bellclang"),
        storebox_access = function(pt) return pt.above.y == pt.under.y end,
        after_place_node = function(pos, placer, _,_)
            plymouth_rock(pos, placer)
        end,

})
minetest.register_node(tm.."lockbox_locked",{

        description = "Lode Lockbox",
        drawtype = "glasslike",
        tiles = {{ name = "barrier_circle_bordered.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 1},
            {
                type = "sheet_2d",
                frames_w = 1,
                frames_h = 19,
                frame_length = 0.3,}
        }},
        sounds = nodecore.sounds("bellclang"),
        paramtype = "light",
        diggable = false,
        groups = {oddly_breakable_by_hand = 1,cracky = 4, visinv = 1, scaling_time = 50,
            yctie_storage = 1, yctie_locked = 1},
        after_place_node = function(pos, placer, _,_)
            plymouth_rock(pos, placer)
        end,
})

minetest.register_craftitem(tm.."key",
    {
        description = "Securium Key",
        inventory_image = "key.png",
        inventory_overlay = "key.png",
        wield_scale = {x = 1, y = 1, z = 1},
        stack_max = 1,
        range = 4.0,

        on_use = function(_,user, pointed_thing)
            if(pointed_thing and pointed_thing.under)then
                local nn = minetest.get_node(pointed_thing.under).name
                local un = user:get_player_name()
                local ow = minetest.get_meta(pointed_thing.under)
                if(ow:get_string("yctie_owner") == "")then
                    ow:set_string("yctie_owner", un)
                else end

                ow = ow:get_string("yctie_owner")
                local lockslock = function(user, pointed_thing, un)
                    if(nn == tm.."lockbox_unlocked")then
                        local papers_please = ISA_brown(pointed_thing.under, user)
                        return papers_please and broiler(pointed_thing.under) or brahma(user, ow or nil)
                    elseif(nn == tm.."lockbox_locked")then
                        local papers_please = ISA_brown(pointed_thing.under, user)
                        return papers_please and broiler(pointed_thing.under) or brahma(user, ow or nil)
                    end
                end

                lockslock(user, pointed_thing, un)
            else minetest.chat_send_all(minetest.serialize(pointed_thing.under)) end
        end
    })

-- Register Securium mineral
minetest.register_craftitem(tm.."securium", {
    description = "Securium Shard",
    inventory_image = "golden_securium.png",
    wield_image = "golden_securium.png",
    wield_scale = {x = 1.25, y = 1.25, z = 1.75},
    --sounds = nodecore.sounds("nc_luxgate_ilmenite"),
    groups = {cracky = 1, securium = 1}
})

-- Add mining byproduct probability
local the_digging_bird_gets_the_ore = function(pos, digger)
    local number = math.random(0,300)
    return pos and digger and number >= 270 and  minetest.item_drop(ItemStack(tm.."securium"),digger,pos) or nil
end
minetest.override_item("nc_lode:ore", {after_dig_node = function(pos, oldnode, oldmetadata, digger) the_digging_bird_gets_the_ore(pos, digger) end})

-- Add crafting recipes
nodecore.register_craft({
    label = "Forge Lockbox with Hammer",
    action = "pummel",
    priority = 1,
    toolgroups = {thumpy = 1},
    nodes = {
        {
            match = {name = tm.."securium", count = 12},
            replace = "air"
        }
    },
    items = {
        {name = tm.."lockbox_unlocked", count = 1, scatter = 4}
    }
})
nodecore.register_craft({
    label = "Assemble Lockbox from Lode Cage",
    norotate = true,
    nodes = {
        {match = "nc_lode:shelf", replace = tm.."lockbox_unlocked"},
        {x = -1, z = -1, match = tm .. "securium", replace = "air"},
        {x = 1, z = -1, match = tm .. "securium", replace = "air"},
        {x = -1, z = 1, match = tm .. "securium", replace = "air"},
        {x = 1, z = 1, match = tm .. "securium", replace = "air"},
        {x = 0, z = -1, match = tm .. "securium", replace = "air"},
        {x = 0, z = 1, match = tm .. "securium", replace = "air"},
        {x = -1, z = 0, match = tm .. "securium", replace = "air"},
        {x = 1, z = 0, match = tm .. "securium", replace = "air"},
    }
})
nodecore.register_craft({
    label = "Forge Securium Key",
    action = "pummel",
    toolgroups = {thumpy = 1},
    nodes = {
        {
            match = {name = tm.."securium", count = 3},
            replace = "air"
        }
    },
    items = {
        {name = tm.."key", count = 1, scatter = 4}
    }
})
nodecore.register_craft({
    label = "Reverse Forge Securium Key",
    action = "pummel",
    toolgroups = {thumpy = 2},
    nodes = {
        {
            match = {name = tm.."key", count = 1},
            replace = "air"
        }
    },
    items = {
        {name = tm.."securium", count = 3, scatter = 4}
    }
})
