set -g fish_greeting
function starship_transient_prompt_func
  starship module character
end
function starship_transient_rprompt_func
  starship module custom.transient_time
end
starship init fish | source

set -gx QT_QPA_PLATFORMTHEME qt6ct
