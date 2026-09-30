-- ============================================================
-- Hammerspoon 設定: 連打トグル + ウインドウ減光 v12
-- 仕様:
--   ・ミラーリング前面時: Space単押しで連打ON/OFF
--   ・自動オフ: 別アプリ切替 / カーソルがウインドウ外に出たとき
--   ・⌥D: ミラーリングのウインドウを暗くする/戻す (全アプリで有効)
--   ・⌥⇧D: 暗さを1段階変更 (60→70→80→90→60…の循環)
--   ・⌥Esc: 連打の緊急停止 (全アプリで有効)
-- ============================================================

-- ▼ 設定(ここだけ触ればOK)---------------------------------
local TOGGLE_KEY = "space"  -- 連打ON/OFF

-- タップ間隔: MIN〜MAX秒の一様乱数で毎回変える
-- ポケGOの通常技は最速でも約0.4秒間隔でしか出ないため、
-- この幅でも技の取りこぼしなし
local INTERVAL_MIN = 0.10
local INTERVAL_MAX = 0.35

-- たまに混ぜる「長めの間」: PAUSE_CHANCE の確率で PAUSE_MIN〜MAX秒休む
local PAUSE_CHANCE = 0.06   -- 6% (0にすれば無効)
local PAUSE_MIN    = 0.5
local PAUSE_MAX    = 1.2

-- クリックの押下時間(マイクロ秒)もランダム化
local HOLD_MIN_US  = 15000  -- 15ms
local HOLD_MAX_US  = 40000  -- 40ms

-- タップ位置のゆらぎ: 狙い位置(アンカー)の周囲±JITTER_PX に散らす
local JITTER_PX    = 6      -- ゆらぎ半径(px)。0で無効
local REANCHOR_PX  = 15     -- カーソルをこれ以上動かしたら狙い位置を取り直す

-- 暗さの段階 (⌥⇧Dで循環)。先頭がデフォルト
local DIM_STEPS  = { 0.6, 0.7, 0.8, 0.9 }
-- ------------------------------------------------------------

local MIRROR_BUNDLE = "com.apple.ScreenContinuity"

-- ============ 連打まわり ============
local clickTimer = nil

local function stopClicking(reason)
  if clickTimer then
    clickTimer:stop()
    clickTimer = nil
    hs.alert.show("連打 OFF" .. (reason and (" (" .. reason .. ")") or ""), 0.6)
  end
end

local function mirrorWindow()
  local app = hs.application.get(MIRROR_BUNDLE)
  if not app then return nil end
  return app:mainWindow()
end

local function cursorInsideMirrorWindow()
  local win = mirrorWindow()
  if not win then return false end
  return hs.geometry.new(hs.mouse.absolutePosition()):inside(win:frame())
end

math.randomseed(os.time())

local function randBetween(a, b)
  return a + math.random() * (b - a)
end

-- 1クリック実行して、次のクリックをランダムな間隔で予約する
local tick  -- 前方宣言(相互参照のため)

local function scheduleNext()
  local delay
  if math.random() < PAUSE_CHANCE then
    delay = randBetween(PAUSE_MIN, PAUSE_MAX)   -- たまの長い間
  else
    delay = randBetween(INTERVAL_MIN, INTERVAL_MAX)
  end
  clickTimer = hs.timer.doAfter(delay, tick)
end

local anchorPos = nil     -- 連打の狙い位置(この周囲に散らす)
local lastClickPos = nil  -- 直前の着弾点(ユーザーの手動移動の検出用)

local function distance(a, b)
  local dx, dy = a.x - b.x, a.y - b.y
  return math.sqrt(dx * dx + dy * dy)
end

tick = function()
  if not clickTimer then return end  -- 停止済みなら何もしない
  local win = mirrorWindow()
  local cur = hs.mouse.absolutePosition()
  if not (win and hs.geometry.new(cur):inside(win:frame())) then
    stopClicking("カーソルが外に出ました")
    return
  end

  -- ユーザーがマウスを動かしたらアンカーを取り直す
  -- (クリック自体でもカーソルは着弾点へ動くため、直前の着弾点との差で判定)
  if not anchorPos or not lastClickPos or distance(cur, lastClickPos) > REANCHOR_PX then
    anchorPos = cur
  end

  -- アンカー周囲にゆらぎを加える(乱数2つの和で中心寄りの分布に)
  local dx = (math.random() + math.random() - 1) * JITTER_PX
  local dy = (math.random() + math.random() - 1) * JITTER_PX
  local target = { x = anchorPos.x + dx, y = anchorPos.y + dy }

  -- ゆらぎでウインドウ外に出ないようにクランプ
  local f = win:frame()
  target.x = math.max(f.x + 2, math.min(f.x + f.w - 2, target.x))
  target.y = math.max(f.y + 2, math.min(f.y + f.h - 2, target.y))

  hs.eventtap.leftClick(target, math.random(HOLD_MIN_US, HOLD_MAX_US))
  lastClickPos = target
  scheduleNext()
end

local function startClicking()
  if clickTimer then return end
  if not cursorInsideMirrorWindow() then
    hs.alert.show("カーソルをミラーリングの画面内に置いてください", 1)
    return
  end
  -- 開始時のカーソル位置を狙い位置として記録
  anchorPos = hs.mouse.absolutePosition()
  lastClickPos = anchorPos
  -- ダミーのタイマー参照を置いてから初回tick(clickTimer≠nil を実行中フラグ扱い)
  clickTimer = hs.timer.doAfter(0.01, tick)
  hs.alert.show("連打 ON", 0.6)
end

local toggleKey = hs.hotkey.new({}, TOGGLE_KEY, function()
  if clickTimer then stopClicking() else startClicking() end
end)

local function setEnabled(on)
  if on then
    toggleKey:enable()
    hs.alert.show("連打キー有効 (Space:ON/OFF)", 0.8)
  else
    toggleKey:disable()
    stopClicking("アプリ切り替え")
  end
end

appWatcher = hs.application.watcher.new(function(_, event, app)
  if event == hs.application.watcher.activated and app then
    setEnabled(app:bundleID() == MIRROR_BUNDLE)
  end
end)
appWatcher:start()

local front = hs.application.frontmostApplication()
if front and front:bundleID() == MIRROR_BUNDLE then
  setEnabled(true)
end

hs.hotkey.bind({"alt"}, "escape", function() stopClicking("手動停止") end)

-- ============ ウインドウ減光 (⌥D) ============
-- ミラーリングのウインドウの上に、クリックを素通しする
-- 半透明の黒いシートを被せて暗く見せる。位置追従つき。
local dimCanvas = nil
local dimTimer = nil
local dimStepIndex = 1  -- 現在の暗さ (DIM_STEPS のインデックス)

local function currentAlpha()
  return DIM_STEPS[dimStepIndex]
end

local function removeDim()
  if dimTimer then dimTimer:stop(); dimTimer = nil end
  if dimCanvas then dimCanvas:delete(); dimCanvas = nil end
end

-- ミラーリングのウインドウの上に他のウインドウが重なっているか判定
-- (orderedWindows は前面→背面の順。ミラーリングより前にある可視ウインドウで
--  枠が交差するものが1つでもあれば「遮られている」)
local function mirrorIsOccluded(mirrorWin)
  local mFrame = mirrorWin:frame()
  local mId = mirrorWin:id()
  for _, w in ipairs(hs.window.orderedWindows()) do
    if w:id() == mId then
      break  -- ここから後ろはミラーリングより背面なので無関係
    end
    local app = w:application()
    local bid = app and app:bundleID() or ""
    -- Hammerspoon自身のウインドウ(減光シートやトースト)は除外
    if bid ~= "org.hammerspoon.Hammerspoon" then
      local inter = w:frame():intersect(mFrame)
      if inter.w > 2 and inter.h > 2 then
        return true
      end
    end
  end
  return false
end

local function updateDimFrame()
  local win = mirrorWindow()
  if not win then
    removeDim()  -- ウインドウが消えたらシートも消す
    return
  end
  if dimCanvas then
    dimCanvas:frame(win:frame())
    if mirrorIsOccluded(win) then
      dimCanvas:hide()  -- 他ウインドウが重なっている間は隠す
    else
      dimCanvas:show()  -- 遮られていなければ暗くする
    end
  end
end

local function addDim()
  local win = mirrorWindow()
  if not win then
    hs.alert.show("ミラーリングのウインドウが見つかりません", 1)
    return
  end
  dimCanvas = hs.canvas.new(win:frame())
  dimCanvas:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = { red = 0, green = 0, blue = 0, alpha = currentAlpha() },
    roundedRectRadii = { xRadius = 12, yRadius = 12 },
  })
  dimCanvas:level(hs.canvas.windowLevels.floating)  -- 常時前面レベル。
  -- 代わりに「他ウインドウがミラーリングに重なったら自動で隠す」制御を行う
  dimCanvas:behavior({"canJoinAllSpaces"})
  dimCanvas:show()
  -- ウインドウ移動・リサイズ・重なりの変化に追従
  dimTimer = hs.timer.doEvery(0.3, updateDimFrame)
  updateDimFrame()
end

hs.hotkey.bind({"alt"}, "d", function()
  if dimCanvas then
    removeDim()
    hs.alert.show("減光 OFF", 0.6)
  else
    addDim()
    if dimCanvas then hs.alert.show("減光 ON (⌥Dで戻す)", 0.8) end
  end
end)

-- ⌥⇧D: 暗さを1段階変更 (循環)
hs.hotkey.bind({"alt", "shift"}, "d", function()
  dimStepIndex = dimStepIndex % #DIM_STEPS + 1
  if dimCanvas then
    dimCanvas[1].fillColor = { red = 0, green = 0, blue = 0, alpha = currentAlpha() }
  end
  hs.alert.show(("暗さ %d%%"):format(math.floor(currentAlpha() * 100 + 0.5)), 0.8)
end)

-- ============ 読み込み完了 ============
-- 権限チェックはダイアログを出さない方式に変更 (v6)
-- ※ hs.accessibilityState() は実際には権限が機能していても
--    false を返すことがあるため、警告ではなくコンソール記録のみ
if not hs.accessibilityState() then
  print("note: hs.accessibilityState() = false (機能が動いていれば無視してOK)")
end
hs.alert.show("設定OK v12: Space=連打 / ⌥D=減光 / ⌥Esc=停止", 2)
