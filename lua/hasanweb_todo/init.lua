local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local Path = require("plenary.path")

math.randomseed(os.time())

todos_directory = os.getenv("HOME") .. "/.config/nvim/lua/hasanweb_todo/todos"
success_audios_directory = os.getenv("HOME") .. "/.config/nvim/lua/hasanweb_todo/audios/success"

local keys = {
  new_folder = "<C-n>",
  a = "<C-t>",
  d = "<C-d>",
  o = "<C-o>",
  b = "<C-u>",
  l = "<C-l>",
  r = "<C-r>",
  copy = "<C-c>",
}

local function stop_all_playback()
  -- Command to stop all instances of the audio player; adjust as needed for your system
  os.execute("pkill -f 'play'") -- This will stop any process running `play`
end

local function play_audio(file_path)
  -- Play the audio file in the background
  os.execute("play " .. file_path .. " > /dev/null 2>&1 &")
end

local function get_file_paths(directory)
  local paths = {}
  local handle = io.popen('ls -p "' .. directory .. '" | grep -v /') -- List files only
  local file_list = handle:read("*a")
  handle:close()

  for file in file_list:gmatch("[^\r\n]+") do
    table.insert(paths, directory .. "/" .. file)
  end

  return paths
end

local function get_random_path(paths)
  if #paths == 0 then
    return nil
  end
  -- Seed the random number generator
  math.randomseed(os.time())
  return paths[math.random(#paths)]
end

local get_folder_name = function(folder, path)
  local parts = {}
  for part in string.gmatch(folder, "[^/]+") do
    table.insert(parts, part)
  end
  return parts[#parts]
end

-- Get the list of folders (dates)
local function get_folders_name(folder_name)
  if folder_name == nil then
    folder_name = ""
  end

  local path = todos_directory .. "/" .. folder_name

  local handle = io.popen("ls -d " .. path .. "/*/")
  result = handle:read("*a")
  handle:close()

  local folders = {}
  for folder in string.gmatch(result, "[^\n]+") do
    local folder_name = get_folder_name(folder, path)
    table.insert(folders, folder_name)
  end

  return folders
end

-- Get lines of a markdown file
local function get_md_file_lines(md_file_path)
  local lines = {}
  for line in io.lines(md_file_path) do
    table.insert(lines, line)
  end
  return lines
end

-- Write updated content to the markdown file
local function write_md_file(md_file_path, lines)
  local file = io.open(md_file_path, "w")
  for _, line in ipairs(lines) do
    file:write(line .. "\n")
  end
  file:close()
end

-- check if todo.md file exists
local function check_md_file_exists(md_file_path, selection)
  local md_file = Path:new(md_file_path)
  if not md_file:exists() then
    md_file:touch({ parents = true }) -- Create the file
    print("Created todo.md in " .. selection[1])
  end
end

local function check_if_folder_exists(new_folder, path)
  if new_folder:exists() then
    print("Folder already exists: " .. get_folder_name(new_folder:expand(), path))
  else
    new_folder:mkdir()
    print("Folder created: " .. get_folder_name(new_folder:expand(), path))
  end
end

-- Display lines from the markdown file
function List_md_file_lines(md_file_path, project_name, opts)
  opts = opts or {}
  local lines = get_md_file_lines(md_file_path)

  -- Delete all empty lines from the lines table
  for i = #lines, 1, -1 do
    if lines[i] == "" then
      table.remove(lines, i)
    end
  end

  -- Immediately write the cleaned-up lines back to the markdown file
  write_md_file(md_file_path, lines)

  pickers
    .new(opts, {
      prompt_title = "Markdown File Content",
      finder = finders.new_table({
        results = lines,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- Create a new line
        map("i", keys.new_folder, function()
          actions.close(prompt_bufnr)
          local new_line = "⏱️  " .. vim.fn.input("New line: ")
          table.insert(lines, new_line)
          write_md_file(md_file_path, lines)
          List_md_file_lines(md_file_path) -- Refresh
        end)

        -- Delete selected line
        map("i", keys.d, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          table.remove(lines, selection.index)
          write_md_file(md_file_path, lines)
          List_md_file_lines(md_file_path) -- Refresh
        end)

        -- go back
        map("i", keys.b, function()
          actions.close(prompt_bufnr)
          List_todo_dates(project_name) -- Refresh
        end)

        local function toggle_todo()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          -- Get the current date
          local current_datetime = os.date("%Y-%m-%d %I:%M:%S %p")

          -- Toggle logic for checkbox and update the date at the end of the line
          if string.match(selection.value, "%⏱️ ") then
            stop_all_playback()
            play_audio(get_random_path(get_file_paths(success_audios_directory)))
            lines[selection.index] = string.gsub(selection.value, "%⏱️ ", "✅")
              .. " (Updated: "
              .. current_datetime
              .. ")"
          elseif string.match(selection.value, "%✅") then
            lines[selection.index] = string.gsub(selection.value, "%✅", "%⏱️ ")
              .. " (Updated: "
              .. current_datetime
              .. ")"
          end

          write_md_file(md_file_path, lines)
          List_md_file_lines(md_file_path) -- Refresh
        end

        map("n", "<space>", toggle_todo)
        map("i", "<space>", toggle_todo)

        map("i", keys.r, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local updated_line = vim.fn.input("Update line: ", selection.value)

          -- Update the selected line with new content
          lines[selection.index] = updated_line
          write_md_file(md_file_path, lines)

          -- Refresh the list
          List_md_file_lines(md_file_path, project_name)
        end)

        return true
      end,
    })
    :find()
end

-- List folders and on selection, display markdown content
function List_todo_dates(project_name)
  opts = opts or {}

  local path = todos_directory .. "/" .. project_name

  pickers
    .new(opts, {
      prompt_title = "Select Date",
      finder = finders.new_table({
        results = get_folders_name(project_name),
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- Create a new folder
        map("i", keys.new_folder, function()
          actions.close(prompt_bufnr)
          local folder_name = vim.fn.input("New folder name: ")
          local new_folder = Path:new(path .. "/" .. folder_name)
          check_if_folder_exists(new_folder, path)
          List_todo_dates(project_name) -- Refresh
        end)

        -- Automatically create a folder with the format "YYYY-MM-DD"
        map("i", keys.a, function()
          actions.close(prompt_bufnr)
          local current_date = os.date("%Y-%m-%d")
          local new_folder = Path:new(path .. "/" .. current_date)

          check_if_folder_exists(new_folder, path)
          List_todo_dates(project_name) -- Refresh
        end)

        -- go back
        map("i", keys.b, function()
          actions.close(prompt_bufnr)
          List_todo_projects()
        end)

        map("i", keys.d, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local folder_path = Path:new(path .. "/" .. selection[1])

          -- Ask for confirmation before deleting
          local confirmation =
            vim.fn.input("Are you sure you want to delete this folder and all its subfolders? (y/n): ")

          if confirmation:lower() == "y" then
            -- Recursively delete the folder and all subfolders
            local command = "rm -rf " .. folder_path:absolute()
            os.execute(command)
            print("Deleted folder and all its contents.")
          else
            print("Deletion canceled.")
          end

          List_todo_dates(project_name) -- Refresh the list after deletion
        end)

        -- Open and list the markdown file inside the selected folder
        map("i", "<CR>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local md_file_path = path .. "/" .. selection[1] .. "/todo.md"

          check_md_file_exists(md_file_path, selection)

          vim.g.Last_accessed_md_file_path = md_file_path

          List_md_file_lines(md_file_path, project_name) -- Open the markdown file
        end)

        map("i", keys.o, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local md_file_path = path .. "/" .. selection[1] .. "/todo.md"

          check_md_file_exists(md_file_path, selection)

          -- Open the markdown file in a new buffer
          vim.cmd("e " .. md_file_path)
        end)

        -- Rename the selected folder, using the old folder name as the default input
        map("i", keys.r, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local old_folder_name = selection[1]
          local old_folder_path = Path:new(path .. "/" .. old_folder_name)
          local new_folder_name = vim.fn.input("New folder name: ", old_folder_name) -- Use the old name as default

          -- Rename the folder
          local new_folder_path = Path:new(path .. "/" .. new_folder_name)
          if old_folder_path:exists() then
            os.rename(old_folder_path:absolute(), new_folder_path:absolute())
            print("Renamed folder to " .. new_folder_name)
          else
            print("Folder does not exist.")
          end

          List_todo_dates(project_name) -- Refresh after renaming
        end)

        -- Copy all lines from the markdown file to the system clipboard with the current date
        map("i", keys.copy, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local md_file_path = path .. "/" .. selection[1] .. "/todo.md"

          check_md_file_exists(md_file_path, selection)

          -- Read the markdown file lines
          local lines = get_md_file_lines(md_file_path)

          -- Add the current date to the beginning of the content
          local current_date = os.date("%Y-%m-%d")
          table.insert(lines, 1, "Date: " .. current_date)

          -- Copy the content (including the date) to the system clipboard as separate lines
          vim.fn.setreg("+", lines)
          print("Copied markdown content with date to clipboard.")
        end)

        return true
      end,
    })
    :find()
end

-- List folders and on selection, display markdown content
function List_todo_projects(opts)
  opts = opts or {}

  local path = todos_directory .. "/"

  pickers
    .new(opts, {
      prompt_title = "Select a Project",
      finder = finders.new_table({
        results = get_folders_name(),
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- Create a new folder
        map("i", keys.new_folder, function()
          actions.close(prompt_bufnr)
          local folder_name = vim.fn.input("New folder name: ")
          local new_folder = Path:new(path .. folder_name)
          check_if_folder_exists(new_folder, path)
          List_todo_projects() -- Refresh
        end)

        -- Delete selected folder
        map("i", keys.d, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local folder_to_delete = Path:new(path .. selection[1])
          folder_to_delete:rmdir()
          List_todo_projects() -- Refresh
        end)

        -- Access the last opend md file
        map("i", keys.l, function()
          List_md_file_lines(vim.g.Last_accessed_md_file_path, vim.g.Last_accessed_project)
        end)

        map("i", keys.d, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local folder_path = Path:new(path .. "/" .. selection[1])

          -- Ask for confirmation before deleting
          local confirmation =
            vim.fn.input("Are you sure you want to delete this folder and all its subfolders? (y/n): ")

          if confirmation:lower() == "y" then
            -- Recursively delete the folder and all subfolders
            local command = "rm -rf " .. folder_path:absolute()
            os.execute(command)
            print("Deleted folder and all its contents.")
          else
            print("Deletion canceled.")
          end

          List_todo_projects() -- Refresh the list after deletion
        end)

        -- Open and list the markdown file inside the selected folder
        map("i", "<CR>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.g.Last_accessed_project = selection[1]
          List_todo_dates(selection[1]) -- Refresh
        end)

        -- Rename the selected folder, using the old folder name as the default input
        map("i", keys.r, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local old_folder_name = selection[1]
          local old_folder_path = Path:new(path .. "/" .. old_folder_name)
          local new_folder_name = vim.fn.input("New folder name: ", old_folder_name) -- Use the old name as default

          -- Rename the folder
          local new_folder_path = Path:new(path .. "/" .. new_folder_name)
          if old_folder_path:exists() then
            os.rename(old_folder_path:absolute(), new_folder_path:absolute())
            print("Renamed folder to " .. new_folder_name)
          else
            print("Folder does not exist.")
          end

          List_todo_projects() -- Refresh after renaming
        end)
        return true
      end,
    })
    :find()
end
