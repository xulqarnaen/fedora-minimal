-----------------------
---- APPLICATIONS ----
-----------------------

local programs = require("programs")

hl.bind("SUPER + Return", hl.dsp.exec_cmd(programs.terminal))
hl.bind("SUPER + B",      hl.dsp.exec_cmd(programs.browser))
hl.bind("SUPER + E",      hl.dsp.exec_cmd(programs.fileManager))
