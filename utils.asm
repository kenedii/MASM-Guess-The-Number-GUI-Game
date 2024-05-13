; THIS FILE CONTAINS CERTAIN PROCEDURES NEEDED FOR GUESSTHENUMBER
; TO FUNCTION PROPERLY.

.data
prng_x  DD 0 ; calculation state
prng_a  DD 1099433 ; current seed

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

to_string PROC                     ; Convert a decimal to ascii
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