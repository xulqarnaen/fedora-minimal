local M = {}

function M.setup()
  require('base16-colorscheme').setup {
    -- Background tones
    base00 = '#0c1017',
    base01 = '#11151d',
    base02 = '#191e2a',
    base03 = '#45a0d6',

    -- Foreground tones
    base04 = '#9b6bc1',
    base05 = '#5c8ac4',
    base06 = '#5c8ac4',
    base07 = '#5c8ac4',

    -- Accent colors
    base08 = '#b32d2d',
    base09 = '#00a66c',
    base0A = '#d14358',
    base0B = '#c4a82e',
    base0C = '#80ffd2',
    base0D = '#e9d996',
    base0E = '#e996a2',
    base0F = '#3f0d0d',
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
