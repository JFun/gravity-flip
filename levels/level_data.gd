## Level definitions for Gravity Flip.
## Each level is a dictionary describing obstacles, stars, and length.
##
## Obstacle types:
##   "wall"          — gap_y (center of gap), gap_size (height of opening)
##   "spike_floor"   — spike on the floor
##   "spike_ceiling" — spike on the ceiling
##
## Positions are relative to level start. Y is absolute screen position.
## Corridor: ceiling at y=80, floor at y=720. Player starts mid-corridor (~400).
class_name LevelData


static func get_level(num: int) -> Dictionary:
	match num:
		1: return level_01()
		2: return level_02()
		3: return level_03()
		4: return level_04()
		5: return level_05()
		6: return level_06()
		7: return level_07()
		8: return level_08()
		9: return level_09()
		10: return level_10()
		_: return _generate_endless(num)


# ========================================
# ZONE 1: "First Flight" — Levels 1–10
# Teaches: tap to flip, walls, gaps, stars, spikes
# ========================================

static func level_01() -> Dictionary:
	## One wall. One wide gap. Impossible to fail.
	return {
		"name": "First Flip",
		"obstacles": [
			{"type": "wall", "x": 400, "gap_y": 400, "gap_size": 300},
		],
		"stars": [
			{"x": 400, "y": 250},  # Star above the gap — easy grab
		],
		"length": 800,
	}


static func level_02() -> Dictionary:
	## Two walls, gaps on alternating sides.
	return {
		"name": "Up and Down",
		"obstacles": [
			{"type": "wall", "x": 350, "gap_y": 250, "gap_size": 250},
			{"type": "wall", "x": 700, "gap_y": 550, "gap_size": 250},
		],
		"stars": [
			{"x": 525, "y": 400},
		],
		"length": 1100,
	}


static func level_03() -> Dictionary:
	## Three walls, tighter gaps. First 3-star level.
	return {
		"name": "Triple Threat",
		"obstacles": [
			{"type": "wall", "x": 300, "gap_y": 250, "gap_size": 220},
			{"type": "wall", "x": 600, "gap_y": 550, "gap_size": 220},
			{"type": "wall", "x": 900, "gap_y": 300, "gap_size": 220},
		],
		"stars": [
			{"x": 300, "y": 250},  # Easy — in the gap
			{"x": 750, "y": 300},  # Medium — between walls
			{"x": 950, "y": 500},  # Hard — requires detour flip just past wall
		],
		"length": 1300,
	}


static func level_04() -> Dictionary:
	## Four walls, rhythm emerges.
	return {
		"name": "Finding Rhythm",
		"obstacles": [
			{"type": "wall", "x": 250, "gap_y": 250, "gap_size": 200},
			{"type": "wall", "x": 500, "gap_y": 550, "gap_size": 200},
			{"type": "wall", "x": 750, "gap_y": 250, "gap_size": 200},
			{"type": "wall", "x": 1000, "gap_y": 550, "gap_size": 200},
		],
		"stars": [
			{"x": 375, "y": 400},
			{"x": 875, "y": 400},
		],
		"length": 1400,
	}


static func level_05() -> Dictionary:
	## Five walls, gaps getting smaller. Precision starts to matter.
	return {
		"name": "Tighten Up",
		"obstacles": [
			{"type": "wall", "x": 250, "gap_y": 300, "gap_size": 190},
			{"type": "wall", "x": 475, "gap_y": 500, "gap_size": 190},
			{"type": "wall", "x": 700, "gap_y": 250, "gap_size": 190},
			{"type": "wall", "x": 925, "gap_y": 550, "gap_size": 190},
			{"type": "wall", "x": 1150, "gap_y": 350, "gap_size": 190},
		],
		"stars": [
			{"x": 475, "y": 500},  # In the gap (gap_y=500)
			{"x": 925, "y": 550},  # In the gap (gap_y=550)
			{"x": 1100, "y": 550},  # Detour: just before wall at 1150
		],
		"length": 1500,
	}


static func level_06() -> Dictionary:
	## Spikes introduced! Ceiling only first — visible but safe.
	return {
		"name": "Watch Your Head",
		"obstacles": [
			{"type": "wall", "x": 300, "gap_y": 300, "gap_size": 220},
			{"type": "spike_ceiling", "x": 550},
			{"type": "wall", "x": 800, "gap_y": 500, "gap_size": 220},
		],
		"stars": [
			{"x": 550, "y": 500},  # Safe down low, away from spike
		],
		"length": 1200,
	}


static func level_07() -> Dictionary:
	## Spikes on both surfaces. Must flip to dodge.
	return {
		"name": "Spike Alley",
		"obstacles": [
			{"type": "spike_floor", "x": 250},
			{"type": "wall", "x": 500, "gap_y": 250, "gap_size": 200},
			{"type": "spike_ceiling", "x": 700},
			{"type": "wall", "x": 950, "gap_y": 550, "gap_size": 200},
			{"type": "spike_floor", "x": 1150},
		],
		"stars": [
			{"x": 350, "y": 200},
			{"x": 825, "y": 600},
		],
		"length": 1500,
	}


static func level_08() -> Dictionary:
	## Tighter spike + wall combos.
	return {
		"name": "Weave",
		"obstacles": [
			{"type": "spike_ceiling", "x": 200},
			{"type": "wall", "x": 400, "gap_y": 500, "gap_size": 200},
			{"type": "spike_floor", "x": 600},
			{"type": "spike_ceiling", "x": 800},
			{"type": "wall", "x": 1000, "gap_y": 300, "gap_size": 200},
			{"type": "spike_floor", "x": 1200},
		],
		"stars": [
			{"x": 400, "y": 500},  # In the gap (gap_y=500)
			{"x": 700, "y": 600},  # Between walls
			{"x": 1100, "y": 200},  # Between walls, demands a flip-up
		],
		"length": 1600,
	}


static func level_09() -> Dictionary:
	## Breather — easy, consolidation level.
	return {
		"name": "Breather",
		"obstacles": [
			{"type": "wall", "x": 400, "gap_y": 400, "gap_size": 280},
			{"type": "wall", "x": 800, "gap_y": 400, "gap_size": 280},
		],
		"stars": [
			{"x": 400, "y": 300},  # In the gap [260, 540]
			{"x": 600, "y": 400},  # Between walls
			{"x": 800, "y": 520},  # In the gap [260, 540], near bottom edge
		],
		"length": 1200,
	}


static func level_10() -> Dictionary:
	## Zone 1 Boss — long, uses everything. Unlocks Zone 2.
	return {
		"name": "Zone 1 Boss",
		"obstacles": [
			{"type": "wall", "x": 250, "gap_y": 300, "gap_size": 190},
			{"type": "spike_ceiling", "x": 450},
			{"type": "wall", "x": 650, "gap_y": 550, "gap_size": 190},
			{"type": "spike_floor", "x": 850},
			{"type": "wall", "x": 1050, "gap_y": 250, "gap_size": 180},
			{"type": "spike_ceiling", "x": 1250},
			{"type": "spike_floor", "x": 1350},
			{"type": "wall", "x": 1550, "gap_y": 500, "gap_size": 180},
			{"type": "wall", "x": 1800, "gap_y": 300, "gap_size": 170},
		],
		"stars": [
			{"x": 450, "y": 550},   # Between walls 250 and 650
			{"x": 1100, "y": 500},  # Detour: just past wall at 1050
			{"x": 1500, "y": 250},  # Detour: just before wall at 1550 — must flip up then dive into gap
		],
		"length": 2200,
	}


# ========================================
# Procedural fallback for levels > 10
# ========================================
static func _generate_endless(num: int) -> Dictionary:
	## Simple procedural generation for levels beyond hand-crafted ones.
	var obstacles := []
	var stars := []
	var rng := RandomNumberGenerator.new()
	rng.seed = num * 7919  # Deterministic per level number

	var x := 0.0
	var num_walls: int = 4 + num / 2
	var gap_size: float = maxf(140.0, 250.0 - num * 3.0)  # Gaps shrink over time

	for i in num_walls:
		x += rng.randf_range(200.0, 350.0)
		var gap_y: float = rng.randf_range(200.0, 600.0)
		obstacles.append({"type": "wall", "x": x, "gap_y": gap_y, "gap_size": gap_size})

		# Randomly add spikes after level 6
		if num >= 6 and rng.randf() > 0.5:
			var spike_x: float = x + rng.randf_range(80.0, 150.0)
			var spike_type: String = "spike_floor" if rng.randf() > 0.5 else "spike_ceiling"
			obstacles.append({"type": spike_type, "x": spike_x})

		# Place a star reachable through this wall: same x, y inside the gap
		# (gap spans gap_y ± gap_size/2). Random Y previously placed stars
		# inside the wall's solid section — physically uncollectable.
		if i % 3 == 0:
			var star_y: float = rng.randf_range(
				gap_y - gap_size * 0.4,
				gap_y + gap_size * 0.4,
			)
			stars.append({"x": x, "y": star_y})

	return {
		"name": "Level %d" % num,
		"obstacles": obstacles,
		"stars": stars,
		"length": x + 400.0,
	}
