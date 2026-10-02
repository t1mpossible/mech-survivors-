extends Node2D

const CELL_SIZE := Vector2(443.5, 443.5)

@export var atlas: Texture2D

const DECORATIONS := [
	[Vector2(78, 72), 0, Vector2(38, 27), -0.12], [Vector2(248, 116), 2, Vector2(31, 24), 0.34],
	[Vector2(478, 61), 1, Vector2(49, 29), -0.08], [Vector2(720, 134), 0, Vector2(43, 30), 0.27],
	[Vector2(1048, 79), 3, Vector2(38, 35), 0.13], [Vector2(1363, 126), 2, Vector2(27, 22), -0.28],
	[Vector2(1535, 72), 4, Vector2(43, 33), 0.19], [Vector2(145, 271), 1, Vector2(48, 29), 0.21],
	[Vector2(350, 358), 0, Vector2(36, 26), -0.34], [Vector2(610, 263), 6, Vector2(46, 39), 0.07],
	[Vector2(887, 183), 2, Vector2(28, 22), 0.18], [Vector2(1225, 330), 5, Vector2(39, 45), -0.17],
	[Vector2(1490, 291), 0, Vector2(39, 28), 0.31], [Vector2(76, 517), 3, Vector2(37, 34), -0.21],
	[Vector2(535, 430), 1, Vector2(55, 33), 0.16], [Vector2(671, 530), 2, Vector2(38, 30), -0.24],
	[Vector2(1025, 452), 4, Vector2(52, 39), 0.31], [Vector2(1120, 570), 7, Vector2(43, 48), -0.08],
	[Vector2(259, 681), 4, Vector2(41, 31), 0.06], [Vector2(522, 762), 2, Vector2(30, 24), 0.39],
	[Vector2(747, 650), 1, Vector2(45, 27), -0.26], [Vector2(1094, 735), 7, Vector2(34, 38), 0.22],
	[Vector2(1330, 618), 6, Vector2(45, 38), -0.15], [Vector2(1518, 730), 0, Vector2(38, 27), 0.18],
	[Vector2(97, 836), 1, Vector2(45, 28), -0.11], [Vector2(358, 850), 2, Vector2(29, 23), 0.24],
	[Vector2(921, 852), 4, Vector2(45, 34), -0.18], [Vector2(1210, 835), 3, Vector2(35, 33), 0.08],
	[Vector2(1485, 850), 5, Vector2(36, 42), 0.29],
]


func _draw() -> void:
	if atlas == null:
		return
	for entry in DECORATIONS:
		var location: Vector2 = entry[0]
		var variant: int = entry[1]
		var draw_size: Vector2 = entry[2]
		var rotation_offset: float = entry[3]
		var column := variant % 4
		var row := variant / 4
		var source := Rect2(Vector2(column, row) * CELL_SIZE, CELL_SIZE)
		draw_set_transform(location, rotation_offset)
		draw_texture_rect_region(atlas, Rect2(-draw_size * 0.5, draw_size), source)
		draw_set_transform(Vector2.ZERO)
