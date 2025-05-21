INCLUDE Irvine32.inc

.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD

; ============================================================================
; Constants definition
; ============================================================================
SCREEN_WIDTH     = 40      ; Game screen width
SCREEN_HEIGHT    = 20      ; Game screen height test Pull Request
MAX_FRUITS       = 5       ; Maximum number of fruits
PLAYER_ROW       = 18      ; Player basket row position
MAX_LEVEL        = 5       ; Maximum level
LEVEL_UP_SCORE   = 30      ; Score needed for each level
BASE_SPEED       = 400     ; Base game speed (ms)      ; Higher number means easier
MIN_SPEED        = 50      ; Minimum game speed

; ============================================================================
; Data section
; ============================================================================
.data
    ; Game variables
    playerPos       DWORD 20                                        ; Player position (column)
    score           DWORD 0                                         ; Score
    gameRunning     DWORD 1                                         ; Game state, =1 running, =0 stopped
    speed           DWORD 400                                       ; Game speed (ms)
    gamePaused      DWORD 0                                         ; Pause state
    pauseMsg        BYTE "Game Paused, Press P to continue", 0
    pauseDrawEnabled BYTE 1                                         ; Default 1 (drawing enabled), 0 for disabled
    pauseDrawMsg    BYTE "Draw game while paused (Press T to toggle): ", 0
    enabledStr      BYTE "Enabled", 0
    disabledStr     BYTE "Disabled", 0
    resumeMsg       BYTE "Game will resume in X seconds", 0
    
    ; Fruit array - Each fruit has 4 DWORDs: X, Y, active(1/0), type
    fruits          DWORD MAX_FRUITS * 4 dup(0)
    
    ; String data
    titleMsg        BYTE "Fruit Catching Game", 13, 10, 0
    instructMsg     BYTE "Use A/D keys to move basket, Q to quit", 13, 10, 0
    scoreMsg        BYTE "Score: ", 0
    gameOverMsg     BYTE "Game Over! Press any key to exit...", 13, 10, 0
    WinMsg          BYTE "You Win!", 0
    difficultyMsg   BYTE "Current Level: ", 0
    difficulty      DWORD 1                                         ; Current difficulty
    pressEnterMsg   BYTE 13,10,"Press Enter to start the game...",13,10,0    
    
    ; Game symbols
    playerChar      BYTE "[===]", 0             ; Player basket
    fruitChars      BYTE "ABCDEFG", 0           ; Fruit symbols

    ; Title screen
    titleArt1 BYTE 13,10,"  ________  _______   __    __  ______  ________        _______    ______   ______  __    __ ",13,10,0
    titleArt2 BYTE       " |        \|       \ |  \  |  \|      \|        \      |       \  /      \ |      \|  \  |  \",13,10,0
    titleArt3 BYTE       " | $$$$$$$$| $$$$$$$\| $$  | $$ \$$$$$$ \$$$$$$$$      | $$$$$$$\|  $$$$$$\ \$$$$$$| $$\ | $$",13,10,0
    titleArt4 BYTE       " | $$__    | $$__| $$| $$  | $$  | $$     | $$         | $$__| $$| $$__| $$  | $$  | $$$\| $$",13,10,0
    titleArt5 BYTE       " | $$  \   | $$    $$| $$  | $$  | $$     | $$         | $$    $$| $$    $$  | $$  | $$$$\ $$",13,10,0
    titleArt6 BYTE       " | $$$$$   | $$$$$$$\| $$  | $$  | $$     | $$         | $$$$$$$\| $$$$$$$$  | $$  | $$\$$ $$",13,10,0
    titleArt7 BYTE       " | $$      | $$  | $$| $$__/ $$ _| $$_    | $$         | $$  | $$| $$  | $$ _| $$_ | $$ \$$$$",13,10,0
    titleArt8 BYTE       " | $$      | $$  | $$ \$$    $$|   $$ \   | $$         | $$  | $$| $$  | $$|   $$ \| $$  \$$$",13,10,0
    titleArt9 BYTE       "  \$$       \$$   \$$  \$$$$$$  \$$$$$$    \$$          \$$   \$$ \$$   \$$ \$$$$$$ \$$   \$$",13,10,0

    ; Game rules
    rulesMsg1 BYTE "Game Rules:", 13, 10, 0
    rulesMsg2 BYTE "1. Use A/D keys to move basket left/right (make sure your input is in English)", 13, 10, 0
    rulesMsg3 BYTE "2. Catch falling fruits (A-G)", 13, 10, 0
    rulesMsg4 BYTE "3. Each fruit caught is worth 10 points", 13, 10, 0
    rulesMsg5 BYTE "4. Difficulty increases at certain score thresholds", 13, 10, 0       ; Every 30 points
    rulesMsg6 BYTE "5. Press P to pause the game", 13, 10, 0
    rulesMsg7 BYTE "6. Press Q to quit the game", 13, 10, 0

.code
; ============================================================================
; Main procedure
; Initializes game -> Shows title -> Shows rules -> Game loop -> Game over
; ============================================================================
main PROC
    call InitGame
    call ShowTitleScreen
    call ShowRulesScreen
    
   ; Game main loop
    .while gameRunning == 1
        call Clrscr
        call ProcessInput
        
        ; Check pause state
        cmp gamePaused, 1
        je PausedState
        
        ; Normal game state processing
        call UpdateGame
        call DrawGame
        jmp ContinueGameLoop
    
    PausedState:
        ; In pause state, check if drawing is enabled
        cmp pauseDrawEnabled, 1
        jne SkipPauseDraw
        call DrawGame
    SkipPauseDraw:
        ; Show pause message
        call DrawPauseMessage
        
    ContinueGameLoop:
        mov eax, speed
        call Delay
        
        ; Check for level up
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
        
        ; Update game speed
        mov eax, BASE_SPEED
        mov ebx, difficulty
        shr eax, 1
        cmp eax, MIN_SPEED
        jge @F
        mov eax, MIN_SPEED
    @@:
        mov speed, eax
        
        ; Game end condition
        cmp score, LEVEL_UP_SCORE * MAX_LEVEL
        jl ContinueGame
        mov gameRunning, 0
    ContinueGame:
    .endw
    
    ; Game over
    call Clrscr
    mov edx, offset WinMsg
    call WriteString
    call Crlf
    mov edx, OFFSET gameOverMsg
    call WriteString
    call ReadChar
    
    invoke ExitProcess, 0
main ENDP

; ============================================================================
; Draw pause message 
; ============================================================================
DrawPauseMessage PROC
    push eax
    push edx
    push ecx

    ; Clear pause message area
    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov ecx, 30
    mov al, ' '
ClearLoop:
    call WriteChar
    loop ClearLoop

    ; Display pause message
    mov eax, yellow
    call SetTextColor
    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET pauseMsg
    call WriteString
    
    ; Display drawing toggle option
    mov dl, 10
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET pauseDrawMsg
    call WriteString
    cmp pauseDrawEnabled, 1
    jne DisabledState
    mov edx, OFFSET enabledStr
    jmp ShowDrawState
DisabledState:
    mov edx, OFFSET disabledStr
ShowDrawState:
    call WriteString

    ; Restore registers
    pop ecx
    pop edx
    pop eax
    ret
DrawPauseMessage ENDP

; ============================================================================
; Initialize game
; ============================================================================
InitGame PROC uses ecx edi eax
    ; Clear fruit array
    mov ecx, MAX_FRUITS * 4
    mov edi, OFFSET fruits
    xor eax, eax
    rep stosd
    
    ; Set initial score and player position
    mov score, 0
    mov playerPos, 20
    
    ; Initialize random number seed
    call Randomize
    
    ; Set text color to white
    mov eax, white
    call SetTextColor
    ret
InitGame ENDP

; =====================================================================
; Show title screen
; =====================================================================
ShowTitleScreen PROC
    call Clrscr
    
    ; Display game title
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
    mov eax, green
    call SetTextColor
    mov edx, OFFSET pressEnterMsg
    call WriteString

    ; Wait for Enter key
WaitForEnter:
    call ReadChar
    cmp al, 13          ; Enter key ASCII = 13
    jne WaitForEnter
    ret
ShowTitleScreen ENDP

; =====================================================================
; Show rules screen
; =====================================================================
ShowRulesScreen PROC
    call Clrscr
    
    ; Display rules title
    mov eax, yellow
    call SetTextColor
    mov edx, OFFSET rulesMsg1
    call WriteString
    call Crlf
    
    ; Display rules
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
    
    ; Display continue prompt
    mov eax, green
    call SetTextColor
    mov edx, OFFSET pressEnterMsg
    call WriteString
    
    ; Wait for Enter key
WaitForEnter:
    call ReadChar
    cmp al, 13          ; Enter key ASCII = 13
    jne WaitForEnter
    ret
ShowRulesScreen ENDP

; ============================================================================
; Process input
; ============================================================================
ProcessInput PROC uses eax
    mov eax, 10            ; 10ms timeout setting
    call ReadKey           ; Non-blocking key read
    jz NoInput             ; No key pressed, return directly

    ; Convert to uppercase for consistent handling
    and al, 11011111b      ; Convert lowercase to uppercase (clear bit 5)

    ; --- Handles these keys in all game states ---
    ; A key - Move left
    cmp al, 'A'
    jne NotAKey
    cmp playerPos, 1        ; Check left boundary
    jle NotAKey
    dec playerPos           ; Move player position
NotAKey:

    ; D key - Move right
    cmp al, 'D'
    jne NotDKey
    mov eax, playerPos
    add eax, 5             ; Basket width is 5 spaces
    cmp eax, SCREEN_WIDTH  ; Check right boundary
    jge NotDKey
    inc playerPos          ; Move player position
NotDKey:

    ; Q key - Quit game
    cmp al, 'Q'
    jne NotQKey
    mov gameRunning, 0     ; End game
NotQKey:

    ; P key - Handle pause/resume
    cmp al, 'P'
    jne NotPKey
    
    ; Toggle based on current state
    cmp gamePaused, 1
    je UnpauseGame        ; Currently paused, unpause
    
    ; Execute pause logic
    mov gamePaused, 1
    jmp NoInput
    
UnpauseGame:
    ; Show countdown (3 seconds)
    mov eax, yellow
    call SetTextColor
    
    mov ecx, 3             ; Count down from 3
CountdownLoop:
    ; Display current countdown
    mov dl, 10
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET resumeMsg
    call WriteString
    
    ; Update the number position
    mov dl, 19             ; X position
    mov dh, 14
    call Gotoxy
    mov eax, ecx
    call WriteDec
    
    mov eax, 1000          ; Delay 1 second
    call Delay
    loop CountdownLoop
    
    ; Clear countdown message
    mov dl, 10
    mov dh, 14
    call Gotoxy
    mov ecx, 30
    mov al, ' '
ClearMsgLoop:
    call WriteChar
    loop ClearMsgLoop
    
    ; Unpause
    mov gamePaused, 0
NotPKey:

    ; T key - Toggle drawing while paused (only valid in pause state)
    cmp gamePaused, 1
    jne NoInput
    cmp al, 'T'
    jne NoInput
    xor pauseDrawEnabled, 1    ; Toggle draw-while-paused option

NoInput:
    ret
ProcessInput ENDP

; ============================================================================
; Update game logic
; ============================================================================
UpdateGame PROC uses eax
    ; Generate new fruit
    mov eax, 100
    call RandomRange
    cmp eax, 20            ; 20% chance to generate fruit
    jge @F
    call AddFruit
    @@:
    
    ; Update all fruit positions
    call UpdateFruits
    
    ; Collision detection
    call CheckCollisions
    ret
UpdateGame ENDP

; ============================================================================
; Add new fruit
; ============================================================================
AddFruit PROC uses esi edi eax ebx ecx edx
    ; Calculate spawn probability (using difficulty)
    mov eax, 100
    call RandomRange
    
    ; Base probability + difficulty bonus (15% + 5% per difficulty level)
    mov ebx, 50                 ; Base probability 15%
    mov ecx, difficulty
    imul ecx, 5                 ; Add 5% per difficulty level
    add ebx, ecx
    
    cmp eax, ebx
    jge @F                      ; If random number > probability, don't spawn
    
    xor esi, esi                ; Start search from beginning
    
    ; Find empty fruit slot
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16             ; Each fruit is 4 DWORDs = 16 bytes
        mul ecx
        add eax, OFFSET fruits
        mov edi, eax
        
        ; Check if active
        cmp DWORD PTR [edi + 8], 0
        jne NextFruit
        
        ; Set up new fruit
        mov eax, SCREEN_WIDTH - 2
        call RandomRange
        inc eax                 ; Avoid being on border, X range 1 to 38
        mov [edi], eax          ; X position
        
        ; Set initial Y position (adjusted by difficulty)
        mov DWORD PTR [edi + 4], 1     ; Base Y position
        mov eax, difficulty
        add DWORD PTR [edi + 4], eax   ; Higher difficulty starts lower
        
        mov DWORD PTR [edi + 8], 1     ; Set as active
        
        ; Set fruit type
        mov eax, 7
        call RandomRange
        mov DWORD PTR [edi + 12], eax  ; Fruit type
        jmp Done
        
    NextFruit:
        inc esi
    .endw
    
Done:
@@:
    ret
AddFruit ENDP

; ============================================================================
; Update fruit positions
; ============================================================================
UpdateFruits PROC uses esi eax ecx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        ; Check if fruit is active
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        ; Move fruit down
        inc DWORD PTR [eax + 4]
        
        ; Check if it reached bottom
        cmp DWORD PTR [eax + 4], SCREEN_HEIGHT - 1
        jl NextFruit
        mov DWORD PTR [eax + 8], 0    ; Set as inactive
        
    NextFruit:
        inc esi
    .endw
    ret
UpdateFruits ENDP

; ============================================================================
; Collision detection
; ============================================================================
CheckCollisions PROC uses esi eax ebx ecx edx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        ; Check if fruit is active
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        mov ebx, [eax]          ; Fruit X
        mov ecx, [eax + 4]      ; Fruit Y
        
        ; Check if at player row
        cmp ecx, PLAYER_ROW
        jne NextFruit
        
        ; Check X range collision
        mov edx, playerPos
        cmp ebx, edx
        jl NextFruit
        add edx, 4
        cmp ebx, edx
        jg NextFruit
        
        ; Collision occurred
        mov DWORD PTR [eax + 8], 0    ; Fruit disappears
        add score, 10                 ; Increase score
        
    NextFruit:
        inc esi
    .endw
    ret
CheckCollisions ENDP

; ============================================================================
; Draw game screen
; ============================================================================
DrawGame PROC uses eax
    ; Draw border
    mov eax, white
    call SetTextColor
    call DrawBorder
    
    ; Draw fruits
    mov eax, yellow
    call SetTextColor
    call DrawFruits
    
    ; Draw player
    mov eax, green
    call SetTextColor
    call DrawPlayer
    
    ; Display score
    mov eax, white
    call SetTextColor
    call DisplayScore
    ; Display level
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
; Draw border
; ============================================================================
DrawBorder PROC uses ecx edx
    ; Top border
    mov dl, 0            ; Column
    mov dh, 0            ; Row
    call Gotoxy
    mov ecx, SCREEN_WIDTH
    .while ecx > 0
        mov al, '-'
        call WriteChar
        dec ecx
    .endw
    
    ; Bottom border
    mov dl, 0
    mov dh, SCREEN_HEIGHT - 1
    call Gotoxy
    mov ecx, SCREEN_WIDTH
    .while ecx > 0
        mov al, '-'
        call WriteChar
        dec ecx
    .endw
    
    ; Left and right borders
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
; Draw fruits
; ============================================================================
DrawFruits PROC uses esi eax ebx ecx edx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        cmp DWORD PTR [eax + 8], 1    ; If fruit is active
        jne NextFruit
        
        mov edx, [eax]              ; X
        mov ebx, [eax + 4]          ; Y
        mov ecx, [eax + 12]         ; Type
        
        ; Move cursor to fruit position
        mov dl, dl
        mov dh, bl
        call Gotoxy
        
        ; Draw fruit symbol
        add ecx, 'A'
        mov al, cl
        call WriteChar
        
    NextFruit:
        inc esi
    .endw
    ret
DrawFruits ENDP

; ============================================================================
; Draw player
; ============================================================================
DrawPlayer PROC uses eax edx
    mov dl, BYTE PTR playerPos
    mov dh, PLAYER_ROW
    call Gotoxy
    
    ; Draw basket
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
; Display score
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
; Clear screen
; ============================================================================
ClearScreen PROC
    call Clrscr
    ret
ClearScreen ENDP

END main