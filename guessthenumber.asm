.386

.MODEL      flat, stdcall
OPTION      casemap:none


INCLUDE     \masm32\include\windows.inc      ; Includes definitions of structures and constants
INCLUDE     \masm32\include\user32.inc       ; Includes the most common usage prototypes
INCLUDE     \masm32\include\kernel32.inc     ; Includes the most common usage prototypes
INCLUDE     \masm32\include\gdi32.inc       
INCLUDE     utils.asm                    ; PrngGet, to_string
INCLUDELIB  \masm32\lib\user32.lib       ; Imports libraries for the linker to work
INCLUDELIB  \masm32\lib\kernel32.lib     ; Imports libraries for the linker to work
INCLUDELIB  \masm32\lib\gdi32.lib        ; Imports libraries for the linker to work

; Main window
cdXPos      EQU  128         ; Double X-Position constant of the window (top-left corner)
cdYPos      EQU  128         ; Double Y-Position constant of the window (top-left corner)
cdXSize     EQU  500         ; Double X-size constant of the window
cdYSize     EQU  300         ; Double Y-size constant of the window
cdColFondo  EQU  COLOR_BTNFACE + 1  ; Background color of the window: button face gray
cdVIcono    EQU  IDI_APPLICATION ; Window icon, see Resource.H
cdVCursor   EQU  IDC_ARROW   ; Cursor for the window
cdVBarTipo  EQU  NULL                                 ; Normal, with icon
cdVBtnTipo  EQU  WS_GROUP+WS_SYSMENU+WS_VISIBLE    ; All buttons visible, but only minimize and close active
idBtnMensa  EQU  400

WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
MakeFont PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD

; 'Attempts' Text subwindow
cdVCarText  EQU  WS_CHILD + WS_VISIBLE + SS_CENTER
cdTXPos     EQU  20            ; Constant double X-Position subwindow for the text 
cdTYPos     EQU  170          ; Constant double Y-Position subwindow for the text 
cdTXSize    EQU  60; Constant double X-size of the subwindow for the text
cdTYSize    EQU  40           ; Constant double Y-size of the subwindow for the text
cdSubType   EQU  NULL         ; Subwindow type (flat-NULL, 3D-1, etc.)

; 'Score' Text subwindow
cdTXPoss     EQU  310           ; Constant double X-Position subwindow for the text 
cdTYPoss     EQU  170          ; Constant double Y-Position subwindow for the text 
cdTXSizes    EQU  50; Constant double X-size of the subwindow for the text
cdTYSizes    EQU  40           ; Constant double Y-size of the subwindow for the text

; Constants for Menu Options
IDM_OPTIONS_NORMAL equ 0
IDM_OPTIONS_HARD equ 1
IDM_OPTIONS_HTP equ 2
IDM_OPTIONS_EXPLAINHC equ 3

.DATA
  szStatic      DB          "STATIC", 0
  ClassName     DB          "SimpleWinClass", 0
  MsgHeader     DB          "Guess The Number", 0
  MsgError      DB          "Initial load failed.",0
  winMsg1       DB          "You guessed the number!",0
  winMsgHeader  db          "Congratulations!", 0
  ButtonClass   db          "BUTTON", 0
  blnk1         db          0
  szTNRoman     DB          "Times New Roman",0
  vdTNRoman     dd          ?
  wc            WNDCLASSEX  <>
  rct           RECT        <NULL, NULL, NULL, NULL>

 attemptsText DB "Attempts",0
 scoreText    DB "Score:",0
 playerScore  DD 0       ; How many numbers the player guessed correctly
 hcToggle     DW 0

; Text to display on the buttons
  MsgText       DB          "1",0
  MsgText2      DB          "2",0    ; Text for the second button
  MsgText3      DB          "3",0
  MsgText4      DB          "4",0
  MsgText5      DB          "5",0
  MsgText6      DB          "6",0
  MsgText7      DB          "7",0
  MsgText8      DB          "8",0
  MsgText9      DB          "9",0
  MsgText10      DB          "10",0

; Text to display on the GameMode/Help Menus
  NormalString   db "&Normal",0
  HardString     db "&Hardcore",0
  gamemodeString db "&Game Mode",0
  helpString     db "&Help",0
  howtoplayString db "&How to Play",0
  htpMsg         DB "Simply guess a number by clicking on it.",13,10
                 DB "You have 3 attempts to guess correctly.",13,10
                 DB "If you guess correctly, you get a point!",0
  htpMsgHeader   db "How to Play", 0
  hchtpMsg       DB "In hardcore mode, you only have one life.",13,10
                 DB "If you don't guess correctly in 3 attempts,",13,10
                 DB "your entire score will be reset. Good luck!",0
  hchtpMsgHeader DB "How to Play Hardcore Mode", 0
    

.DATA?
  CommandLine DD ?
  hButton1    DD ?
  hButton2    DD ?   ; Handle for the second button
  hButton3    DD ?
  hButton4    DD ?
  hButton5    DD ?
  hButton6    DD ?
  hButton7    DD ?
  hButton8    DD ?
  hButton9    DD ?
  hButton10   DD ?

  ; GameMode/Help Menu variables
  hMenubar HMENU ?
  hMenuGameMode HMENU ?
  hMenuHelp HMENU ?

 winningNumber DD ?

.CODE
  start:
    INVOKE    GetModuleHandle, NULL
    MOV       wc.hInstance, EAX
    INVOKE    GetCommandLine
    MOV       CommandLine, EAX

    call newWinningNumber ; Generates a new pseudorandom number and stores in [winningNumber]

    INVOKE    WinMain, wc.hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    INVOKE    ExitProcess, EAX

  WinMain PROC hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    ; Purpose: Initialize the main window of the application and handle errors if any
    ; Input  : hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    ; Output : None
    ; Destroy: None
    LOCAL     msg:MSG
    LOCAL     hwnd:HWND

    ; If we initialize wc with its values, we risk doing it out of order in case
    ; the definition of the WNDCLASSEX structure changes
    MOV       wc.cbSize, SIZEOF WNDCLASSEX
    MOV       wc.style, CS_HREDRAW OR CS_VREDRAW
    MOV       wc.lpfnWndProc, OFFSET WndProc
    MOV       wc.cbClsExtra, NULL
    MOV       wc.cbWndExtra, NULL 
    ; hInstance already valued above
    MOV       wc.hbrBackground, cdColFondo  ; Background color of the window
    MOV       wc.lpszMenuName, NULL
    MOV       wc.lpszClassName, OFFSET ClassName
    INVOKE    LoadIcon, hInst,NULL
    MOV       wc.hIcon, EAX
    MOV       wc.hIconSm, EAX
    INVOKE    LoadCursor, NULL, cdVCursor
    MOV       wc.hCursor, EAX
    INVOKE    RegisterClassEx, ADDR wc
    TEST      EAX, EAX
    JZ        L_Error
    INVOKE    CreateWindowEx,cdVBarTipo,ADDR ClassName,ADDR MsgHeader,\
              cdVBtnTipo,cdXPos, cdYPos, cdXSize, cdYSize,\
              NULL,NULL,hInst,NULL
    TEST      EAX, EAX
    JZ        L_Error
    MOV       hwnd, EAX
    INVOKE    ShowWindow, hwnd, SW_SHOWNORMAL
    INVOKE    UpdateWindow, hwnd

    .WHILE    TRUE
        INVOKE    GetMessage, ADDR msg, NULL, 0, 0
        .BREAK    .IF (!EAX)
        INVOKE    TranslateMessage, ADDR msg
        INVOKE    DispatchMessage, ADDR msg
    .ENDW
    JMP       L_End
    
    L_Error:
      INVOKE    MessageBox, NULL,ADDR MsgError, NULL, MB_ICONERROR+MB_OK

    L_End:
    MOV       EAX, msg.wParam
    RET
  WinMain ENDP
  
  WndProc proc hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    ; Purpose: Processes messages coming from windows
    ; Input  : hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    ; Output : None
    ; Destroy: None
    .if       uMsg == WM_COMMAND
        .if       wParam == idBtnMensa             ; If the first button is pressed
            .if winningNumber == 0
                 add playerScore, 1                ; Increment player's score by 1
                 push playerScore
                 call display_score                ; Update the player's score if they win
                 invoke    MessageBox,hWin,ADDR winMsg1,ADDR winMsgHeader,MB_OK
                 call clear_attempts               ; Reset the users attempts when they win
                 call newWinningNumber
            .else                                  ; If winningNumber is not 0
                 invoke increment_attempts, hWin
                 .if eax == 1 ; If eax is 1 (indicating a new winning number is needed as player lost)
                    call resetScoreHC              ; Resets the players score if HC mode is on.
                    call newWinningNumber
                 .endif
            .endif
            
        .elseif   wParam == idBtnMensa+1           ; Check for the second button
            .if winningNumber == 1
                 add playerScore, 1                ; Increment player's score by 1
                 push playerScore
                 call display_score
                 invoke    MessageBox,hWin,ADDR winMsg1,ADDR winMsgHeader,MB_OK
                 call clear_attempts
                 call newWinningNumber
            .else                                  ; If winningNumber is not 1
                 invoke increment_attempts, hWin
                 .if eax == 1 ; If eax is 1 (indicating a new winning number is needed as player lost)
                    call resetScoreHC
                    call newWinningNumber
                 .endif
            .endif
        .elseif   wParam == idBtnMensa+2           
            .if winningNumber == 2
                 add playerScore, 1                ; Increment player's score by 1
                 push playerScore
                 call display_score
                 invoke    MessageBox,hWin,ADDR winMsg1,ADDR winMsgHeader,MB_OK
                 call clear_attempts
                 call newWinningNumber
            .else                                  
                 invoke increment_attempts, hWin
                 .if eax == 1 ; If eax is 1 (indicating a new winning number is needed as player lost)
                    call resetScoreHC
                    call newWinningNumber
                 .endif
            .endif
        .elseif   wParam == idBtnMensa+3           
            .if winningNumber == 3
                 add playerScore, 1                ; Increment player's score by 1
                 push playerScore
                 call display_score
                 invoke    MessageBox,hWin,ADDR winMsg1,ADDR winMsgHeader,MB_OK
                 call clear_attempts
                 call newWinningNumber
            .else                                  
                 invoke increment_attempts, hWin
                 .if eax == 1 ; If eax is 1 (indicating a new winning number is needed as player lost)
                    call resetScoreHC
                    call newWinningNumber
                 .endif
            .endif
        .elseif   wParam == idBtnMensa+4           
            .if winningNumber == 4
                 add playerScore, 1                ; Increment player's score by 1
                 push playerScore
                 call display_score
                 invoke    MessageBox,hWin,ADDR winMsg1,ADDR winMsgHeader,MB_OK
                 call clear_attempts
                 call newWinningNumber
            .else                                  
                 invoke increment_attempts, hWin
                 .if eax == 1 ; If eax is 1 (indicating a new winning number is needed as player lost)
                    call resetScoreHC
                    call newWinningNumber
                 .endif
            .endif
        .elseif   wParam == idBtnMensa+5           
            .if winningNumber == 5
                 add playerScore, 1                ; Increment player's score by 1
                 push playerScore
                 call display_score
                 invoke    MessageBox,hWin,ADDR winMsg1,ADDR winMsgHeader,MB_OK
                 call clear_attempts
                 call newWinningNumber
            .else                                 
                 invoke increment_attempts, hWin
                 .if eax == 1 ; If eax is 1 (indicating a new winning number is needed as player lost)
                    call resetScoreHC
                    call newWinningNumber
                 .endif
            .endif
        .elseif   wParam == idBtnMensa+6           
            .if winningNumber == 6
                 add playerScore, 1                ; Increment player's score by 1
                 push playerScore
                 call display_score
                 invoke    MessageBox,hWin,ADDR winMsg1,ADDR winMsgHeader,MB_OK
                 call clear_attempts
                 call newWinningNumber
            .else                                  
                 invoke increment_attempts, hWin
                 .if eax == 1 ; If eax is 1 (indicating a new winning number is needed as player lost)
                    call resetScoreHC
                    call newWinningNumber
                 .endif
            .endif
        .elseif   wParam == idBtnMensa+7           
            .if winningNumber == 7
                 add playerScore, 1                ; Increment player's score by 1
                 push playerScore
                 call display_score
                 invoke    MessageBox,hWin,ADDR winMsg1,ADDR winMsgHeader,MB_OK
                 call clear_attempts
                 call newWinningNumber
            .else                                  
                 invoke increment_attempts, hWin
                 .if eax == 1 ; If eax is 1 (indicating a new winning number is needed as player lost)
                    call resetScoreHC
                    call newWinningNumber
                 .endif
            .endif
        .elseif   wParam == idBtnMensa+8           
            .if winningNumber == 8
                 add playerScore, 1                ; Increment player's score by 1
                 push playerScore
                 call display_score
                 invoke    MessageBox,hWin,ADDR winMsg1,ADDR winMsgHeader,MB_OK
                 call clear_attempts
                 call newWinningNumber
            .else                                  
                 invoke increment_attempts, hWin
                 .if eax == 1 ; If eax is 1 (indicating a new winning number is needed as player lost)
                    call resetScoreHC
                    call newWinningNumber
                 .endif
            .endif
        .elseif   wParam == idBtnMensa+9             ; Last button check (For number 10)           
            .if winningNumber == 9
                 add playerScore, 1                ; Increment player's score by 1
                 push playerScore
                 call display_score
                 invoke    MessageBox,hWin,ADDR winMsg1,ADDR winMsgHeader,MB_OK
                 call clear_attempts
                 call newWinningNumber
            .else                                  
                 invoke increment_attempts, hWin
                 .if eax == 1 ; If eax is 1 (indicating a new winning number is needed as player lost)
                    call resetScoreHC
                    call newWinningNumber
                 .endif
            .endif

        .elseif wParam == IDM_OPTIONS_NORMAL    ; Set gamemode to Normal
            mov hcToggle, 0
            mov playerScore, 0
            push 0
            call hardcoreToggle
            invoke CheckMenuItem, hMenuGameMode, IDM_OPTIONS_NORMAL, MF_CHECKED    ; Check 'Normal' option
            invoke CheckMenuItem, hMenuGameMode, IDM_OPTIONS_HARD, MF_UNCHECKED   ; Uncheck 'Hardcore' option
            invoke MessageBeep, MB_ICONINFORMATION

        .elseif wParam == IDM_OPTIONS_HARD      ; Set gamemode to Hard
            mov hcToggle, 1
            mov playerScore, 0
            push 1
            call hardcoreToggle
            invoke CheckMenuItem, hMenuGameMode, IDM_OPTIONS_HARD, MF_CHECKED      ; Check 'Hardcore' option
            invoke CheckMenuItem, hMenuGameMode, IDM_OPTIONS_NORMAL, MF_UNCHECKED ; Uncheck 'Normal' option
            invoke MessageBeep, MB_ICONINFORMATION

        .elseif wParam == IDM_OPTIONS_HTP      ; When the user clicks on 'How to Play'
            INVOKE MessageBox, hWin, ADDR htpMsg, ADDR htpMsgHeader, MB_OK or MB_SETFOREGROUND or MB_ICONINFORMATION

        .elseif wParam == IDM_OPTIONS_EXPLAINHC
            invoke MessageBox, hWin, ADDR hchtpMsg, ADDR hchtpMsgHeader, MB_OK or MB_SETFOREGROUND or MB_ICONINFORMATION
            
        .endif

        
    .elseif   uMsg == WM_CREATE              ; Creates buttons and text in the game
                                                                    
                                             ; Create the first button
        invoke    CreateWindowEx,WS_EX_LEFT,
                          ADDR ButtonClass,
                          ADDR MsgText,
                          WS_CHILD or WS_VISIBLE,; or BS_ICON,
                          20,20,60,60,
                          hWin,idBtnMensa,
                          wc.hInstance,NULL
        mov       hButton1,eax
        invoke    SendMessage,hButton1,WM_SETFONT,vdTNRoman,0
        
                                             ; Create the second button (labeled '2')
        invoke    CreateWindowEx,WS_EX_LEFT,
                          ADDR ButtonClass,
                          ADDR MsgText2,  ; Text for the second button
                          WS_CHILD or WS_VISIBLE,
                          100,20,60,60,  ; Adjust position to the right
                          hWin,idBtnMensa+1,  ; Increment button ID
                          wc.hInstance,NULL
        mov       hButton2,eax
        invoke    SendMessage,hButton2,WM_SETFONT,vdTNRoman,0

        ; Create the third button 
        invoke    CreateWindowEx,WS_EX_LEFT,
                          ADDR ButtonClass,
                          ADDR MsgText3,  ; Text for the third button
                          WS_CHILD or WS_VISIBLE,
                          180,20,60,60,  ; Adjust position to the right
                          hWin,idBtnMensa+2,  ; Increment button ID
                          wc.hInstance,NULL
        mov       hButton3,eax
        invoke    SendMessage,hButton3,WM_SETFONT,vdTNRoman,0

        ; Create the fourth button 
        invoke    CreateWindowEx,WS_EX_LEFT,
                          ADDR ButtonClass,
                          ADDR MsgText4,  ; Text for the third button
                          WS_CHILD or WS_VISIBLE,
                          260,20,60,60,  ; Adjust position to the right
                          hWin,idBtnMensa+3,  ; Increment button ID
                          wc.hInstance,NULL
        mov       hButton4,eax
        invoke    SendMessage,hButton4,WM_SETFONT,vdTNRoman,0

        ; Create the fifth button 
        invoke    CreateWindowEx,WS_EX_LEFT,
                          ADDR ButtonClass,
                          ADDR MsgText5,  ; Text for the third button
                          WS_CHILD or WS_VISIBLE,
                          340,20,60,60,  ; Adjust position to the right
                          hWin,idBtnMensa+4,  ; Increment button ID
                          wc.hInstance,NULL
        mov       hButton5,eax
        invoke    SendMessage,hButton5,WM_SETFONT,vdTNRoman,0

        ; Create the sixth button (second row of buttons)
        invoke    CreateWindowEx,WS_EX_LEFT,
                          ADDR ButtonClass,
                          ADDR MsgText6,  ; Text for the third button
                          WS_CHILD or WS_VISIBLE,
                          20,100,60,60,  ; Adjust position to the right
                          hWin,idBtnMensa+5,  ; Increment button ID
                          wc.hInstance,NULL
        mov       hButton6,eax
        invoke    SendMessage,hButton6,WM_SETFONT,vdTNRoman,0

        ; Create the seventh button 
        invoke    CreateWindowEx,WS_EX_LEFT,
                          ADDR ButtonClass,
                          ADDR MsgText7,  ; Text for the third button
                          WS_CHILD or WS_VISIBLE,
                          100,100,60,60,  ; Adjust position to the right
                          hWin,idBtnMensa+6,  ; Increment button ID
                          wc.hInstance,NULL
        mov       hButton7,eax
        invoke    SendMessage,hButton7,WM_SETFONT,vdTNRoman,0

        ; Create the eighth button 
        invoke    CreateWindowEx,WS_EX_LEFT,
                          ADDR ButtonClass,
                          ADDR MsgText8,  ; Text for the third button
                          WS_CHILD or WS_VISIBLE,
                          180,100,60,60,  ; Adjust position to the right
                          hWin,idBtnMensa+7,  ; Increment button ID
                          wc.hInstance,NULL
        mov       hButton8,eax
        invoke    SendMessage,hButton8,WM_SETFONT,vdTNRoman,0

        ; Create the ninth button 
        invoke    CreateWindowEx,WS_EX_LEFT,
                          ADDR ButtonClass,
                          ADDR MsgText9,  ; Text for the third button
                          WS_CHILD or WS_VISIBLE,
                          260,100,60,60,  ; Adjust position to the right
                          hWin,idBtnMensa+8,  ; Increment button ID
                          wc.hInstance,NULL
        mov       hButton9,eax
        invoke    SendMessage,hButton9,WM_SETFONT,vdTNRoman,0

        ; Create the tenth button 
        invoke    CreateWindowEx,WS_EX_LEFT,
                          ADDR ButtonClass,
                          ADDR MsgText10,  ; Text for the third button
                          WS_CHILD or WS_VISIBLE,
                          340,100,60,60,  ; Adjust position to the right
                          hWin,idBtnMensa+9,  ; Increment button ID
                          wc.hInstance,NULL
        mov       hButton10,eax
        invoke    SendMessage,hButton10,WM_SETFONT,vdTNRoman,0

        ; Create the subwindow for the text (Attempts)
        INVOKE    CreateWindowEx, cdSubType, ADDR szStatic, ADDR attemptsText, cdVCarText,\ 
                  cdTXPos, cdTYPos, cdTXSize, cdTYSize, hWin,\
                  500, wc.hInstance, NULL

        ; Create the subwindow for the text (Score)
        INVOKE    CreateWindowEx, cdSubType, ADDR szStatic, ADDR scoreText, cdVCarText,\ 
                  cdTXPoss, cdTYPoss, cdTXSizes, cdTYSizes, hWin,\
                  500, wc.hInstance, NULL

        push hWin
        call display_scoreI ; Create score subwindow, initialize at zero.

        ; Initialize the GameMode/Help menus
        
        ; Create menu
        invoke CreateMenu
	  mov hMenubar, eax
        ; Create sub menus
        invoke CreateMenu
	  mov hMenuGameMode, eax
        invoke CreateMenu
        mov hMenuHelp, eax
        
        invoke AppendMenuA, hMenubar, MF_POPUP, hMenuGameMode, addr gamemodeString ; Display 'GameMode' in menu
        invoke AppendMenuA, hMenuGameMode, MF_STRING or MF_CHECKED, IDM_OPTIONS_NORMAL, ADDR NormalString ; Set 'Normal' option checked
	  invoke AppendMenuA, hMenuGameMode, MF_STRING, IDM_OPTIONS_HARD, ADDR HardString ; 'Hardcore' option
                
        invoke AppendMenuA, hMenubar, MF_POPUP, hMenuHelp, addr helpString ; Display 'Help' in menu 
        invoke AppendMenuA, hMenuHelp, MF_STRING, IDM_OPTIONS_HTP, ADDR howtoplayString
	  invoke AppendMenuA, hMenuHelp, MF_STRING, IDM_OPTIONS_EXPLAINHC, ADDR HardString

        INVOKE SetMenu, hWin, hMenubar ; Set menu
        
    .elseif   uMsg == WM_DESTROY
        invoke    DeleteObject,vdTNRoman     ; delete the font
        invoke    PostQuitMessage,NULL
        ret 
    .endif
    invoke    DefWindowProc,hWin,uMsg,wParam,lParam
    ret
  WndProc endp

newWinningNumber PROC   ; Generates a new pseudorandom number and stores in [winningNumber]
 push 9
 call PrngGet
 mov [winningNumber], eax
 ret
newWinningNumber ENDP

resetScoreHC PROC       ; If player guesses 3 wrong, resets their score if they are on HC mode
cmp hcToggle, 1
je resetScore           ; If hcToggle==1, Reset score
jne go_back             ; Else we do nothing and return

resetScore:
 mov [playerScore], 0
 jmp go_back

go_back:
 ret
resetScoreHC ENDP

END start
