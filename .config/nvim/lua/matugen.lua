local M = {}

function M.setup()
  require('base16-colorscheme').setup {
    -- Background tones
    base00 = '#101315',
    base01 = '#1a1e20',
    base02 = '#23292b',
    base03 = '#5b6265',

    -- Foreground tones
    base04 = '#a5aeb4',
    base05 = '#cacccc',
    base06 = '#cacccc',
    base07 = '#cacccc',

    -- Accent colors
    base08 = '#de6145',
    base09 = '#a8adb0',
    base0A = '#798186',
    base0B = '#de6145',
    base0C = '#96cae9',
    base0D = '#eca393',
    base0E = '#96c9e9',
    base0F = '#621e0e',
  }
end

-- Register a signal handler for SIGUSR1 (matugen updates)
local signal = vim.uv.new_signal()
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
