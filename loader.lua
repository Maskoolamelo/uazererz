-- Do not save this file
-- Always use the loadstring 
pcall(function() delfile('49abdfcd1ce9ec893553a573b9348ca3-cache.lua') end)
  local a pcall(function()a=readfile("static_content_130525/initv4.lua")end) if a and #a>2000 then a=loadstring(a) end;
if a then return a() else pcall(makefolder, "static_content_130525") a=game:HttpGet("https://cdn.luarmor.net/v4_init_may312.lua") writefile("static_content_130525/initv4.lua", a) pcall(delfile, "static_content_130525/init.lua"); pcall(delfile, "static_content_130525/initv2.lua"); pcall(delfile, "static_content_130525/initv3.lua"); loadstring(a)() end
  
