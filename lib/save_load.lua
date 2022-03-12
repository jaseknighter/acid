local save_load = {}
local folder_path = norns.state.data .. "acid_data/" 
local pset_folder_path  = folder_path .. ".psets/"

function save_load.save_acid_data(name_or_path)
  if name_or_path then
    if os.rename(folder_path, folder_path) == nil then
      os.execute("mkdir " .. folder_path)
      os.execute("mkdir " .. pset_folder_path)
      os.execute("touch" .. pset_folder_path)
    end

    local save_path
    local pset_path

    if string.find(name_or_path,"/") == 1 then
      local x,y = string.find(name_or_path,folder_path)
      local filename = string.sub(name_or_path,y+1,#name_or_path-4)
      pset_path = pset_folder_path .. filename
      params:write(pset_path)
      save_path = name_or_path
    else
      pset_path = pset_folder_path .. name_or_path
      if  name_or_path ~= "cancel" then
        params:write(pset_path)
        save_path =  folder_path .. name_or_path  ..".acd"
      end
    end
    
    -- save sequence data    
    local save_object = {
      context=deep_copy(context)
    }
    tab.save(save_object, save_path)
    print("saved!")
  else
    print("save cancel")
  end
end

function save_load.remove_acid_data(path)
   if string.find(path, 'acid') ~= nil then
    local data = tab.load(path)
    if data ~= nil then
      print("sequence found to remove", path)
      os.execute("rm -rf "..path)

      local start,finish = string.find(path,folder_path)

      local data_filename = string.sub(path,finish+1)
      local start2,finish2 = string.find(data_filename,".acd")
      local pset_filename = string.sub(path,finish+1,finish+start2-1)
      local pset_path = pset_folder_path .. pset_filename
      print("pset path found",pset_path)
      os.execute("rm -rf "..pset_path)  
    else
      print("no data")
    end
  end
end

function save_load.load_acid_data(path)
  acid_data = tab.load(path)
  if acid_data ~= nil then
    print("acid data found", path)
    local start,finish = string.find(path,folder_path)

    local data_filename = string.sub(path,finish+1)
    local start2,finish2 = string.find(data_filename,".acd")
    local pset_filename = string.sub(path,finish+1,finish+start2-1)
    local pset_path = pset_folder_path .. pset_filename
    print("pset path found",pset_path)
    -- load pset
    params:read(pset_path)

    -- local last_param = params:lookup_param("last_loaded")
    -- last_param.options[1] = pset_path


    -- set sequence data
    context.range:settable(acid_data.context.range.data)
    context.note:settable(acid_data.context.note.data)
    context.gate:settable(acid_data.context.gate.data)
    context.accent:settable(acid_data.context.accent.data)
    context.slide:settable(acid_data.context.slide.data)
    context.octave:settable(acid_data.context.octave.data)
    -- new_data_loaded = true
    -- print("sequence is now loaded")

          

 else
    print("no data")
  end
end

function save_load.load_idx(idx)

end

function save_load.init()  
  
--   params:add{
--     type = "option", id = "last_loaded", name = "last loaded", 
--     options = {"nil","nil"},
--     default = 1,
--     action = function(value) 
--       local last_param = params:lookup_param("last_loaded")
--       local last_loaded = last_param.options[1]
--       print("last_loaded",last_loaded)
--   end}

  -- params:add_separator("DATA MANAGEMENT")
  params:add_group("acid data",4)

  params:add_trigger("save_acid_data", "> SAVE ACID DATA")
  params:set_action("save_acid_data", function(x) textentry.enter(save_load.save_acid_data) end)

  params:add_trigger("overwrite_acid_data", "> OVERWRITE ACID DATA")
  params:set_action("overwrite_acid_data", function(x) fileselect.enter(folder_path, save_load.save_acid_data) end)

  params:add_trigger("remove_acid_data", "< REMOVE ACID DATA")
  params:set_action("remove_acid_data", function(x) fileselect.enter(folder_path, save_load.remove_acid_data) end)

  params:add_trigger("load_acid_data", "> LOAD ACID DATA" )
  params:set_action("load_acid_data", function(x) fileselect.enter(folder_path, save_load.load_acid_data) end)


end

return save_load
