.386
.model flat, stdcall
option casemap :none

include engine.inc

.data
    header_format           DB "%Ala: %d", 0
    header_msg              DB "Resultado", 0
    buffer                  DB 256 dup(?)

    player player_obj <<WIN_WD/2, WIN_HT-70>, 0, 4, 0>
    ball ball_obj <<WIN_WD/2, WIN_HT-300>, <5, 5>>
    grid b_grid <>

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
    LOCAL layer_1:b_layer
    LOCAL layer_2:b_layer
    LOCAL layer_3:b_layer
    LOCAL layer_4:b_layer

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

    INVOKE BeginPaint, _hWnd, addr ps
    MOV    hDC, eax

    INVOKE CreateCompatibleDC, hDC
    MOV    hMemDC, eax


    INVOKE SelectObject, hMemDC, hBackgroundBmp
    INVOKE BitBlt, hDC, 0, 0, WIN_WD, WIN_HT, hMemDC, 0, 0, SRCCOPY

    INVOKE SelectObject, hMemDC, hPlayerBmp
    MOVZX  eax, player.pos.x
    MOVZX  ebx, player.pos.y
    SUB eax, PLAYER_WD/2
    INVOKE BitBlt, hDC, eax, ebx, PLAYER_WD, PLAYTER_HT, hMemDC, 0, 0, SRCCOPY

    INVOKE SelectObject, hMemDC, hBallBmp
    MOVZX  eax, ball.pos.x
    MOVZX  ebx, ball.pos.y
    SUB eax, BALL_SIZE/2
    SUB ebx, BALL_SIZE/2
    INVOKE BitBlt, hDC, eax, ebx, BALL_SIZE, BALL_SIZE, hMemDC, 0, 0, SRCCOPY


    INVOKE DeleteDC, hMemDC
    INVOKE EndPaint, _hWnd, addr ps
    RET
UpdateScreen endp

UpdatePhysics proc
    INVOKE MovePlayer, offset player
    INVOKE MoveBall, offset ball
UpdatePhysics endp

MovePlayer proc _player:DWORD
    ASSUME eax : ptr player_obj
    MOV eax, _player

    ; Incrementa o X
    MOV bx, [eax].pos.x
    MOV cx, [eax].speed

    ADD bx, cx

    MOV [eax].pos.x, bx

    ASSUME eax:nothing
    RET
MovePlayer endp

MoveBall proc _ball:DWORD
    ASSUME eax : ptr ball_obj
    MOV eax, _ball

    ; Incrementa o X
    MOV bx, [eax].pos.x
    MOV cx, [eax].speed.x

    ADD bx, cx

    MOV [eax].pos.x, bx

    ; Incrementa o Y
    MOV bx, [eax].pos.y
    MOV cx, [eax].speed.y

    ADD bx, cx

    MOV [eax].pos.y, bx

    ASSUME eax:nothing
    RET
MoveBall endp

end start