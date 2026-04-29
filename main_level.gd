extends Node2D

var gelecek_puani = 15.0          
var saniye_basina_uretim = 0.0   

# --- UI ELEMANLARI (Unique Name % Kullanıldı) ---
# Sahne ağacında bu nodlara sağ tıklayıp "Access as Unique Name" demeyi unutma!
@onready var points_label = %PointsLabel
@onready var pps_label = %PPSLabel
@onready var win_screen = %WinScreen 
@onready var btn_oyunu_bitir = %BtnOyunuBitir
@onready var hata_mesaji = %HataMesaji

@onready var muzik_slider = %MuzikSlider
@onready var ses_efekti_slider = %SesEfektiSlider

# Godot'da ses kanallarının (bus) numaralarını alıyoruz
var music_bus_idx = AudioServer.get_bus_index("Music")
var sfx_bus_idx = AudioServer.get_bus_index("SFX")

@onready var btn_bonus_kulube = %BtnBonusKulube

# BONUSLAR SÖZLÜĞÜ (İstediğin kadar ekleyebilirsin)
var bonuslar = {
	"kulube_x2": {"fiyat": 75, "hedef": "kulube", "carpan": 2.0, "alindi": false},
	"ev_x2": {"fiyat": 250, "hedef": "ev", "carpan": 2.0, "alindi": false},
	"ilkokul_x2": {"fiyat": 500, "hedef": "ilkokul", "carpan": 2.0, "alindi": false},
	"hastane_x2": {"fiyat": 1000, "hedef": "hastane", "carpan": 2.0, "alindi": false},
	"universite_x2": {"fiyat": 2500, "hedef": "universite", "carpan": 2.0, "alindi": false}
}

@onready var butonlar = {
	"kulube": %BtnKulube,
	"ev": %BtnEv,
	"ilkokul": %BtnIlkokul,
	"hastane": %BtnHastane,
	"universite": %BtnUniversite
}

var house_scene = preload("res://house.tscn")

# OYUNUN DENGESİ VE LİMİTLER
var binalar = {
	"kulube":     {"isim": "Kulübe",     "fiyat": 15,    "gelir": 1,   "tik_degeri": 1.0,  "adet": 0, "maks_adet": 10, "satir_y": 100, "bosluk_x": 85,  "tex": preload("res://kulube.png")},
	"ev":         {"isim": "Ev",         "fiyat": 100,   "gelir": 5,   "tik_degeri": 2.0,  "adet": 0, "maks_adet": 8,  "satir_y": 210, "bosluk_x": 105, "tex": preload("res://ev.png")},
	"ilkokul":    {"isim": "İlkokul",    "fiyat": 500,   "gelir": 15,  "tik_degeri": 5.0,  "adet": 0, "maks_adet": 5,  "satir_y": 320, "bosluk_x": 160, "tex": preload("res://ilkokul.png")},
	"hastane":    {"isim": "Hastane",    "fiyat": 2000,  "gelir": 50,  "tik_degeri": 15.0, "adet": 0, "maks_adet": 3,  "satir_y": 430, "bosluk_x": 220, "tex": preload("res://hastane.png")},
	"universite": {"isim": "Üniversite", "fiyat": 5000,  "gelir": 100, "tik_degeri": 50.0, "adet": 0, "maks_adet": 2,  "satir_y": 540, "bosluk_x": 220, "tex": preload("res://universite.png")}
}

func _ready():
	
	# Başlangıç ayarları
	for bina_id in binalar.keys():
		buton_yazisini_guncelle(bina_id)
	
	update_ui()
	win_screen.visible = false 
	btn_oyunu_bitir.visible = false
	
	muzik_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_idx))
	ses_efekti_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))

func _process(delta):
	if saniye_basina_uretim > 0:
		gelecek_puani += saniye_basina_uretim * delta
		update_ui()

func add_points(amount):
	gelecek_puani += amount
	update_ui()

func update_ui():
	points_label.text = "Gelecek Puanı: " + str(int(gelecek_puani))
	pps_label.text = "Saniyede: " + str(saniye_basina_uretim)

func satin_al(bina_id):
	var bina = binalar[bina_id]
	var buton = butonlar[bina_id]
	
	if bina["adet"] >= bina["maks_adet"]:
		return
		
	if gelecek_puani >= bina["fiyat"]:
		gelecek_puani -= bina["fiyat"]
		saniye_basina_uretim += bina["gelir"]
		bina["adet"] += 1
		
		bina_yarat(bina_id, bina["adet"])
		
		bina["fiyat"] = int(bina["fiyat"] * 1.15)
		buton_yazisini_guncelle(bina_id)
		
		if bina["adet"] >= bina["maks_adet"]:
			buton.disabled = true
		
		update_ui()
		oyun_bitme_kontrolu()
	else:
		# 3. PUAN YETMEDİĞİNDE ÇALIŞACAK KISIM:
		hata_mesaji_goster("Yeterli gelecek puanınız yok!")

func buton_yazisini_guncelle(bina_id):
	var bina = binalar[bina_id]
	var buton = butonlar[bina_id]
	
	var satir_1 = ""
	
	# Eğer bina maksimum adede ulaştıysa fiyatı yazma, "Maksimum" yaz.
	if bina["adet"] >= bina["maks_adet"]:
		satir_1 = bina["isim"] + " (Maksimum) [" + str(bina["adet"]) + "/" + str(bina["maks_adet"]) + "]"
	else:
	# Henüz sınır dolmadıysa normal fiyatlı halini yaz.
		satir_1 = bina["isim"] + " (" + str(bina["fiyat"]) + " P) [" + str(bina["adet"]) + "/" + str(bina["maks_adet"]) + "]"
	
	var satir_2 = "Tık: +" + str(bina["tik_degeri"]) + " | San: +" + str(bina["gelir"])
	
	buton.text = satir_1 + "\n" + satir_2

func bina_yarat(bina_id, kacinci_bina):
	var bina_verisi = binalar[bina_id]
	var yeni_bina = house_scene.instantiate()
	
	var ekran_genisligi = 1152 
	var magaza_genisligi = 250 
	var oyun_alani_merkezi = magaza_genisligi + (ekran_genisligi - magaza_genisligi) / 2
	
	var bina_arasi_mesafe = bina_verisi["bosluk_x"]
	var toplam_satir_genisligi = (bina_verisi["maks_adet"] - 1) * bina_arasi_mesafe
	var baslangic_x = oyun_alani_merkezi - (toplam_satir_genisligi / 2)
	
	var x_pozisyonu = baslangic_x + ((kacinci_bina - 1) * bina_arasi_mesafe)
	var y_pozisyonu = bina_verisi["satir_y"]
	
	yeni_bina.position = Vector2(x_pozisyonu, y_pozisyonu)
	yeni_bina.building_name = bina_verisi["isim"]
	yeni_bina.building_texture = bina_verisi["tex"]
	yeni_bina.click_value = bina_verisi["tik_degeri"] 
	
	# Binayı kendi adındaki bir gruba ekliyoruz (örn: "kulube" grubu)
	yeni_bina.add_to_group(bina_id)
	
	add_child(yeni_bina)

func oyun_bitme_kontrolu():
	var hepsi_tamam_mi = true
	for bina_id in binalar.keys():
		if binalar[bina_id]["adet"] < binalar[bina_id]["maks_adet"]:
			hepsi_tamam_mi = false
			break
			
	if hepsi_tamam_mi:
		btn_oyunu_bitir.visible = true

func win_game():
	win_screen.visible = true
	# Kazanma ekranında üretimi durdurmak istersen:
	saniye_basina_uretim = 0

func _on_btn_kulube_pressed():
	satin_al("kulube")

func _on_btn_ev_pressed():
	satin_al("ev")

func _on_btn_ilkokul_pressed():
	satin_al("ilkokul")

func _on_btn_hastane_pressed():
	satin_al("hastane")

func _on_btn_universite_pressed():
	satin_al("universite")

func _on_btn_oyunu_bitir_pressed():
	win_game()

func _on_muzik_slider_value_changed(value):
	# Slider'dan gelen 0 ile 1 arasındaki değeri, Godot'nun Desibel (dB) sistemine çevirir
	AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(value))

func _on_ses_efekti_slider_value_changed(value):
	AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(value))


func _on_ana_menu_butonu_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")

func bonus_satin_al(bonus_id) -> bool:
	# 1. Sözlükten ilgili bonus verisini çekiyoruz
	var bonus = bonuslar[bonus_id]
	var hedef_bina_id = bonus["hedef"]
	var hedef_bina_verisi = binalar[hedef_bina_id]
	
	# 2. Kontroller: Zaten alınmış mı veya puan yetiyor mu?
	if bonus["alindi"] == true:
		return false
		
	if gelecek_puani >= bonus["fiyat"]:
		# 3. SATIN ALMA BAŞARILI: Puanı düş ve bonusu işaretle
		gelecek_puani -= bonus["fiyat"]
		bonus["alindi"] = true
		
		# 4. DEĞERLERİ KATLA: Mağazadaki binanın hem tık hem saniye gelirini çarpanla çarp
		hedef_bina_verisi["gelir"] *= bonus["carpan"]
		hedef_bina_verisi["tik_degeri"] *= bonus["carpan"]
		
		# 5. TOPLAM ÜRETİMİ YENİDEN HESAPLA: 
		# Mevcut binaların yeni gelirleriyle toplam saniye başı üretimi güncelliyoruz.
		saniye_basina_uretim = 0
		for b_id in binalar.keys():
			saniye_basina_uretim += binalar[b_id]["adet"] * binalar[b_id]["gelir"]
			
		# 6. SAHNEDEKİ BİNALARI GÜNCELLE: 
		# Ekranda halihazırda duran binaların (örn: tüm kulübelerin) tık gücünü anında artırır.
		for bina in get_tree().get_nodes_in_group(hedef_bina_id):
			bina.click_value = hedef_bina_verisi["tik_degeri"]
			
		# 7. ARAYÜZÜ PARLAT: Mağaza butonundaki "Tık" ve "San" yazılarını yeni değerlerle güncelle
		buton_yazisini_guncelle(hedef_bina_id)
		update_ui()
		
		return true # İşlem başarıyla bitti, sinyale 'evet' cevabı gönder
		
	else:
		# 8. PUAN YETMEDİĞİNDE: Oyuncuya kırmızı hata mesajını göster
		hata_mesaji_goster("Bonus için yeterli puanınız yok!")
		return false # İşlem başarısız, sinyale 'hayır' cevabı gönder

func hata_mesaji_goster(mesaj: String):
	hata_mesaji.text = mesaj
	hata_mesaji.visible = true
	
	# Eski zamanlayıcıları temizlemek yerine basitçe bir 'await' kullanalım
	# 2 saniye bekle ve sonra yazıyı kapat
	await get_tree().create_timer(0.5).timeout
	hata_mesaji.visible = false

func _on_btn_bonus_kulube_pressed():
	if bonus_satin_al("kulube_x2"):
		%BtnBonusKulube.text = "Satın Alındı"
		%BtnBonusKulube.disabled = true

func _on_btn_bonus_ev_pressed():
	if bonus_satin_al("ev_x2"):
		%BtnBonusEv.text = "Satın Alındı"
		%BtnBonusEv.disabled = true

func _on_btn_bonus_ilkokul_pressed():
	if bonus_satin_al("ilkokul_x2"):
		%BtnBonusIlkokul.text = "Satın Alındı"
		%BtnBonusIlkokul.disabled = true

func _on_btn_bonus_hastane_pressed():
	if bonus_satin_al("hastane_x2"):
		%BtnBonusHastane.text = "Satın Alındı"
		%BtnBonusHastane.disabled = true

func _on_btn_bonus_universite_pressed():
	if bonus_satin_al("universite_x2"):
		%BtnBonusUniversite.text = "Satın Alındı"
		%BtnBonusUniversite.disabled = true
