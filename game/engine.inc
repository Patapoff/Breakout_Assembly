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
	x  dd ?
    y  dd ?
obj ends

block_obj struct ; Estrutura dos blocos (<<x, y>, bool>): 
    pos obj <>
    destroyed db FALSE
block_obj ends

player_obj struct ; Dados de um jogador (<x, y, speed>):
    pos obj <>
    score dd ?
    life_count dd ?
    speed dd ?
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

    OFFSET_TOP equ 202

    BALL_SIZE equ 15
    CELL_WD equ 60
    CELL_HT equ 23
    PLAYER_WD equ 120
    PLAYTER_HT equ 23
    SPEED equ 8

    ICON equ 500

    BACKGROUND_BMP equ 100
    CELLS_BMP equ 101
    BALL_BMP equ 102
    PLAYER_BMP equ 103

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
WinCreate PROTO : DWORD, : DWORD   

WndProc PROTO : DWORD, : DWORD, : DWORD, : DWORD   

LoadAssets PROTO ; Carrega as imagens do jogo

UpdateScreen PROTO : DWORD ; Desenha na tela todos os objetos

UpdatePhysics PROTO ; Atualiza a física do jogo

GameHandler PROTO : DWORD ; Thread principal do jogo

DrawBackground PROTO : DWORD, : DWORD ; Desenha o background

DrawPlayer PROTO : DWORD, : DWORD ; Desenha o jogador

DrawBall PROTO : DWORD, : DWORD ; Desenha a bola

DrawBlocks PROTO : DWORD, : DWORD ; Desenha a bola

MovePlayer PROTO ; Move o jogador

MoveBall PROTO ; Move a bola