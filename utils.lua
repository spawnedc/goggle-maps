setfenv(1, SP)

Utils = {}

function Utils.log(msg)
  Utils.print(msg)
end

function Utils.print(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
  local f = DEFAULT_CHAT_FRAME
  f:AddMessage(
    "|cffccccffSpwMap: |cffffffff" ..
    (string.format(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10) or "nil"), 1,
    1, 1)
end

function Utils.mod(a, b)
  return a - (math.floor(a / b) * b)
end
