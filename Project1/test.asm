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
BOMB_TYPE        = 7       ; Bomb type identifier (0-6 for fruits, 7 for bomb)
MAX_LIVES        = 3       ; Maximum number of lives

; Color constants for SetTextColor
red              = 12
green            = 10
blue             = 9
yellow           = 14
magenta          = 13
cyan             = 11
white            = 15
lightRed         = 4

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
    winMsg          BYTE "You Win! ", 13, 10, 0
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
    fruits          DWORD MAX_FRUITS * 4 dup(0)

    ; Game symbols
    playerChar      BYTE "[===]", 0             ; Player basket
    fruitChars      BYTE "ABCDEFG@", 0          ; Fruit symbols + bomb (@)

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
    rulesMsg3 BYTE "2. Catch the falling fruits (A-G)", 13, 10, 0
    rulesMsg4 BYTE "3. Points: A/B=5, C/D=10, E/F=15, G=20", 13, 10, 0
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
        mov edx, OFFSET winMsg
        invoke PlaySound, NULL, 0, 0
        call WriteString
        call Crlf
        mov edx, OFFSET yourScoreStr
        call WriteString
        mov eax, score
        call WriteDec
        call Crlf
        call ReadChar
        INVOKE ExitProcess, 0

    ContinueGame:
    .endw
    
    call Clrscr
    mov eax, white
    call SetTextColor
    mov edx, OFFSET gameOverMsg
    invoke PlaySound, NULL, 0, 0
    call WriteString
    call Crlf
    mov edx, OFFSET yourScoreStr
    call WriteString
    mov eax, score
    call WriteDec
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
    mov ecx, 40
    mov al, ' '
ClearLoop:
    call WriteChar
    inc dl
    loop ClearLoop

    mov eax, yellow
    call SetTextColor
    mov dl, 4
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
    mov eax, 400
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
    mov eax, 150
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
    mov ecx, 40
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
    mov eax, 100
    call RandomRange
    
    mov ebx, 50
    mov ecx, difficulty
    imul ecx, 5
    add ebx, ecx
    
    cmp eax, ebx
    jge @F
    
    ; Find empty fruit position
    xor esi, esi
    mov ecx, MAX_FRUITS
    .while esi < ecx
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        mov edi, eax
        
        cmp DWORD PTR [edi + 8], 0
        jne NextFruit
        
        mov eax, SCREEN_WIDTH - 2
        call RandomRange
        inc eax
        mov [edi], eax
        
        mov DWORD PTR [edi + 4], 1
        mov eax, difficulty
        add DWORD PTR [edi + 4], eax
        mov DWORD PTR [edi + 8], 1
        
        ; Randomly decide fruit or bomb based on difficulty
        mov eax, 100
        call RandomRange
        mov ecx, difficulty
        cmp ecx, 1
        je EasyBombChance
        cmp ecx, 2
        je NormalBombChance
        cmp ecx, 3
        je HardBombChance
        jmp RegularFruit

EasyBombChance:
        cmp eax, 12
        jl SetBomb
        jmp RegularFruit

NormalBombChance:
        cmp eax, 25
        jl SetBomb
        jmp RegularFruit

HardBombChance:
        cmp eax, 40
        jl SetBomb
        jmp RegularFruit

SetBomb:
        mov DWORD PTR [edi + 12], BOMB_TYPE
        jmp Done

RegularFruit:
        mov eax, 7
        call RandomRange
        mov DWORD PTR [edi + 12], eax
        
    NextFruit:
        inc esi
        mov ecx, MAX_FRUITS
    .endw
    
Done:
@@:
    ret
AddFruit ENDP

; ============================================================================
; Update Fruit Positions
; ============================================================================
UpdateFruits PROC uses esi eax ecx ebx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        ; Update Y coordinate based on difficulty
        mov ebx, fruitDropSpeed
        add DWORD PTR [eax + 4], ebx
        
        cmp DWORD PTR [eax + 4], SCREEN_HEIGHT - 1
        jl NextFruit
        mov DWORD PTR [eax + 8], 0
        
    NextFruit:
        inc esi
    .endw
    ret
UpdateFruits ENDP

; ============================================================================
; Collision Detection
; ============================================================================
CheckCollisions PROC uses esi eax ebx ecx edx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        mov ebx, [eax]      ; X
        mov ecx, [eax + 4]  ; Y
        
        ; Check if fruit is at basket row or will pass it
        cmp ecx, PLAYER_ROW
        je CheckXCollision
        mov edx, PLAYER_ROW
        sub edx, fruitDropSpeed
        cmp ecx, edx
        jl NextFruit
        mov edx, ecx
        add edx, fruitDropSpeed
        cmp edx, PLAYER_ROW
        jle NextFruit
        
CheckXCollision:
        mov edx, playerPos
        cmp ebx, edx
        jl NextFruit
        add edx, 4
        cmp ebx, edx
        jg NextFruit
        
        ; Check if it's a bomb
        cmp DWORD PTR [eax + 12], BOMB_TYPE
        je BombHit
        
        ; Regular fruit collision - assign score based on fruit type
        mov DWORD PTR [eax + 8], 0
        mov ebx, [eax + 12]  ; Get fruit type
        cmp ebx, 0           ; Fruit A
        je AddScore5
        cmp ebx, 1           ; Fruit B
        je AddScore5
        cmp ebx, 2           ; Fruit C
        je AddScore10
        cmp ebx, 3           ; Fruit D
        je AddScore10
        cmp ebx, 4           ; Fruit E
        je AddScore15
        cmp ebx, 5           ; Fruit F
        je AddScore15
        cmp ebx, 6           ; Fruit G
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
        mov edx, OFFSET gameOverMsg
        invoke PlaySound, NULL, 0, 0
        call WriteString
        call Crlf
        mov edx, OFFSET yourScoreStr
        call WriteString
        mov eax, score
        call WriteDec
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
    
    mov eax, green
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
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        mov edx, [eax]              ; X
        mov ebx, [eax + 4]          ; Y
        mov ecx, [eax + 12]         ; Type
        mov dl, dl
        mov dh, bl
        call Gotoxy
        
        ; Set color based on fruit/bomb type
        push eax
        mov eax, ecx
        cmp eax, 0
        je SetRed
        cmp eax, 1
        je SetGreen
        cmp eax, 2
        je SetBlue
        cmp eax, 3
        je SetYellow
        cmp eax, 4
        je SetMagenta
        cmp eax, 5
        je SetCyan
        cmp eax, 6
        je SetWhite
        cmp eax, BOMB_TYPE
        je SetLightRed
        jmp DrawCharacter

SetRed:
        mov eax, red
        jmp SetColor
SetGreen:
        mov eax, green
        jmp SetColor
SetBlue:
        mov eax, blue
        jmp SetColor
SetYellow:
        mov eax, yellow
        jmp SetColor
SetMagenta:
        mov eax, magenta
        jmp SetColor
SetCyan:
        mov eax, cyan
        jmp SetColor
SetWhite:
        mov eax, white
        jmp SetColor
SetLightRed:
        mov eax, lightRed
SetColor:
        call SetTextColor
DrawCharacter:
        mov al, BYTE PTR [fruitChars + ecx]
        call WriteChar
        mov eax, white
        call SetTextColor
        pop eax
        
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