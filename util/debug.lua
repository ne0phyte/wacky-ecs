local Debug = {}
local stats = {}

function Debug.gcMemory()
   local kb = math.ceil(collectgarbage("count"))
   print("Memory: " .. kb .. "kb")
end

function Debug.graphicsMemory()
   love.graphics.getStats(stats)
   print("Graphics:" .. Debug.dump(stats))
end

function Debug.printDump(obj, withType, ignore)
   print(Debug.dump(obj, withType, ignore))
end

function Debug.dump(o, withType, ignore, indent, visited)
   local visited = visited or {}
   local ignore = ignore or {}
   if not indent then indent = 0 end
   if not withType then withType = false end
   local s = ''
   if o and type(o) == "table" then
      local spaces = string.rep('  ', indent)
      s = s .. '{\n'
      for k, v in pairs(o) do
         s = s .. spaces .. '  '
         if withType then s = s .. '(' .. type(v) .. ')' end
         if type(v) ~= 'table' then
            s = s .. tostring(k) .. ' = ' .. tostring(v) .. ',\n'
         else
            if visited[v] then
              s = s .. tostring(k) .. ' = ' .. tostring(v) .. ' [circular reference]' .. ',\n'
            elseif ignore[k] == v then
              s = s .. tostring(k) .. ' = ' .. tostring(v) .. ' [ignored]' .. ',\n'
            else
              visited[v] = v
              s = s .. tostring(k) .. ' = ' .. Debug.dump(v, withType, ignore, indent+1, visited) .. ',\n'
            end
         end
      end
      return s .. spaces .. '}'
   end
   if withType then s = s .. '(' .. type(o) .. ')' end
   return s .. tostring(o)
end

return Debug
