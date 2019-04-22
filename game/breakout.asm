.386
.model flat, stdcall
option casemap :none

include engine.inc

.data
    format     DB "Value: %d", 0
    header_msg DB "Result", 0
    buffer     DB 256 dup(?)

    player player_obj <<WIN_WD/2, WIN_HT-70>, 0, 4, 0>
    ball ball_obj <<WIN_WD/2, WIN_HT-300>, <5, 5>>
    blocks block_obj 108 dup(<<>, FALSE>)

.code 
start:
    INVOKE GetModuleHandle, NULL
    MOV    hInstance, eax

    INVOKE WinCreate, hInstance, SW_SHOWDEFAULT
    INVOKE ExitProcess, eax

WinCreate proc hInst:HINSTANCE, CmdShow:DWORD 
    LOCAL  wc:WNDCLASSEX                          ; create local variables on stack 
    LOCAL  msg:MSG 
    LOCAL  hwnd:HWND
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
        
    MOV    hwnd, eax 
    INVOKE ShowWindow, hwnd, CmdShow               ; Mostra a janela
    INVOKE UpdateWindow, hwnd                      ; Atualiza a área da janela

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

        ;INVOKE wsprintf, ADDR buffer, ADDR format, blocks[0].pos.x
        ;INVOKE MessageBox, 0, ADDR buffer, ADDR header_msg, 0

        ;MOV eax, OFFSET GameHandler
        ;INVOKE CreateThread, NULL, NULL, eax, 0, 0, ADDR threadID  ; Cria a thread principal
        ;INVOKE CloseHandle, eax 
    .ELSEIF uMsg == WM_DESTROY                                     ; Caso o jogador feche a janela
        INVOKE PostQuitMessage, NULL                               ; Fecha o jogo
    .ELSEIF uMsg == WM_PAINT      
        INVOKE UpdateScreen, _hWnd                                 ; Atualizar a tela
    .ELSE
        INVOKE DefWindowProc, _hWnd, uMsg, wParam, lParam          ; Messagem padrão
        RET
    .ENDIF

    XOR eax, eax 
    RET
WndProc endp

LoadAssets proc ; Carrega os bitmaps e matriz de blocos do jogo:
    LOCAL block_index:DWORD
    LOCAL row_index:DWORD
    LOCAL column_index:DWORD

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

GameHandler proc p:dword
GameHandler endp

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
    INVOKE MovePlayer
    INVOKE MoveBall

    RET
UpdatePhysics endp

MovePlayer proc
    ; Incrementa o X
    MOV ebx, player.pos.x
    MOV ecx, player.speed
    ADD ebx, ecx

    MOV player.pos.x, ebx

    RET
MovePlayer endp

MoveBall proc
    ; Incrementa o X
    MOV ebx, ball.pos.x
    MOV ecx, ball.speed.x
    ADD ebx, ecx

    MOV ball.pos.x, ebx

    ; Incrementa o Y
    MOV ebx, ball.pos.y
    MOV ecx, ball.speed.y
    ADD ebx, ecx

    MOV ball.pos.y, ebx

    RET
MoveBall endp

DrawBackground proc _hDC:DWORD, _hMemDC:DWORD
    INVOKE SelectObject, _hMemDC, hBackgroundBmp
    INVOKE BitBlt, _hDC, 0, 0, WIN_WD, WIN_HT, _hMemDC, 0, 0, SRCCOPY

    RET
DrawBackground endp

DrawPlayer proc _hDC:DWORD, _hMemDC:DWORD
    INVOKE SelectObject, _hMemDC, hPlayerBmp
    MOV eax, player.pos.x
    MOV ebx, player.pos.y
    SUB eax, PLAYER_WD/2
    INVOKE BitBlt, _hDC, eax, ebx, PLAYER_WD, PLAYTER_HT, _hMemDC, 0, 0, SRCCOPY

    RET
DrawPlayer endp

DrawBall proc _hDC:DWORD, _hMemDC:DWORD
    INVOKE SelectObject, _hMemDC, hBallBmp
    MOV eax, ball.pos.x
    MOV ebx, ball.pos.y
    SUB eax, BALL_SIZE/2
    SUB ebx, BALL_SIZE/2
    INVOKE BitBlt, _hDC, eax, ebx, BALL_SIZE, BALL_SIZE, _hMemDC, 0, 0, SRCCOPY

    RET
DrawBall endp

DrawBlocks proc _hDC:DWORD, _hMemDC:DWORD
    LOCAL block_index:DWORD
    LOCAL row_index:DWORD
    LOCAL column_index:DWORD

    LOCAL pos_x:DWORD
    LOCAL pos_y:DWORD

    LOCAL sprite_offset:DWORD

    INVOKE SelectObject, _hMemDC, hCellsBmp

    MOV row_index, 0
    .WHILE row_index < 6
        MOV eax, CELL_HT
        MUL row_index
        MOV sprite_offset, eax

        MOV column_index, 0
        .WHILE column_index < 18
            MOV eax, 18
            MUL row_index
            ADD eax, column_index
            MOV block_index, eax

            MOV eax, CELL_WD
            MUL column_index
            ADD eax, CELL_WD
            MOV blocks[block_index].pos.x, eax

            MOV eax, CELL_HT
            MUL row_index
            ADD eax, OFFSET_TOP
            MOV blocks[block_index].pos.y, eax

            .IF blocks[block_index].destroyed == FALSE
                MOV eax, blocks[block_index].pos.x
                MOV pos_x, eax
                MOV eax, blocks[block_index].pos.y
                MOV pos_y, eax

                INVOKE BitBlt, _hDC, pos_x, pos_y, CELL_WD, CELL_HT, _hMemDC, 0, sprite_offset, SRCCOPY
            .ENDIF

            INC column_index
        .ENDW
        INC row_index
    .ENDW

    RET
DrawBlocks endp

end start