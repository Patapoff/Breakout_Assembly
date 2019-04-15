.386
.model flat, stdcall
option casemap :none

include engine.inc

.data
    ;Estruturas dos jogadores:
   ; player player <MAX_LIFE, 7, <IMG_SIZE, WIN_HT / 2, <0, 0>>>

   canPlyrsMov pair <0, 0> ;Indica se cada jogador pode se mover

   hit db FALSE ;Indica se algum jogador pontuo

    over byte 0 ;Indica se o jogo acabou

.code 
start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax

    invoke GameMain, hInstance, SW_SHOWDEFAULT
    invoke ExitProcess, eax



end start