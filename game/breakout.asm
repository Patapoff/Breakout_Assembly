.386
.model flat, stdcall
option casemap :none

include engine.inc

.data
    header_format           DB "%Ala: %d", 0
    header_msg              DB "Resultado", 0
    buffer                  DB 256 dup(?)


    player player_obj <<WIN_WD/2, WIN_HT-70>, 0, 4, 0>
    ball ball_obj <<WIN_WD/2, WIN_HT-300>, <1, 1>>
    grid b_grid <>

.code 
start:
    invoke GetModuleHandle, NULL
    mov    hInstance, eax

    invoke WinCreate, hInstance, SW_SHOWDEFAULT
    invoke ExitProcess, eax

WinCreate proc hInst:HINSTANCE, CmdShow:DWORD 
    local  wc:WNDCLASSEX                                            ; create local variables on stack 
    local  msg:MSG 
    local  hwnd:HWND
    local  clientRect:RECT

    mov    wc.cbSize, SIZEOF WNDCLASSEX                   ; fill values in members of wc 
    mov    wc.style, CS_HREDRAW or CS_VREDRAW 
    mov    wc.lpfnWndProc, OFFSET WndProc 
    mov    wc.cbClsExtra, NULL 
    mov    wc.cbWndExtra, NULL 

    push   hInstance 
    pop    wc.hInstance 

    mov    wc.hbrBackground, COLOR_WINDOW+3
    mov    wc.lpszMenuName, NULL 
    mov    wc.lpszClassName, OFFSET ClassName 

    invoke LoadIcon, hInstance, 500
    mov    wc.hIcon, eax 
    mov    wc.hIconSm, 0

    invoke LoadCursor, NULL, IDC_ARROW 
    mov    wc.hCursor,eax 
    invoke RegisterClassEx, addr wc                       ; register our window class 

    ;======================================

    mov    clientRect.left, 0
    mov    clientRect.top, 0
    mov    clientRect.right, WIN_WD
    mov    clientRect.bottom, WIN_HT

    invoke AdjustWindowRect, addr clientRect, WS_CAPTION, FALSE

    mov    eax, clientRect.right
    sub    eax, clientRect.left
    mov    ebx, clientRect.bottom
    sub    ebx, clientRect.top

    ;==============================

    invoke CreateWindowEx, NULL, addr ClassName, addr AppName,\ 
        WS_OVERLAPPED or WS_SYSMENU or WS_MINIMIZEBOX,\ 
        CW_USEDEFAULT, CW_USEDEFAULT,\
        eax, ebx, NULL, NULL, hInst, NULL 
        
    mov    hwnd, eax 
    invoke ShowWindow, hwnd, CmdShow               ; display our window on desktop 
    invoke UpdateWindow, hwnd                      ; refresh the client area

    .WHILE TRUE                                    ; Enter message loop 
        invoke GetMessage, ADDR msg, NULL, 0, 0 
        .BREAK .IF (!eax) 
        invoke TranslateMessage, ADDR msg 
        invoke DispatchMessage, ADDR msg 
   .ENDW

    mov  eax, msg.wParam                        ; return exit code in eax
    ret
WinCreate endp

WndProc proc _hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg == WM_CREATE                                        ;Carrega as imagens e cria a thread principal:---------
        invoke LoadAssets
    .ELSEIF uMsg == WM_DESTROY                                   ; if the user closes our window 
        invoke PostQuitMessage, NULL                             ; quit our application
    .ELSEIF uMsg == WM_PAINT                                     ;Atualizar da página:-------------------------------  
        invoke UpdateScreen, _hWnd
    .ELSE
        invoke DefWindowProc, _hWnd, uMsg, wParam, lParam         ; Default message processing 
        ret
    .ENDIF

    xor eax, eax 
    ret
WndProc endp

LoadAssets proc ; Carrega os bitmaps e matriz de blocos do jogo:
    LOCAL layer_1:b_layer
    LOCAL layer_2:b_layer
    LOCAL layer_3:b_layer
    LOCAL layer_4:b_layer

    invoke LoadBitmap, hInstance, BACKGROUND_BMP
    mov    hBackgroundBmp, eax

    invoke LoadBitmap, hInstance, CELLS_BMP
    mov    hCellsBmp, eax

    invoke LoadBitmap, hInstance, BALL_BMP
    mov    hBallBmp, eax

    invoke LoadBitmap, hInstance, PLAYER_BMP
    mov    hPlayerBmp, eax

    mov layer_1.layer_index, 0
    mov layer_2.layer_index, 1
    mov layer_3.layer_index, 2
    mov layer_4.layer_index, 3

    xor ecx, ecx
    .WHILE ecx < 18
        mov layer_1.blocks[ecx], <>
        mov layer_2.blocks[ecx], <>
        mov layer_3.blocks[ecx], <>
        mov layer_4.blocks[ecx], <>

        inc ecx
    .ENDW

    ret
LoadAssets endp

UpdateScreen proc _hWnd:HWND
    local  ps:PAINTSTRUCT 
    local  hDC:HDC 
    local  hMemDC:HDC 

    invoke BeginPaint, _hWnd, addr ps
    mov    hDC, eax

    invoke CreateCompatibleDC, hDC
    mov    hMemDC, eax


    invoke SelectObject, hMemDC, hBackgroundBmp
    invoke BitBlt, hDC, 0, 0, WIN_WD, WIN_HT, hMemDC, 0, 0, SRCCOPY

    ;invoke SelectObject, hMemDC, hBackgroundBmp
    ;xor ecx, ecx
    ;.WHILE lengthof 

    ;.ENDW


    invoke SelectObject, hMemDC, hPlayerBmp
    movzx  eax, player.pos.x
    movzx  ebx, player.pos.y
    invoke BitBlt, hDC, eax, ebx, PLAYER_WD, PLAYTER_HT, hMemDC, 0, 0, SRCCOPY

    invoke SelectObject, hMemDC, hBallBmp
    movzx  eax, ball.pos.x
    movzx  ebx, ball.pos.y
    invoke BitBlt, hDC, eax, ebx, BALL_SIZE, BALL_SIZE, hMemDC, 0, 0, SRCCOPY

    invoke DeleteDC, hMemDC
    invoke EndPaint, _hWnd, addr ps
    ret
UpdateScreen endp

end start