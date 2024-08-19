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
local dates = {}

-- List folders and on selection, display markdown content
dates.list_todo_dates = function(project_name)
  opts = opts or {}

  local path = Todos_directory .. "/" .. project_name

  pickers
    .new(opts, {
      prompt_title = "Select Date",
      finder = finders.new_table({
        results = helpers.get_folders_name(project_name),
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- Create a new folder
        map("i", keys.new_folder, function()
          actions.close(prompt_bufnr)
          local folder_name = vim.fn.input("New folder name: ")
          local new_folder = Path:new(path .. "/" .. folder_name)
          helpers.check_if_folder_exists(new_folder, path)
          dates.list_todo_dates(project_name) -- Refresh
        end)

        -- Automatically create a folder with the format "YYYY-MM-DD"
        map("i", keys.new_folder_with_current_date_name, function()
          actions.close(prompt_bufnr)
          local current_date = os.date("%Y-%m-%d")
          local new_folder = Path:new(path .. "/" .. current_date)

          helpers.check_if_folder_exists(new_folder, path)
          dates.list_todo_dates(project_name) -- Refresh
        end)

        -- go back
        map("i", keys.previous_picker, function()
          actions.close(prompt_bufnr)
          List_todo_projects()
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

          dates.list_todo_dates(project_name) -- Refresh the list after deletion
        end)

        -- Open and list the markdown file inside the selected folder
        map("i", "<CR>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local md_file_path = path .. "/" .. selection[1] .. "/todo.md"

          helpers.check_md_file_exists(md_file_path, selection)

          vim.g.Last_accessed_md_file_path = md_file_path

          files.list_md_file_lines(md_file_path, project_name) -- Open the markdown file
        end)

        map("i", keys.open_file, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local md_file_path = path .. "/" .. selection[1] .. "/todo.md"

          helpers.check_md_file_exists(md_file_path, selection)

          -- Open the markdown file in a new buffer
          vim.cmd("e " .. md_file_path)
        end)

        -- Rename the selected folder, using the old folder name as the default input
        map("i", keys.rename, function()
          keys_functions.rename(prompt_bufnr, path)
          dates.list_todo_dates(project_name) -- Refresh after renaming
        end)

        -- Copy all lines from the markdown file to the system clipboard with the current date
        map("i", keys.copy_file_content, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local md_file_path = path .. "/" .. selection[1] .. "/todo.md"

          helpers.check_md_file_exists(md_file_path, selection)

          -- Read the markdown file lines
          local lines = helpers.get_md_file_lines(md_file_path)

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

return dates
