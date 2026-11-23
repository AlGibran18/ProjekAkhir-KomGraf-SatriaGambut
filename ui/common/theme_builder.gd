# ui/common/theme_builder.gd - Skrip sekali-jalan yang menyimpan tema global satria_theme.tres dari UiStyle.build_theme().
extends SceneTree

func _initialize() -> void:
	var theme: Theme = UiStyle.build_theme()
	var err: int = ResourceSaver.save(theme, "res://ui/common/satria_theme.tres")
	print("theme saved: ", err)
	quit()
