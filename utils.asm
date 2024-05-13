; THIS FILE CONTAINS CERTAIN PROCEDURES NEEDED FOR GUESSTHENUMBER
; TO FUNCTION PROPERLY.

MakeFont PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
; X Text subwindow
cdVCarText1  EQU  WS_CHILD + WS_VISIBLE + SS_CENTER
cdSubType1   EQU  NULL         ; Subwindow type (flat-NULL, 3D-1, etc.)
cdTXPos1     EQU  80           ; Constant double X-Position subwindow for the text 
cdTYPos1     EQU  170          ; Constant double Y-Position subwindow for the text

cdTX2Pos     EQU  100          ; Constant double X-Position subwindow for the text 

cdTX3Pos     EQU  120          ; Constant double X-Position subwindow for the text 
 
cdTXSize1    EQU  30           ; Constant double X-size of the subwindow for the text
cdTYSize1    EQU  30           ; Constant double Y-size of the subwindow for the text

scoreXPos     EQU  360          ; Constant double X-Position subwindow for the text

.data
wc1            WNDCLASSEX  <>
szStatic1      DB          "STATIC", 0

prng_x  DD 0 ; calculation state
prng_a  DD 1099433 ; current seed
noAttempts DD 0 ; Number of guess attempts the user has made
winMsgL       DB          "You ran out of guesses!",0
winMsgHeaderL  db          "You lose.", 0
XText DB "X",0

hWndX1 HANDLE ?
hWndX2 HANDLE ?
hWndX3 HANDLE ?

scoreHandle HANDLE ?
playersScoreA DB "0",0        ; Buffer to store the player's score in ascii


.code

PrngGet PROC range:DWORD             ; Generate a pseudo-random number in range 0,range

    ; count the number of cycles since
    ; the machine has been reset
    invoke GetTickCount

    ; accumulate the value in eax and manage
    ; any carry-spill into the x state var
    adc eax, edx
    adc eax, prng_x

    ; multiply this calculation by the seed
    mul prng_a

    ; manage the spill into the x state var
    adc eax, edx
    mov prng_x, eax

    ; put the calculation in range of what
    ; was requested
    mul range

    ; ranged-random value in eax
    mov eax, edx

    ret

PrngGet ENDP

to_string PROC                ; Convert a decimal to ascii
 mov ebx, 10
 xor ecx, ecx

 repeated_division:
  xor edx, edx
  div ebx
  push dx
  add cl,1
  or eax,eax
  jnz repeated_division

 load_digits:
  pop ax
  or al, 00110000b ; transforms to ascii
  stosb  ; store al into edi. edi = pointer to buffer
  loop load_digits
  mov byte ptr [edi], 0
  
 ret
to_string ENDP

MakeFont PROC hgt:DWORD,wid:DWORD,weight:DWORD,italic:DWORD,lpFontName:DWORD
    ; Purpose: Creates the font
    ; Input  : hgt:DWORD,wid:DWORD,weight:DWORD,italic:DWORD,lpFontName:DWORD
    ; Output : None
    ; Destroy: None
    invoke CreateFont,hgt,wid,NULL,NULL,weight,italic,NULL,NULL,
                      DEFAULT_CHARSET,OUT_TT_PRECIS,CLIP_DEFAULT_PRECIS,
                      PROOF_QUALITY,DEFAULT_PITCH or FF_DONTCARE,
                      lpFontName
    ret
MakeFont ENDP

increment_attempts PROC hanWin:HWND
 add noAttempts, 1  ; Add one to the number of attempts
 cmp noAttempts, 3  ; Compare it with 3
 je newGame         ; If newGame = 3, start new game
 jl continueGame    ; Else we continue

newGame:
 INVOKE    CreateWindowEx, cdSubType1, ADDR szStatic1, ADDR XText, cdVCarText1,\ 
                  cdTX3Pos, cdTYPos1, cdTXSize1, cdTYSize1, hanWin,\
                  500, wc1.hInstance, NULL                           ; Display the 3rd 'X' on the screen
 mov hWndX3, eax    ; Move the file handle into memory so it can be deleted later.
 invoke    MessageBox,hanWin,ADDR winMsgL,ADDR winMsgHeaderL,MB_OK  ; Show a losing OK message box
 mov [noAttempts], 0
 ; Clear the 3 X's on the screen when the user clicks OK
 INVOKE    DestroyWindow, hWndX1   ; Destroy the first 'X' window
 INVOKE    DestroyWindow, hWndX2   ; Destroy the second 'X' window
 INVOKE    DestroyWindow, hWndX3   ; Destroy the third 'X' window
 mov eax, 1         ; We check if eax=1 in the main code file to determine if we need a new random number.
 jmp go_back 

continueGame:
 cmp noAttempts, 1
 je one             ; If noAttempts = 1, jmp to one
 jne two            ; Else jump to 2

 one:
 INVOKE    CreateWindowEx, cdSubType1, ADDR szStatic1, ADDR XText, cdVCarText1,\ 
                  cdTXPos1, cdTYPos1, cdTXSize1, cdTYSize1, hanWin,\
                  500, wc1.hInstance, NULL                           ; Display the first 'X' on the screen
 mov hWndX1, eax    ; Move the file handle into memory so it can be deleted later.
 mov eax, 0
 jmp go_back

 two:
 INVOKE    CreateWindowEx, cdSubType1, ADDR szStatic1, ADDR XText, cdVCarText1,\ 
                  cdTX2Pos, cdTYPos1, cdTXSize1, cdTYSize1, hanWin,\
                  500, wc1.hInstance, NULL                           ; Display the second 'X' on the screen
 mov hWndX2, eax
 mov eax, 0
 jmp go_back

go_back:

 ret
increment_attempts ENDP

clear_attempts PROC ; This is called when the user correctly guesses the number to clear their guesses
 mov [noAttempts], 0
 INVOKE    DestroyWindow, hWndX1   ; Destroy the first 'X' window
 INVOKE    DestroyWindow, hWndX2   ; Destroy the second 'X' window
 INVOKE    DestroyWindow, hWndX3   ; Destroy the third 'X' window
 ret
clear_attempts ENDP

display_scoreI PROC hanWin:HWND    ; call this first to initialize the score to 0
 INVOKE    CreateWindowEx, cdSubType1, ADDR szStatic1, addr playersScoreA, cdVCarText1,\ 
                  scoreXPos, cdTYPos1, cdTXSize1, cdTYSize1, hanWin,\
                  500, wc1.hInstance, NULL                         ; Display the user's score
 mov scoreHandle, eax              ; Move the handle for the score subwindow to memory
 ret
display_scoreI ENDP

display_score PROC score:DWORD ; call this to update the score after initialization
 mov eax, score
 lea edi, playersScoreA
 call to_string                    ; Convert the decimal score to ascii representation
 INVOKE SetWindowText, scoreHandle, ADDR playersScoreA
 ret
display_score ENDP