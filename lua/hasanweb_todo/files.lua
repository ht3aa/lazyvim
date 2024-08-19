local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local helpers = require("hasanweb_todo.helpers")
local keys = require("hasanweb_todo.keys")

local files = {}

-- Display lines from the markdown file
files.list_md_file_lines = function(md_file_path, project_name, opts)
  opts = opts or {}
  local lines = helpers.get_md_file_lines(md_file_path)

  -- Delete all empty lines from the lines table
  for i = #lines, 1, -1 do
    if lines[i] == "" then
      table.remove(lines, i)
    end
  end

  -- Immediately write the cleaned-up lines back to the markdown file
  helpers.write_md_file(md_file_path, lines)

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
          helpers.write_md_file(md_file_path, lines)
          files.list_md_file_lines(md_file_path) -- Refresh
        end)

        -- Delete selected line
        map("i", keys.delete, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          table.remove(lines, selection.index)
          helpers.write_md_file(md_file_path, lines)
          files.list_md_file_lines(md_file_path) -- Refresh
        end)

        -- go back
        map("i", keys.previous_picker, function()
          local dates = require("hasanweb_todo.dates")
          actions.close(prompt_bufnr)
          dates.list_todo_dates(project_name) -- Refresh
        end)

        local function toggle_todo()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          -- Get the current date
          local current_datetime = os.date("%Y-%m-%d %I:%M:%S %p")

          -- Toggle logic for checkbox and update the date at the end of the line
          if string.match(selection.value, "%⏱️ ") then
            helpers.stop_all_playback()
            helpers.play_audio(helpers.get_random_path(helpers.get_file_paths(Success_audios_directory)))
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

          helpers.write_md_file(md_file_path, lines)
          files.list_md_file_lines(md_file_path) -- Refresh
        end

        map("n", keys.toggle_todo, toggle_todo)
        map("i", keys.toggle_todo, toggle_todo)

        map("i", keys.rename, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local updated_line = vim.fn.input("Update line: ", selection.value)

          -- Update the selected line with new content
          lines[selection.index] = updated_line
          helpers.write_md_file(md_file_path, lines)

          -- Refresh the list
          files.list_md_file_lines(md_file_path, project_name)
        end)

        return true
      end,
    })
    :find()
end

return files
