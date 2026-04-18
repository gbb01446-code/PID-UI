local function run()
    local sw_mode = getValue('sd')
    local fm = getFlightMode() or 0
    local raw_idx = 0

    if sw_mode < -500 then
        -- SD奥 (Up): 調整無効 (0の代わりに11を使用)
        raw_idx = 11
    elseif sw_mode < 500 then
        -- SD中 (Mid): TX Set (送信機側設定)
        raw_idx = 1
    else
        -- SD手前 (Down): 3x3 グリッド
        local sw_row  = getValue('sb')
        local sw_col  = getValue('sa')
        if sw_row < -500 then         -- SB奥
            if sw_col < -500 then raw_idx = 2      -- ② M-Rate
            elseif sw_col < 500 then raw_idx = 3   -- ③ C-Rate
            else raw_idx = 4 end                   -- ④ Expo (FC)
        elseif sw_row < 500 then      -- SB中
            if sw_col < -500 then raw_idx = 5      -- ⑤ P Gain
            elseif sw_col < 500 then raw_idx = 6   -- ⑥ I Gain
            else raw_idx = 7 end                   -- ⑦ D Gain
        else                          -- SB手前
            if sw_col < -500 then raw_idx = 8      -- ⑧ FeedForward
            elseif sw_col < 500 then raw_idx = 9   -- ⑨ B-Gain
            else raw_idx = 10 end                  -- ⑩ Stop-gain
        end
    end

    -- GV8 (Index) を更新
    if model.getGlobalVariable(7, fm) ~= raw_idx then
        model.setGlobalVariable(7, fm, raw_idx)
    end

    -- GV9 (RF出力) を更新
    local rf_val = -100
    if raw_idx >= 2 and raw_idx <= 10 then
        rf_val = (raw_idx - 6) * 20 -- Index 2(-80) ~ 10(80)
    end
    if model.getGlobalVariable(8, fm) ~= rf_val then
        model.setGlobalVariable(8, fm, rf_val)
    end
end

return { run=run }
