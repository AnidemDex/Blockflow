# GdUnit generated TestSuite
class_name CollectionTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/blockflow/collection.gd'

const CollectionClass = preload(__source)
const CommandClass = preload("res://addons/blockflow/commands/command.gd")

class DummyCommand extends CommandClass:
	func _get_name() -> StringName: return &"DummyCommand"

class FakeCommand extends CommandClass:
	func _get_name() -> StringName: return &"FakeCommand"

var collection:CollectionClass

func before_test() -> void:
	collection = CollectionClass.new()
	assert_array(collection.collection).is_empty()


func test_add() -> void:
	assert_array(collection.collection).is_empty()
	
	var fake_command := CommandClass.new()
	collection.add(fake_command)
	
	assert_array(collection.collection).is_not_empty().has_size(1)


func test_insert() -> void:
	assert_array(collection.collection).is_empty()
	
	var command_a := CommandClass.new()
	var command_b := CommandClass.new()
	var command_c := CommandClass.new()
	
	collection.add(command_a)
	collection.add(command_c)
	
	assert_array(collection.collection).has_size(2)\
	.contains_exactly([command_a, command_c])
	
	collection.insert(command_b, 1)
	
	assert_array(collection.collection).has_size(3)\
	.contains_exactly([command_a, command_b, command_c])
	


func test_copy() -> void:
	assert_array(collection.collection).is_empty()
	
	var dummy_command := DummyCommand.new()
	collection.add(dummy_command)
	
	for i in 10:
		var fake_command := FakeCommand.new()
		collection.add(fake_command)
	
	collection.copy(dummy_command, 8)
	assert_array(collection.collection).is_not_empty()\
	.contains([dummy_command]).has_size(12)
	
	assert_object(collection.collection[0]).is_instanceof(DummyCommand)
	assert_object(collection.collection[1]).is_not_instanceof(DummyCommand)
	assert_object(collection.collection[8]).is_instanceof(DummyCommand)


func test_move() -> void:
	for i in 10:
		collection.add(FakeCommand.new())
	
	var dummy_command := DummyCommand.new()
	collection.add(dummy_command)
	assert_array(collection.collection).is_not_empty()
	assert_bool(collection.collection.find(dummy_command) == 10).is_true()
	
	collection.move(dummy_command, 1)
	assert_bool(collection.collection.find(dummy_command) == 1).is_true()


func test_erase() -> void:
	for i in 10:
		collection.add(FakeCommand.new())
	
	assert_array(collection.collection).is_not_empty()\
	.has_size(10)
	
	collection.erase(collection.collection[-1])
	assert_array(collection.collection).is_not_empty()\
	.has_size(9)


func test_remove() -> void:
	for i in 10:
		collection.add(FakeCommand.new())
	
	assert_array(collection.collection).is_not_empty()\
	.has_size(10)
	
	collection.remove(0)
	assert_array(collection.collection).is_not_empty()\
	.has_size(9)


func test_clear() -> void:
	for i in 10:
		collection.add(FakeCommand.new())
	
	assert_array(collection.collection).is_not_empty()\
	.has_size(10)
	
	collection.clear()
	assert_array(collection.collection).is_empty()


func test_get_command() -> void:
	assert_array(collection.collection).is_empty()
	
	var command_a := CommandClass.new()
	var command_b := CommandClass.new()
	var command_c := CommandClass.new()
	
	collection.add(command_a)
	collection.add(command_b)
	collection.add(command_c)
	
	var result = collection.get_command(1)
	assert_bool(result == command_a).is_false()
	assert_bool(result == command_b).is_true()
	assert_bool(result == command_c).is_false()


func test_get_last_command() -> void:
	assert_array(collection.collection).is_empty()
	
	var command_a := CommandClass.new()
	var command_b := CommandClass.new()
	var command_c := CommandClass.new()
	
	collection.add(command_a)
	collection.add(command_b)
	collection.add(command_c)
	
	var result = collection.get_last_command()
	assert_bool(result == command_c).is_true()
	assert_bool(result == command_a).is_false()


func test_get_command_position() -> void:
	var expected_position := randi_range(0, 10)
	var dummy_command := DummyCommand.new()
	
	for i in 10:
		if i == expected_position:
			collection.add(dummy_command)
			continue
		
		collection.add(FakeCommand.new())
	
	assert_array(collection.collection).is_not_empty()\
	.has_size(10)
	
	var result = collection.get_command_position(dummy_command)
	assert_bool(result == expected_position).is_true()


func test_get_duplicated() -> void:
	for i in 10:
		collection.add(FakeCommand.new())
	var duplicated = collection.get_duplicated()
	
	assert_object(duplicated).is_not_same(collection)


func test_has() -> void:
	assert_array(collection.collection).is_empty()
	
	var command_a := FakeCommand.new()
	var command_b := FakeCommand.new()
	var command_c := FakeCommand.new()
	
	collection.add(command_a)
	collection.add(command_b)
	collection.add(command_c)
	
	assert_array(collection.collection).contains_same([command_b])
	assert_bool(collection.collection.has(command_b))
	assert_bool(collection.has(command_b))


func test_find() -> void:
	var expected_position := randi_range(0, 10)
	var dummy_command := DummyCommand.new()
	
	for i in 10:
		if i == expected_position:
			collection.add(dummy_command)
			continue
		
		collection.add(FakeCommand.new())
		
	var result := collection.find(dummy_command)
	
	assert_bool(result == expected_position).is_true()
	assert_bool(collection.find(FakeCommand.new()) != -1).is_false()

func test_size() -> void:
	assert_array(collection.collection).is_empty()
	var expected_result := randi_range(1, 20)
	for i in expected_result:
		collection.add(FakeCommand.new())
	
	assert_array(collection.collection).is_not_empty()\
	.has_size(expected_result)
	
	assert_int(collection.size()).is_equal(expected_result)


func test_is_empty() -> void:
	assert_array(collection.collection).is_empty()
	assert_bool(collection.is_empty()).is_true()
