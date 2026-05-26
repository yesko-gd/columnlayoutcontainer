## Arranges child controls in a balanced vertical layout with a certain number of columns.

@tool
class_name ColumnLayoutContainer
extends Container

@export_range(1, 100, 1, "or_greater") var column_count: int = 1:
	set(value):
		column_count = value
		update_minimum_size()
		queue_sort()

@export_range(0, 100, 1, "or_greater") var hseparation: int = 0:
	set(value):
		hseparation = value
		update_minimum_size()
		queue_sort()

@export_range(0, 100, 1, "or_greater") var vseparation: int = 0:
	set(value):
		vseparation = value
		update_minimum_size()
		queue_sort()

# override

func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return

	_sort_children()

func _get_minimum_size() -> Vector2:
	var min_sizes: Array[Vector2] = []
	min_sizes.resize(column_count)
	min_sizes.fill(Vector2.ZERO)

	var child_count: int = get_child_count()
	for i in range(child_count):
		var child := get_child(i) as Control
		if not child:
			child_count -= 1
			continue

		var child_info: ChildInfo = _calculate_child_info(child_count, i)

		var min_size: Vector2 = child.get_combined_minimum_size()
		min_sizes[child_info.column].x = max(min_sizes[child_info.column].x, min_size.x)
		if child_info.vertical_index > 0:
			min_sizes[child_info.column].y += vseparation
		min_sizes[child_info.column].y += min_size.y

	var calculate_min_from_columns := func(accum: Vector2, a: Vector2) -> Vector2:
		return Vector2(accum.x + a.x, max(accum.y, a.y))

	var effective_column_count = min(column_count, child_count)
	return min_sizes.reduce(calculate_min_from_columns) + Vector2((effective_column_count - 1) * hseparation, 0)

# other

func _calculate_child_info(count: int, index: int) -> ChildInfo:
	var column: int = 0
	var temp_column_count: int = column_count
	while true:
		var shift = ceil(float(count) / temp_column_count)
		if index < shift:
			return ChildInfo.new(column, index)
		count -= shift
		index -= shift
		temp_column_count -= 1
		column += 1

	return null

func _sort_children() -> void:
	var child_count: int = get_child_count()

	var current_column: int = 0
	var next_y: float = 0
	for i in range(child_count):
		var child := get_child(i) as Control
		if not child:
			child_count -= 1
			continue

		var child_info: ChildInfo = _calculate_child_info(child_count, i)

		if child_info.column != current_column:
			current_column = child_info.column
			next_y = 0

		var effective_column_count: int = min(column_count, child_count)
		var column_width: float = (size.x - (effective_column_count - 1) * hseparation) / effective_column_count

		child.size.x = column_width

		child.position.x = child_info.column * (column_width + hseparation)
		child.position.y = next_y

		next_y += child.size.y + vseparation

# classes

class ChildInfo:
	var column: int
	var vertical_index: int

	func _init(new_column: int, new_vertical_index: int) -> void:
		column = new_column
		vertical_index = new_vertical_index
