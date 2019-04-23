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

ball_obj struct ; Estrutura de um ator
    x dd ?
    y dd ?
    speedx dd ?
    speedy dd ?
ball_obj ends

player_obj struct ; Dados de um jogador
    x dd ?
    y dd ?
    speedx dd ?
    score dd ?
    life_count dd ?
player_obj ends

block_obj struct ; Estrutura dos blocos 
    x dd ?
    y dd ?
    destroyed db FALSE
block_obj ends


;=====================
;     Constantes
;=====================
.const
    FALSE equ 0
    TRUE equ 1

    WIN_WD equ 1200 ; Largura da janela
	WIN_HT equ 750 ; Altura da janela

    WM_UPDATE equ WM_USER+100h

    OFFSET_TOP equ 202
    OFFSET_SIDE equ 60
    OFFSET_BOTTOM equ 70

    X_MIN_LIMIT equ 60
    X_MAX_LIMIT equ 1140
    Y_MAX_LIMIT equ 109

    BALL_WD equ 15
    CELL_WD equ 60
    CELL_HT equ 23
    PLAYER_WD equ 120
    PLAYER_HT equ 23
    SPEED equ 20

    BLOCK_SIZE equ sizeof block_obj

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
ThreadID DWORD ?
hThread DWORD ?
hEventStart DWORD ?
hInstance HINSTANCE ? 
hWnd HWND ?

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

MovePlayer proto ;Atualiza a posição de um ator

MoveBall proto ;Atualiza a posição de um ator