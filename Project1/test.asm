INCLUDE Irvine32.inc
INCLUDELIB Winmm.lib

.386
.model flat, stdcall
.stack 4096

ExitProcess PROTO, dwExitCode:DWORD
PlaySound PROTO, pszSound:PTR BYTE, hmod:DWORD, fdwSound:DWORD

; ============================================================================
; Constants Definition
; ============================================================================
SCREEN_WIDTH     = 40      ; Game screen width
SCREEN_HEIGHT    = 20      ; Game screen height
MAX_FRUITS       = 5       ; Maximum number of fruits on screen
PLAYER_ROW       = 18      ; Player basket row position
MAX_LEVEL        = 5       ; Maximum level for speed scaling
LEVEL_UP_SCORE   = 30      ; Score needed per level
BASE_SPEED       = 400     ; Base game speed (ms)
MIN_SPEED        = 50      ; Minimum game speed
BOMB_TYPE        = 5       ; Bomb type identifier (0-4 for fruits, 5 for bomb)
MAX_LIVES        = 3       ; Maximum number of lives

; Color constants for SetTextColor
red              = 4
green            = 2
blue             = 1
yellow           = 14
cyan             = 3
white            = 15
lightRed         = 12
pink             = 13  
orange           = 6    
purple           = 5    

; ============================================================================
; Data Section
; ============================================================================
.data
    ; Game variables
    playerPos       DWORD ?                                         ; Player position (column)
    score           DWORD ?                                         ; Score
    lives           DWORD MAX_LIVES                                ; Player lives
    gameRunning     DWORD 1                                         ; Game state, =1 running, =0 stopped
    speed           DWORD 400                                       ; Game speed (ms)
    gamePaused      DWORD 0                                         ; Pause state
    pauseMsg        BYTE "Game paused, press P to continue", 0
    resumeMsg       BYTE "Game will continue in  X seconds", 0
    scoreMsg        BYTE "Score: ", 0
    livesMsg        BYTE "Lives: ", 0
    gameOverMsg     BYTE "Game Over! ", 13, 10, 0
    yourScoreStr    BYTE "Your score: ", 0
    difficultyMsg   BYTE "Difficulty: ", 0
    difficulty      DWORD 2                                         ; Default difficulty: Normal
    pressEnterMsg   BYTE 13,10,"Press Enter key to start game...",13,10,0
    baseSpeed       DWORD ?
    levelUpScore    DWORD ?
    maxFruits       DWORD ?
    diffEasy        BYTE "Easy", 0
    diffNormal      BYTE "Normal", 0
    diffHard        BYTE "Hard", 0
    currentLevel    DWORD 1
    fruitDropSpeed  DWORD 1
    ; Fruit/bomb array - each has 4 DWORDs: X, Y, active(1/0), type
    fruits DWORD MAX_FRUITS * 5 dup(0)

    ; Game symbols
    playerChar      BYTE "[===]", 0             ; Player basket
    fruitChars      BYTE "SBOGW@", 0          ; Fruit symbols + bomb (@)
    ; Title screen
    titleArt1 BYTE 13,10,"  ________  _______   __    __  ______  ________        _______    ______   ______  __    __ ",13,10,0
    titleArt2 BYTE       " |        \|       \ |  \  |  \|      \|        \      | $$$$$$$\|  $$$$$$\ \$$$$$$| $$\ | $$",13,10,0
    titleArt3 BYTE       " | $$$$$$$$| $$$$$$$\| $$  | $$ \$$$$$$ \$$$$$$$$      | $$__| $$| $$__| $$  | $$  | $$$\| $$",13,10,0
    titleArt4 BYTE       " | $$__    | $$__| $$| $$  | $$  | $$     | $$         | $$    $$| $$    $$  | $$  | $$$$\ $$",13,10,0
    titleArt5 BYTE       " | $$  \   | $$    $$| $$  | $$  | $$     | $$         | $$$$$$$\| $$$$$$$$  | $$  | $$\$$ $$",13,10,0
    titleArt6 BYTE       " | $$$$$   | $$$$$$$\| $$  | $$  | $$     | $$         | $$  | $$| $$  | $$ _| $$_ | $$ \$$$$",13,10,0
    titleArt7 BYTE       " | $$      | $$  | $$| $$__/ $$ _| $$_    | $$         | $$  | $$| $$  | $$|   $$ \| $$  \$$$",13,10,0
    titleArt8 BYTE       " | $$      | $$  | $$ \$$    $$|   $$ \   | $$         | $$  | $$| $$  | $$ \$$$$$$ \$$   \$$",13,10,0
    titleArt9 BYTE       " | $$       \$$   \$$  \$$$$$$  \$$$$$$    \$$          \$$   \$$ \$$   \$$ \$$$$$$ \$$   \$$",13,10,0

    ; Game rules
    rulesMsg1 BYTE "Game Rules:", 13, 10, 0
    rulesMsg2 BYTE "1. Use A/D keys to move the basket left and right, please make sure your input method is set to English", 13, 10, 0
    rulesMsg3 BYTE "2. Catch the falling fruits: S(Strawberry), B(Banana), O(Orange), G(Grape), W(Watermelon)", 13, 10, 0
    rulesMsg4 BYTE "3. Points: S=5, B=10, O=10, G=15, W=20", 13, 10, 0
    rulesMsg5 BYTE "4. Level difficulty increases at certain score thresholds", 13, 10, 0
    rulesMsg6 BYTE "5. Press P key to pause the game", 13, 10, 0
    rulesMsg7 BYTE "6. Press Q key to quit the game", 13, 10, 0
    rulesMsg8 BYTE "7. Avoid bombs (@) - catching one reduces lives (3 lives total)!", 13, 10, 0


    ; Music
    SND_ASYNC    DWORD 00000001h   ; Asynchronous playback
    SND_LOOP     DWORD 00000008h   ; Loop playback
    SND_FILENAME DWORD 00020000h   ; Sound is a filename
    backgroundMusic BYTE "background.wav", 0  ; Music filename
    combinedFlags DWORD 00020009h   ; SND_FILENAME | SND_ASYNC | SND_LOOP
    chooseDiffMsg BYTE "Choose difficulty level:", 13,10,0
    diffOptionsMsg BYTE "1. Easy   2. Normal   3. Hard", 13,10,0

; ============================================================================
; Code Section
; ============================================================================
.code
main PROC
    call InitGame
    call ShowTitleScreen
    call ShowRulesScreen
    call SelectDifficulty
    invoke PlaySound, OFFSET backgroundMusic, 0, combinedFlags
    ; Game main loop
    .while gameRunning == 1
        call ProcessInput
        
        cmp gamePaused, 1
        je PausedState
        
        call Clrscr
        call UpdateGame
        call DrawGame
        jmp ContinueGameLoop
    
    PausedState:
        call DrawGame
        call DrawPauseMessage
        
    ContinueGameLoop:
        mov eax, speed
        call Delay
        
        ; Calculate current level (based on score), but don't affect user-selected difficulty
        mov eax, score
        xor edx, edx
        mov ecx, LEVEL_UP_SCORE
        div ecx
        inc eax
        ; Cap at MAX_LEVEL
        cmp eax, MAX_LEVEL
        jle @F
        mov eax, MAX_LEVEL
    @@:
        mov currentLevel, eax
        
        ; Calculate game speed based on initial difficulty and current level
        mov eax, baseSpeed
        mov ebx, currentLevel
        shr eax, 1               ; Divide by 2
        cmp eax, MIN_SPEED 
        jge @F
        mov eax, MIN_SPEED
    @@:
        mov speed, eax
        ; Game win condition
        cmp score, LEVEL_UP_SCORE * MAX_LEVEL
        jl ContinueGame
        mov gameRunning, 0
        call Clrscr
        mov eax, white
        call SetTextColor
        invoke PlaySound, NULL, 0, 0
        mov edx, OFFSET yourScoreStr
        call WriteString
        mov eax, score
        call WriteDec
        call Crlf
        mov edx, OFFSET gameOverMsg
        call WriteString
        call Crlf
        call ReadChar
        INVOKE ExitProcess, 0

    ContinueGame:
    .endw
    
    call Clrscr
    mov eax, white
    call SetTextColor
    invoke PlaySound, NULL, 0, 0
    mov edx, OFFSET yourScoreStr
    call WriteString
    mov eax, score
    call WriteDec
    call Crlf
    mov edx, OFFSET gameOverMsg
    call WriteString
    call Crlf
    call ReadChar
    INVOKE ExitProcess, 0
main ENDP

; ============================================================================
; Pause Message
; ============================================================================
DrawPauseMessage PROC
    push eax
    push edx
    push ecx

    ; Clear pause message area
    mov dl, 4
    mov dh, 10
    call Gotoxy
    mov ecx, 20
    mov al, ' '
ClearLoop:
    call WriteChar
    inc dl
    loop ClearLoop

    mov eax, yellow
    call SetTextColor
    mov dl,4
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET pauseMsg
    call WriteString

    pop ecx
    pop edx
    pop eax
    ret
DrawPauseMessage ENDP

; ============================================================================
; Initialize Game
; ============================================================================
InitGame PROC uses ecx edi eax
    mov ecx, MAX_FRUITS * 4
    mov edi, OFFSET fruits
    xor eax, eax
    rep stosd
    
    mov score, 0
    mov lives, MAX_LIVES
    mov playerPos, 20
    call Randomize
    mov eax, white
    call SetTextColor
    ret
InitGame ENDP

; =====================================================================
; Show Game Title Screen
; =====================================================================
ShowTitleScreen PROC
    call Clrscr
    
    mov eax, blue
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

    ; Display prompt message
    invoke PlaySound, NULL, 0, 0
    mov eax, green
    call SetTextColor
    mov edx, OFFSET pressEnterMsg
    call WriteString

    ; Wait for Enter key
WaitForEnter:
    call ReadChar
    cmp al, 13
    jne WaitForEnter
    ret
ShowTitleScreen ENDP

; =====================================================================
; Show Rules Screen
; =====================================================================
ShowRulesScreen PROC
    call Clrscr
    
    mov eax, yellow
    call SetTextColor
    mov edx, OFFSET rulesMsg1
    call WriteString
    call Crlf
    
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
    mov edx, OFFSET rulesMsg8
    call WriteString
    
    mov eax, green
    call SetTextColor
    mov edx, OFFSET pressEnterMsg
    call WriteString
    
WaitForEnter:
    call ReadChar
    cmp al, 13
    jne WaitForEnter
    ret
ShowRulesScreen ENDP

; =====================================================================
; Select Difficulty
; =====================================================================
SelectDifficulty PROC
    call Clrscr
    mov eax, yellow
    call SetTextColor

    mov edx, OFFSET chooseDiffMsg
    call WriteString
    mov edx, OFFSET diffOptionsMsg
    call WriteString

WaitForChoice:
    call ReadChar
    cmp al, '1'
    je SetEasy
    cmp al, '2'
    je SetNormal
    cmp al, '3'
    je SetHard
    jmp WaitForChoice

SetEasy:
    mov eax, 1
    mov difficulty, eax
    mov eax, 600
    mov baseSpeed, eax
    mov eax, 50
    mov levelUpScore, eax
    mov eax, 5
    mov maxFruits, eax
    mov eax, 1            ; Easy difficulty drop speed - move 1 row per update
    mov fruitDropSpeed, eax
    jmp EndSelect

SetNormal:
    mov eax, 2
    mov difficulty, eax
    mov eax, 450
    mov baseSpeed, eax
    mov eax, 30
    mov levelUpScore, eax
    mov eax, 5
    mov maxFruits, eax
    mov eax, 2            ; Normal difficulty drop speed - move 2 rows per update
    mov fruitDropSpeed, eax
    jmp EndSelect

SetHard:
    mov eax, 3
    mov difficulty, eax
    mov eax, 250
    mov baseSpeed, eax
    mov eax, 30
    mov levelUpScore, eax
    mov eax, 4
    mov maxFruits, eax
    mov eax, 3            ; Hard difficulty drop speed - move 3 rows per update
    mov fruitDropSpeed, eax
    jmp EndSelect

EndSelect:
    ret
SelectDifficulty ENDP

; ============================================================================
; Process Input
; ============================================================================
ProcessInput PROC uses eax
    mov eax, 10
    call ReadKey
    jz NoInput

    and al, 11011111b      ; Convert to uppercase

    ; Q key - Quit game
    cmp al, 'Q'
    jne NotQKey
    mov gameRunning, 0
    jmp NoInput
NotQKey:

    ; P key - Pause/Resume toggle
    cmp al, 'P'
    jne NotPKey
    cmp gamePaused, 1
    je UnpauseGame
    mov gamePaused, 1
    call DrawPauseMessage
    jmp NoInput

UnpauseGame:
    mov gamePaused, 0
    mov eax, yellow
    call SetTextColor
    
    mov ecx, 3
CountdownLoop:
    mov dl, 4
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET resumeMsg
    call WriteString
    mov dl, 27
    mov dh, 10
    call Gotoxy
    mov eax, ecx
    call WriteDec
    mov eax, 1000
    call Delay
    loop CountdownLoop
    
    mov dl, 4
    mov dh, 10
    call Gotoxy
    mov ecx, 20
    mov al, ' '
ClearLoop:
    call WriteChar
    loop ClearLoop
    jmp NoInput
NotPKey:

    ; Skip movement keys if paused
    cmp gamePaused, 1
    je NoInput

    ; A key - Move left
    cmp al, 'A'
    jne NotAKeyMove
    cmp playerPos, 1
    jle NotAKeyMove
    dec playerPos
NotAKeyMove:

    ; D key - Move right
    cmp al, 'D'
    jne NotDKeyMove
    mov eax, playerPos
    add eax, 5
    cmp eax, SCREEN_WIDTH
    jge NotDKeyMove
    inc playerPos
NotDKeyMove:

NoInput:
    ret
ProcessInput ENDP

; ============================================================================
; Update Game Logic
; ============================================================================
UpdateGame PROC uses eax
    mov eax, 100
    call RandomRange
    cmp eax, 30            ; 20% chance to generate fruit
    jge @F
    call AddFruit
@@:
    call UpdateFruits
    call CheckCollisions
    ret
UpdateGame ENDP

; ============================================================================
; Add New Fruit/Bomb
; ============================================================================
AddFruit PROC uses esi edi eax ebx ecx edx
    ; 1. 決定是否生成新水果 (根據機率)
    mov eax, 100
    call RandomRange
    mov edx, eax         ; 保存初始隨機值

    ; 基礎閾值 + 難度修正
    mov ebx, 50
    mov ecx, difficulty
    imul ecx, 5
    add ebx, ecx

    ; 添加隨機波動 (-10 ~ +10)
    push ebx
    mov eax, 20
    call RandomRange
    sub eax, 10
    pop ebx
    add ebx, eax

    ; 限制閾值在 20 ~ 70 範圍
    cmp ebx, 20
    jge @F
    mov ebx, 20
@@:
    cmp ebx, 70
    jle @F
    mov ebx, 70
@@:

    cmp edx, ebx
    jge NoNewFruit        ; 不新增水果

    ; 2. 尋找空位
    mov eax, MAX_FRUITS
    call RandomRange
    mov esi, eax          ; 隨機起始索引

    mov ecx, MAX_FRUITS
SearchSlot:
    mov eax, esi
    mov edx, 20           ; 每個fruit佔20 bytes
    mul edx
    add eax, OFFSET fruits

    cmp DWORD PTR [eax + 8], 0
    je FoundEmptySlot     ; isActive == 0

    inc esi
    cmp esi, MAX_FRUITS
    jl @F
    xor esi, esi          ; 回繞
@@:
    loop SearchSlot
    jmp NoNewFruit

FoundEmptySlot:
    mov edi, eax          ; edi 指向該 fruit 結構

    ; 3. 隨機位置（避開邊界兩格）
    mov eax, SCREEN_WIDTH
    sub eax, 4
    call RandomRange
    add eax, 2
    mov [edi], eax        ; xPos

    ; Y 起始位置 1 + 偏移
    mov DWORD PTR [edi + 4], 1
    mov eax, 5
    call RandomRange
    sub eax, 2
    add DWORD PTR [edi + 4], eax

    ; 設定速度與活動狀態
    mov ebx, 1
    mov eax, difficulty
    add ebx, eax
    mov DWORD PTR [edi + 8], 1      ; isActive = 1
    mov DWORD PTR [edi + 12], ebx   ; speed

    ; 4. 水果 / 炸彈判定
    mov eax, 100
    call RandomRange

    .if difficulty == 1
        cmp eax, 15
    .elseif difficulty == 2
        cmp eax, 30
    .else
        cmp eax, 45
    .endif
    jl CreateBomb

CreateFruit:
    mov eax, 5
    call RandomRange
    jmp SetType

CreateBomb:
    mov eax, BOMB_TYPE

SetType:
    mov DWORD PTR [edi + 16], eax

NoNewFruit:
    ret
AddFruit ENDP


; ============================================================================
; Update Fruit Positions
; ============================================================================
UpdateFruits PROC uses esi eax ecx ebx
    xor esi, esi

    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 20
        mul ecx
        add eax, OFFSET fruits

        cmp DWORD PTR [eax + 8], 1
        jne NextFruit

        mov ebx, [eax + 12]        ; speed
        mov ecx, [eax + 4]         ; yPos
        add DWORD PTR [eax + 4], ebx

        ; 檢查碰撞（在移動後立即檢查）
        push esi
        push eax
        call CheckCollisionSingle
        pop eax
        pop esi

        ; 若碰到底部，關閉水果
        cmp DWORD PTR [eax + 4], SCREEN_HEIGHT - 1
        jl NextFruit
        mov DWORD PTR [eax + 8], 0

    NextFruit:
        inc esi
    .endw
    ret
UpdateFruits ENDP

CheckCollisionSingle PROC uses eax ebx ecx edx
    ; eax 指向當前 fruit 結構
    mov ebx, [eax]             ; xPos
    mov ecx, [eax + 4]         ; yPos (當前 Y)
    mov edx, ecx
    sub edx, fruitDropSpeed    ; prevY = yPos - fruitDropSpeed

    ; 檢查 Y 是否經過 PLAYER_ROW
    cmp edx, PLAYER_ROW
    jg Done
    cmp ecx, PLAYER_ROW
    jl Done

    ; 檢查 X 座標
    mov edx, playerPos
    cmp ebx, edx
    jle Done
    add edx, 4
    cmp ebx, edx
    jge Done

    ; 碰撞發生
    cmp DWORD PTR [eax + 16], BOMB_TYPE
    je BombHit

    ; 是水果，處理加分
    mov DWORD PTR [eax + 8], 0
    mov ebx, [eax + 16]

    cmp ebx, 0
    je AddScore5
    cmp ebx, 1
    je AddScore10
    cmp ebx, 2
    je AddScore10
    cmp ebx, 3
    je AddScore15
    cmp ebx, 4
    je AddScore20
    jmp Done

AddScore5:
    add score, 5
    jmp Done
AddScore10:
    add score, 10
    jmp Done
AddScore15:
    add score, 15
    jmp Done
AddScore20:
    add score, 20
    jmp Done

BombHit:
    mov DWORD PTR [eax + 8], 0
    dec lives
    cmp lives, 0
    jg Done
    mov gameRunning, 0
    call Clrscr
    mov eax, white
    call SetTextColor
    invoke PlaySound, NULL, 0, 0
    mov edx, OFFSET yourScoreStr
    call WriteString
    mov eax, score
    call WriteDec
    call Crlf
    mov edx, OFFSET gameOverMsg
    call WriteString
    call Crlf
    call ReadChar
    INVOKE ExitProcess, 0

Done:
    ret
CheckCollisionSingle ENDP
; ============================================================================
; Collision Detection
; ============================================================================
CheckCollisions PROC uses esi eax ebx ecx edx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 20
        mul ecx
        add eax, OFFSET fruits

        cmp DWORD PTR [eax + 8], 1
        jne NextFruit

        mov ebx, [eax]             ; xPos
        mov ecx, [eax + 4]         ; yPos (當前 Y)
        mov edx, ecx
        sub edx, fruitDropSpeed    ; prevY = yPos - fruitDropSpeed

        ; 檢查 Y 是否經過 PLAYER_ROW
        cmp edx, PLAYER_ROW        ; prevY <= PLAYER_ROW
        jg NextFruit
        cmp ecx, PLAYER_ROW        ; currY >= PLAYER_ROW
        jl NextFruit

CheckXCollision:
        mov edx, playerPos
        cmp ebx, edx
        jle NextFruit
        add edx, 4
        cmp ebx, edx
        jge NextFruit

        ; 碰撞發生，檢查是否炸彈
        cmp DWORD PTR [eax + 16], BOMB_TYPE
        je BombHit

        ; 是水果，處理加分
        mov DWORD PTR [eax + 8], 0
        mov ebx, [eax + 16]

        cmp ebx, 0
        je AddScore5
        cmp ebx, 1
        je AddScore10
        cmp ebx, 2
        je AddScore10
        cmp ebx, 3
        je AddScore15
        cmp ebx, 4
        je AddScore20
        jmp NextFruit

AddScore5:
        add score, 5
        jmp NextFruit
AddScore10:
        add score, 10
        jmp NextFruit
AddScore15:
        add score, 15
        jmp NextFruit
AddScore20:
        add score, 20
        jmp NextFruit

BombHit:
        mov DWORD PTR [eax + 8], 0
        dec lives
        cmp lives, 0
        jg NextFruit

        mov gameRunning, 0
        call Clrscr
        mov eax, white
        call SetTextColor
        invoke PlaySound, NULL, 0, 0
        mov edx, OFFSET yourScoreStr
        call WriteString
        mov eax, score
        call WriteDec
        call Crlf
        mov edx, OFFSET gameOverMsg
        call WriteString
        call Crlf
        call ReadChar
        INVOKE ExitProcess, 0

NextFruit:
        inc esi
    .endw
    ret
CheckCollisions ENDP
; ============================================================================
; Draw Game Screen
; ============================================================================
DrawGame PROC uses eax
    mov eax, white
    call SetTextColor
    call DrawBorder
    
    call DrawFruits
    
    mov eax, blue
    call SetTextColor
    call DrawPlayer
    
    mov eax, white
    call SetTextColor
    call DisplayScore
    call DisplayLives
    call DisplayDifficulty
    ret
DrawGame ENDP

; ============================================================================
; Draw Border
; ============================================================================
DrawBorder PROC uses ecx edx
    mov dl, 0
    mov dh, 0
    call Gotoxy
    mov ecx, SCREEN_WIDTH
    .while ecx > 0
        mov al, '-'
        call WriteChar
        dec ecx
    .endw
    
    mov dl, 0
    mov dh, SCREEN_HEIGHT - 1
    call Gotoxy
    mov ecx, SCREEN_WIDTH
    .while ecx > 0
        mov al, '-'
        call WriteChar
        dec ecx
    .endw
    
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
; Draw Fruits/Bombs with Colors
; ============================================================================
DrawFruits PROC uses esi eax ebx ecx edx
    xor esi, esi                    ; ESI 為 fruit 索引

    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 20
        mul ecx
        add eax, OFFSET fruits      ; EAX 指向 fruits[esi]

        cmp DWORD PTR [eax + 8], 1  ; isActive == 1 ?
        jne NextFruit               ; 如果非活動，跳過

        ; 取得 X (EDX), Y (EBX), Type (ECX)
        mov edx, [eax]              ; xPos
        mov ebx, [eax + 4]          ; yPos
        mov ecx, [eax + 16]         ; type

        ; 設定游標位置
        mov dl, BYTE PTR [eax]      ; DL = x (低8位)
        mov dh, BYTE PTR [eax + 4]  ; DH = y
        call Gotoxy

        ; 設定文字顏色（根據 type）
        push eax                    ; 保存 fruit 指標

        mov eax, ecx
        cmp eax, 0
        je SetLightRed
        cmp eax, 1
        je SetYellow
        cmp eax, 2
        je SetOrange
        cmp eax, 3
        je SetPurple
        cmp eax, 4
        je SetGreen
        cmp eax, BOMB_TYPE
        je SetRed

        mov eax, white              ; 預設顏色
        jmp SetColor

    SetLightRed:
        mov eax, lightRed
        jmp SetColor
    SetYellow:
        mov eax, yellow
        jmp SetColor
    SetOrange:
        mov eax, orange
        jmp SetColor
    SetPurple:
        mov eax, purple
        jmp SetColor
    SetGreen:
        mov eax, green
        jmp SetColor
    SetRed:
        mov eax, red
        ; 不用跳轉，直接落到 SetColor

    SetColor:
        call SetTextColor

        mov eax, ecx
        mov al, [fruitChars + eax]
        call WriteChar

        ; 重設顏色
        mov eax, white
        call SetTextColor

        pop eax                    ; 還原 fruit 結構指標

    NextFruit:
        inc esi
    .endw

    ret
DrawFruits ENDP


; ============================================================================
; Draw Player
; ============================================================================
DrawPlayer PROC uses eax edx
    mov dl, BYTE PTR playerPos
    mov dh, PLAYER_ROW
    call Gotoxy
    
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
; Display Score
; ============================================================================
DisplayScore PROC uses eax edx
    mov dl, 0
    mov dh, SCREEN_HEIGHT + 1
    call Gotoxy
    
    mov edx, OFFSET scoreMsg
    call WriteString
    mov eax, score
    call WriteDec
    ret
DisplayScore ENDP

; ============================================================================
; Display Lives
; ============================================================================
DisplayLives PROC uses eax edx
    mov dl, 12
    mov dh, SCREEN_HEIGHT + 1
    call Gotoxy
    
    mov edx, OFFSET livesMsg
    call WriteString
    mov eax, lives
    call WriteDec
    ret
DisplayLives ENDP

; ============================================================================
; Display Difficulty
; ============================================================================
DisplayDifficulty PROC uses eax edx
    mov dl, 25
    mov dh, SCREEN_HEIGHT + 1
    call Gotoxy
    
    mov edx, OFFSET difficultyMsg
    call WriteString

    mov eax, difficulty
    cmp eax, 1
    je ShowEasy
    cmp eax, 2
    je ShowNormal
    cmp eax, 3
    je ShowHard
    jmp EndShowDifficulty

ShowEasy:
    mov edx, OFFSET diffEasy
    call WriteString
    jmp EndShowDifficulty

ShowNormal:
    mov edx, OFFSET diffNormal
    call WriteString
    jmp EndShowDifficulty

ShowHard:
    mov edx, OFFSET diffHard
    call WriteString

EndShowDifficulty:
    ret
DisplayDifficulty ENDP

END main