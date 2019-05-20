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

    MOV    wc.hbrBackground, COLOR_WINDOW+3
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
		MOV    hEventStart, eax

        MOV eax, OFFSET GameHandler
        INVOKE CreateThread, NULL, NULL, eax, 0, 0, ADDR ThreadID  ; Cria a thread principal
        INVOKE CloseHandle, eax

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

    RET
LoadAssets endp

UpdateScreen proc _hWnd:HWND
    LOCAL  ps:PAINTSTRUCT 
    LOCAL  hDC:HDC 
    LOCAL  hMemDC:HDC 

    INVOKE BeginPaint, _hWnd, ADDR ps
    MOV    hDC, eax
    INVOKE CreateCompatibleDC, hDC
    MOV    hMemDC, eax

    INVOKE DrawBackground, hDC, hMemDC
    INVOKE DrawBlocks, hDC, hMemDC
    INVOKE DrawPlayer, hDC, hMemDC
    INVOKE DrawBall, hDC, hMemDC
    
    INVOKE DeleteDC, hMemDC
    INVOKE EndPaint, _hWnd, addr ps

    RET
UpdateScreen endp

UpdatePhysics proc
    INVOKE CheckRestart
    INVOKE CheckCollisions

    INVOKE MovePlayer
    INVOKE MoveBall

    INVOKE InvalidateRect, hWnd, NULL, TRUE

    RET
UpdatePhysics endp

CheckCollisions proc
    LOCAL row_index:DWORD
    LOCAL column_index:DWORD

    LOCAL pos_x:DWORD
    LOCAL pos_y:DWORD

    MOV edx, X_MIN_LIMIT+BALL_WD/2
    MOV ebx, X_MAX_LIMIT-BALL_WD/2
    .IF ball.x < edx
        MOV ball.x, edx
        MOV eax, ball.speedx
        NEG eax
        MOV ball.speedx, eax
    .ELSEIF ball.x > ebx
        MOV ball.x, ebx
        MOV eax, ball.speedx
        NEG eax
        MOV ball.speedx, eax
    .ENDIF

    .IF ball.y < Y_MAX_LIMIT+BALL_WD/2
        MOV ball.y, Y_MAX_LIMIT+BALL_WD/2
        MOV eax, ball.speedy
        NEG eax
        MOV ball.speedy, eax
    .ENDIF

    MOV eax, platform.x
    SUB eax, PLAYER_WD/2
    SUB eax, BALL_WD/2
    .IF ball.x >= eax
        MOV eax, platform.x
        ADD eax, PLAYER_WD/2
        ADD eax, BALL_WD/2
        .IF ball.x <= eax
            MOV eax, platform.y
            SUB eax, BALL_WD/2
            .IF ball.y >= eax
                MOV eax, platform.y
                ADD eax, 2
                ADD eax, BALL_WD/2
                .IF ball.y <= eax
                    MOV eax, ball.speedy
                    NEG eax
                    MOV ball.speedy, eax
                .ENDIF
            .ENDIF
        .ENDIF
    .ENDIF

    MOV esi, offset blocks
    MOV row_index, 0
    .WHILE row_index < 6
        MOV column_index, 0
        .WHILE column_index < 18
            MOV eax, DWORD PTR [esi]
            MOV pos_x, eax
            MOV eax, DWORD PTR [esi + 4]
            MOV pos_y, eax

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

                            MOV eax, row_index
                            .IF eax < maxrow
                                MOV maxrow, eax
                                ADD ball.speedx, -2
                                ADD ball.speedy, -2
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

DrawBackground proc _hDC:DWORD, _hMemDC:DWORD
    INVOKE SelectObject, _hMemDC, hBackgroundBmp
    INVOKE BitBlt, _hDC, 0, 0, WIN_WD, WIN_HT, _hMemDC, 0, 0, SRCCOPY

    RET
DrawBackground endp

DrawPlayer proc _hDC:DWORD, _hMemDC:DWORD
    INVOKE SelectObject, _hMemDC, hPlayerBmp
    MOV eax, platform.x
    MOV ebx, platform.y
    SUB eax, PLAYER_WD/2
    INVOKE BitBlt, _hDC, eax, ebx, PLAYER_WD, PLAYER_HT, _hMemDC, 0, 0, SRCCOPY

    RET
DrawPlayer endp

DrawBlocks proc _hDC:DWORD, _hMemDC:DWORD
    LOCAL row_index:DWORD
    LOCAL column_index:DWORD

    LOCAL pos_x:DWORD
    LOCAL pos_y:DWORD

    LOCAL sprite_offset:DWORD

    INVOKE SelectObject, _hMemDC, hCellsBmp

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

                INVOKE BitBlt, _hDC, pos_x, pos_y, CELL_WD, CELL_HT, _hMemDC, 0, sprite_offset, SRCCOPY
            .ENDIF

            ADD esi, BLOCK_SIZE
            INC column_index
        .ENDW
        INC row_index
    .ENDW

    RET
DrawBlocks endp

DrawBall proc _hDC:DWORD, _hMemDC:DWORD
    INVOKE SelectObject, _hMemDC, hBallBmp
    MOV eax, ball.x
    MOV ebx, ball.y
    SUB eax, BALL_WD/2
    SUB ebx, BALL_WD/2
    INVOKE BitBlt, _hDC, eax, ebx, BALL_WD, BALL_WD, _hMemDC, 0, 0, SRCCOPY

    RET
DrawBall endp

GameHandler proc Param:dword 
    INVOKE WaitForSingleObject, hEventStart, 45

    .IF eax == WAIT_TIMEOUT
            INVOKE PostMessage, hWnd, WM_UPDATE, NULL, NULL   
    .ELSEIF eax == WAIT_OBJECT_0	
            INVOKE PostMessage, hWnd, WM_UPDATE, NULL, NULL
    .ENDIF

    JMP GameHandler
    RET
GameHandler endp

end start