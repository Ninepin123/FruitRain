; 接水果遊戲 - Irvine32 版本
; 使用鍵盤左右鍵控制籃子接掉落的水果

INCLUDE Irvine32.inc

; ============================================================================
; 常數定義
; ============================================================================
SCREEN_WIDTH     = 40      ; 遊戲畫面寬度
SCREEN_HEIGHT    = 20      ; 遊戲畫面高度
MAX_FRUITS       = 5       ; 最多水果數量
PLAYER_ROW       = 18      ; 玩家籃子的行位置

; ============================================================================
; 資料區
; ============================================================================
.data
    ; 遊戲變數
    playerPos       DWORD 20             ; 玩家位置(列) 測試123123123
    score           DWORD 0              ; 分數
    gameRunning     DWORD 1              ; 遊戲狀態456
    
    ; 水果陣列 - 每個水果 4 個 DWORD: X, Y, active(1/0), type
    fruits          DWORD MAX_FRUITS * 4 dup(0)
    
    ; 字串資料
    titleMsg        BYTE "接水果遊戲", 13, 10, 0
    instructMsg     BYTE "使用 A/D 鍵移動籃子，Q 鍵退出", 13, 10, 0
    scoreMsg        BYTE "分數: ", 0
    gameOverMsg     BYTE "遊戲結束! 按任意鍵退出...", 13, 10, 0
    
    ; 遊戲符號
    playerChar      BYTE "[===]", 0        ; 玩家籃子
    fruitChars      BYTE "ABCDEFG", 0      ; 水果符號
    borderChar      BYTE "-|+", 0         ; 邊框符號
    
.code
; ============================================================================
; 主程式
; ============================================================================
main PROC
    call InitGame
    
    ; 顯示遊戲說明
    mov edx, OFFSET titleMsg
    call WriteString
    mov edx, OFFSET instructMsg
    call WriteString
    call WaitMsg
    
    ; 遊戲主循環
    .while gameRunning == 1
        call ClearScreen
        call ProcessInput
        call UpdateGame
        call DrawGame
        mov eax, 150            ; 遊戲速度
        call Delay
    .endw
    
    ; 遊戲結束
    call ClearScreen
    mov edx, OFFSET gameOverMsg
    call WriteString
    call ReadChar
    
    call ExitProcess
main ENDP

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

; ============================================================================
; 處理輸入
; ============================================================================
ProcessInput PROC uses eax
    mov eax, 10            ; 10ms timeout
    call ReadKey           ; 非阻塞讀取
    jz NoInput             ; 沒有按鍵
    
    ; 轉為大寫
    and al, 11011111b      ; 將小寫轉為大寫
    
    ; A 鍵 - 向左移動
    cmp al, 'A'
    jne @F
    cmp playerPos, 1
    jle @F
    dec playerPos
    @@:
    
    ; D 鍵 - 向右移動
    cmp al, 'D'
    jne @F
    mov eax, playerPos
    add eax, 6
    cmp eax, SCREEN_WIDTH
    jge @F
    inc playerPos
    @@:
    
    ; Q 鍵 - 退出遊戲
    cmp al, 'Q'
    jne NoInput
    mov gameRunning, 0
    
NoInput:
    ret
ProcessInput ENDP

; ============================================================================
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
; ============================================================================
AddFruit PROC uses esi edi eax ebx ecx edx
    xor esi, esi
    
    ; 尋找空的水果位置
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16         ; 每個水果 4 個 DWORD = 16 bytes
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
        mov [edi], eax         ; X 位置
        mov DWORD PTR [edi + 4], 1     ; Y 位置（從第二行開始）
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
    ret
DrawGame ENDP

; ============================================================================
; 繪製邊框
; ============================================================================
DrawBorder PROC uses ecx edx
    ; 上邊框
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

; ============================================================================
; 清除螢幕
; ============================================================================
ClearScreen PROC
    call Clrscr
    ret
ClearScreen ENDP

END main