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

block struct ; Estrutura dos blocos (<<x, y>, bool>): 
    pos obj <>
    destroyed db FALSE
block ends

b_layer struct ; Estrutura da camada de blocos (<layer_index, [<<x, y>, bool>]): 
    layer_index db ?
    blocks block 18 dup(<>)
b_layer ends

b_grid struct ; Estrutura da grade de camada de blocos ([<layer_index, [<<x, y>, bool>]]): 
    b_layers b_layer 6 dup(<>)
b_grid ends 

player_obj struct ; Dados de um jogador (<x, y, speed>):
    pos obj <>
    score dw ?
    life_count dw ?
    speed dw ?
player_obj ends

ball_obj struct ; Dados de um jogador (<x, y, <vx, vy>>):
    pos obj <>
    speed obj <>
ball_obj ends

;=====================
;     Constantes
;=====================
.const
    FALSE equ 0
    TRUE equ 1

    WIN_WD equ 1200 ; Largura da janela
	WIN_HT equ 750 ; Altura da janela

    ICON equ 500

    BACKGROUND_BMP equ 100
    CELLS_BMP equ 101
    BALL_BMP equ 102
    PLAYER_BMP equ 103

    BALL_SIZE equ 15
    CELL_WD equ 60
    CELL_HT equ 23
    PLAYER_WD equ 120
    PLAYTER_HT equ 23

;=================
;      Data
;=================
.data
AppName db "Atari Breakout", 0 ; Título da janela
ClassName db "BreakoutClass", 0 ; Classe da janela

.data?                
threadID DWORD ?
hInstance HINSTANCE ? 

hBackgroundBmp DWORD ?
hCellsBmp DWORD ?
hBallBmp DWORD ?
hPlayerBmp DWORD ?

;=================
; prototypes
;=================
WinCreate proto : DWORD, : DWORD   

WndProc proto : DWORD, : DWORD, : DWORD, : DWORD   

GameHandler proto : DWORD ; Thread principal do jogo

UpdateScreen proto : DWORD ; Desenha na tela todos os objetos

LoadAssets proto ; Carrega as imagens do jogo