-- main.lua  (Widget: PID_UI)
-- EdgeTX 2.12 / Rotorflight 2.2 対応
--
-- GV8  : Widgetの表示・入力処理用インデックス (rfadj.luaが設定)
-- GV9  : RF2機能識別用CH9出力              (rfadj.luaが設定)
-- GV1〜4: TX Setパラメータ (EdgeTX完結)
--   GV1 = スロットルウェイト (CH13トリム)
--   GV2 = コレクティブウェイト (CH11トリム)
--   GV3 = サイクリックExpo (CH10トリム)
--   GV4 = ラダーExpo (CH12トリム)
-- AdjV : RF2テレメトリー返信値 (元値+増減値)。無操作時は一定時間後0に戻る
--        0および1はノイズ/無操作とみなす (実パラメータ値が0や1になることは実用上ない)

local app_name = "PID_UI"
local base_path = "/WIDGETS/" .. app_name .. "/"

-- カラー定数
local WHITE  = 0xFFFFFF
local GREY   = 0x808080
local YELLOW = 0xFFFF00
local GREEN  = 0x00FF00
local RED    = 0xFF0000

-- API キャッシュ (グローバル参照を減らしてパフォーマンス向上)
local drawText   = lcd.drawText
local drawNumber = lcd.drawNumber
local drawLine   = lcd.drawLine
local getVal     = getValue

-- ヘルパー: mm:ss フォーマット
local function formatTime(s)
    local abs_s = math.abs(s)
    return string.format("%d:%02d", math.floor(abs_s / 60), abs_s % 60)
end

-- ヘルパー: 音声ファイルを安全に再生 (ファイル存在確認付き)
local function playFileSafe(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        playFile(path)
    end
end

-- ヘルパー: コレクティブピッチ度数計算 (入力処理・描画で共用)
local function collDeg(val, maxColl)
    return maxColl * (val + 100) / 200
end

-- ヘルパー: スロットル回転数計算 (入力処理・描画で共用)
-- GV1: -100〜100 → 0〜MaxRPM にマッピング
local function thrRPM(val, maxRPM)
    return math.floor(maxRPM * (val + 100) / 200)
end

-- ファイルパス生成
local function getFilePath(bank_name)
    local info = model.getInfo()
    local name = (info and info.name ~= "") and info.name or "Model"
    return base_path .. string.gsub(tostring(name), "[^%w]", "_") .. "_" .. (bank_name or "FM0") .. ".txt"
end

-- フライトモード → バンク名変換
-- FM番号から動的に生成するため、FM数に上限なし
local function getBankName()
    local fm = getFlightMode() or 0
    return "FM" .. fm
end

-- バンク名からFM番号を取得
local function getFMFromBank(bank_name)
    return tonumber(string.match(bank_name, "^FM(%d+)$")) or 0
end

-- インデックス対応キー
-- activeStep と row_keys の対応 (オフセット -1):
--   activeStep 2=MR, 3=CR, 4=E, 5=P, 6=I, 7=D, 8=F, 9=B, 10=TL/TR
local row_keys = { "MR", "CR", "E", "P", "I", "D", "F", "B", "TL", "TR" }
-- row_keys[activeStep - 1] で参照する

local function saveBankData(bank_name, d)
    if not d then return end
    local file = io.open(getFilePath(bank_name), "w")
    if file then
        local t = {}
        for _, ax in ipairs({"Ail", "Ele", "Rud"}) do
            for _, k in ipairs(row_keys) do table.insert(t, d[ax .. k] or 0) end
        end
        io.write(file, table.concat(t, ","))
        io.close(file)
    end
end

local function loadBankData(bank)
    local file = io.open(getFilePath(bank), "r")
    local d, t = {}, {}
    if file then
        local content = io.read(file, 512)
        io.close(file)
        if content then
            for val in string.gmatch(content, "([%-?%d]+)") do
                table.insert(t, tonumber(val) or 0)
            end
        end
    end
    local idx = 1
    for _, ax in ipairs({"Ail", "Ele", "Rud"}) do
        for _, k in ipairs(row_keys) do
            d[ax .. k] = t[idx] or 0
            idx = idx + 1
        end
    end
    return d
end

local function create(zone, options)
    -- 起動時のFMを検出し、そのFMのデータをロード
    -- 他のFMは切替時に遅延ロードする (起動時間を短縮)
    local initial_bank = getBankName()
    local all_data     = {}
    all_data[initial_bank] = loadBankData(initial_bank)
    return {
        zone               = zone,
        options            = options,
        last_adj           = 0,
        active_axis        = "Ail",
        last_bank          = initial_bank,
        all_vals           = all_data,
        vals               = all_data[initial_bank],
        pending_save       = false,
        last_inputs        = { c10=0, c11=0, c12=0, c13=0 },
        last_tick          = 0,
        pending_voice_val  = nil,
        voice_timer        = 0,
        save_timer         = 0,
        target_bank        = initial_bank,
        last_trim_side     = "TL",
        gv_vals            = {},        -- 描画用GVキャッシュ
        last_gv_tick       = 0,
        last_proc_tick     = 0,
        last_active_step   = 0,
        last_voice_step    = -1,
        pending_step_voice = nil,
        step_voice_timer   = 0,
        last_played_num    = -999,
        min_voice_gap      = 0,
        voice_dirty        = false,
    }
end

local function refresh(wgt)
    if not wgt then return end
    local zone = wgt.zone
    local x, y, w, h = zone.x, zone.y, zone.w, zone.h

    local fm         = getFlightMode() or 0
    local activeStep = model.getGlobalVariable(7, fm)  -- GV8: Widget用インデックス
    local raw_adj    = getVal("AdjV") or 0             -- RF2テレメトリー返信値
    local now        = getTime()
    local v_delay    = (wgt.options and wgt.options.VoiceDelay)     or 40
    local v_guard    = (wgt.options and wgt.options.VoiceGuardTime) or 70

    -- ==========================================================================
    --  モード名読み上げ (デバウンス付き)
    --  スイッチを素早く動かした時は途中の音をスキップする
    -- ==========================================================================
    if activeStep ~= wgt.last_voice_step then
        wgt.pending_step_voice = activeStep
        wgt.step_voice_timer   = now + 40   -- 400ms待機
        wgt.last_voice_step    = activeStep
        wgt.pending_voice_val  = nil        -- モード切替時は数値読み上げ待ちをキャンセル
        wgt.last_played_num    = -999
        wgt.voice_dirty        = false
    end

    if wgt.pending_step_voice and now > wgt.step_voice_timer and now > wgt.min_voice_gap then
        if wgt.pending_step_voice >= 1 and wgt.pending_step_voice <= 11 then
            playFileSafe(base_path .. "sounds/step" .. wgt.pending_step_voice .. ".wav")
            wgt.min_voice_gap = now + v_guard
        end
        wgt.pending_step_voice = nil
    end

    -- ==========================================================================
    --  GVキャッシュ更新 (50ms周期)
    --  TX Set表示用: 全FM(0〜2) × GV(0〜3) をキャッシュ
    --  set後は即時キャッシュを更新するため、周期外でも整合性を保つ
    -- ==========================================================================
    if now > wgt.last_gv_tick then
        -- TX Set表示用GVキャッシュ: 全FMを動的に取得
        -- model.getFlightModesCount() でFM数を取得し、存在するFM分だけキャッシュ
        local fm_count = (model.getFlightModesCount and model.getFlightModesCount()) or 3
        for f = 0, fm_count - 1 do
            for g = 0, 3 do
                wgt.gv_vals["f" .. f .. "g" .. g] = model.getGlobalVariable(g, f)
            end
        end
        wgt.last_gv_tick = now + 5  -- 約50ms後に再キャッシュ
    end

    local maxColl = (wgt.options and wgt.options.MaxColl) or 14
    local cb = getBankName()

    if cb ~= wgt.last_bank then
        -- 未ロードのバンクは切替時に遅延ロード (任意のFM数に対応)
        if not wgt.all_vals[cb] then
            wgt.all_vals[cb] = loadBankData(cb)
        end
        wgt.vals      = wgt.all_vals[cb]
        wgt.last_bank = cb
    end

    local c10 = getVal("ch10") or 0
    local c11 = getVal("ch11") or 0
    local c12 = getVal("ch12") or 0

    -- アクティブ軸判定 (閾値500で統一)
    if     math.abs(c10) > 500 then wgt.active_axis = "Ail"
    elseif math.abs(c11) > 500 then wgt.active_axis = "Ele"
    elseif math.abs(c12) > 500 then wgt.active_axis = "Rud"
    end

    -- Stop-Gain時の左右判定 (閾値をactive_axis判定と同じ500に統一)
    -- c10(Ail方向) > 500 → TR、c12(Rud方向) > 500 → TL
    if math.abs(c10) > 500 then wgt.last_trim_side = "TR" end
    if math.abs(c12) > 500 then wgt.last_trim_side = "TL" end

    -- Stop-Gain時はRud軸を強制選択
    if activeStep == 10 then wgt.active_axis = "Rud" end

    -- ==========================================================================
    --  入力処理
    -- ==========================================================================
    local c13    = getVal("ch13") or 0
    local is_tick = (now > wgt.last_tick)

    if activeStep == 1 then
        -- TX Set モード: EdgeTX完結パラメータをトリムで調整
        -- GV1: スロットルウェイト ← CH13 (1クリック=±1)
        if wgt.last_inputs.c13 == 0 and math.abs(c13) > 500 and is_tick then
            local val = wgt.gv_vals["f" .. fm .. "g" .. 0] or 0
            val = math.max(-100, math.min(100, val + ((c13 > 500) and 1 or -1)))
            model.setGlobalVariable(0, fm, val)
            wgt.gv_vals["f" .. fm .. "g" .. 0] = val   -- キャッシュ即時更新
            wgt.last_tick         = now + 5
            local maxRPM          = (wgt.options and wgt.options.MaxRPM) or 2500
            wgt.pending_voice_val = thrRPM(val, maxRPM)  -- RPM値で読み上げ
            wgt.voice_timer       = now + v_delay
            wgt.voice_dirty       = true
            wgt.last_played_num   = -999
        end

        -- GV2: コレクティブウェイト ← CH11 (1クリック=±1)
        if wgt.last_inputs.c11 == 0 and math.abs(c11) > 500 and is_tick then
            local val = wgt.gv_vals["f" .. fm .. "g" .. 1] or 0
            val = math.max(-100, math.min(100, val + ((c11 > 500) and 1 or -1)))
            model.setGlobalVariable(1, fm, val)
            wgt.gv_vals["f" .. fm .. "g" .. 1] = val   -- キャッシュ即時更新
            wgt.last_tick         = now + 5
            local deg             = collDeg(val, maxColl)
            local disp_val        = math.floor(deg * 10)  -- 例: 12.5度 → 125 (playNumberで読み上げ)
            wgt.pending_voice_val = disp_val
            wgt.voice_timer       = now + v_delay
            wgt.voice_dirty       = true
            wgt.last_played_num   = -999
        end

        -- GV3: サイクリックExpo ← CH10
        if wgt.last_inputs.c10 == 0 and math.abs(c10) > 500 and is_tick then
            local val = wgt.gv_vals["f" .. fm .. "g" .. 2] or 0
            val = math.max(0, math.min(100, val + ((c10 > 500) and 2 or -2)))
            model.setGlobalVariable(2, fm, val)
            wgt.gv_vals["f" .. fm .. "g" .. 2] = val   -- キャッシュ即時更新
            wgt.last_tick         = now + 5
            wgt.pending_voice_val = val
            wgt.voice_timer       = now + v_delay
            wgt.voice_dirty       = true
            wgt.last_played_num   = -999
        end

        -- GV4: ラダーExpo ← CH12
        if wgt.last_inputs.c12 == 0 and math.abs(c12) > 500 and is_tick then
            local val = wgt.gv_vals["f" .. fm .. "g" .. 3] or 0
            val = math.max(0, math.min(100, val + ((c12 > 500) and 2 or -2)))
            model.setGlobalVariable(3, fm, val)
            wgt.gv_vals["f" .. fm .. "g" .. 3] = val   -- キャッシュ即時更新
            wgt.last_tick         = now + 5
            wgt.pending_voice_val = val
            wgt.voice_timer       = now + v_delay
            wgt.voice_dirty       = true
            wgt.last_played_num   = -999
        end

    elseif activeStep >= 2 and activeStep <= 10 and raw_adj ~= 0 and raw_adj ~= wgt.last_adj then
        -- RF2 Adjustments モード: AdjVテレメトリーで確定した値を受信して保存
        -- AdjV: 0〜1はノイズ/無操作とみなす (RF2から負値は返らない)
        local clean_adj = (raw_adj >= 0 and raw_adj <= 1) and 0 or raw_adj

        local suf  = row_keys[activeStep - 1]  -- activeStep 2→"MR", 3→"CR", ... 10→"TL"
        local axis = wgt.active_axis
        local target

        if activeStep == 10 then
            -- Stop-Gain: Rud軸固定、左右トリムで TL/TR を切り替え
            axis   = "Rud"
            suf    = (wgt.last_trim_side == "TR") and "TR" or "TL"
        end
        target = axis .. suf

        -- MR/CR は10倍スケール (RF2側の値域に合わせる)
        local f_val = (suf == "MR" or suf == "CR") and (clean_adj * 10) or clean_adj
        wgt.vals[target]  = f_val
        wgt.pending_save  = true
        wgt.save_timer    = now + 10   -- 100ms後にファイル保存 (保険用)
        wgt.target_bank   = cb

        wgt.pending_voice_val = f_val
        wgt.voice_timer       = now + v_delay
        wgt.voice_dirty       = true
        wgt.last_adj          = raw_adj
    end

    -- AdjVが 0 に戻った瞬間を検知 → 値確定として即時保存
    -- 「AdjVが0に戻る = RF2の送信完了」を保存トリガーとして使う
    -- これにより電源OFFのタイミングに依存せず確実に保存できる
    if wgt.last_adj > 1 and raw_adj <= 1 then
        if wgt.pending_save then
            saveBankData(wgt.target_bank, wgt.all_vals[wgt.target_bank])
            wgt.pending_save = false
        end
    end

    -- last_adj の更新 (0/1はノイズなので0として扱う)
    -- AdjVが0に戻ったらリセットすることで、次回同じ値が来ても正しく検知できる
    wgt.last_adj = (raw_adj <= 1) and 0 or raw_adj

    -- ラッチ処理: 調整モード(2〜10)を抜けた瞬間に未保存データを強制書き込み
    -- (SD操作で明示的にモード離脱した場合の保険)
    if wgt.last_active_step >= 2 and wgt.last_active_step <= 10 then
        if activeStep < 2 or activeStep > 10 then
            if wgt.pending_save then
                saveBankData(wgt.target_bank, wgt.all_vals[wgt.target_bank])
                wgt.pending_save = false
            end
        end
    end
    wgt.last_active_step = activeStep

    -- 入力状態の更新 (エッジ検出用、閾値500で統一)
    wgt.last_inputs.c13 = (math.abs(c13) > 500) and 1 or 0
    wgt.last_inputs.c10 = (math.abs(c10) > 500) and 1 or 0
    wgt.last_inputs.c11 = (math.abs(c11) > 500) and 1 or 0
    wgt.last_inputs.c12 = (math.abs(c12) > 500) and 1 or 0

    -- 音声再生 (voice_dirtyフラグでガード時間終了後に最終値を確実に読み上げ)
    if wgt.voice_dirty and now > wgt.voice_timer
       and not wgt.pending_step_voice and now > wgt.min_voice_gap then
        if wgt.pending_voice_val and wgt.pending_voice_val ~= wgt.last_played_num then
            playNumber(wgt.pending_voice_val, 0)
            wgt.last_played_num = wgt.pending_voice_val
            wgt.min_voice_gap   = now + v_guard
        end
        wgt.voice_dirty = false
    end

    -- デバウンス保存 (AdjV=0戻りで保存できなかった場合の最終保険、100ms)
    if wgt.pending_save and now > wgt.save_timer then
        saveBankData(wgt.target_bank, wgt.all_vals[wgt.target_bank])
        wgt.pending_save = false
    end

    -- ==========================================================================
    --  描画処理
    -- ==========================================================================
    local c_p = (wgt.options and wgt.options.ColorPast)   or 2048
    local c_a = (wgt.options and wgt.options.ColorActive) or RED
    local c_l = (wgt.options and wgt.options.ColorLabel)  or WHITE

    -- -----------------------------------------------------------------------
    --  レスポンシブレイアウト計算
    --  zone.h に応じてフォントサイズ・行高さ・余白を動的に決定する
    --
    --  区分:
    --    LARGE  : h >= 280  (TX15 フルスクリーン等)
    --    MEDIUM : h >= 220  (TX16S MK2 フルスクリーン / TX15 分割等)
    --    SMALL  : h <  220  (分割画面・小型液晶等)
    -- -----------------------------------------------------------------------
    local fontL, fontS, footerH, headerH, labelW
    if h >= 280 then
        -- LARGE: 通常フォント
        fontL   = MIDSIZE   -- 値表示フォント
        fontS   = SMLSIZE   -- ラベルフォント
        footerH = 28        -- フッター高さ
        headerH = 18        -- ヘッダー高さ
        labelW  = 75        -- TX Setラベル幅
    elseif h >= 220 then
        -- MEDIUM: ラベルを小さく、値は維持
        fontL   = MIDSIZE
        fontS   = SMLSIZE
        footerH = 22
        headerH = 15
        labelW  = 65
    else
        -- SMALL: 全体を小さく
        fontL   = SMLSIZE
        fontS   = SMLSIZE
        footerH = 18
        headerH = 13
        labelW  = 55
    end

    -- 行高さ: フッター・ヘッダー・余白を除いた残りを5行で均等割り
    local lineH     = math.floor((h - footerH - headerH - 10) / 5)
    local infoW     = w * 0.28
    local gridStart = x + infoW + 8
    local startY    = y + headerH
    local alignX    = x + infoW - 10

    -- 左側パネル: モデル情報
    drawText(x + 6, y + 2,             model.getInfo().name,               fontL + c_l)
    drawText(x + 6, startY + lineH,    "T1:",                              fontS + c_l)
    drawText(alignX, startY + lineH,   formatTime(model.getTimer(0).value), fontL + c_a + RIGHT)
    drawText(x + 6, startY + lineH*2,  "RPM:",                             fontS + c_l)
    drawText(alignX, startY + lineH*2, getVal("Hspd") or 0,                fontL + c_a + RIGHT)

    local battV = (wgt.options and wgt.options.BattSrc and wgt.options.BattSrc ~= 0)
                  and getVal(wgt.options.BattSrc) or 0
    drawText(x + 6, startY + lineH*3,  "V:",                               fontS + c_l)
    drawText(alignX, startY + lineH*3, string.format("%.1f", battV),
             fontL + (battV < 3.5 and RED or c_a) + RIGHT)
    drawText(x + 6, startY + lineH*4,  "Bat%",                             fontS + c_l)
    drawText(alignX, startY + lineH*4, getVal("Bat%") or 0,                fontL + c_a + RIGHT)

    drawLine(gridStart - 4, y + 6, gridStart - 4, y + h - footerH - 4, SOLID, FORCE)

    -- 右側パネル: モードに応じて表示切替
    local function drawTXSet(editable)
        -- TX Set表示 (activeStep=1: 編集可, activeStep=11: 参照のみ)
        -- FM数を動的に取得し、表示列数をFM数に合わせる
        local fm_count = (model.getFlightModesCount and model.getFlightModesCount()) or 3
        local colW     = (w - gridStart - labelW) / fm_count
        local maxRPM   = (wgt.options and wgt.options.MaxRPM) or 3000
        drawText(gridStart + 4, y + 2, "TX Set", fontS + c_l)
        for i = 0, fm_count - 1 do
            drawText(gridStart + labelW + (i + 0.5)*colW, y + 2, "FM"..i, fontS + c_l + CENTER)
        end
        local params = {
            { name="Thr RPM", gv=0, chan= editable and c13 or 0 },
            { name="Coll P.", gv=1, chan= editable and c11 or 0 },
            { name="A/E Exp", gv=2, chan= editable and c10 or 0 },
            { name="Rud Exp", gv=3, chan= editable and c12 or 0 },
        }
        for idx, p in ipairs(params) do
            local ry          = startY + (lineH * idx) - 4
            local isRowActive = editable and (math.abs(p.chan) > 500)
            drawText(gridStart + 4, ry, p.name, fontS + (isRowActive and c_a or c_l))
            for i = 0, fm_count - 1 do
                local val   = wgt.gv_vals["f" .. i .. "g" .. p.gv] or 0
                local color = (fm == i) and (isRowActive and c_a or c_l) or c_p
                if p.gv == 0 then
                    drawNumber(gridStart + labelW + (i + 0.5)*colW, ry,
                               thrRPM(val, maxRPM), fontL + CENTER + color)
                elseif p.name == "Coll P." then
                    drawText(gridStart + labelW + (i + 0.5)*colW, ry,
                             string.format("%.1f", collDeg(val, maxColl)), fontL + CENTER + color)
                else
                    drawNumber(gridStart + labelW + (i + 0.5)*colW, ry,
                               val, fontL + CENTER + color)
                end
            end
        end
    end

    if activeStep == 1 then
        drawTXSet(true)   -- 編集可

    elseif activeStep == 11 then
        drawTXSet(false)  -- 参照のみ

    elseif activeStep >= 2 and activeStep <= 10 then
        -- RF2 Adjustments 画面: 3軸 × パラメータグリッド
        local isScreen1 = (activeStep <= 4 or activeStep >= 10)
        local headers   = isScreen1
                          and {"M-Rt", "C-Rt", "Exp", "T-L", "T-R"}
                          or  {"P",    "I",    "D",   "FF",  "B"}
        local axLabelW  = (h >= 280) and 45 or 36  -- 軸ラベル幅もh依存
        local colW      = (w - gridStart - axLabelW) / #headers

        -- ヘッダー描画
        for idx, txt in ipairs(headers) do
            drawText(gridStart + axLabelW + (idx-0.5)*colW, y + 2, txt, fontS + c_l + CENTER)
        end

        local axes = {"Ail", "Ele", "Rud"}
        for i = 1, 3 do
            local ry      = startY + (lineH * i)
            local ax      = axes[i]
            local isSelAx = (wgt.active_axis == ax)
            drawText(gridStart + 4, ry, ax, fontL + (isSelAx and c_a or c_l))

            if isScreen1 then
                local keys = {
                    {k="MR", id=2}, {k="CR", id=3}, {k="E", id=4},
                    {k="TL", id=10}, {k="TR", id=10}
                }
                for j, item in ipairs(keys) do
                    if (item.k ~= "TL" and item.k ~= "TR") or ax == "Rud" then
                        local val = wgt.vals[ax .. item.k] or 0
                        local isF = (isSelAx and activeStep == item.id)
                        if item.id == 10 then
                            isF = (isSelAx and activeStep == 10 and item.k == wgt.last_trim_side)
                        end
                        drawNumber(gridStart + axLabelW + (j-0.5)*colW, ry, val,
                                   fontL + (isF and c_a or c_p) + CENTER)
                    end
                end
            else
                local keys = {
                    {k="P", id=5}, {k="I", id=6}, {k="D", id=7},
                    {k="F", id=8}, {k="B", id=9}
                }
                for j, item in ipairs(keys) do
                    local val = wgt.vals[ax .. item.k] or 0
                    local isF = (isSelAx and activeStep == item.id)
                    drawNumber(gridStart + axLabelW + (j-0.5)*colW, ry, val,
                               fontL + (isF and c_a or c_p) + CENTER)
                end
            end
        end

    else
        -- 未定義のactiveStep (安全のため空白表示)
    end

    -- フッター: バンク名 / AdjV現在値
    local footerY = y + h - footerH
    drawLine(x + 6, footerY - 2, x + w - 6, footerY - 2, SOLID, FORCE)
    drawText(x + 10,      footerY, "Bank:",  fontS + c_l)
    drawText(x + 55,      footerY, cb,       fontL + c_a)
    drawText(x + w - 100, footerY, "AdjV:",  fontS + c_l)
    drawNumber(x + w - 45, footerY, raw_adj, fontL + c_a)
end

local options = {
    { "BattSrc",       SOURCE, 0                 },
    { "ColorPast",     COLOR,  2048              },
    { "ColorActive",   COLOR,  RED               },
    { "ColorLabel",    COLOR,  WHITE             },
    { "MaxColl",       VALUE,  14,   10,  16     },  -- コレクティブピッチ最大角度 (度)
    { "MaxRPM",        VALUE,  3000, 2000, 6000  },  -- スロットル最大回転数 (RPM)
    { "VoiceDelay",    VALUE,  30,   0,   200    },  -- 数値読み上げデバウンス時間 (10ms単位)
    { "VoiceGuardTime",VALUE,  200,  0,   300    },  -- 音声再生間の最低ガード時間 (10ms単位)
}

return {
    name    = app_name,
    options = options,
    create  = create,
    refresh = refresh,
    update  = function(wgt, options) wgt.options = options end,
}
