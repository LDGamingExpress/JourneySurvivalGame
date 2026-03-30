extends CharacterBody3D

var AlreadyDead = false

var SPEED = 10.0 # Player speed
var JUMP_VELOCITY = 5.5 # Player jump velocity
var push_force = 1.0 # Player push force; used to allow forces on rigid bodies

var MineObject = null # Node the player can mine
var MineProgress = 0.0 # Progress the player has made into mining the object

var PickUpObject = null # Node the player can pick up

var InitialRayActive = true # Used to set the initial position of the player

var Music = ["res://Music/Danger Rising.mp3","res://Music/Landscape.mp3","res://Music/Night.mp3","res://Music/Open World.mp3"]

#Player stats 
var Health = 10.0
var HealthTween

var Hunger = 100.0
var HungerTween

#Used for fall damage
var IsInAir = true
var InitialHeight = 0.0

var Inventory = [[],
	[],
	[],
	[],
	[],
	[],
	[],
	[],
	[],
	]
# Inventory using an array of arrays
# Setup: ["Name of Item", Integer Amount of Item]
# Ex: ["Log",5] for 5 logs

var Recipes =[
	["Stick",[["Log",1]],4],
	["Wooden Sword",[["Log",2],["Stick",1]],1],
	["Wooden Axe",[["Log",3],["Stick",1]],1],
	["Wooden Pick",[["Log",3],["Stick",1]],1],
	["Stone Axe",[["Stone",3],["Stick",1]],1],
	["Stone Pick",[["Stone",3],["Stick",1]],1],
]
# Recipes using an array of arrays
# Setup: ["Name of Item to Craft",[["Name of Item Needed for Crafting", Integer Amount of Item Needed], ...], Integer Amount of Item That Will Be Crafted]
# Ex: ["Wooden Sword",[["Log",1],["Stick",1]],1] for crafting 1 Wooden Sword using 1 Log and 1 Stick.

var ItemPaths = {
	"Wooden Sword": "res://WoodenSword.tscn",
	"Wooden Axe": "res://WoodenAxe.tscn",
	"Wooden Pick": "res://WoodenPickaxe.tscn",
	"Stone Axe": "res://StoneAxe.tscn",
	"Stone Pick": "res://StonePickaxe.tscn",
	"Log": "res://Models/AutumnLog.glb",
	"Stick": "res://Models/Stick.glb",
	"Stone": "res://Models/SmallStone.glb",
	"Apple": "res://Models/Apple.glb"
}
# Dictionary tying the names of items (same as in the inventory and crafting) to the model paths for displaying the items
# Can modify to reference necessary scenes of the items if not just a model is needed

var CraftingPanel = load("res://CraftingPanel.tscn")
# Scene with a template of a panel for crafting
# Contains the name of item to craft, items needed, and a button to craft

var isCrafting = false # Bool for whether the player is crafting or not

var ItemSelected = 0
# Integer for what inventory slot is currently selected in the player's hand
# Matches the index in the inventory and child number of the Inventory node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(0, len(Recipes)): # Loops through each recipe
		var NewPanel = CraftingPanel.instantiate() # Instantiates new crafting panel
		NewPanel.get_child(0).get_child(0).text = (Recipes[i][0] + "\n") # Adds name of item to be crafted to the Label in the crafting panel
		for j in range(0, len(Recipes[i][1])): # Loops through each item required for crafting
			NewPanel.get_child(0).get_child(0).text = NewPanel.get_child(0).get_child(0).text + Recipes[i][1][j][0] + " " + str(Recipes[i][1][j][1]) + "\n"
			# Adds text to the Label showing the item needed and how many
		NewPanel.RecipeNumber = i
		# Assigns value to the RecipeNumber of the crafting panel so the panel can call the _on_craft_button_pressed() function with the index of the recipe
		get_node("Camera3D/CanvasLayer/CraftingWindow").add_child(NewPanel) # Adds the crafting panel to the crafting window
	_on_music_player_finished()

func _input(event): # Checks for input
	if event is InputEventMouseMotion and !isCrafting: # Checks if the input is the mouse moving
		rotate(Vector3.UP, -event.relative.x * 0.002) # Rotates the player horizontally with the mouse
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and $Camera3D/Hand.get_children().size() > 0:
		if $Camera3D/Hand.get_child(0).scene_file_path == ItemPaths["Apple"]:
			Eat(20)
			var index = 0
			for i in range(0, Inventory.size()):
				if Inventory[i].size() > 0 and Inventory[i][0] == "Apple":
					index = i
			
			Inventory[index][1] -= 1
			if Inventory[index][1] <= 0:
				Inventory[index] = []
			
			var SlotContainer = $Camera3D/CanvasLayer/Inventory.get_child(index).get_child(0)
			if len(Inventory[index]) > 0:
				SlotContainer.get_child(0).text = Inventory[index][0]
				SlotContainer.get_child(1).text = str(Inventory[index][1])
			else:
				SlotContainer.get_child(0).text = ""
				SlotContainer.get_child(1).text = ""
			RefreshHand() # Called to change visual model in the player's hand

# Called continuously
func _physics_process(delta: float) -> void:
	
	if InitialRayActive and get_node("InitialRay").is_colliding():
		position.y = get_node("InitialRay").get_collision_point().y + 5.0
		InitialRayActive = false
		
	if Health <= 0.0 and !AlreadyDead:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$Camera3D/CanvasLayer/DeathMenu.visible = true
		AlreadyDead = true
		get_tree().paused = true
	
	var LastItemSelected = ItemSelected # Tracks the last item selected for comparison
	
	if Input.is_action_just_released("ItemLeft"): # Checks if the player scrolls left in their inventory
		# Decreases index of item selected
		ItemSelected -= 1
		if ItemSelected < 0:
			ItemSelected = 8
	
	if Input.is_action_just_released("ItemRight"): # Checks if the player scrolls right in their inventory
		# Increases index of item selected
		ItemSelected += 1
		if ItemSelected > 8:
			ItemSelected = 0
	
	if LastItemSelected != ItemSelected: # Checks whether player has switched item selected
		$Camera3D/CanvasLayer/Inventory.get_child(LastItemSelected).self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		# Resets the slot of the previous selected item back to normal (i.e. no longer highlighted)
		
		$Camera3D/CanvasLayer/Inventory.get_child(ItemSelected).self_modulate = Color(18.892, 18.892, 18.892, 1.0)
		# Modulates the slot of the now selected item to be highlighted
		
		RefreshHand() # Called to change visual model in the player's hand
	
	if Input.is_action_just_pressed("Crafting"): # Checks if the player pressed the button for the crafting window
		if isCrafting: # Checks if already crafting
			# Toggles isCrafting and changes mouse mode to keep the mouse centered and hidden
			isCrafting = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else: # If not already crafting
			# Toggles isCrafting and changes mouse mode to let the mouse move and be visible
			isCrafting = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$Camera3D/CanvasLayer/CraftingWindow.visible = isCrafting # Sets visibility of the crafting window based on isCrafting
	
	# Mineable object and pickup detection
	if $Camera3D/RayCast3D.is_colliding(): # Checks if the raycast coming out the player is colliding with an object
		if $Camera3D/RayCast3D.get_collider() != null: # Makes sure the object still exists (required when object is deleted but still detected)
			if $Camera3D/RayCast3D.get_collider().get_parent().get_parent().is_in_group("Mineable"): # Checks if object can be mined
				if $Camera3D/Hand.get_children().size() > 0:
					var currEquip = $Camera3D/Hand.get_child(0).get_child(0)
					var currObj = $Camera3D/RayCast3D.get_collider().get_parent().get_parent()
					if currEquip.is_in_group("Axe") and currObj.is_in_group("Axe"):
						MineObject = $Camera3D/RayCast3D.get_collider().get_parent().get_parent().get_parent()
					elif currEquip.is_in_group("Pickaxe") and currObj.is_in_group("Pickaxe"):
						MineObject = $Camera3D/RayCast3D.get_collider().get_parent().get_parent().get_parent()
					elif currObj.is_in_group("Any"):
						MineObject = $Camera3D/RayCast3D.get_collider().get_parent().get_parent().get_parent()
					else:
						MineObject = null
				else:
					var currObj = $Camera3D/RayCast3D.get_collider().get_parent().get_parent()
					if currObj.is_in_group("Any"):
						MineObject = $Camera3D/RayCast3D.get_collider().get_parent().get_parent().get_parent()
			if $Camera3D/RayCast3D.get_collider().get_parent().is_in_group("Pickup"): # Checks if object can be picked up
				PickUpObject = $Camera3D/RayCast3D.get_collider().get_parent().get_parent()
			# Note: These get_parent() amounts are based on the mineable objects being static and the pickups being rigid bodies.
			# If this is switched, you will need to change the get_parent() amounts as these are based on the generated paths from the collision nodes.
	else:
		MineObject = null
		PickUpObject = null
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		#Used to calculate fall damage
		if !IsInAir:
			IsInAir = true
			InitialHeight = position.y
	elif is_on_floor() and IsInAir:
		#Fall damage is taken if player falls atleast 4 units down
		IsInAir = false
		var damage = clamp((InitialHeight - position.y) - 4, 0, 10)
		InitialHeight = 0.0
		UpdateHealth(damage)
	
	#Handles Regenerating health
	if Health < 9.0 and Hunger >= 10.0 and $HungerTimer.is_stopped():
		UpdateHealth(-1.0)
		UpdateHunger(10.0)
		$HungerTimer.start(2.0)
	elif $HungerTimer.is_stopped() and Health < 10.0 and Hunger > 0.0:
		var regen
		if (10.0 - Health) < (100.0 - Hunger) / 10.0:
			regen = 10.0 - Health
		else:
			regen = (100.0 - Hunger) / 10.0
		
		UpdateHealth(-regen)
		UpdateHunger(regen * 10.0)
		$HungerTimer.start(2.0)
	
	if Hunger <= 0.0 and $HungerTimer.is_stopped():
		UpdateHealth(0.5)
		SPEED = 5.0
		JUMP_VELOCITY = 2.75
		$HungerTimer.start(2.0)
	
	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		UpdateHunger(1.0)
	
	# Mining objects
	if MineObject != null: # Checks if there is an object to mine
		$Camera3D/CanvasLayer/TextureRect.self_modulate = Color(0.733, 0.176, 0.0, 1.0)
		# Changes cursor color to show player can mine
		
		if Input.is_action_pressed("Mine"): # Checks if player is pressing button to mine
			if MineProgress == 0.0 and $Camera3D/Hand.get_children().size() > 0:
				if $Camera3D/Hand.get_child(0).is_in_group("Axe") or $Camera3D/Hand.get_child(0).is_in_group("Pickaxe"):
					MineProgress = $Camera3D/Hand.get_child(0).boost
			
			$Camera3D/CanvasLayer/MineLabel.visible = true # Displays text to show player is mining
			MineProgress += delta # Adds time to mining progress (seconds)
			if MineProgress >= MineObject.get_meta("MineTime"): # Grabs the meta data of the mineable object for mining time
				var Counter = 0 # Counts items dropped
				
				if MineObject.get_child(0).is_in_group("Tree"):
					var rand = randi_range(1, 3)
					if rand == 3:
						Counter += 1
						var NewObj = load("res://Apple.tscn").instantiate() # Instantiates the dropped loot
						NewObj.position = MineObject.global_position + Vector3(0,4*Counter,0) # Uses counter to spawn each dropped lot 4 units above the last
						get_parent().add_child(NewObj) # Adds loot to the scene
				
				for i in range(0,len(MineObject.get_meta("Drops"))): # Loops through drops for the mineable object based on its meta data
					for j in range(0,MineObject.get_meta("Amounts")[i]): # Loops through the amounts for each drop based on the object's meta data
						Counter += 1 # Increases counter for each item being dropped
						var NewObj = MineObject.get_meta("Drops")[i].instantiate() # Instantiates the dropped loot
						NewObj.position = MineObject.global_position + Vector3(0,4*Counter,0) # Uses counter to spawn each dropped lot 4 units above the last
						get_parent().add_child(NewObj) # Adds loot to the scene
				MineObject.queue_free() # Deletes the mined object
				MineObject = null # Resets variable as mined object no longer exists
				MineProgress = 0.0 # Resets mining progress
				$Camera3D/CanvasLayer/MineLabel.visible = false  # Hides text to show player is no longer mining
		else: # Occurs if player is not mining but there is an object to mine
			$Camera3D/CanvasLayer/MineLabel.visible = false  # Hides text to show player is no longer mining
			MineProgress = 0.0 # Resets mining progress
	else: # Occurs if there is not an object to mine
		MineProgress = 0.0 # Resets mining progress
	
	# Picking up objects
	if PickUpObject != null: # Checks if there is an object to pick up
		$Camera3D/CanvasLayer/TextureRect.self_modulate = Color(0.12, 0.496, 0.06, 1.0)
		# Changes cursor color to show player can pick up the object
		
		if Input.is_action_just_pressed("Interact"): # Checks if player is pressing button to pick up (same action can be used for interactions)
			var CanPickUp = false # Used to check if the player has space to pick up the object
			var Slot = 0 # Slot to put the new item into
			for i in range(0, len(Inventory)): # Loops through the inventory
				if Inventory[i].has(PickUpObject.get_meta("Loot")) or len(Inventory[i]) == 0: # Checks if a slot already has the item or is empty
					CanPickUp = true # Switched to true to show player has space to pick up the object
					Slot = i
					break
			if CanPickUp: # Checks if player has space to put the item into
				if len(Inventory[Slot]) == 0: # Checks if the slot is empty
					Inventory[Slot] = [PickUpObject.get_meta("Loot"),PickUpObject.get_meta("Amount")]
					# Uses meta data of the item to update the slot's data
				else:
					Inventory[Slot] = [PickUpObject.get_meta("Loot"),Inventory[Slot][1] + PickUpObject.get_meta("Amount")]
					# Uses meta data of the item to update the slot's data
				
				# Gets the slot UI of the associated inventory slot and updates the text
				var SlotContainer = $Camera3D/CanvasLayer/Inventory.get_child(Slot).get_child(0)
				SlotContainer.get_child(0).text = PickUpObject.get_meta("Loot")
				SlotContainer.get_child(1).text = str(Inventory[Slot][1])
				
				PickUpObject.queue_free() # Deletes item as it has been picked up
				
				if Slot == ItemSelected: # Checks if this slot is the one in the player's hand
					RefreshHand() # Called to change visual model in the player's hand
	elif MineObject == null: # Occurs if there is not an object to mine or pick up
		# Resets modulation of the cursor
		$Camera3D/CanvasLayer/TextureRect.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		UpdateHunger(delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# Force integration for rigid bodies
	for i in get_slide_collision_count(): # Loops through bodies being collided with
		# Checks if the bodies are rigid bodies and applies forces if so
		
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force)

# Called when the crafting button of one of the crafting panels is clicked
func _on_craft_button_pressed(RecipeNumber) -> void:
	
	var CanPickUp = false # Used to check if the player has space to craft the object
	var Slot = 0 # Slot to put the new item into
	for i in range(0, len(Inventory)): # Loops through the inventory
		if Inventory[i].has(Recipes[RecipeNumber][0]) or len(Inventory[i]) == 0: # Checks if a slot already has the item or is empty
			CanPickUp = true # Switched to true to show player has space to craft the object
			Slot = i
			break
	
	if CanPickUp: # Checks if the player has space for the item
		var CanCraft = true # Tracks if the player can craft the item
		var NewInventory = Inventory.duplicate_deep()
		# Inventory is duplicated so a new version can be made to replace the main one with later if the player can craft the item
		
		for i in range(0, len(Recipes[RecipeNumber][1])): # Loops through the items required for the recipe
			var CanCraftPart = false # Tracks if the player has enough of that particular crafting item
			var ItemsStillNeeded = Recipes[RecipeNumber][1][i][1] # Tracks how many of that particular crafting item the player needs
			for j in range(0, len(Inventory)): # Loops through the inventory
				if len(Inventory[j]) > 0: # Checks the slot is not empty
					if Inventory[j][0] == Recipes[RecipeNumber][1][i][0]: # Checks that this slot has that item
						if Inventory[j][1] >= ItemsStillNeeded: # Checks if there is enough of the item in that slot
							# Changes amount in that slot and breaks from inventory loop as there are already enough of that item
							CanCraftPart = true
							NewInventory[j][1] -= ItemsStillNeeded
							if NewInventory[j][1] == 0:
								NewInventory[j] = []
							break
						else: # Checks if there is not enough of the item just in that slot
							# Removes the amount in that slot from the amount still needed so loop can continue
							ItemsStillNeeded -= NewInventory[j][1]
							NewInventory[j] = []
			if CanCraftPart == false: # Checks if there is not enough of that particular crafting item
				# Changes CanCraft to show item cannot be crafted and breaks from recipe loop
				CanCraft = false
				break
		if CanCraft: # Checks if item can be crafted
			Inventory = NewInventory.duplicate_deep() # Sets main inventory based on required items being used
			if len(Inventory[Slot]) == 0: # Checks if slot is empty
				# Modifies slot's data based on recipe data (name and amount)
				Inventory[Slot] = [Recipes[RecipeNumber][0],Recipes[RecipeNumber][2]]
			else:
				# Modifies slot's data based on recipe data (name and amount)
				Inventory[Slot] = [Recipes[RecipeNumber][0],Inventory[Slot][1] + Recipes[RecipeNumber][2]]
			for i in range(0,len(Inventory)): # Loops through each inventory slot
				# Assumes every slot is part of the UI
				
				# Gets the slot UI of the associated inventory slot and updates the text
				var SlotContainer = $Camera3D/CanvasLayer/Inventory.get_child(i).get_child(0)
				if len(Inventory[i]) > 0:
					SlotContainer.get_child(0).text = Inventory[i][0]
					SlotContainer.get_child(1).text = str(Inventory[i][1])
				else:
					SlotContainer.get_child(0).text = ""
					SlotContainer.get_child(1).text = ""
			RefreshHand() # Called to change visual model in the player's hand

# Called when the model in the player's hand needs to be refreshed
func RefreshHand():
	if $Camera3D/Hand.get_child_count() > 0: # Checks if there is already an item in the hand
		$Camera3D/Hand.get_child(0).queue_free() # Deletes model of the item
	if len(Inventory[ItemSelected]) > 0: # Checks if there is an item to show
		var NewObj = load(ItemPaths[Inventory[ItemSelected][0]]).instantiate()
		# Gets the model using the item path and instantiates it
		
		if NewObj.get_child(0) is RigidBody3D: # Checks if the model is a rigid body
			NewObj.get_child(0).freeze = true
			# Freezes the rigid body so that it does not fall in the player's hand
		
		$Camera3D/Hand.add_child(NewObj) # Adds the model as a child of the player's hand

func Eat(hunger : float):
	UpdateHunger(-hunger)
	if SPEED == 5.0:
		SPEED = 10.0
	if JUMP_VELOCITY == 2.75:
		JUMP_VELOCITY = 5.5


func UpdateHunger(hunger : float):
	if HungerTween:
		HungerTween.kill()
	
	Hunger -= hunger
	Hunger = clamp(Hunger, 0.0, 100.0)
	
	#HungerTween = create_tween()
	$Camera3D/CanvasLayer/HungerPanel/HungerBar.value = Hunger
	#HungerTween.tween_property($Camera3D/CanvasLayer/HungerPanel/HungerBar, "value", Hunger, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func UpdateHealth(damage : float):
	if HealthTween:
		HealthTween.kill()
	
	Health -= damage
	Health = clamp(Health, 0.0, 10.0)
	
	#HealthTween = create_tween()
	$Camera3D/CanvasLayer/HealthPanel/HealthBar.value = Health
	#HealthTween.tween_property($Camera3D/CanvasLayer/HealthPanel/HealthBar, "value", Health, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_music_player_finished() -> void:
	var Music2Play = Music.pick_random()
	$MusicPlayer.stream = load(Music2Play)
	$MusicPlayer.play()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_parent().get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
