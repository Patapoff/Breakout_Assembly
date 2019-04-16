.386
.model flat, stdcall
option casemap :none

include engine.inc


.code 
start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax

    invoke WinCreate, hInstance, SW_SHOWDEFAULT
    invoke ExitProcess, eax

;loadGraphics proc ;Carrega os bitmaps do jogo:
;ret
;loadGraphics dd

WinCreate proc hInst:HINSTANCE, CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX                                            ; create local variables on stack 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND

    mov   wc.cbSize,SIZEOF WNDCLASSEX                   ; fill values in members of wc 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc 
    mov   wc.cbClsExtra,NULL 
    mov   wc.cbWndExtra,NULL 
    push  hInstance 
    pop   wc.hInstance 
    mov   wc.hbrBackground,COLOR_WINDOW+3
    mov   wc.lpszMenuName,NULL 
    mov   wc.lpszClassName,OFFSET ClassName 
    invoke LoadIcon,hInstance, 500
    mov   wc.hIcon,eax 
    mov   wc.hIconSm,eax 
    invoke LoadCursor,NULL,IDC_ARROW 
    mov   wc.hCursor,eax 
    invoke RegisterClassEx, addr wc                       ; register our window class 
    invoke CreateWindowEx,NULL,\ 
                ADDR ClassName,\ 
                ADDR AppName,\ 
                WS_OVERLAPPEDWINDOW,\ 
                CW_USEDEFAULT,\ 
                CW_USEDEFAULT,\ 
                CW_USEDEFAULT,\ 
                CW_USEDEFAULT,\ 
                NULL,\ 
                NULL,\ 
                hInst,\ 
                NULL 
    mov   hwnd,eax 
    invoke ShowWindow, hwnd,CmdShow               ; display our window on desktop 
    invoke UpdateWindow, hwnd                                 ; refresh the client area

    .WHILE TRUE                                                         ; Enter message loop 
                invoke GetMessage, ADDR msg,NULL,0,0 
                .BREAK .IF (!eax) 
                invoke TranslateMessage, ADDR msg 
                invoke DispatchMessage, ADDR msg 
   .ENDW 
    mov     eax,msg.wParam                                            ; return exit code in eax 
    ret 
WinCreate endp

WndProc proc _hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    .IF uMsg==WM_DESTROY                           ; if the user closes our window 
        invoke PostQuitMessage,NULL             ; quit our application 
    .ELSE 
        invoke DefWindowProc,_hWnd,uMsg,wParam,lParam     ; Default message processing 
        ret 
    .ENDIF 
    xor eax,eax 
    ret 
WndProc endp

end start