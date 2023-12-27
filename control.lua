--[[
    Multiplayer Trading by Luke Perkin.
    Some concepts taken from Teamwork mod (credit to DragoNFly1) and Diplomacy mod (credit to ZwerOxotnik).
]]
-- Modfied by ZwerOxotnik

require "systems/specializations"


--#region Constants
local tostring = tostring
local call = remote.call
---#endregion


--#region Global data
local early_bird_tech
local specializations
---#endregion

local function link_data()
    early_bird_tech = global.early_bird_tech
    specializations = global.specializations
end

local function CheckGlobalData()
    global.specializations = global.specializations or {}
    global.output_stat = global.output_stat or {}
    global.early_bird_tech = global.early_bird_tech or {}

    link_data()
end

local function on_force_created(event)
    for name, technology in pairs(event.force.technologies) do
        if string.find(name, "-mpt-") ~= nil then
            technology.enabled = false
        end
    end
end

local function on_init()
    CheckGlobalData()
    for _, force in pairs(game.forces) do
        on_force_created({force=force})
    end
end

local function on_load()
    link_data()
end

local function fix_force_recipes(event)
  local force = event.force
  local recipes = force.recipes
  local force_name = force.name
  for spec_name, _force_name in pairs(specializations)  do
    if _force_name == force_name then
      recipes[spec_name].enabled = true
    end
  end
end

local function on_research_finished(event)
    local research = event.research
    local tech_cost_multiplier = settings.startup['early-bird-multiplier'].value
    local base_tech_name = string.gsub(research.name, "%-mpt%-[0-9]+", "")
    if research.force.technologies[base_tech_name .. "-mpt-1"] == nil then
        return
    end
    early_bird_tech[research.force.name .. "/" .. base_tech_name] = true
    for _, force in pairs(game.forces) do
        local force_tech_state_id = force.name .. "/" .. base_tech_name
        local tech = force.technologies[research.name]
        if not tech.researched then
            local progress = force.get_saved_technology_progress(research.name)
            if string.find(research.name, "-mpt-") ~= nil then
                -- Another force has researched the 2nd, 3rd or 4th version of this tech.
                local tier_index = string.find(research.name, "[0-9]$")
                local tier = tonumber(string.sub( research.name, tier_index ))
                if tier < 4 then
                    local next_tech_name =  base_tech_name .. "-mpt-" .. tostring(tier + 1)
                    if progress then
                        progress = progress / math.pow(tech_cost_multiplier, tier + 1)
                        force.set_saved_technology_progress(next_tech_name, progress)
                    end
                    if not early_bird_tech[force_tech_state_id] then
                        force.technologies[next_tech_name].enabled = true
                    end
                    tech.enabled = false
                end
            else
                -- Another force has researched this tech for the 1st time.
                local next_tech_name = research.name .. "-mpt-1"
                if progress then
                    progress = progress / tech_cost_multiplier
                    force.set_saved_technology_progress(next_tech_name, progress)
                end
                force.technologies[next_tech_name].enabled = true
                tech.enabled = false
            end
        end
    end
end

script.on_init(on_init)
script.on_load(on_load)

if settings.startup['specializations'].value then
    script.on_event("specialization-gui", function(event)
        pcall(SpecializationGUI, game.get_player(event.player_index))
    end)
end

script.on_event(defines.events.on_force_reset, function(event)
    pcall(fix_force_recipes, event)
end)
script.on_event(defines.events.on_technology_effects_reset, function(event)
    pcall(fix_force_recipes, event)
end)
script.on_event(defines.events.on_gui_click, function(event)
    pcall(on_gui_click, event)
end)
script.on_event(defines.events.on_force_created, on_force_created)
if settings.startup['early-bird-research'].value then
    script.on_event(defines.events.on_research_finished, on_research_finished)
end

remote.add_interface("multiplayer-trading", {})

if settings.startup['specializations'].value == true then
    script.on_nth_tick(3600, UpdateSpecializations)
end
