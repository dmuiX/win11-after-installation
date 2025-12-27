-- script to set DISPLAY variable for X11 forwarding
-- Place this file in your Clink scripts directory (e.g., %LOCALAPPDATA%\clink)

local display_val = "localhost:0.0"

-- Set the environment variable for the current process (cmd.exe)
os.setenv("DISPLAY", display_val)

-- Optional: print confirmation (useful for debugging, can be removed later)
-- print("Clink: DISPLAY set to " .. display_val)
