INCLUDE Irvine32.inc

.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD

; ============================================================================
; 常數定義
; ============================================================================
SCREEN_WIDTH     = 40      ; 遊戲畫面寬度
SCREEN_HEIGHT    = 20      ; 遊戲畫面高度
MAX_FRUITS       = 5       ; 最多水果數量
PLAYER_ROW       = 18      ; 玩家籃子的行位置
MAX_LEVEL       = 5       ; 最大關卡數
LEVEL_UP_SCORE  = 30      ; 每關所需分數
BASE_SPEED      = 400     ; 基礎遊戲速度(ms)      ;數字越大越簡單
MIN_SPEED       = 50      ; 最小遊戲速度

; ============================================================================
; 資料區
; ============================================================================
.data
    ; 遊戲變數
    playerPos       DWORD ?                                         ; 玩家位置(列) 
    score           DWORD ?                                         ; 分數
    gameRunning     DWORD 1                                         ; 遊戲狀態，=1進行，=0停止
    speed           DWORD 400                                       ; 遊戲速度(ms)
    gamePaused      DWORD 0                                         ; 暫停狀態
    pauseMsg        BYTE "遊戲暫停，按P繼續遊戲", 0
    resumeMsg       BYTE "遊戲將在 X 秒後繼續", 0  
    scoreMsg        BYTE "分數: ", 0
    gameOverMsg     BYTE "遊戲結束! 按任意鍵退出...", 13, 10, 0
    WinMsg          BYTE "你贏了！", 0
    difficultyMsg   BYTE "目前難度: ", 0
    difficulty      DWORD 1                                         ; 當前難度
    pressEnterMsg BYTE 13,10,"點擊 Enter 鍵開始遊戲...",13,10,0    


    ; 水果陣列 - 每個水果 4 個 DWORD: X, Y, active(1/0), type
    fruits          DWORD MAX_FRUITS * 4 dup(0)
    
    ; 遊戲符號
    playerChar      BYTE "[===]", 0             ; 玩家籃子
    fruitChars      BYTE "ABCDEFG", 0           ; 水果符號

    ;封面
    titleArt1 BYTE 13,10,"  ________  _______   __    __  ______  ________        _______    ______   ______  __    __ ",13,10,0
    titleArt2 BYTE       " |        \|       \ |  \  |  \|      \|        \      |       \  /      \ |      \|  \  |  \",13,10,0
    titleArt3 BYTE       " | $$$$$$$$| $$$$$$$\| $$  | $$ \$$$$$$ \$$$$$$$$      | $$$$$$$\|  $$$$$$\ \$$$$$$| $$\ | $$",13,10,0
    titleArt4 BYTE       " | $$__    | $$__| $$| $$  | $$  | $$     | $$         | $$__| $$| $$__| $$  | $$  | $$$\| $$",13,10,0
    titleArt5 BYTE       " | $$  \   | $$    $$| $$  | $$  | $$     | $$         | $$    $$| $$    $$  | $$  | $$$$\ $$",13,10,0
    titleArt6 BYTE       " | $$$$$   | $$$$$$$\| $$  | $$  | $$     | $$         | $$$$$$$\| $$$$$$$$  | $$  | $$\$$ $$",13,10,0
    titleArt7 BYTE       " | $$      | $$  | $$| $$__/ $$ _| $$_    | $$         | $$  | $$| $$  | $$ _| $$_ | $$ \$$$$",13,10,0
    titleArt8 BYTE       " | $$      | $$  | $$ \$$    $$|   $$ \   | $$         | $$  | $$| $$  | $$|   $$ \| $$  \$$$",13,10,0
    titleArt9 BYTE       "  \$$       \$$   \$$  \$$$$$$  \$$$$$$    \$$          \$$   \$$ \$$   \$$ \$$$$$$ \$$   \$$",13,10,0

    ;遊戲規則
    rulesMsg1 BYTE "遊戲規則:", 13, 10, 0
    rulesMsg2 BYTE "1. 使用 A/D 鍵左右移動籃子，請先確認輸入法轉為英文", 13, 10, 0
    rulesMsg3 BYTE "2. 接住從天而降的水果(A-G)", 13, 10, 0
    rulesMsg4 BYTE "3. 每接住一個水果得10分", 13, 10, 0
    rulesMsg5 BYTE "4. 達到一定分數關卡難度會提升", 13, 10, 0                    ;每30分跳一級
    rulesMsg6 BYTE "5. 按 P 鍵可暫停遊戲", 13, 10, 0
    rulesMsg7 BYTE "6. 按 Q 鍵可退出遊戲", 13, 10, 0

.code
; ============================================================================
; 主程式
; 會先初始化遊戲->顯示封面->顯示規則->進入遊戲->遊戲結束
; ============================================================================
main PROC
    call InitGame
    call ShowTitleScreen
    call ShowRulesScreen
    
    ; 遊戲主循環
    .while gameRunning == 1
        ;處理輸入
        call ProcessInput
        
        ; 檢查暫停狀態
        cmp gamePaused, 1
        je PausedState
        
        ; 正常遊戲狀態的處理
        call Clrscr
        call UpdateGame
        call DrawGame
        jmp ContinueGameLoop
    
    PausedState:
        ; 暫停狀態只繪製畫面
        call DrawGame
        call DrawPauseMessage
        
    ContinueGameLoop:
        mov eax, speed
        call Delay
        
        ; 檢查是否升級
        mov eax, score
        xor edx, edx
        mov ecx, LEVEL_UP_SCORE
        div ecx
        inc eax
        cmp eax, MAX_LEVEL
        jle @F
        mov eax, MAX_LEVEL
    @@:
        mov difficulty, eax
        
        ; 更新遊戲速度
        mov eax, BASE_SPEED
        mov ebx, difficulty
        shr eax, 1
        cmp eax, MIN_SPEED
        jge @F
        mov eax, MIN_SPEED
    @@:
        mov speed, eax
        
        ; 結束條件
        cmp score, LEVEL_UP_SCORE * MAX_LEVEL
        jl ContinueGame
        mov gameRunning, 0
    ContinueGame:
    .endw
    
    ; 遊戲結束
    call Clrscr
    mov edx, offset WinMsg
    call WriteString
    call Crlf
    mov edx, OFFSET gameOverMsg
    call WriteString
    call ReadChar
    
    call ExitProcess
main ENDP

; ============================================================================
; 暫停訊息 
; ============================================================================
DrawPauseMessage PROC
    push eax
    push edx
    push ecx

    ; 清除暫停訊息區域
    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov ecx, 16
    mov al, ' '
ClearLoop:
    call WriteChar
    inc dl
    loop ClearLoop

    ; 顯示暫停訊息
    mov eax, yellow
    call SetTextColor
    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET pauseMsg
    call WriteString

    ; 恢復暫存器
    pop ecx
    pop edx
    pop eax
    ret
DrawPauseMessage ENDP

; ============================================================================
; 初始化遊戲
; ============================================================================
InitGame PROC uses ecx edi eax
    ; 清空水果陣列
    mov ecx, MAX_FRUITS * 4
    mov edi, OFFSET fruits
    xor eax, eax
    rep stosd
    
    ; 設置初始分數和玩家位置
    mov score, 0
    mov playerPos, 20
    
    ; 初始化隨機數種子
    call Randomize
    
    ; 設置文字顏色為白色
    mov eax, white
    call SetTextColor
    ret
InitGame ENDP

; =====================================================================
; 顯示遊戲封面
; =====================================================================
ShowTitleScreen PROC
    call Clrscr
    
    ; 顯示遊戲標題
    mov eax, cyan
    call SetTextColor

    mov edx, OFFSET titleArt1
    call WriteString
    mov edx, OFFSET titleArt2
    call WriteString
    mov edx, OFFSET titleArt3
    call WriteString
    mov edx, OFFSET titleArt4
    call WriteString
    mov edx, OFFSET titleArt5
    call WriteString
    mov edx, OFFSET titleArt6
    call WriteString
    mov edx, OFFSET titleArt7
    call WriteString
    mov edx, OFFSET titleArt8
    call WriteString
    mov edx, OFFSET titleArt9
    call WriteString

    ; 顯示提示訊息
    mov eax, green
    call SetTextColor
    mov edx, OFFSET pressEnterMsg
    call WriteString

    ; 等待 Enter 鍵
WaitForEnter:
    call ReadChar
    cmp al, 13          ; Enter 鍵 ASCII = 13
    jne WaitForEnter
    ret
ShowTitleScreen ENDP

; =====================================================================
; 顯示規則畫面
; =====================================================================
ShowRulesScreen PROC
    call Clrscr
    
    ; 顯示規則標題
    mov eax, yellow
    call SetTextColor
    mov edx, OFFSET rulesMsg1
    call WriteString
    call Crlf
    
    ; 顯示規則
    mov eax, white
    call SetTextColor
    mov edx, OFFSET rulesMsg2
    call WriteString
    mov edx, OFFSET rulesMsg3
    call WriteString
    mov edx, OFFSET rulesMsg4
    call WriteString
    mov edx, OFFSET rulesMsg5
    call WriteString
    mov edx, OFFSET rulesMsg6
    call WriteString
    mov edx, OFFSET rulesMsg7
    call WriteString
    
    ; 顯示繼續提示
    mov eax, green
    call SetTextColor
    mov edx, OFFSET pressEnterMsg
    call WriteString
    
    ; 等待 Enter 鍵
WaitForEnter:
    call ReadChar
    cmp al, 13          ; Enter 鍵 ASCII = 13
    jne WaitForEnter
    ret
ShowRulesScreen ENDP
; ============================================================================
; 處理輸入
; ============================================================================
ProcessInput PROC uses eax
    mov eax, 10            ; 10ms 超時設定
    call ReadKey           ; 非阻塞讀取按鍵
    jz NoInput             ; 沒有按鍵則直接返回

    ; 轉為大寫統一處理
    and al, 11011111b      ; 轉換小寫為大寫 (清除第5位)

    ; --- 所有遊戲狀態都處理的按鍵 ---
    ; A鍵 - 向左移動
    cmp al, 'A'
    jne NotAKey
    cmp playerPos, 1        ; 檢查左邊界
    jle NotAKey
    dec playerPos           ; 移動玩家位置
NotAKey:

    ; D鍵 - 向右移動
    cmp al, 'D'
    jne NotDKey
    mov eax, playerPos
    add eax, 5             ; 籃子寬度為5格
    cmp eax, SCREEN_WIDTH  ; 檢查右邊界
    jge NotDKey
    inc playerPos          ; 移動玩家位置
NotDKey:

    ; Q鍵 - 退出遊戲
    cmp al, 'Q'
    jne NotQKey
    mov gameRunning, 0     ; 遊戲結束
NotQKey:

    ; --- 暫停/繼續專用處理 ---
    cmp al, 'P'
    jne NoInput            ; 不是P鍵則結束處理

    ; 根據當前狀態切換
    cmp gamePaused, 1
    je  UnpauseGame        ; 當前狀態是已暫停，取消暫停

    ; 執行暫停邏輯
    mov gamePaused, 1      ; 設置暫停標誌
    call DrawPauseMessage  ; 繪製暫停訊息
    jmp NoInput

UnpauseGame:
    ; 執行取消暫停邏輯
    mov gamePaused, 0      ; 清除暫停標誌
    
    ; 顯示倒計時 (3秒)
    mov eax, yellow        ; 設置黃色文字
    call SetTextColor
    
    mov ecx, 3             ; 倒數3秒
CountdownLoop:
    ; 先清除舊訊息
    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET resumeMsg
    call WriteString       ; "遊戲將在 X 秒後恢復..."
    
    ; 動態更新數字位置 (覆蓋X)
    mov dl, 19             ; X的X座標
    mov dh, 10             ; X的Y座標
    call Gotoxy
    mov eax, ecx
    call WriteDec          ; 顯示當前倒數數字
    
    mov eax, 1000          ; 延遲1秒
    call Delay
    loop CountdownLoop
    
    ; 清除倒數訊息
    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov ecx, 16  
    mov al, ' '
ClearLoop:
    call WriteChar
    loop ClearLoop

NoInput:
    ret
ProcessInput ENDP
;============================================================================
; 更新遊戲邏輯
; ============================================================================
UpdateGame PROC uses eax
    ; 生成新水果
    mov eax, 100
    call RandomRange
    cmp eax, 20            ; 20% 機率生成水果
    jge @F
    call AddFruit
    @@:
    
    ; 更新所有水果位置
    call UpdateFruits
    
    ; 碰撞檢測
    call CheckCollisions
    ret
UpdateGame ENDP

; ============================================================================
; 添加新水果
; 這邊算法要再看一下，RandomRange沒用到
; ============================================================================
AddFruit PROC uses esi edi eax ebx ecx edx
    ; 計算生成機率 (使用difficulty而不是level)
    mov eax, 100
    call RandomRange
    
    ; 基礎機率 + 難度加成 (15% + 5% per difficulty level)
    mov ebx, 50                 ; 基礎機率 15%
    mov ecx, difficulty
    imul ecx, 5                 ; 每級難度增加5%
    add ebx, ecx
    
    cmp eax, ebx
    jge @F                      ; 如果隨機數大於機率值則不生成
    
    xor esi, esi                ; 從頭開始搜索
    
    ; 尋找空的水果位置
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16             ; 每個水果 4 個 DWORD = 16 bytes
        mul ecx
        add eax, OFFSET fruits
        mov edi, eax
        
        ; 檢查是否活躍
        cmp DWORD PTR [edi + 8], 0
        jne NextFruit
        
        ; 設置新水果
        mov eax, SCREEN_WIDTH - 2
        call RandomRange
        inc eax                 ; 避免在邊框上，X範圍 1 到 38
        mov [edi], eax          ; X 位置
        
        ; 設置初始Y位置 (根據難度調整)
        mov DWORD PTR [edi + 4], 1     ; 基礎Y位置
        mov eax, difficulty
        add DWORD PTR [edi + 4], eax   ; 難度越高初始位置越低
        
        mov DWORD PTR [edi + 8], 1     ; 設為活躍
        
        ; 設置水果類型
        mov eax, 7
        call RandomRange
        mov DWORD PTR [edi + 12], eax  ; 水果類型
        jmp Done
        
    NextFruit:
        inc esi
    .endw
    
Done:
@@:
    ret
AddFruit ENDP

; ============================================================================
; 更新水果位置
; ============================================================================
UpdateFruits PROC uses esi eax ecx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        ; 檢查水果是否活躍
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        ; 移動水果向下
        inc DWORD PTR [eax + 4]
        
        ; 檢查是否到底
        cmp DWORD PTR [eax + 4], SCREEN_HEIGHT - 1
        jl NextFruit
        mov DWORD PTR [eax + 8], 0    ; 設為非活躍
        
    NextFruit:
        inc esi
    .endw
    ret
UpdateFruits ENDP

; ============================================================================
; 碰撞檢測
; ============================================================================
CheckCollisions PROC uses esi eax ebx ecx edx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        ; 檢查水果是否活躍
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        mov ebx, [eax]          ; 水果 X
        mov ecx, [eax + 4]      ; 水果 Y
        
        ; 檢查是否在玩家行
        cmp ecx, PLAYER_ROW
        jne NextFruit
        
        ; 檢查 X 範圍碰撞
        mov edx, playerPos
        cmp ebx, edx
        jl NextFruit
        add edx, 4
        cmp ebx, edx
        jg NextFruit
        
        ; 碰撞發生
        mov DWORD PTR [eax + 8], 0    ; 水果消失
        add score, 10                 ; 增加分數
        
    NextFruit:
        inc esi
    .endw
    ret
CheckCollisions ENDP

; ============================================================================
; 繪製遊戲畫面
; ============================================================================
DrawGame PROC uses eax
    ; 繪製邊框
    mov eax, white
    call SetTextColor
    call DrawBorder
    
    ; 繪製水果
    mov eax, yellow
    call SetTextColor
    call DrawFruits
    
    ; 繪製玩家
    mov eax, green
    call SetTextColor
    call DrawPlayer
    
    ; 顯示分數
    mov eax, white
    call SetTextColor
    call DisplayScore
    ; 顯示關卡
    mov dl, 20
    mov dh, SCREEN_HEIGHT + 1
    call Gotoxy
    mov edx, OFFSET difficultyMsg
    call WriteString
    mov eax, difficulty
    call WriteDec
    ret
DrawGame ENDP

; ============================================================================
; 繪製邊框
; ============================================================================
DrawBorder PROC uses ecx edx
    ; 邊框
    mov dl, 0            ; Column
    mov dh, 0            ; Row
    call Gotoxy
    mov ecx, SCREEN_WIDTH
    .while ecx > 0
        mov al, '-'
        call WriteChar
        dec ecx
    .endw
    
    ; 下邊框
    mov dl, 0
    mov dh, SCREEN_HEIGHT - 1
    call Gotoxy
    mov ecx, SCREEN_WIDTH
    .while ecx > 0
        mov al, '-'
        call WriteChar
        dec ecx
    .endw
    
    ; 左右邊框
    mov ebx, 1
    .while ebx < SCREEN_HEIGHT - 1
        mov dl, 0
        mov dh, bl
        call Gotoxy
        mov al, '|'
        call WriteChar
        
        mov dl, SCREEN_WIDTH - 1
        mov dh, bl
        call Gotoxy
        mov al, '|'
        call WriteChar
        
        inc ebx
    .endw
    ret
DrawBorder ENDP

; ============================================================================
; 繪製水果
; ============================================================================
DrawFruits PROC uses esi eax ebx ecx edx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        cmp DWORD PTR [eax + 8], 1    ; 如果水果活躍
        jne NextFruit
        
        mov edx, [eax]              ; X
        mov ebx, [eax + 4]          ; Y
        mov ecx, [eax + 12]         ; 類型
        
        ; 移動游標到水果位置
        mov dl, dl
        mov dh, bl
        call Gotoxy
        
        ; 繪製水果符號
        add ecx, 'A'
        mov al, cl
        call WriteChar
        
    NextFruit:
        inc esi
    .endw
    ret
DrawFruits ENDP

; ============================================================================
; 繪製玩家
; ============================================================================
DrawPlayer PROC uses eax edx
    mov dl, BYTE PTR playerPos
    mov dh, PLAYER_ROW
    call Gotoxy
    
    ; 繪製籃子
    mov al, '['
    call WriteChar
    mov al, '='
    call WriteChar
    call WriteChar
    call WriteChar
    mov al, ']'
    call WriteChar
    ret
DrawPlayer ENDP

; ============================================================================
; 顯示分數
; ============================================================================
DisplayScore PROC uses eax edx
    mov dl, 0
    mov dh, SCREEN_HEIGHT + 1
    call Gotoxy
    
    mov edx, OFFSET scoreMsg
    call WriteString
    mov eax, score
    call WriteDec
    call Crlf
    ret
DisplayScore ENDP

END main
