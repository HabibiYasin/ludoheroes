extends RefCounted

const SKILL_TEXT := {
	"Brilia": "Menyerang semua musuh yang memenuhi jangkauan di depan dan belakang.",
	"Suki": "Menyerang satu musuh. Target otomatis adalah musuh dengan HP terendah.",
	"Mordian": "Memberi diri sendiri Shield: menahan satu serangan biasa berapa pun damagenya. Tidak menumpuk dan tidak memiliki batas giliran. Damage skill melewatinya.",
	"Anata": "Memberi Shield kepada satu teman acak tanpa Shield dalam jangkauan. Jika tidak ada, memilih diri sendiri bila belum memiliki Shield.",
	"Kaelgrave": "Memberi Stun kepada maksimal dua musuh di depan; otomatis memilih yang terdekat.",
	"Nyssara": "Hidden selama 1 turn: tidak dapat ditarget lawan. Serangan biasa berikutnya memukul dua kali dan membuka Hidden.",
	"Vilmira": "Memberi Bleed kepada satu musuh: 1–3 langkah kehilangan 1 HP, 4–6 langkah kehilangan 2 HP, maksimal 3 HP untuk gerakan lebih panjang. Bukan Cursed.",
	"Zyrella": "Maju tepat tiga petak, tanpa tambahan gerak dari dadu, item, atau kelas Runner.",
	"Silvy": "Menyerang maksimal tiga musuh di depan, dimulai dari yang terdekat.",
	"Garruk": "Memberi 2 poin Nature Shield ke diri sendiri, maksimal total 4. Menyerap damage serangan biasa setelah defense, tanpa Stun. Habis saat giliran pemilik berikutnya dimulai.",
	"Pirunrun": "Menyerang dua musuh acak yang berbeda dengan damage magical.",
	"Mycellia": "Memberi 4 poin Nature Shield kepada teman terdekat, maksimal total 4. Menyerap damage serangan biasa, tanpa Stun. Habis saat giliran pemilik berikutnya dimulai.",
	"Skalfin": "Memukul satu musuh dua kali. Setiap pukulan memiliki peluang 50% mendapat tambahan 1 damage.",
	"Octavus": "Menyerang maksimal empat musuh acak yang berbeda dengan damage magical.",
	"Velissa": "Memberi Drown kepada satu musuh acak. Selama aktif, hero kehilangan 1 HP di akhir giliran pemilik jika tidak bergerak.",
	"Kragor": "Melintas lurus sejauh empat petak melewati belokan. Hanya tersedia jika ada petak tujuan valid yang lebih jauh di jalur menuju finish.",
}

const ARTICLES := {
	"Peraturan": "TUJUAN PERMAINAN\nBawa hero dari base menuju finish sambil menghadapi hero lawan. Setiap faksi memiliki empat hero dengan atribut dan skill berbeda.\n\nDADU DAN GERAK\nDua dadu digunakan dalam satu giliran. Pilih dadu lalu hero yang dapat bergerak. Nilai 6 dapat memanggil hero dari base; pasangan dadu dengan jumlah 6 juga dapat digunakan untuk summon.\n\nPERTEMPURAN\nSerangan biasa terjadi saat hero mendarat dan memiliki target sesuai kelasnya. Petak aman melindungi dari serangan; skill ofensif juga tidak dapat digunakan dari petak aman atau menarget petak aman. Hero yang kalah kembali ke base dan memulihkan HP.",
	"Giliran": "RONDE DAN GILIRAN\nPenanda A1, A2, dan seterusnya menunjukkan perkembangan ronde. Setiap pemilik mendapat giliran menggunakan dua dadu.\n\nDURASI STATUS\nSemua status berdurasi berkurang saat giliran pemilik hero yang terkena dimulai. Efek 1 turn pada giliran Thornvale di A4 habis saat giliran Thornvale dimulai di A5. Efek 2 turn habis pada giliran pemilik kedua berikutnya.\n\nCOOLDOWN SKILL\nCooldown menghitung giliran penuh yang dilewati. Skill CD 1 dipakai di A1: terkunci sepanjang A2, tersedia di A3. CD 2 tersedia di A4. Kematian tidak menghapus cooldown.",
	"Kelas Hero": "WARRIOR\nDapat menyerang petak pendaratan serta satu petak di depan atau belakang.\n\nRANGER\nDapat menyerang petak pendaratan serta satu atau dua petak di depan.\n\nASSASSIN\nMemprioritaskan musuh dengan HP terendah untuk serangan biasa.\n\nTANK\nMengurangi 1 damage dari serangan biasa yang tidak berada di petak yang sama.\n\nSUPPORT\nMemulihkan 1 HP teman di petak yang dimasuki.\n\nRUNNER\nTambahan satu langkah untuk dadu 1, 2, atau 3 di jalur bersama. Bonus gerak tidak berlaku saat masuk jalur finish.\n\nMAGE\nPeriksa detail skill tiap hero untuk jangkauan dan jenis damagenya.",
	"Skill": "AKTIVASI\nGunakan dadu yang sesuai pada hero untuk membuka tombol buku. Skill menggantikan gerakan dadu tersebut. Jangkauan 0/0 berarti skill diri sendiri.\n\nMEMILIH TARGET\nKlik buku untuk target otomatis. Tahan buku untuk memilih target melalui lingkaran hero, kemudian konfirmasi. Membatalkan pilihan tidak menghabiskan dadu.\n\nDAMAGE\nSkill damage menambahkan atribut Skill Damage pada setiap pukulan. Damage physical memakai Physical Defense; damage magical memakai Magical Defense. Shield dan Nature Shield tidak menahan damage skill.\n\nPRESENTASI\nSetiap skill menampilkan hero dan nama skill. Skill damage dilanjutkan ke arena dengan semua target dan angka damage.",
	"Equipment": "MENDAPATKAN ITEM\nMendarat di petak item menawarkan dua equipment. Pilih melalui kotak nama, gambar, deskripsi, atau dua ikon di kontrol kanan. Jika waktu habis, pilihan dilakukan otomatis.\n\nDUA JENIS ITEM\nHero dapat menyimpan maksimal dua jenis equipment. Item yang sama dapat menumpuk dan menambah atributnya lagi. Jika kedua jenis sudah terisi, hadiah berikutnya menambah salah satu item yang dimiliki.\n\nSETELAH KALAH\nEquipment tetap tersimpan saat hero kembali ke base. Heart of Gaia meningkatkan HP maksimum, tetapi tidak langsung menyembuhkan HP saat diperoleh.",
	"Status": "BUFF\nShield: menahan satu serangan biasa tanpa batas giliran; tidak menumpuk.\nNature Shield: maksimal 4 poin penyerapan damage setelah defense, bertahan 1 turn, tanpa Stun atau pantulan.\nHidden: tidak dapat ditarget lawan; serangan biasa membuka Hidden.\n\nDEBUFF\nStun: menghalangi gerak dan penggunaan skill selama aktif.\nFrozen: menghalangi gerak; pecah saat gerak legal mencapai minimal 6.\nBleed: 1 HP per 2 langkah, maksimal 3; skill Vilmira menggunakan aturan khusus di detail hero.\nConfused: setiap langkah dapat maju atau mundur secara acak.\nThorned: langkah di atas 3 menimbulkan damage sebesar kelebihannya.\nDrown: kehilangan 1 HP di akhir giliran bila tidak bergerak.\nSlowed: mengurangi gerak 1.\nCursed: dapat dibersihkan oleh dadu 4; mati setelah empat giliran pemilik tanpa mendapatkannya.\n\nDURASI\nStatus berdurasi habis saat giliran pemilik berikutnya dimulai sesuai jumlah turn. Termasuk Stun 1 turn: hilang sebelum hero bertindak pada giliran berikutnya. Status hilang saat hero kalah.",
}

static func hero_texture(id: String) -> Texture2D:
	return load("res://Arts/Textures_Game/Pieces/%s.png" % ("Brillia" if id == "Brilia" else id))

static func skill_description(id: String) -> String:
	var data: Dictionary = preload("res://Scripts/SkillCatalog.gd").get_skill(id)
	var text: String = SKILL_TEXT.get(id, "")
	if data.has("damage"):
		text += "\n\nDamage dasar: %d per pukulan." % data.damage
	if data.has("duration") and data.effect not in ["nature", "thornhide"]:
		text += "\nDurasi: %d turn." % data.duration
	return text
