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

;=================
; Structs
;=================
pair struct ;Par ordenado (<a, b>): 
    x  db ?
    y  db ?
pair ends

gameObj struct ;Objeto primário (<x, y, <Vx, Vy>>):
	x  dw ?
    y  dw ?
    
	speed pair <>
gameObj ends

player struct ;Dados de um jogador (<Life, <x, y, <Vx, Vy>>>):
    life db ?
    direc db ?
    playerObj gameObj <>
player ends

node struct ;Nó de uma lista ligada
    next dd ?
    value gameObj <>
node ends
;=====================
; Constantes
;=====================
.const
	WIN_HT equ 700 ;Altura da janela
    WIN_WD equ 600 ;Largura da janela

    OFFSETX equ WIN_WD - HALF_SIZE
    OFFSETY equ WIN_HT - HALF_SIZE

    SCORE_SPACING equ 10 ;Espaço de separação dos digitos do jogo

    SPEED equ 4 ;Velocidade dos jogador


;=================
; data
;=================
.data      
AppName db "Combat", 0 ;Título da janela
ClassName db "CombatClass", 0 ;Classe da janela

.data?                
hWnd HWND ?
threadID DWORD ?
hInstance HINSTANCE ?  

;=================
; prototypes
;=================
GameMain proto :DWORD, :DWORD   

gameHandler proto :DWORD ;Thread principal do jogo

updateScreen proto ;Desenha na tela todos os objetos






