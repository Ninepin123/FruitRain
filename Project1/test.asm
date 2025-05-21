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
MAX_FRUITS       = 5       ; Maximum number of fruits
PLAYER_ROW       = 18      ; Player basket row position
MAX_LEVEL       = 5       ; Maximum level
LEVEL_UP_SCORE  = 30      ; Score needed per level
BASE_SPEED      = 400     ; Base game speed (ms)      ; Higher number = easier
MIN_SPEED       = 50      ; Minimum game speed

; ============================================================================
; Data Section
; ============================================================================
.data
    ; Game variables
    playerPos       DWORD ?                                         ; Player position (column) 
    score           DWORD ?                                         ; Score
    gameRunning     DWORD 1                                         ; Game state, =1 running, =0 stopped
    speed           DWORD 400                                       ; Game speed (ms)
    gamePaused      DWORD 0                                         ; Pause state
    pauseMsg        BYTE "Game paused, press P to continue", 0
    resumeMsg       BYTE "Game will continue in X seconds", 0  
    scoreMsg        BYTE "Score: ", 0
    gameOverMsg     BYTE "Game Over! Press any key to exit...", 13, 10, 0
    WinMsg          BYTE "You Win!", 0
    difficultyMsg   BYTE "Current difficulty: ", 0
    difficulty      DWORD 1                                         ; Current difficulty
    pressEnterMsg BYTE 13,10,"Press Enter key to start game...",13,10,0    


    ; Fruit array - each fruit has 4 DWORDs: X, Y, active(1/0), type
    fruits          DWORD MAX_FRUITS * 4 dup(0)
    
    ; Game symbols
    playerChar      BYTE "[===]", 0             ; Player basket hello hello
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
    rulesMsg2 BYTE "1. Use A/D keys to move the basket left and right, please make sure your input method is set to English", 13, 10, 0
    rulesMsg3 BYTE "2. Catch the falling fruits (A-G)", 13, 10, 0
    rulesMsg4 BYTE "3. Get 10 points for each caught fruit", 13, 10, 0
    rulesMsg5 BYTE "4. Level difficulty increases at certain score thresholds", 13, 10, 0        ; Every 30 points jumps one level
    rulesMsg6 BYTE "5. Press P key to pause the game", 13, 10, 0
    rulesMsg7 BYTE "6. Press Q key to quit the game", 13, 10, 0

.code
; ============================================================================
; Main Program
; Will initialize game -> show title screen -> show rules -> enter game -> game over
; ============================================================================
main PROC
    call InitGame
    call ShowTitleScreen
    call ShowRulesScreen
    
    ; Game main loop
    .while gameRunning == 1
        ; Process input
        call ProcessInput
        
        ; Check pause state
        cmp gamePaused, 1
        je PausedState
        
        ; Normal game state processing
        call Clrscr
        call UpdateGame
        call DrawGame
        jmp ContinueGameLoop
    
    PausedState:
        ; Pause state only draws the screen
        call DrawGame
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
        
        ; End condition
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
    
    call ExitProcess
main ENDP

; ============================================================================
; Pause Message 
; ============================================================================
DrawPauseMessage PROC
    push eax
    push edx
    push ecx

    ; Clear pause message area
    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov ecx, 16
    mov al, ' '
ClearLoop:
    call WriteChar
    inc dl
    loop ClearLoop

    ; Display pause message
    mov eax, yellow
    call SetTextColor
    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET pauseMsg
    call WriteString

    ; Restore registers
    pop ecx
    pop edx
    pop eax
    ret
DrawPauseMessage ENDP

; ============================================================================
; Initialize Game
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
; Show Game Title Screen
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
; Show Rules Screen
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
; Process Input
; ============================================================================
ProcessInput PROC uses eax
    mov eax, 10            ; 10ms timeout setting
    call ReadKey           ; Non-blocking key read
    jz NoInput             ; If no key, return directly

    ; Convert to uppercase for uniform processing
    and al, 11011111b      ; Convert lowercase to uppercase (clear 5th bit)

    ; --- Keys processed in all game states ---
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
    mov gameRunning, 0     ; Game over
NotQKey:

    ; --- Pause/Resume specific handling ---
    cmp al, 'P'
    jne NoInput            ; If not P key, end processing

    ; Toggle based on current state
    cmp gamePaused, 1
    je  UnpauseGame        ; Current state is paused, unpause

    ; Execute pause logic
    mov gamePaused, 1      ; Set pause flag
    call DrawPauseMessage  ; Draw pause message
    jmp NoInput

UnpauseGame:
    ; Execute unpause logic
    mov gamePaused, 0      ; Clear pause flag
    
    ; Show countdown (3 seconds)
    mov eax, yellow        ; Set yellow text
    call SetTextColor
    
    mov ecx, 3             ; Count down 3 seconds
CountdownLoop:
    ; Clear old message first
    mov dl, 10
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET resumeMsg
    call WriteString       ; "Game will continue in X seconds"
    
    ; Dynamically update number position (override X)
    mov dl, 19             ; X coordinate of X
    mov dh, 10             ; Y coordinate of X
    call Gotoxy
    mov eax, ecx
    call WriteDec          ; Display current countdown number
    
    mov eax, 1000          ; Delay 1 second
    call Delay
    loop CountdownLoop
    
    ; Clear countdown message
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
; Update Game Logic
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
; Add New Fruit
; Need to review this algorithm, RandomRange not used
; ============================================================================
AddFruit PROC uses esi edi eax ebx ecx edx
    ; Calculate spawn probability (using difficulty instead of level)
    mov eax, 100
    call RandomRange
    
    ; Base probability + difficulty bonus (15% + 5% per difficulty level)
    mov ebx, 50                 ; Base probability 15%
    mov ecx, difficulty
    imul ecx, 5                 ; 5% increase per difficulty level
    add ebx, ecx
    
    cmp eax, ebx
    jge @F                      ; If random number > probability value, don't spawn
    
    xor esi, esi                ; Start search from beginning
    
    ; Find empty fruit position
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16             ; Each fruit is 4 DWORD = 16 bytes
        mul ecx
        add eax, OFFSET fruits
        mov edi, eax
        
        ; Check if active
        cmp DWORD PTR [edi + 8], 0
        jne NextFruit
        
        ; Set new fruit
        mov eax, SCREEN_WIDTH - 2
        call RandomRange
        inc eax                 ; Avoid border, X range 1 to 38
        mov [edi], eax          ; X position
        
        ; Set initial Y position (adjusted by difficulty)
        mov DWORD PTR [edi + 4], 1     ; Base Y position
        mov eax, difficulty
        add DWORD PTR [edi + 4], eax   ; Higher difficulty = lower initial position
        
        mov DWORD PTR [edi + 8], 1     ; Set as active
        
        ; Set fruit type
        mov eax, 7
        call RandomRange
        mov DWORD PTR [edi + 12], eax  ; Fruit type test
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
        
        ; Check if fruit is active
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        ; Move fruit downward
        inc DWORD PTR [eax + 4]
        
        ; Check if reached bottom
        cmp DWORD PTR [eax + 4], SCREEN_HEIGHT - 1
        jl NextFruit
        mov DWORD PTR [eax + 8], 0    ; Set as inactive
        
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
        
        ; Check if fruit is active
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        mov ebx, [eax]          ; Fruit X
        mov ecx, [eax + 4]      ; Fruit Y
        
        ; Check if on player row
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
; Draw Game Screen
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
; Draw Border
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
; Draw Fruits
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
        
        mov edx, [eax]              ; X123123123
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
; Draw Player
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
    call Crlf
    ret
DisplayScore ENDP

END main