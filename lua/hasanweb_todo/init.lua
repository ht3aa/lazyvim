local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local Path = require("plenary.path")
local helpers = require("hasanweb_todo.helpers")
local keys = require("hasanweb_todo.keys")
local keys_functions = require("hasanweb_todo.keys-functions")
local files = require("hasanweb_todo.files")
local dates = require("hasanweb_todo.dates")

math.randomseed(os.time())

Todos_directory = os.getenv("HOME") .. "/.config/nvim/lua/hasanweb_todo/todos"
Success_audios_directory = os.getenv("HOME") .. "/.config/nvim/lua/hasanweb_todo/audios/success"

-- List folders and on selection, display markdown content
function List_todo_projects(opts)
  opts = opts or {}

  local path = Todos_directory .. "/"

  pickers
    .new(opts, {
      prompt_title = "Select a Project",
      finder = finders.new_table({
        results = helpers.get_folders_name(),
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- Create a new folder
        map("i", keys.new_folder, function()
          actions.close(prompt_bufnr)
          local folder_name = vim.fn.input("New folder name: ")
          local new_folder = Path:new(path .. folder_name)
          helpers.check_if_folder_exists(new_folder, path)
          List_todo_projects() -- Refresh
        end)

        -- Access the last opend md file
        map("i", keys.last_path, function()
          files.list_md_file_lines(vim.g.Last_accessed_md_file_path, vim.g.Last_accessed_project)
        end)

        map("i", keys.delete, function()
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
          dates.list_todo_dates(selection[1]) -- Refresh
        end)

        -- Rename the selected folder, using the old folder name as the default input
        map("i", keys.rename, function()
          keys_functions.rename(prompt_bufnr, path)
          List_todo_projects() -- Refresh after renaming
        end)
        return true
      end,
    })
    :find()
end
