local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Path = require("plenary.path")

local keys_functions = {}

keys_functions.rename = function(prompt_bufnr, path)
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
end

return keys_functions
