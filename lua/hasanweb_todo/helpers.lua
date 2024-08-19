local Path = require("plenary.path")
local helpers = {}

helpers.stop_all_playback = function()
  -- Command to stop all instances of the audio player; adjust as needed for your system
  os.execute("pkill -f 'play'") -- This will stop any process running `play`
end

helpers.play_audio = function(file_path)
  -- Play the audio file in the background
  os.execute("play " .. file_path .. " > /dev/null 2>&1 &")
end

helpers.get_file_paths = function(directory)
  local paths = {}
  local handle = io.popen('ls -p "' .. directory .. '" | grep -v /') -- List files only
  local file_list = handle:read("*a")
  handle:close()

  for file in file_list:gmatch("[^\r\n]+") do
    table.insert(paths, directory .. "/" .. file)
  end

  return paths
end

helpers.get_random_path = function(paths)
  if #paths == 0 then
    return nil
  end
  -- Seed the random number generator
  math.randomseed(os.time())
  return paths[math.random(#paths)]
end

helpers.get_folder_name = function(folder, path)
  local parts = {}
  for part in string.gmatch(folder, "[^/]+") do
    table.insert(parts, part)
  end
  return parts[#parts]
end

-- Get the list of folders (dates)
helpers.get_folders_name = function(folder_name)
  if folder_name == nil then
    folder_name = ""
  end

  local path = Todos_directory .. "/" .. folder_name

  local handle = io.popen("ls -d " .. path .. "/*/")
  result = handle:read("*a")
  handle:close()

  local folders = {}
  for folder in string.gmatch(result, "[^\n]+") do
    local folder_name = helpers.get_folder_name(folder, path)
    table.insert(folders, folder_name)
  end

  return folders
end

-- Get lines of a markdown file
helpers.get_md_file_lines = function(md_file_path)
  local lines = {}
  for line in io.lines(md_file_path) do
    table.insert(lines, line)
  end
  return lines
end

-- Write updated content to the markdown file
helpers.write_md_file = function(md_file_path, lines)
  local file = io.open(md_file_path, "w")
  for _, line in ipairs(lines) do
    file:write(line .. "\n")
  end
  file:close()
end

-- check if todo.md file exists
helpers.check_md_file_exists = function(md_file_path, selection)
  local md_file = Path:new(md_file_path)
  if not md_file:exists() then
    md_file:touch({ parents = true }) -- Create the file
    print("Created todo.md in " .. selection[1])
  end
end

helpers.check_if_folder_exists = function(new_folder, path)
  if new_folder:exists() then
    print("Folder already exists: " .. helpers.get_folder_name(new_folder:expand(), path))
  else
    new_folder:mkdir()
    print("Folder created: " .. helpers.get_folder_name(new_folder:expand(), path))
  end
end

return helpers
