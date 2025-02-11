-- acid
--
-- tb-303-style sequencer
-- for crow + x0x-heart + grid
--

-- influenced by Julian Schmidt’s “analysis of the µpd650c-133 cpu timing”
-- http://sonic-potions.com/Documentation/Analysis_of_the_D650C-133_CPU_timing.pdf
--
-- designed for use with the open source x0x-heart + pacemaker
-- http://openmusiclabs.com/projects/x0x-heart


fileselect = require "fileselect"
textentry= require "textentry"
save_load = include "acid/lib/save_load"
include "acid/lib/globals"

s = require 'sequins'
new_data_loaded = false

local g = grid.connect()

local function wrap_index(s, ix) return ((ix - 1) % s.length) + 1 end

context = {
  -- 6 clock pulses per step
  pulse   = s{1,2,3,4,5,6},

  -- 16-step pattern pattern playback
  length  = 16,
  range   = s{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},

  -- pattern data
  note    = s{ 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 },
  gate    = s{ 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 },
  accent  = s{ 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 },
  slide   = s{ 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 },
  octave  = s{ 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 },        

  -- current step
  currstep = 1,

  -- editing
  cursor = 1,

  -- playback
  running = false
}
--params
params:add_group("acid steps",3)

params:add{
  type="number", id = "step_amt", name = "step amout",min=1, max=8, default = 1,
  action=function(x) 
  end
}

params:add{
  type="number", id = "step_start", name = "step start",min=1, max=16, default = 1,
  action=function(x) 
    local step_end = params:get("step_end")
    if x > step_end then params:set("step_start",step_end) end
  end
}

params:add{
  type="number", id = "step_end", name = "step end",min=1, max=16, default = 16,
  action=function(x) 
    local step_start = params:get("step_start")
    if x < step_start then params:set("step_end",step_start) end
  end
}

params:add_trigger("step_amt_trg", "> apply step amount")
params:set_action("step_amt_trg", function(x) 
  local step_amt = params:get("step_amt")
  context.range:step(step_amt)
  context.note:step(step_amt)
  context.gate:step(step_amt)
  context.accent:step(step_amt)
  context.slide:step(step_amt)
  context.octave:step(step_amt)
end)
params:hide("step_amt_trg")

params:add_trigger("step_start_trg", "> apply step start")
params:set_action("step_start_trg", function(x) 
  local step = params:get("step_start")
  context.range:select(step)
  context.note:select(step)
  context.gate:select(step)
  context.accent:select(step)
  context.slide:select(step)
  context.octave:select(step)
end)
params:hide("step_start_trg")


-- params:add_trigger("step_end_trg", "> apply step end")
-- params:set_action("step_end_trg", function(x) 
--   local step = params:get("step_end")
--   context.range:select(step)
--   context.note:select(step)
--   context.gate:select(step)
--   context.accent:select(step)
--   context.slide:select(step)
--   context.octave:select(step)
-- end)


function check_pulse1_step_params()
  
end

function check_pulse6_step_params()
  if context.range.ix + context.range.n - 1 >= params:get("step_end") then
    params:set("step_amt_trg",1)
    params:set("step_start_trg",1)
  end

end

--crow
local function crow_send_cv(volts)
  crow.output[1].volts = volts
end
local function crow_send_gate_on()
  crow.output[2].volts = 5
end
local function crow_send_gate_off()
  crow.output[2].volts = 0
end
local function crow_send_accent_on()
  crow.output[3].volts = 5
end
local function crow_send_accent_off()
  crow.output[3].volts = 0
end
local function crow_send_slide_on()
  crow.output[4].volts = 5
end
local function crow_send_slide_off()
  crow.output[4].volts = 0
end

-- TODO add MIDI out support
local send_cv = crow_send_cv
local send_gate_on = crow_send_gate_on
local send_gate_off = crow_send_gate_off
local send_accent_on = crow_send_accent_on
local send_accent_off = crow_send_accent_off
local send_slide_on = crow_send_slide_on
local send_slide_off = crow_send_slide_off

function jump_to_step(n)
  context.pulse:select(n)
  context.range:select(n)
  context.note:select(n)
  context.gate:select(n)
  context.accent:select(n)
  context.slide:select(n)
  context.octave:select(n)
end

local function send_transport_rewind_and_start()
  jump_to_step(1)
  context.running = true
end
local function send_transport_pause()
  context.running = false
  send_gate_off()
end
local function send_transport_continue()
  context.running = true
end


local function on_pulse()
  if not context.running then
    return
  end

  pulse = context.pulse()

  if pulse == 1 then
    check_pulse1_step_params()
    context.currstep = context.range()

    send_cv(
      (24 + (context.note() + (context.octave() * 12))) / 12
    )

    if context.gate() == 1 then
      send_gate_on()
    end

    if context.accent() == 1 then
      send_accent_on()
    else
      send_accent_off()
    end

    if context.slide() == 1 then
      send_slide_on()
    else
      send_slide_off()
    end
  end

  if pulse == 4 then
    local nextslide = context.slide[wrap_index(context.slide, context.slide.ix + 1)]
    local nextgate = context.gate[wrap_index(context.gate, context.gate.ix + 1)]

    if nextslide == 0 then
      send_gate_off()
    end
  end

  if pulse == 6 then
    check_pulse6_step_params()
  end
end

function gridredraw()
  g:all(0)

  -- start/end
  for n in pairs(context.range.data) do
    g:led(n, 1, 3)
  end

  -- playing pos
  g:led(context.currstep, 1, 5)

  -- editing pos
  g:led(context.cursor, 1, 8)

  -- gate/accent
  for n = 1, 16 do
    local v = 2
    if context.accent[n] == 1 then
      v = 12
    elseif context.gate[n] == 1 then
      v = 5
    else
      v = 0
    end
    g:led(n, 2, v)
  end

  -- slide
  for n = 1, 16 do
    if context.slide[n] == 1 then g:led(n, 3, 5) end
  end

  -- up
  for n = 1, 16 do
    g:led(n, 4, context.octave[n] == 1 and 5 or 0)
  end

  -- down
  for n = 1, 16 do
    g:led(n, 5, context.octave[n] == -1 and 5 or 0)
  end

  local selection = context.note[context.cursor]

  -- keys
  local r = 8
  g:led(1, r, selection == 0 and 5 or 2)
   g:led(2, r-1, selection == 1 and 5 or 2)
  g:led(3, r, selection == 2 and 5 or 2)
   g:led(4, r-1, selection == 3 and 5 or 2)
  g:led(5, r, selection == 4 and 5 or 2)
  g:led(6, r, selection == 5 and 5 or 2)
    g:led(7, r-1, selection == 6 and 5 or 2)
  g:led(8, r, selection == 7 and 5 or 2)
    g:led(9, r-1, selection == 8 and 5 or 2)
  g:led(10, r, selection == 9 and 5 or 2)
   g:led(11, r-1, selection == 10 and 5 or 2)
  g:led(12, r, selection == 11 and 5 or 2)
  g:led(13, r, selection == 12 and 5 or 2)

  -- -- step left/right
  -- g:led(15, 6, 5)
  -- g:led(16, 6, 5)

  -- meta
  g:led(16, r, 5)

  g:refresh()
end

function key(n,z)
  if n == 2 and z == 1 then
    send_transport_rewind_and_start()
  end
  if n == 3 and z == 1 then
    if context.running then
      send_transport_pause()
    else
      send_transport_continue()
    end
    redraw()
  end
end

function g.key(x, y, z)
  if x == 16 and y == 8 then
    if z == 1 then
      context.meta = true
    else
      context.meta = false
    end
  end

  -- toggle gate/accent
  if y == 2 and z == 1 then
    -- if meta key is down
    if context.meta then
      -- clear immediately
      context.accent[x] = 0
      context.gate[x] = 0

    else
      if context.accent[x] == 1 then
        context.accent[x] = 0
        context.gate[x] = 0
      elseif context.gate[x] == 1 then
        context.accent[x] = 1
        context.gate[x] = 1
      else 
        context.gate[x] = 1
      end
    end

    -- update the cursor loc
    context.cursor = x
  end

  -- slide
  if y == 3 and z == 1 then
    if context.slide[x] == 1 then
      context.slide[x] = 0
    else
      context.slide[x] = 1
    end

    -- update the cursor loc
    context.cursor = x
  end

  -- up
  if y == 4 and z == 1 then
    if context.octave[x] == 1 then
      context.octave[x] = 0
    else
      context.octave[x] = 1
    end

    -- update the cursor loc
    context.cursor = x
  end
  -- down
  if y == 5 and z == 1 then
    if context.octave[x] == -1 then
      context.octave[x] = 0
    else
      context.octave[x] = -1
    end

    -- update the cursor loc
    context.cursor = x
  end

  -- select cursor
  if y == 1 and z == 1 then
    context.cursor = x
  end

  -- note input
  if z == 1 then
    if x == 1 and y == 8 then context.note[context.cursor] = 0 end
    if x == 2 and y == 7 then context.note[context.cursor] = 1 end
    if x == 3 and y == 8 then context.note[context.cursor] = 2 end
    if x == 4 and y == 7 then context.note[context.cursor] = 3 end
    if x == 5 and y == 8 then context.note[context.cursor] = 4 end
    if x == 6 and y == 8 then context.note[context.cursor] = 5 end
    if x == 7 and y == 7 then context.note[context.cursor] = 6 end
    if x == 8 and y == 8 then context.note[context.cursor] = 7 end
    if x == 9 and y == 7 then context.note[context.cursor] = 8 end
    if x == 10 and y == 8 then context.note[context.cursor] = 9 end
    if x == 11 and y == 7 then context.note[context.cursor] = 10 end
    if x == 12 and y == 8 then context.note[context.cursor] = 11 end
    if x == 13 and y == 8 then context.note[context.cursor] = 12 end
  end

  gridredraw()
  redraw()
end

function redraw()
  screen.clear()

  screen.aa(1)

  -- screen.move(0, 7)
  -- screen.font_size(10)
  -- screen.font_face(17)
  -- screen.text("ACID")
  -- screen.close()

  screen.aa(1)
  screen.line_width(1)

  screen.level(15)
  screen.move(80, 32)
  screen.circle(64, 32, 16)
  screen.level(15)
  screen.fill()
  screen.close()

  screen.aa(1)
  screen.line_width(1.75)
  screen.level(0)
  screen.arc(64, 32, 10, (math.pi*2) + 0.15, (math.pi*3) - 0.15)
  screen.stroke()
  screen.close()

  screen.move(59, 24)
  screen.line(59, 31)
  screen.stroke()
  screen.close()

  screen.move(69, 24)
  screen.line(69, 31)
  screen.stroke()
  screen.close()

  screen.aa(0)

  screen.move(0, 63)
  if context.running then
    screen.level(15)
    screen.text("RESTART")
  else
    screen.level(6)
    screen.text("START")
  end

  screen.level(6)
  if context.running then
    screen.level(6)
    screen.move(86, 63)
    screen.text("STOP")
    screen.move(105, 63)
    screen.text("/")
    -- screen.level(15)
    screen.move(111, 63)
    screen.text("CONT")
  else
    screen.level(15)
    screen.move(86, 63)
    screen.text("STOP")
    screen.move(105, 63)
    screen.text("/")
    -- screen.level(6)
    screen.move(111, 63)
    screen.text("CONT")
  end

  if norns.crow.connected() then
    screen.level(15)
  else
    screen.level(2)
  end
  screen.move(121, 5)
  screen.text("^^")

  screen.update()
end

function init()
  save_load.init()
  clock.run(
  function()
    while true do
      clock.sync(1/24)
      on_pulse()
      gridredraw()
      redraw()
    end
  end
  )
end
