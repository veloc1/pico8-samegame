pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
field_pixel_width = 128
field_pixel_height = 128 - 16
field_size_width = flr(field_pixel_width / 10)
field_size_height = flr(field_pixel_height / 10)

sprites = {}
highlightscoretext = nil
corutines = {}

is_input_enabled = true

score = 0

_is_ready_to_recalc = false

function _init()
	_init_sprites()

	field = {}
	for x = 1, field_size_width do
		field[x] = {}
		for y = 1, field_size_height do
			ind = flr(rnd(3) + 1)
			field[x][y] = make_gameitem(ind, x, y)
		end
	end

	game_cursor = make_gcursor(sprites[4], field_size_width, field_size_height)

	cm = make_cm(field, game_cursor)
	cm:reset()
end

function _update60()
	local has_movement = false
	if is_input_enabled then
		if (btnp(0)) then
			game_cursor:move_left()
			sfx(0)
	  has_movement = true
		elseif (btnp(1)) then
			game_cursor:move_right()
			sfx(0)
			has_movement = true
		end
		if (btnp(2)) then
			game_cursor:move_up()
			sfx(0)
			has_movement = true
		elseif (btnp(3)) then
			game_cursor:move_down()
			sfx(0)
			has_movement = true
		end
		if (btnp(4)) then
			sfx(1)
			cm:start_destroy()
			highlightscoretext = make_scoretext(0, game_cursor.x * 10, game_cursor.y * 10)
			is_input_enabled = false
		end
	end

	game_cursor:update()

	for x = 1, #field do
		for y = 1, #field[x] do
			field[x][y]:update()
		end
	end


	if (has_movement) then
		cm:reset()
	end
	cm:update()
	

	local completed = {}
	for i = 1, #corutines do
		assert(coresume(corutines[i]))
		if (costatus(corutines[i]) == "dead") then
			completed[#completed + 1] = corutines[i]
		end
	end
	for i = 1, #completed do
		del(corutines, completed[i])				
	end

	if _is_ready_to_recalc then
		_is_ready_to_recalc = false
		recalc()
		cm:reset()
		is_input_enabled = true
	end

	if highlightscoretext then
		highlightscoretext:update()
  if (highlightscoretext.is_deleted) then 
			highlightscoretext = nil
  end
	end

end

function _draw()
	cls(0)
	print("score: " .. score, 0, 0)
	print(tostr(game_cursor.x) .. " " .. tostr(game_cursor.y), 0, 128 - 8 )
	print(tostr("mem: " .. stat(0)), 30, 128 - 8)
	print(tostr("cpu: " .. stat(1)), 60, 128 - 8)
	print(tostr("c: " .. #corutines), 100, 128 - 8)
	for x = 1, #field do
		for y = 1, #field[x] do
			field[x][y]:draw()
		end
	end

	cm:draw()

	game_cursor:draw()

	if highlightscoretext then
		highlightscoretext:draw()
	end
end

function _init_sprites()
	// game objects
	sprites[1] = {1}
	sprites[2] = {16}
	sprites[3] = {32}

	sprites[5] = {3, 4, 5}
	sprites[6] = {18, 19, 20}
	sprites[7] = {34, 35, 36}

	// cursor
	sprites[4] = {48, 49}
end

function recalc()
	for x = 1, #field do
		for y = #field[x], 1, -1 do
			if field[x][y].is_destroyed and y > 1 then
			 // find not destroyed cell on top
			 local new_y = y
	 		for y2 = y - 1, 1, -1 do
	 		 if not field[x][y2].is_destroyed then
	 		 	new_y = y2
	 		 	break
	 		 end
	 		end
				swap(x, y, x, new_y)
			end
		end
	end


 for x = 1, #field - 1 do
 	local is_column_empty = true
	 for y = 1, #field[x] do	
	 	if not field[x][y].is_destroyed then
	 		is_column_empty = false
	 	end
 	end
 	if is_column_empty then 
	 	local not_empty_column = x
 		for x2 = x, #field do
 			local is_new_column_empty = true
			 for y2 = 1, #field[x2] do	
			 	if not field[x2][y2].is_destroyed then
			 		is_new_column_empty = false
		 		end
		 	end
				if not is_new_column_empty then
					not_empty_column = x2
					break
				end
 		end
 	
 		for y = 1, #field[x] do	
 			swap(x, y, not_empty_column, y)
 		end
 	end
 end

	for x = 1, #field do
		for y = 1, #field[x] do
			field[x][y]:animate_move()
		end
	end
end

function swap(x1, y1, x2, y2) 
	local tmp = field[x2][y2]
	field[x2][y2] = field[x1][y1]
	field[x1][y1] = tmp
	
	field[x1][y1].x = x1
	field[x1][y1].y = y1
	field[x2][y2].x = x2
	field[x2][y2].y = y2
end
-->8
asprite = {}
function asprite.update(self)
	self.frame_count = self.frame_count + 1
	if (self.frame_count > 60 / self.fps) then
		self.current_frame = self.current_frame + 1
		if (self.current_frame > #self.frames) then
			self.on_anim_end()
 		self.current_frame = 1
		end
		self.frame_count = 0
	end
end

function asprite.draw(self)
	spr(self.frames[self.current_frame], self.x, self.y)
end

asprite.__index = asprite

function make_sprite(frames_arr, _x, _y)
 local	self = {
		frames = frames_arr,
		current_frame = 1,
		x = _x,
		y = _y,
		fps = 2,
		frame_count = 0,
		on_anim_end = function() end
	}
	setmetatable(self, asprite)
	return self
end


// 🐱🐱🐱 gameitem 🐱🐱🐱
gameitem = {}
gameitem.__index = gameitem


function gameitem.update(self)
	if self.sprite then
		self.sprite:update()
	end
	
	if self.move_animation_started > 0 then
		local t = (time() - self.move_animation_started) / 0.5
		if (t >= 1) then
			self.move_animation_started = -1
			self.sprite.x = self.new_sprite_x
			self.sprite.y = self.new_sprite_y
			self.destroy_sprite.x = self.new_sprite_x
			self.destroy_sprite.y = self.new_sprite_y

			return
		end
		
		self.sprite.x = ease_out(t, self.old_sprite_x, self.new_sprite_x)
		self.sprite.y = ease_out(t, self.old_sprite_y, self.new_sprite_y)
		
	end
end

function gameitem.draw(self)
	if self.sprite then
		self.sprite:draw()
	end
end


function gameitem.destroy(self)
	self.sprite = self.destroy_sprite
	self.sprite.fps = 8
	self.sprite.on_anim_end = function() self.sprite = nil end
	score = score + self.score
	highlightscoretext.text = highlightscoretext.text + self.score
	highlightscoretext.created = time()
	sfx(2)
	self.is_destroyed = true
end

function gameitem.animate_move(self)
	if self.is_destroyed then
		return
	end
	if self.sprite.x == self.x * 10 - 5 and self.sprite.y == self.y * 10 then
		return
	end

	self.move_animation_started = time()
	self.old_sprite_x = self.sprite.x
	self.old_sprite_y = self.sprite.y
	self.new_sprite_x = self.x * 10 - 5
	self.new_sprite_y = self.y * 10
end

function make_gameitem(t, x, y)
	local self = {}
	self.sprite = make_sprite(sprites[t], x * 10 - 5, y * 10)
	self.destroy_sprite = make_sprite(sprites[t + 4], x * 10 - 5, y * 10)
	self.x = x
	self.y = y
	self.item_index = t
	self.is_destroyed = false
	self.move_animation_started = -1
	setmetatable(self, gameitem)
	return self
end


// 🐱🐱🐱 cursor 🐱🐱🐱
gcursor = {}

function gcursor.update(self)
	self.sprite.x = self.x * 10 - 5
	self.sprite.y = self.y * 10
	self.sprite:update()
end

function gcursor.draw(self)
	self.sprite:draw()
end

function gcursor.move_left(self)
	self.x = self.x - 1
	if (self.x <= 0) then
		self.x = self.field_width
	end
end

function gcursor.move_right(self)
	self.x = self.x + 1
	if (self.x > self.field_width) then
		self.x = 1
	end
end

function gcursor.move_up(self)
	self.y = self.y - 1
	if (self.y <= 0) then
		self.y = self.field_height
	end
end

function gcursor.move_down(self)
	self.y = self.y + 1
	if (self.y > self.field_height) then
		self.y = 1
	end
end


gcursor.__index = gcursor

function make_gcursor(frames_arr, field_w, field_h)
 local	self = {
		sprite = make_sprite(frames_arr, 0, 0),
		x = 1,
		y = 1,
		field_width = field_w,
		field_height = field_h
	}
	setmetatable(self, gcursor)
	return self
end

scoretext = {}
scoretext.__index = scoretext

function scoretext.update(self)
	self.y -= 0.1
	
	if (time() > self.created + self.lifetime) then
		self.is_deleted = true
	end
end

function scoretext.draw(self)
	print(self.text, self.x, self.y, 9)
end

function make_scoretext(t, x, y) 
	local self = {}
	self.lifetime = 1
	self.text = t
	self.x = x
	self.y = y
	self.created = time()
	self.is_deleted = false
	setmetatable(self, scoretext)
	return self
end


// 🐱🐱🐱 utils 🐱🐱🐱

function ease_out(x, from, to)
	local c1 = 1.70158
	local c3 = c1 + 1
	
	local t = 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
	
	local d = to - from
	local d2 = d * t
	return from + d2
end
-->8
candidates_manager = {}
candidates_manager.__index = candidates_manager

function candidates_manager.update(self)
	for i = 1, #self.sprites do
		self.sprites[i]:update()
	end
end

function candidates_manager.draw(self)
	for i = 1, #self.sprites do
		self.sprites[i]:draw()
	end
end

function candidates_manager.reset(self)
	self.sprites = {}

 local traversed = {}
 for x = 1, #field do
 	traversed[x] = {}
		for y = 1, #field[x] do
			traversed[x][y] = 0
		end
	end

	self.sprites =	traverse_and_create_sprites(field, self.cursor.x, self.cursor.y, field[self.cursor.x][self.cursor.y].item_index)
end

function candidates_manager.start_destroy(self)
	for i = 1, #self.sprites do
		local x = flr((self.sprites[i].x + 5) / 10)
		local y = flr(self.sprites[i].y / 10)

		local fn = function()
			local c_time = time() + 0.1 * self.sprites[i].distance
			while time() < c_time do
				yield()
			end
			field[x][y].score = self.sprites[i].distance
			field[x][y]:destroy()
		end
		local cor = cocreate(fn)
		corutines[#corutines + 1] = cor
 end
	
 local recalc_fn = function() 
 	local c_time = time() + 0.1 * self.sprites[#self.sprites].distance + 0.1
 	while time() < c_time do
	 	yield()
 	end
 	_is_ready_to_recalc = true
 	//self.sprites = {}
	 //recalc()
	 //self:reset()
 end
 local recalc_cor = cocreate(recalc_fn)
 corutines[#corutines + 1] = recalc_cor
end

function traverse_and_create_sprites(field, x, y, item_type)
	local query = {}
	local next_query = {}
	local passed = {}
	local distance = 1
	local sprites = {}
	
	query[#query + 1] = {x = x, y = y}
	
	while (#query > 0) do
		local current = query[1]
		deli(query, 1)

		local has_passed = false
		for v in all(passed) do 
			if (current.x == v.x and current.y == v.y) then
				has_passed = true
			end
		end
		
		local is_accesible = true
		if current.x <= 0 or current.x > #field or current.y <= 0 or current.y > #field[1] then
			is_accesible = false
		end

		if (not has_passed and is_accesible and field[current.x][current.y].item_index == item_type and field[current.x][current.y].is_destroyed == false) then
			sprites[#sprites + 1] = make_sprite({53}, current.x * 10 - 5, current.y * 10)
			sprites[#sprites].distance = distance
			
			passed[#passed + 1] = current
			
			next_query[#next_query + 1] = {x = current.x + 1, y = current.y}
			next_query[#next_query + 1] = {x = current.x - 1, y = current.y}
			next_query[#next_query + 1] = {x = current.x, y = current.y + 1}
			next_query[#next_query + 1] = {x = current.x, y = current.y - 1}
		end
		
		if (#query == 0) then
			distance = distance + 1
			query =  next_query
			next_query = {}
		end
		
	end
	
	return sprites
end


function traverse_recurse_and_create_sprites(field, x, y, item_type, traversed, sprites)
	if (x <= 0 or x > #field or y <= 0 or y > #field[1]) then
			return {sprites, traversed}
	end
	if (traversed[x][y] == 1) then
		return {sprites, traversed}
	end
	if (field[x][y].item_index == item_type) then
		sprites[#sprites + 1] = make_sprite({53}, x * 10 - 5, y * 10)
		traversed[x][y] = 1

		ret =	traverse_recurse_and_create_sprites(field, x - 1, y, item_type, traversed, sprites)
		ret =	traverse_recurse_and_create_sprites(field, x + 1, y, item_type, ret[2], ret[1])
		ret =	traverse_recurse_and_create_sprites(field, x, y - 1, item_type, ret[2], ret[1])
		ret =	traverse_recurse_and_create_sprites(field, x, y + 1, item_type, ret[2], ret[1])
		sprites = ret[1]
		traversed = ret[2]
	end
	return {sprites, traversed}
end

function make_cm(f, gc)
	local self = {
		sprites = {},
		field = f,
		cursor = gc
	}
	setmetatable(self, candidates_manager)
	return self
end
__gfx__
00000000008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888800000000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070088887e880000000008887e800008e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770008888ee88000000000888ee800088ee000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000888888880000000008888880008888000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700888888880000000008888880000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888800000000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001c000000000000001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001ccc00000000000001c0000001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001ccc0000000000001ccc000001cc000001c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01ccccc00000000001cccc00001ccc00001cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01ccccc00000000001ccccc0001ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1ccccccc000000001cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbbb0000000003bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbbb0000000003bbbbb0003bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbbb0000000003bbbbb0003bbb000003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbbb0000000003bbbbb0003bbb00000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbbb0000000003bbbbb000333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbbb000000000333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700777000000000000000000000000666006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000007077007700000000000000000600000060aa00aa000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000007070000700000000000000000600000060a0000a000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000007070000700000000000000000600000060a0000a000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000007077007700000000000000000600000060aa00aa000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700777000000000000000000000000666006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001d0502005023050260402803025030220301f0201d020110200f0100e0100d0100c0100e0000000000000000000100001000010000200002000020000200002000020000200002000020000200006000
00010000301502b150281502613024130231302413026130271202812029120291202c110311103211032110261002510025100241002410023100231002210021100201001f1001e1001d1001c1001b1001c100
00010000103501035010350103501031021700207002260020700217002070020700207001f7001f7001f7001f7001f7001f7001f7001f7001f70020700256002560025600246002460024600000000000000000
