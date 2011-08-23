Console = { }

local console
local logLocked = false
local commandEnv = createEnvironment()
local maxLines = 80
local numLines = 0

function Console.onLog(level, message, time)
  -- avoid logging while reporting logs (would cause a infinite loop)
  if not logLocked then
    logLocked = true

    local color
    if level == LogDebug then
      color = '#5555ff'
    elseif level == LogInfo then
      color = '#5555ff'
    elseif level == LogWarning then
      color = '#ffff00'
    else
      color = '#ff0000'
    end

    if level ~= LogDebug then
      Console.addLine(message, color)
    end

    logLocked = false
  end
end

function Console.addLine(text, color)
  -- create new label

  local label = UILabel.create()
  label:setStyle('ConsoleLabel')
  label:setText(text)
  label:setForegroundColor(color)
  console:insertChild(3, label)

  local lastLabel = console:getChildByIndex(4)
  if lastLabel then
    lastLabel:addAnchor(AnchorBottom, "prev", AnchorTop)
  end

  numLines = numLines + 1
  if numLines > maxLines then
    local firstLabel = console:getChildByIndex(-1)
    firstLabel:destroy()
  end
end

function Console.create()
  console = loadUI("/console/console.otui")
  rootWidget:addChild(console)
  console:hide()

  Logger.setOnLog(Console.onLog)
  Logger.fireOldMessages()
end

function Console.destroy()
  Logger.setOnLog(nil)
  console:destroy()
  console = nil
end

function Console.show()
  console.parent:lockChild(console)
  console.visible = true
end

function Console.hide()
  console.parent:unlockChild(console)
  console.visible = false
end

function Console.executeCommand(command)
  Console.addLine(">> " .. command, "#ffffff")
  local func, err = loadstring(command, "@")
  if func then
    setfenv(func, commandEnv)
    local ok, ret = pcall(func)
    if ok then
      if ret then
        print(ret)
      end
    else
      Logger.log(LogError, 'command failed: ' .. ret)
    end
  else
    Logger.log(LogError, 'incorrect lua syntax: ' .. err:sub(5))
  end
end