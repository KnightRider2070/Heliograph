extends RefCounted

var assertion_count: int = 0
var failures: Array[String] = []
var _current_test: String = ""


func suite_name() -> String:
	return get_script().resource_path.get_file()


func run() -> void:
	pass


func start_test(name: String) -> void:
	_current_test = name


func expect_true(value: bool, message: String = "expected true") -> void:
	assertion_count += 1
	if not value:
		_record_failure(message)


func expect_false(value: bool, message: String = "expected false") -> void:
	assertion_count += 1
	if value:
		_record_failure(message)


func expect_equal(actual: Variant, expected: Variant, message: String = "") -> void:
	assertion_count += 1
	if actual != expected:
		var detail := message if not message.is_empty() else "expected %s, got %s" % [expected, actual]
		_record_failure(detail)


func expect_approx(actual: float, expected: float, tolerance: float = 0.0001, message: String = "") -> void:
	assertion_count += 1
	if absf(actual - expected) > tolerance:
		var detail := message if not message.is_empty() else "expected %f +/- %f, got %f" % [expected, tolerance, actual]
		_record_failure(detail)


func expect_vector_approx(
	actual: Vector2,
	expected: Vector2,
	tolerance: float = 0.0001,
	message: String = ""
) -> void:
	assertion_count += 1
	if not actual.is_equal_approx(expected) and actual.distance_to(expected) > tolerance:
		var detail := message if not message.is_empty() else "expected %s, got %s" % [expected, actual]
		_record_failure(detail)


func _record_failure(message: String) -> void:
	var prefix := _current_test if not _current_test.is_empty() else "unnamed test"
	failures.append("%s: %s" % [prefix, message])
