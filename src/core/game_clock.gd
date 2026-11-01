class_name GameClock
extends RefCounted

## 时间与调度（契约 02 §1.4）。GameClock 不自行前进，只由 CraftUseCase.tick 调用 advance。

const MINUTES_PER_HOUR := 60  # no-magic-ok: 分钟与小时的单位换算，非策划数值

signal hour_passed(hour: float)
signal day_passed(day: int, season: int, year: int)

var year: int = 1
var season: int = 0
var day: int = 1
var minute_of_day: int = 0

var _db: ContentDatabase
var _minutes_per_day: int
var _season_days: int
var _seasons_per_year: int
var _day_start_hour: int


func _init(db: ContentDatabase) -> void:
	_db = db
	_season_days = int(db.constant("time.season_days"))
	_seasons_per_year = int(db.constant("time.seasons_per_year"))
	_day_start_hour = int(db.constant("time.day_start_hour"))
	var day_end_hour := int(db.constant("time.day_end_hour"))
	_minutes_per_day = (day_end_hour - _day_start_hour) * MINUTES_PER_HOUR


func advance(game_minutes: int) -> void:
	if game_minutes <= 0 or _minutes_per_day <= 0:
		return
	var remaining := game_minutes
	while remaining > 0:
		var to_end := _minutes_per_day - minute_of_day
		if remaining < to_end:
			minute_of_day += remaining
			remaining = 0
		else:
			remaining -= to_end
			minute_of_day = _minutes_per_day
			_advance_day()
	hour_passed.emit(current_hour())


func current_hour() -> float:
	return float(_day_start_hour) + float(minute_of_day) / float(MINUTES_PER_HOUR)


func today() -> int:
	var days_per_year := _season_days * _seasons_per_year
	return (year - 1) * days_per_year + season * _season_days + day


func real_seconds_for(game_minutes: int) -> float:
	var seconds_per_hour := float(_db.constant("time.real_seconds_per_game_hour"))
	return float(game_minutes) * seconds_per_hour / float(MINUTES_PER_HOUR)


func _advance_day() -> void:
	day += 1
	if day > _season_days:
		day = 1
		season += 1
		if season >= _seasons_per_year:
			season = 0
			year += 1
	minute_of_day = 0
	day_passed.emit(day, season, year)
