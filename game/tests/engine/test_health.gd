extends GutTest
## Health bookkeeping.

var _health: Health


func before_each() -> void:
	_health = Health.new()
	watch_signals(_health)
	_health.setup(100)


func test_setup_reports_full_health() -> void:
	assert_signal_emitted_with_parameters(_health, "changed", [100, 100])
	assert_false(_health.is_dead())


func test_damage_reduces_current_and_reports_it() -> void:
	_health.take_damage(30)
	assert_eq(_health.current, 70)
	assert_signal_emitted_with_parameters(_health, "changed", [70, 100])
	assert_signal_not_emitted(_health, "depleted")


func test_health_never_goes_below_zero_and_depletes_once() -> void:
	_health.take_damage(60)
	_health.take_damage(60)
	_health.take_damage(10)
	assert_eq(_health.current, 0)
	assert_true(_health.is_dead())
	assert_signal_emit_count(_health, "depleted", 1)
	assert_signal_emit_count(_health, "changed", 3, "setup + two damaging hits; hits on the dead are ignored")
