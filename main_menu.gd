extends Control

# Sahnedeki var olan tek slider'ımızı alıyoruz
@onready var ses_slider = $SesSlider

# Sadece Müzik kanalını kontrol edeceğiz
var music_bus_idx = AudioServer.get_bus_index("Music")

func _ready():
	# 1. 'Music' kanalının numarasını al (Hata yapmamak için değişkene atıyoruz)
	var music_bus_idx = AudioServer.get_bus_index("Music")
	
	# EĞER KANAL BULUNAMAZSA (Hata kontrolü)
	if music_bus_idx == -1:
		print("HATA: 'Music' isimli bir ses kanalı bulunamadı! Lütfen Audio panelini kontrol et.")
		return

	# 2. Slider'ın ayarlarını kodla sabitleyelim (Inspector'daki hataları ezer)
	ses_slider.min_value = 0.0
	ses_slider.max_value = 1.0
	ses_slider.step = 0.01
	
	# 3. KRİTİK ADIM: AudioServer'daki gerçek DB değerini al ve Slider'ın anlayacağı 0-1 arasına çevir
	var mevcut_ses_db = AudioServer.get_bus_volume_db(music_bus_idx)
	ses_slider.value = db_to_linear(mevcut_ses_db)
	
	# Debug için konsola yazdıralım (Çalıştığını görmek için)
	print("Ana Menü Yüklendi. Mevcut Ses Seviyesi: ", ses_slider.value)

# 3. Slider'ı farenle sağa sola çektiğinde müziğin sesini anlık olarak değiştirir
func _on_ses_slider_value_changed(value):
	var music_bus_idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(value))

# BAŞLA butonunun fonksiyonu 
func _on_button_pressed():
	get_tree().change_scene_to_file("res://main_level.tscn")

# OYUNDAN ÇIK butonunun fonksiyonu 
func _on_cikis_pressed():
	get_tree().quit()
