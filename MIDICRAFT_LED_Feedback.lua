------- start v3.2.x  bug warning  - delete when fixed ---------
local function warning()
  local version = gma.show.getvar('VERSION') 
  if version:find('^3.2.') then
    local funcName = debug.getinfo(1).source
    local txt = [[ 
      V%s may not properly terminate infinite loops.
      To terminate this plugin, use OffOffEverythingOff,
      or activate its cleanup-procedure manually via cmdline: 
      Lua "%s_cleanup()"
    ]]
    return gma.gui.confirm('WARNING!!',txt:format(version, funcName))
  else 
    return true
  end
end
------- end v3.2.x  bug warning  - delete when fixed  ---------

---------------------------------------------------------------
------------- MidiFeedbackLoop by GLAD - 2016 -----------------
---------------------------------------------------------------
-------- sends Midi note-velocity combinations based ----------
----------- on Lua accessible executor information: -----------
---- empty / non-empty / sequence (off) / sequence (on) -------
---------------------------------------------------------------

local gma = gma
local pairs, tonumber = pairs, tonumber

local isStart = true

local midifeedback = {}
do local _ENV = midifeedback

  local velocity = {0,126,126,127} -- velocity(color)codes for empty, non-empty, sequence (off), sequence (on)
    
  getHandle = gma.show.getobj.handle
  getClass = gma.show.getobj.class
  getAmount = gma.show.getobj.amount
  getChild = gma.show.getobj.child
  getProperty = gma.show.property.get
  
  doCommandline = gma.cmd
  gotoSleep = gma.sleep
   
  getMidiRemoteSetup = function ()
  
    local midiRemotes = getHandle('Remote "MidiRemotes"')
    local found = {}   
     
    for i=0, getAmount(midiRemotes)-1 do
    
      local remoteLine = getChild(midiRemotes,i)
      local type, button = getProperty(remoteLine, 'Type'), getProperty(remoteLine, 'Button')
      
      if type == 'Exec' and (button == 'Button 1' or button == 'Button 2' or button == 'Button 3') then
      
        local executor, page = getProperty(remoteLine, 'Executor'), getProperty(remoteLine, 'Page')
        if tonumber(page) then
          executor = page..'.'..executor
        end 
        
        local note, channel = getProperty(remoteLine, 'Note'), getProperty(remoteLine, 'Channel')
        if tonumber(channel) then
          note = channel..'.'..note
        end
        
        found[note] = executor
      end
    end
    return found 
  end
  
  class2velocity = { CMD_ROOT = velocity[1], CMD_EXEC = velocity[2], CMD_SEQUENCE = velocity[3], CMD_CUE = velocity[4] }  

  midiSyntax, execToken, cueToken = 'MidiNote %s %i', 'Executor %s', 'Executor %s Cue'  

  start = function()
    
    enabled = not warning or warning() 
    midiNote2exec = getMidiRemoteSetup()  
    cache = {}
    gma.echo('MidiFeedbackLoop started')
    
    while enabled do 
      for note, exec in pairs(midiNote2exec) do
        local handle = getHandle(cueToken:format(exec)) or getHandle(execToken:format(exec))
        local class = getClass(handle or 1)    
        if class ~= cache[note] then   
          cache[note] = class 
          local velocity = class2velocity[class]
          doCommandline(midiSyntax:format(note, velocity))
          if isStart then
            gotoSleep(0.01)
          end
        end
      end
      isStart = false
      gotoSleep(0.05)
    end
    
  end

  stop = function()
    enabled = false
    gma.echo('MidiFeedbackLoop terminated')
  end

end 

return midifeedback.start, midifeedback.stop