.386
.model flat, stdcall
option casemap :none

include engine.inc

.data
    format     DB "Value: %d", 0
    header_msg DB "Result", 0
    buffer     DB 256 dup(?)

    platform player_obj <?, ?, ?, ?, ?>
    ball ball_obj <?, ?, ?, ?>
    blocks block_obj 108 dup(<?, ?, ?>)
    maxrow dd ?

    should_play_beep db FALSE
    should_play_long_beep db FALSE
    should_play_plop db FALSE
    should_play_starting db FALSE
    should_play_game_over db FALSE

.code 
start:
    INVOKE GetModuleHandle, NULL
    MOV    hInstance, eax

    INVOKE WinCreate, hInstance, SW_SHOWDEFAULT
    INVOKE ExitProcess, eax

WinCreate proc hInst:HINSTANCE, CmdShow:DWORD 
    LOCAL  wc:WNDCLASSEX                          ; create local variables on stack 
    LOCAL  msg:MSG 
    LOCAL  clientRect:RECT

    MOV    wc.cbSize, SIZEOF WNDCLASSEX           ; fill values in members of wc 
    MOV    wc.style, CS_HREDRAW or CS_VREDRAW 
    MOV    wc.lpfnWndProc, OFFSET WndProc 
    MOV    wc.cbClsExtra, NULL 
    MOV    wc.cbWndExtra, NULL 

    PUSH   hInstance 
    POP    wc.hInstance 

    MOV    wc.hbrBackground, NULL
    MOV    wc.lpszMenuName, NULL 
    MOV    wc.lpszClassName, OFFSET ClassName 

    INVOKE LoadIcon, hInstance, 500
    MOV    wc.hIcon, eax 
    MOV    wc.hIconSm, 0

    INVOKE LoadCursor, NULL, IDC_ARROW 
    MOV    wc.hCursor,eax 
    INVOKE RegisterClassEx, addr wc               ; register our window class 

    ;======================================

    MOV    clientRect.left, 0
    MOV    clientRect.top, 0
    MOV    clientRect.right, WIN_WD
    MOV    clientRect.bottom, WIN_HT

    INVOKE AdjustWindowRect, addr clientRect, WS_CAPTION, FALSE

    MOV    eax, clientRect.right
    SUB    eax, clientRect.left
    MOV    ebx, clientRect.bottom
    SUB    ebx, clientRect.top

    ;==============================

    INVOKE CreateWindowEx, NULL, addr ClassName, addr AppName,\ 
        WS_OVERLAPPED or WS_SYSMENU or WS_MINIMIZEBOX,\ 
        CW_USEDEFAULT, CW_USEDEFAULT,\
        eax, ebx, NULL, NULL, hInst, NULL 
        
    MOV    hWnd, eax 
    INVOKE ShowWindow, hWnd, CmdShow               ; Mostra a janela
    INVOKE UpdateWindow, hWnd                      ; Atualiza a área da janela

    .WHILE TRUE                                    ; Loop de mensagem
        INVOKE GetMessage, ADDR msg, NULL, 0, 0 
        .BREAK .IF (!eax) 
        INVOKE TranslateMessage, ADDR msg 
        INVOKE DispatchMessage, ADDR msg 
   .ENDW

    MOV    eax, msg.wParam                           ; Retorna o código de saída no eax
    RET
WinCreate endp

WndProc proc _hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg == WM_CREATE                                          ; Carrega as imagens

        INVOKE LoadAssets
        INVOKE Initialize


        INVOKE CreateEvent, NULL, FALSE, FALSE, NULL
		MOV    hGameEventStart, eax

        MOV eax, OFFSET GameHandler
        INVOKE CreateThread, NULL, NULL, eax, 0, 0, ADDR GameHandlerID  ; Cria a thread principal
        INVOKE CloseHandle, eax


        INVOKE CreateEvent, NULL, FALSE, FALSE, NULL
		MOV    hSoundEventStart, eax

        MOV eax, OFFSET SoundHandler
        INVOKE CreateThread, NULL, NULL, eax, 0, 0, ADDR SoundHandlerID  ; Cria a thread principal
        INVOKE CloseHandle, eax

        ;INVOKE wsprintf, ADDR buffer, ADDR format, 0
        ;INVOKE MessageBox, 0, ADDR buffer, ADDR header_msg, 0

    .ELSEIF uMsg == WM_KEYDOWN

        .IF (wParam == VK_LEFT)
           mov platform.speedx, -SPEED
        .ELSEIF (wParam == VK_RIGHT)
            mov platform.speedx, SPEED
        .ENDIF
    
    .ELSEIF uMsg == WM_KEYUP 

        .IF (wParam == VK_LEFT)
            mov platform.speedx, 0
        .ELSEIF (wParam == VK_RIGHT)
            mov platform.speedx, 0
        .ENDIF

    .ELSEIF uMsg == WM_DESTROY                                     ; Caso o jogador feche a janela
        
        INVOKE PostQuitMessage, NULL                               ; Fecha o jogo
    
    .ELSEIF uMsg == WM_PAINT
        
        INVOKE UpdateScreen, _hWnd                                 ; Atualizar a tela
    
    .ELSEIF uMsg == WM_UPDATE

        INVOKE UpdatePhysics

    .ELSE

        INVOKE DefWindowProc, _hWnd, uMsg, wParam, lParam          ; Messagem padrão
        RET

    .ENDIF

    XOR eax, eax 
    RET
WndProc endp

LoadAssets proc ; Carrega os bitmaps e matriz de blocos do jogo:

    INVOKE LoadBitmap, hInstance, BACKGROUND_BMP
    MOV    hBackgroundBmp, eax

    INVOKE LoadBitmap, hInstance, CELLS_BMP
    MOV    hCellsBmp, eax

    INVOKE LoadBitmap, hInstance, BALL_BMP
    MOV    hBallBmp, eax

    INVOKE LoadBitmap, hInstance, PLAYER_BMP
    MOV    hPlayerBmp, eax

    INVOKE LoadBitmap, hInstance, GAME_OVER_BMP
    MOV    hGame_OverBmp, eax

    INVOKE LoadBitmap, hInstance, STARTING_BMP
    MOV    hStartingBmp, eax

    RET
LoadAssets endp

UpdateScreen proc _hWnd:HWND
    LOCAL  ps:PAINTSTRUCT 
    LOCAL  hDC:HDC 
    LOCAL  hMemDC:HDC 
    LOCAL  hMemDCTwo:HDC 
    LOCAL  hBitmap:HDC 

    INVOKE BeginPaint, _hWnd, ADDR ps
    MOV    hDC, eax
    INVOKE CreateCompatibleDC, hDC
    MOV    hMemDC, eax
    INVOKE CreateCompatibleDC, hDC
    MOV    hMemDCTwo, eax
    INVOKE CreateCompatibleBitmap, hDC, WIN_WD, WIN_HT
    MOV    hBitmap, eax

    INVOKE SelectObject, hMemDC, hBitmap

    INVOKE DrawBackground, hMemDC, hMemDCTwo

    .IF !(should_play_game_over || should_play_starting)
        
        INVOKE DrawBlocks, hMemDC, hMemDCTwo
        INVOKE DrawPlayer, hMemDC, hMemDCTwo
        INVOKE DrawBall, hMemDC, hMemDCTwo
    .ELSEIF should_play_game_over
        INVOKE DrawGameOver, hMemDC, hMemDCTwo
    .ELSEIF should_play_starting
        INVOKE DrawStarting, hMemDC, hMemDCTwo
    .ENDIF
    
    INVOKE BitBlt, hDC, 0, 0, WIN_WD, WIN_HT, hMemDC, 0, 0, SRCCOPY

    INVOKE DeleteDC, hMemDC
    INVOKE DeleteDC, hMemDCTwo
    INVOKE DeleteObject, hBitmap
    INVOKE EndPaint, _hWnd, addr ps

    RET
UpdateScreen endp

UpdatePhysics proc
    .IF !(should_play_game_over || should_play_starting)
        INVOKE CheckRestart

        INVOKE MovePlayer
        INVOKE MoveBall

        INVOKE CheckCollisions

        INVOKE InvalidateRect, hWnd, NULL, TRUE

        RET
    .ENDIF
UpdatePhysics endp

CheckCollisions proc
    LOCAL row_index:DWORD
    LOCAL column_index:DWORD

    LOCAL pos_x:DWORD
    LOCAL pos_y:DWORD

    LOCAL bloco_plataforma:DWORD ; variavel para definir em que parte da plataforma bateu
   
    MOV edx, X_MIN_LIMIT + BALL_WD/2  ;   limite da esquerda
    MOV ebx, X_MAX_LIMIT - BALL_WD/2  ;   limite da direita

    .IF ball.x < edx    ;   quer dizer que houve colisao, inverte a velocidade x e volta a posicao para o limite
        MOV ball.x, edx
        MOV eax, ball.speedx
        NEG eax
        MOV ball.speedx, eax

        MOV should_play_beep, TRUE
    .ELSEIF ball.x > ebx
        MOV ball.x, ebx
        MOV eax, ball.speedx
        NEG eax
        MOV ball.speedx, eax

        MOV should_play_beep, TRUE
    .ENDIF
    
    MOV ebx, Y_MIN_LIMIT + BALL_WD/2   ;   limite de cima

    .IF ball.y < ebx    ;   quer dizer que houve colisao, inverte velocidade y e volta a posicao para o limite
        MOV ball.y, ebx
        MOV eax, ball.speedy
        NEG eax
        MOV ball.speedy, eax

        MOV should_play_beep, TRUE
    .ENDIF

    ;0 = fora, de 1 a 5 indo da esquerda pra direita
    XOR eax, eax
    MOV bloco_plataforma, eax ; coloca em 0

    ;coloca o limite esquerdo da plataforma no registrador
    MOV eax, platform.x
    SUB eax, PLAYER_WD/2
    SUB eax, BALL_WD/2

    .IF ball.x >= eax

        ADD eax, PLAYER_WD/5
        ADD eax, BALL_WD/5

        .IF ball.x >= eax

            ADD eax, PLAYER_WD/5
            ADD eax, BALL_WD/5

            .IF ball.x >= eax

                ADD eax, PLAYER_WD/5
                ADD eax, BALL_WD/5

                .IF ball.x >= eax

                    ADD eax, PLAYER_WD/5
                    ADD eax, BALL_WD/5

                    .IF ball.x >= eax

                        ADD eax, PLAYER_WD/5
                        ADD eax, BALL_WD/5

                        .IF ball.x <= eax                                                                                
                            MOV bloco_plataforma, 5
                        .ENDIF  ;   se chegar aqui eh pq ele nao esta na plataforma
                    .ELSE
                        MOV bloco_plataforma, 4
                    .ENDIF

                .ELSE
                    MOV bloco_plataforma, 3
                .ENDIF

            .ELSE   ;   quer dizer que esta no segundo bloco da plataforma

                MOV bloco_plataforma, 2

            .ENDIF

        .ELSE   ;   quer dizer q esta no primeiro bloco da plataforma

            MOV bloco_plataforma, 1

        .ENDIF

    .ENDIF

    .IF !(bloco_plataforma == 0) ; checa se eh possivel ter colisao
        ;coloca o limite de cima de plataforma no registrador
            MOV eax, platform.y
            SUB eax, BALL_WD/2

            .IF ball.y >= eax
                MOV eax, platform.y
                ADD eax, 2
                ADD eax, BALL_WD/2

                .IF ball.y <= eax   ;   quer dizer que houve colisao com a plataforma
                    MOV should_play_beep, TRUE
                    ;em todos os casos se inverte a velocidade vertical
                    MOV eax, ball.speedy
                    NEG eax
                    MOV ball.speedy, eax

                     ; calcula a velocidade para ser o número de rows quebradas * 2
                    MOV eax, 5
                    SUB eax, maxrow
                    MOV edx, 2
                    MUL edx

                    .IF bloco_plataforma == 1
                                               
                        ;   se move bastante para a esquerda
                        MOV ball.speedy, -9
                        NEG eax
                        SUB eax, 18
                        MOV ball.speedx, eax                                                                                                        

                    .ELSEIF bloco_plataforma == 2
                        
                        ;   se move um pouco para a esquerda
                        MOV ball.speedy, -9
                        NEG eax
                        SUB eax, 9
                        MOV ball.speedx, eax                        

                    .ELSEIF bloco_plataforma == 3
                        
                        ;   a bola vai para cima
                        MOV ball.speedy, -18
                        MOV ball.speedx, 0

                    .ELSEIF bloco_plataforma == 4
                        
                        ;se move um pouco para a direita
                        MOV ball.speedy, -9
                        ADD eax, 9                    
                        MOV ball.speedx, eax

                    .ELSE 
                        
                        ;se move bastante para a direita
                        MOV ball.speedy, -9
                        ADD eax, 18                        
                        MOV ball.speedx, eax        

                    .ENDIF
                    
                .ENDIF
            .ENDIF
    .ENDIF

;    .IF ball.x >= eax

        ;coloca o limite direito da plataforma no registrador
;        MOV eax, platform.x
;        ADD eax, PLAYER_WD/2
;        ADD eax, BALL_WD/2

;        .IF ball.x <= eax ; quer dizer que está no mesmo x da plataforma

            ;coloca o limite de cima de plataforma no registrador
;            MOV eax, platform.y
;            SUB eax, BALL_WD/2

;            .IF ball.y >= eax

                ;coloca o limite de baixo da plataforma no registrador
;                MOV eax, platform.y
;                ADD eax, 2
;                ADD eax, BALL_WD/2

;                .IF ball.y <= eax   ;   quer dizer que houve colisao com a plataforma

;                    MOV eax, ball.speedy
;                    NEG eax
;                  MOV ball.speedy, eax

 ;                   .IF maxrow < 2
 ;                       MOV should_play_beep, TRUE
 ;                   .ELSEIF
 ;                       MOV should_play_long_beep, TRUE
 ;                   .ENDIF
 ;               .ENDIF
 ;           .ENDIF
 ;       .ENDIF
 ;   .ENDIF

    MOV esi, offset blocks
    MOV row_index, 0
    .WHILE row_index < 6
        MOV column_index, 0
        .WHILE column_index < 18
            MOV eax, DWORD PTR [esi]
            MOV pos_x, eax
            MOV eax, DWORD PTR [esi + 4]
            MOV pos_y, eax

            .IF BYTE PTR [esi + 8] == FALSE
                MOV eax, ball.x
                MOV edx, pos_x
                .IF eax >= edx
                    ADD edx, CELL_WD
                    .IF eax <= edx
                        MOV eax, ball.y
                        MOV edx, pos_y
                        .IF eax >= edx
                            ADD edx, CELL_HT
                            .IF eax <= edx
                                MOV BYTE PTR [esi + 8], TRUE

                                MOV eax, ball.speedy
                                NEG eax
                                MOV ball.speedy, eax

                                MOV should_play_beep, TRUE

                                MOV eax, row_index
                                .IF eax < maxrow
                                    MOV maxrow, eax
                                    ;ADD ball.speedx, -2
                                    ;ADD ball.speedy, -2
                                .ENDIF
                            .ENDIF
                        .ENDIF
                    .ENDIF
                .ENDIF
            .ENDIF

            ADD esi, BLOCK_SIZE
            INC column_index
        .ENDW
        INC row_index
    .ENDW

    RET
CheckCollisions endp

CheckRestart proc
    MOV eax, ball.y

    .IF eax > WIN_HT
        ;INVOKE wsprintf, ADDR buffer, ADDR format, 0
        ;INVOKE MessageBox, 0, ADDR buffer, ADDR header_msg, 0
        MOV should_play_game_over, TRUE
        INVOKE Initialize
    .ENDIF

    RET
CheckRestart endp

Initialize proc
    LOCAL row_index:DWORD
    LOCAL column_index:DWORD

    MOV platform.x, WIN_WD/2
    MOV platform.y, WIN_HT-OFFSET_BOTTOM
    MOV platform.speedx, 0
    MOV platform.score, 0
    MOV platform.life_count, 4

    MOV ball.x, WIN_WD/2
    MOV ball.y, WIN_HT-300
    MOV ball.speedx, -9
    MOV ball.speedy, -9

    MOV maxrow, 5

    MOV esi, offset blocks
    MOV row_index, 0
    .WHILE row_index < 6
        MOV column_index, 0
        .WHILE column_index < 18
            MOV eax, CELL_WD
            MUL column_index
            ADD eax, OFFSET_SIDE
            MOV DWORD PTR [esi], eax

            MOV eax, CELL_HT
            MUL row_index
            ADD eax, OFFSET_TOP
            MOV DWORD PTR [esi + 4], eax

            MOV BYTE PTR [esi + 8], FALSE

            ADD esi, BLOCK_SIZE
            INC column_index
        .ENDW
        INC row_index
    .ENDW
    MOV should_play_starting, TRUE
    RET
Initialize endp

MoveBall proc ; Atualiza a posição de um ator de acordo com sua velocidade
    ;Eixo x
    MOV eax, ball.x
    MOV ebx, ball.speedx

    ADD eax, ebx
    MOV ball.x, eax

    ;Eixo y
    MOV eax, ball.y
    MOV ebx, ball.speedy

    ADD eax, ebx
    MOV ball.y, eax

    RET    
MoveBall endp

MovePlayer proc ; Atualiza a posição de um ator de acordo com sua velocidade
    ;Eixo x
    MOV eax, platform.x
    MOV ebx, platform.speedx

    ADD eax, ebx
    MOV platform.x, eax

    .IF platform.x < X_MIN_LIMIT+PLAYER_WD/2
        MOV platform.x, X_MIN_LIMIT+PLAYER_WD/2
    .ELSEIF platform.x > X_MAX_LIMIT-PLAYER_WD/2
        MOV platform.x, X_MAX_LIMIT-PLAYER_WD/2
    .ENDIF

    RET
MovePlayer endp

DrawBackground proc _hMemDC:DWORD, _hMemDCTwo:DWORD
    INVOKE SelectObject, _hMemDCTwo, hBackgroundBmp
    INVOKE BitBlt, _hMemDC, 0, 0, WIN_WD, WIN_HT, _hMemDCTwo, 0, 0, SRCCOPY

    RET
DrawBackground endp

DrawGameOver proc _hMemDC:DWORD, _hMemDCTwo:DWORD
    INVOKE SelectObject, _hMemDCTwo, hGame_OverBmp
    INVOKE BitBlt, _hMemDC, 0, 0, WIN_WD, WIN_HT, _hMemDCTwo, 0, 0, SRCCOPY

    RET
DrawGameOver endp

DrawStarting proc _hMemDC:DWORD, _hMemDCTwo:DWORD
    INVOKE SelectObject, _hMemDCTwo, hStartingBmp
    INVOKE BitBlt, _hMemDC, 0, 0, WIN_WD, WIN_HT, _hMemDCTwo, 0, 0, SRCCOPY

    RET
DrawStarting endp

DrawPlayer proc _hMemDC:DWORD, _hMemDCTwo:DWORD
    INVOKE SelectObject, _hMemDCTwo, hPlayerBmp
    MOV eax, platform.x
    MOV ebx, platform.y
    SUB eax, PLAYER_WD/2
    INVOKE BitBlt, _hMemDC, eax, ebx, PLAYER_WD, PLAYER_HT, _hMemDCTwo, 0, 0, SRCCOPY

    RET
DrawPlayer endp

DrawBlocks proc _hMemDC:DWORD, _hMemDCTwo:DWORD
    LOCAL row_index:DWORD
    LOCAL column_index:DWORD

    LOCAL pos_x:DWORD
    LOCAL pos_y:DWORD

    LOCAL sprite_offset:DWORD

    INVOKE SelectObject, _hMemDCTwo, hCellsBmp

    MOV esi, offset blocks
    MOV row_index, 0
    .WHILE row_index < 6
        MOV eax, CELL_HT
        MUL row_index
        MOV sprite_offset, eax

        MOV column_index, 0
        .WHILE column_index < 18
            .IF BYTE PTR [esi + 8] == FALSE
                MOV eax, DWORD PTR [esi]
                MOV pos_x, eax
                MOV eax, DWORD PTR [esi + 4]
                MOV pos_y, eax

                INVOKE BitBlt, _hMemDC, pos_x, pos_y, CELL_WD, CELL_HT, _hMemDCTwo, 0, sprite_offset, SRCCOPY
            .ENDIF

            ADD esi, BLOCK_SIZE
            INC column_index
        .ENDW
        INC row_index
    .ENDW

    RET
DrawBlocks endp

DrawBall proc _hMemDC:DWORD, _hMemDCTwo:DWORD
    INVOKE SelectObject, _hMemDCTwo, hBallBmp
    MOV eax, ball.x
    MOV ebx, ball.y
    SUB eax, BALL_WD/2
    SUB ebx, BALL_WD/2
    INVOKE BitBlt, _hMemDC, eax, ebx, BALL_WD, BALL_WD, _hMemDCTwo, 0, 0, SRCCOPY

    RET
DrawBall endp

GameHandler proc Param:dword 
    INVOKE WaitForSingleObject, hGameEventStart, 45

    .IF eax == WAIT_TIMEOUT
            INVOKE PostMessage, hWnd, WM_UPDATE, NULL, NULL   
    .ELSEIF eax == WAIT_OBJECT_0	
            INVOKE PostMessage, hWnd, WM_UPDATE, NULL, NULL
    .ENDIF

    JMP GameHandler
    RET
GameHandler endp

SoundHandler proc Param:dword 
    INVOKE WaitForSingleObject, hSoundEventStart, 45

    .IF eax == WAIT_TIMEOUT
            .IF should_play_beep == TRUE
                INVOKE PlaySound, OFFSET beep, NULL, SND_FILENAME
                MOV should_play_beep, FALSE
            .ELSEIF should_play_plop == TRUE
                INVOKE PlaySound, OFFSET plop, NULL, SND_FILENAME
                MOV should_play_plop, FALSE
            .ELSEIF should_play_long_beep == TRUE
                INVOKE PlaySound, OFFSET long_beep, NULL, SND_FILENAME
                MOV should_play_long_beep, FALSE
            .ELSEIF should_play_game_over == TRUE
                INVOKE PlaySound, OFFSET game_over, NULL, SND_FILENAME
                MOV should_play_game_over, FALSE
            .ELSEIF should_play_starting == TRUE
                INVOKE PlaySound, OFFSET starting, NULL, SND_FILENAME
                MOV should_play_starting, FALSE
            .ENDIF
    .ELSEIF eax == WAIT_OBJECT_0
    .ENDIF

    JMP SoundHandler
    RET
SoundHandler endp

end start