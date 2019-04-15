include C:\masm32\include\windows.inc
include C:\masm32\include\masm32.inc
include C:\masm32\include\gdi32.inc
include C:\masm32\include\user32.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\Comctl32.inc
include C:\masm32\include\comdlg32.inc
include C:\masm32\include\shell32.inc
include C:\masm32\include\msimg32.inc

includelib C:\masm32\lib\masm32.lib
includelib C:\masm32\lib\gdi32.lib
includelib C:\masm32\lib\user32.lib
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\Comctl32.lib
includelib C:\masm32\lib\comdlg32.lib
includelib C:\masm32\lib\shell32.lib
includelib C:\masm32\lib\msimg32.lib

;===================
;      Structs
;===================
obj struct ; Objeto primário (<x, y>):
	x  dw ?
    y  dw ?
obj ends

block struct ; Estrutura dos blocos (<x, y>): 
    x   dw ?
    y   dw ?
block ends

block_row struct ; Estrutura da linha de blocos (<ptr_next, <bx, by>>): 
    next  dd ?
    value block <>
block_row ends

grid struct ; Estrutura da grade de linhas de blocos (<ptr_next_row, <ptr_next_block, <bx, by>>): 
    next  dd ?
    value block_row <>
grid ends

player struct ; Dados de um jogador (<x, y, speed>):
    x     dw ?
    y     dw ?
    speed dw ?
player ends

ball struct ; Dados de um jogador (<x, y, <vx, vy>>):
    x     dw ?
    y     dw ?
    speed obj <>
ball ends

;=====================
;     Constantes
;=====================
.const
	WIN_HT equ 700 ; Altura da janela
    WIN_WD equ 600 ; Largura da janela

    OFFSETX equ WIN_WD - HALF_SIZE
    OFFSETY equ WIN_HT - HALF_SIZE

    SCORE_SPACING equ 10 ; Espaço de separação dos digitos do jogo

    SPEED equ 4 ; Velocidade dos jogador


;=================
;      Data
;=================
.data
AppName db "Atari Breakout", 0 ; Título da janela
ClassName db "BreakoutClass", 0 ; Classe da janela

.data?                
hWnd HWND ?
threadID DWORD ?
hInstance HINSTANCE ?  

;=================
; prototypes
;=================
WinMain proto : DWORD, : DWORD   

GameHandler proto : DWORD ; Thread principal do jogo

UpdateScreen proto ; Desenha na tela todos os objetos

LoadGraphics proto 