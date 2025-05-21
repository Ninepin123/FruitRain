INCLUDE Irvine32.inc

.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD

; ============================================================================
; Constants Definition
; ============================================================================
SCREEN_WIDTH     = 40      ; Game screen width
SCREEN_HEIGHT    = 20      ; Game screen height
MAX_FRUITS       = 5       ; Maximum number of fruits/bombs
PLAYER_ROW       = 18      ; Player basket row position
MAX_LEVEL       = 5       ; Maximum level
LEVEL_UP_SCORE  = 30      ; Score needed per level
BASE_SPEED      = 400     ; Base game speed (ms)
MIN_SPEED       = 50      ; Minimum game speed
BOMB_TYPE       = 7       ; Bomb type identifier (0-6 for fruits, 7 for bomb)
MAX_LIVES       = 3       ; Maximum number of lives

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
    resumeMsg       BYTE "Game will continue in X seconds", 0  
    scoreMsg        BYTE "Score: ", 0
    livesMsg        BYTE "Lives: ", 0
    gameOverMsg     BYTE "Game Over! Press any key to exit...", 13, 10, 0
    WinMsg          BYTE "You Win!", 0
    difficultyMsg   BYTE "Current difficulty: ", 0
    difficulty      DWORD 1                                         ; Current difficulty
    pressEnterMsg   BYTE 13,10,"Press Enter key to start game...",13,10,0    

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
    rulesMsg4 BYTE "3. Get 10 points for each caught fruit", 13, 10, 0
    rulesMsg5 BYTE "4. Level difficulty increases at certain score thresholds", 13, 10, 0
    rulesMsg6 BYTE "5. Press P key to pause the game", 13, 10, 0
    rulesMsg7 BYTE "6. Press Q key to quit the game", 13, 10, 0
    rulesMsg8 BYTE "7. Avoid bombs (@) - catching one reduces lives (3 lives total)!", 13, 10, 0

.code
; ============================================================================
; Main Program
; ============================================================================
main PROC
    call InitGame
    call ShowTitleScreen
    call ShowRulesScreen
    
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
        
        mov eax, BASE_SPEED
        mov ebx, difficulty
        shr eax, 1
        cmp eax, MIN_SPEED
        jge @F
        mov eax, MIN_SPEED
    @@:
        mov speed, eax
        
        cmp score, LEVEL_UP_SCORE * MAX_LEVEL
        jl ContinueGame
        mov gameRunning, 0
    ContinueGame:
    .endw
    
    call Clrscr
    mov edx, OFFSET WinMsg
    call WriteString
    call Crlf
    mov edx, OFFSET gameOverMsg
    call WriteString
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

    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov ecx, 16
    mov al, ' '
ClearLoop:
    call WriteChar
    inc dl
    loop ClearLoop

    mov eax, yellow
    call SetTextColor
    mov dl, 10
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

    mov eax, green
    call SetTextColor
    mov edx, OFFSET pressEnterMsg
    call WriteString

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

; ============================================================================
; Process Input
; ============================================================================
ProcessInput PROC uses eax
    mov eax, 10
    call ReadKey
    jz NoInput

    and al, 11011111b

    cmp al, 'A'
    jne NotAKey
    cmp playerPos, 1
    jle NotAKey
    dec playerPos
NotAKey:

    cmp al, 'D'
    jne NotDKey
    mov eax, playerPos
    add eax, 5
    cmp eax, SCREEN_WIDTH
    jge NotDKey
    inc playerPos
NotDKey:

    cmp al, 'Q'
    jne NotQKey
    mov gameRunning, 0
NotQKey:

    cmp al, 'P'
    jne NoInput

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
    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET resumeMsg
    call WriteString
    
    mov dl, 19
    mov dh, 10
    call Gotoxy
    mov eax, ecx
    call WriteDec
    
    mov eax, 1000
    call Delay
    loop CountdownLoop
    
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

; ============================================================================
; Update Game Logic
; ============================================================================
UpdateGame PROC uses eax
    mov eax, 100
    call RandomRange
    cmp eax, 20
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
    
    xor esi, esi
    .while esi < MAX_FRUITS
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
        
        ; Randomly decide fruit or bomb (10% chance for bomb)
        mov eax, 100
        call RandomRange
        cmp eax, 40
        jge RegularFruit
        mov DWORD PTR [edi + 12], BOMB_TYPE  ; Set as bomb
        jmp Done
RegularFruit:
        mov eax, 7
        call RandomRange
        mov DWORD PTR [edi + 12], eax
        jmp Done
        
    NextFruit:
        inc esi
    .endw
    
Done:
@@:
    ret
AddFruit ENDP

; ============================================================================
; Update Fruit Positions
; ============================================================================
UpdateFruits PROC uses esi eax ecx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        inc DWORD PTR [eax + 4]
        
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
        
        mov ebx, [eax]
        mov ecx, [eax + 4]
        
        cmp ecx, PLAYER_ROW
        jne NextFruit
        
        mov edx, playerPos
        cmp ebx, edx
        jl NextFruit
        add edx, 4
        cmp ebx, edx
        jg NextFruit
        
        ; Check if it's a bomb
        cmp DWORD PTR [eax + 12], BOMB_TYPE
        je BombHit
        
        ; Regular fruit collision
        mov DWORD PTR [eax + 8], 0
        add score, 10
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
        call WriteString
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
    
    mov eax, yellow
    call SetTextColor
    call DrawFruits
    
    mov eax, green
    call SetTextColor
    call DrawPlayer
    
    mov eax, white
    call SetTextColor
    call DisplayScore
    call DisplayLives
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
; Draw Fruits/Bombs
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
        
        mov edx, [eax]
        mov ebx, [eax + 4]
        mov ecx, [eax + 12]
        
        mov dl, dl
        mov dh, bl
        call Gotoxy
        
        mov al, BYTE PTR [fruitChars + ecx]
        call WriteChar
        
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
    mov dl, 10
    mov dh, SCREEN_HEIGHT + 1
    call Gotoxy
    
    mov edx, OFFSET livesMsg
    call WriteString
    mov eax, lives
    call WriteDec
    call Crlf
    ret
DisplayLives ENDP

END main