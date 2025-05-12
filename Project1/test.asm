; ����G�C�� - Irvine32 ����
; �ϥ���L���k�䱱���x�l����������G 测试是测试

INCLUDE Irvine32.inc

; ============================================================================
; �`�Ʃw�q
; ============================================================================
SCREEN_WIDTH     = 40      ; �C���e���e��
SCREEN_HEIGHT    = 20      ; �C���e������
MAX_FRUITS       = 5       ; �̦h��G�ƶq
PLAYER_ROW       = 18      ; ���a�x�l�����m

; ============================================================================
; ��ư�
; ============================================================================
.data
    ; �C���ܼ�
    playerPos       DWORD 20             ; ���a��m(�C) ����123123123
    score           DWORD 0              ; ����
    gameRunning     DWORD 1              ; �C�����A456
    
    ; ��G�}�C - �C�Ӥ�G 4 �� DWORD: X, Y, active(1/0), type
    fruits          DWORD MAX_FRUITS * 4 dup(0)
    
    ; �r����
    titleMsg        BYTE "����G�C��", 13, 10, 0
    instructMsg     BYTE "�ϥ� A/D �䲾���x�l�AQ ��h�X", 13, 10, 0
    scoreMsg        BYTE "����: ", 0
    gameOverMsg     BYTE "�C������! ����N��h�X...", 13, 10, 0
    
    ; �C���Ÿ�
    playerChar      BYTE "[===]", 0        ; ���a�x�l
    fruitChars      BYTE "ABCDEFG", 0      ; ��G�Ÿ�
    borderChar      BYTE "-|+", 0         ; ��زŸ�
    
.code
; ============================================================================
; �D�{��
; ============================================================================
main PROC
    call InitGame
    
    ; ��ܹC������
    mov edx, OFFSET titleMsg
    call WriteString
    mov edx, OFFSET instructMsg
    call WriteString
    call WaitMsg
    
    ; �C���D�`��
    .while gameRunning == 1
        call ClearScreen
        call ProcessInput
        call UpdateGame
        call DrawGame
        mov eax, 150            ; �C���t��
        call Delay
    .endw
    
    ; �C������
    call ClearScreen
    mov edx, OFFSET gameOverMsg
    call WriteString
    call ReadChar
    
    call ExitProcess
main ENDP

; ============================================================================
; ��l�ƹC��
; ============================================================================
InitGame PROC uses ecx edi eax
    ; �M�Ť�G�}�C
    mov ecx, MAX_FRUITS * 4
    mov edi, OFFSET fruits
    xor eax, eax
    rep stosd
    
    ; �]�m��l���ƩM���a��m
    mov score, 0
    mov playerPos, 20
    
    ; ��l���H���ƺؤl
    call Randomize
    
    ; �]�m��r�C�⬰�զ�
    mov eax, white
    call SetTextColor
    ret
InitGame ENDP

; ============================================================================
; �B�z��J
; ============================================================================
ProcessInput PROC uses eax
    mov eax, 10            ; 10ms timeout
    call ReadKey           ; �D����Ū��
    jz NoInput             ; �S������
    
    ; �ର�j�g
    and al, 11011111b      ; �N�p�g�ର�j�g
    
    ; A �� - �V������
    cmp al, 'A'
    jne @F
    cmp playerPos, 1
    jle @F
    dec playerPos
    @@:
    
    ; D �� - �V�k����
    cmp al, 'D'
    jne @F
    mov eax, playerPos
    add eax, 6
    cmp eax, SCREEN_WIDTH
    jge @F
    inc playerPos
    @@:
    
    ; Q �� - �h�X�C��
    cmp al, 'Q'
    jne NoInput
    mov gameRunning, 0
    
NoInput:
    ret
ProcessInput ENDP

; ============================================================================
; ��s�C���޿�
; ============================================================================
UpdateGame PROC uses eax
    ; �ͦ��s��G
    mov eax, 100
    call RandomRange
    cmp eax, 20            ; 20% ���v�ͦ���G
    jge @F
    call AddFruit
    @@:
    
    ; ��s�Ҧ���G��m
    call UpdateFruits
    
    ; �I���˴�
    call CheckCollisions
    ret
UpdateGame ENDP

; ============================================================================
; �K�[�s��G
; ============================================================================
AddFruit PROC uses esi edi eax ebx ecx edx
    xor esi, esi
    
    ; �M��Ū���G��m
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16         ; �C�Ӥ�G 4 �� DWORD = 16 bytes
        mul ecx
        add eax, OFFSET fruits
        mov edi, eax
        
        ; �ˬd�O�_���D
        cmp DWORD PTR [edi + 8], 0
        jne NextFruit
        
        ; �]�m�s��G
        mov eax, SCREEN_WIDTH - 2
        call RandomRange
        inc eax                 ; �קK�b��ؤW�AX�d�� 1 �� 38
        mov [edi], eax         ; X ��m
        mov DWORD PTR [edi + 4], 1     ; Y ��m�]�q�ĤG��}�l�^
        mov DWORD PTR [edi + 8], 1     ; �]�����D
        
        ; �]�m��G����
        mov eax, 7
        call RandomRange
        mov DWORD PTR [edi + 12], eax  ; ��G����
        jmp Done
        
    NextFruit:
        inc esi
    .endw
    
Done:
    ret
AddFruit ENDP

; ============================================================================
; ��s��G��m
; ============================================================================
UpdateFruits PROC uses esi eax ecx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        ; �ˬd��G�O�_���D
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        ; ���ʤ�G�V�U
        inc DWORD PTR [eax + 4]
        
        ; �ˬd�O�_�쩳
        cmp DWORD PTR [eax + 4], SCREEN_HEIGHT - 1
        jl NextFruit
        mov DWORD PTR [eax + 8], 0    ; �]���D���D
        
    NextFruit:
        inc esi
    .endw
    ret
UpdateFruits ENDP

; ============================================================================
; �I���˴�
; ============================================================================
CheckCollisions PROC uses esi eax ebx ecx edx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        ; �ˬd��G�O�_���D
        cmp DWORD PTR [eax + 8], 1
        jne NextFruit
        
        mov ebx, [eax]          ; ��G X
        mov ecx, [eax + 4]      ; ��G Y
        
        ; �ˬd�O�_�b���a��
        cmp ecx, PLAYER_ROW
        jne NextFruit
        
        ; �ˬd X �d��I��
        mov edx, playerPos
        cmp ebx, edx
        jl NextFruit
        add edx, 4
        cmp ebx, edx
        jg NextFruit
        
        ; �I���o��
        mov DWORD PTR [eax + 8], 0    ; ��G����
        add score, 10                 ; �W�[����
        
    NextFruit:
        inc esi
    .endw
    ret
CheckCollisions ENDP

; ============================================================================
; ø�s�C���e��
; ============================================================================
DrawGame PROC uses eax
    ; ø�s���
    mov eax, white
    call SetTextColor
    call DrawBorder
    
    ; ø�s��G
    mov eax, yellow
    call SetTextColor
    call DrawFruits
    
    ; ø�s���a
    mov eax, green
    call SetTextColor
    call DrawPlayer
    
    ; ��ܤ���
    mov eax, white
    call SetTextColor
    call DisplayScore
    ret
DrawGame ENDP

; ============================================================================
; ø�s���
; ============================================================================
DrawBorder PROC uses ecx edx
    ; �W���
    mov dl, 0            ; Column
    mov dh, 0            ; Row
    call Gotoxy
    mov ecx, SCREEN_WIDTH
    .while ecx > 0
        mov al, '-'
        call WriteChar
        dec ecx
    .endw
    
    ; �U���
    mov dl, 0
    mov dh, SCREEN_HEIGHT - 1
    call Gotoxy
    mov ecx, SCREEN_WIDTH
    .while ecx > 0
        mov al, '-'
        call WriteChar
        dec ecx
    .endw
    
    ; ���k���
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
; ø�s��G
; ============================================================================
DrawFruits PROC uses esi eax ebx ecx edx
    xor esi, esi
    
    .while esi < MAX_FRUITS
        mov eax, esi
        mov ecx, 16
        mul ecx
        add eax, OFFSET fruits
        
        cmp DWORD PTR [eax + 8], 1    ; �p�G��G���D
        jne NextFruit
        
        mov edx, [eax]              ; X
        mov ebx, [eax + 4]          ; Y
        mov ecx, [eax + 12]         ; ����
        
        ; ���ʴ�Ш��G��m
        mov dl, dl
        mov dh, bl
        call Gotoxy
        
        ; ø�s��G�Ÿ�
        add ecx, 'A'
        mov al, cl
        call WriteChar
        
    NextFruit:
        inc esi
    .endw
    ret
DrawFruits ENDP

; ============================================================================
; ø�s���a
; ============================================================================
DrawPlayer PROC uses eax edx
    mov dl, BYTE PTR playerPos
    mov dh, PLAYER_ROW
    call Gotoxy
    
    ; ø�s�x�l
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
; ��ܤ���
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
; �M���ù�
; ============================================================================
ClearScreen PROC
    call Clrscr
    ret
ClearScreen ENDP

END main