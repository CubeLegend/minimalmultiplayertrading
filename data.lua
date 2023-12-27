SPECIALIZATIONS = require "specializations-data"

data:extend{
    {
        type = "custom-input",
        name = "specialization-gui",
        key_sequence = "J"
    }
}

if settings.startup['specializations'].value then
    for _, spec in ipairs(SPECIALIZATIONS) do
        local recipe = {
            type = "recipe",
            name = spec.name,
            ingredients = spec.recipe.ingredients,
            energy_required = spec.recipe.energy_required,
            enabled = false,
            category = spec.recipe.category,
            subgroup = spec.recipe.subgroup,
            icon = spec.recipe.icon
        }
        if spec.recipe.result then
            recipe.result = spec.recipe.result
        else
            recipe.results = spec.recipe.results
        end
        if spec.recipe.icon then recipe.icon_size = 32 end
        data:extend{recipe}
    end
end
