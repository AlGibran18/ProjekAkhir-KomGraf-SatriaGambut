# tools/tool_enums.gd - Definisi enumerasi tipe alat pemadam, kategori risiko PFVI, dan fase permainan Satria Gambut.
class_name ToolEnums
extends RefCounted

enum ToolType {
	NONE,
	SEKAT_BAKAR,
	SEMPROT_PERMUKAAN,
	TOMBAK_GAMBUT,
	MODE_THERMAL
}

enum RiskCategory {
	RENDAH,
	SEDANG,
	TINGGI,
	EKSTREM
}

enum GamePhase {
	PLANNING,
	ACTIVE_FPS,
	PAUSED,
	VICTORY,
	DEFEAT
}
