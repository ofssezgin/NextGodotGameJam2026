extends Area2D

var building_name = ""
var building_texture: Texture2D
var click_value = 1.0 
var base_scale = Vector2(1, 1) 

@onready var sprite = $Sprite2D        
# İsim ve Tıklama etiketleri silindiği için buradaki @onready satırlarını kaldırdık.

@onready var click_sound = $ClickSound 

func _ready():
	if building_texture != null:
		sprite.texture = building_texture
	
	base_scale = sprite.scale 

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var game_manager = get_tree().current_scene
		
		# Tıklama animasyonu ve puan kazanımı
		animate_click()
		
		if click_sound:
			click_sound.play() 
			
		game_manager.add_points(click_value)
		show_floating_text("+" + str(click_value)) 
		
		# --- ÇÖZÜM: Sadece en üstteki binaya tıklanmasını sağlar ---
		get_viewport().set_input_as_handled()

func show_floating_text(text_to_show):
	var floating_label = Label.new()
	floating_label.text = text_to_show
	floating_label.modulate = Color(0, 1, 0)
	
	# Eğer proje ayarlarından font yumuşatmayı kapattıysan keskin görünecektir.
	add_child(floating_label)
	floating_label.global_position = get_global_mouse_position() - Vector2(10, 10)
	
	var tween = create_tween()
	tween.tween_property(floating_label, "position", floating_label.position - Vector2(0, 50), 0.5)
	tween.parallel().tween_property(floating_label, "modulate:a", 0.0, 0.5) 
	tween.tween_callback(floating_label.queue_free)

func animate_click():
	var tween = create_tween()
	tween.tween_property(sprite, "scale", base_scale * 1.2, 0.05)
	tween.tween_property(sprite, "scale", base_scale, 0.05)
