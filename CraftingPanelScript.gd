extends PanelContainer
@export var RecipeNumber:int = 0
# Matches the index for the recipe that will be crafted using this panel
# Can be set manually, but is usually set automatically by the player when the crafting panels are generated based on the recipes

# Called when the button for the associated crafting button is pressed
func _on_craft_button_pressed() -> void:
	get_parent().get_parent().get_parent().get_parent()._on_craft_button_pressed(RecipeNumber)
