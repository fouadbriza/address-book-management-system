
; multi-segment executable file template.

data segment
    ; add your data here!  
   
   contact db 352 dup('$') ;allocating space for the full 16 contacts as the form of an array
   
                          ;REMARQUE: the original number was 20*16=320 but i will dlemit each
                          ; name and phone number by $ also a $ for next name and so on
                          ;for an easy interpreatation of the strings later hence its became 22*16=352
   
   
   buffer db 11,?,11 dup('$') ; buffer to store the name input
 
 
   msg_nom db "Entrer le nom du contact: $"
   msg_phone db "Entrer le numero telephone: $"
   new_line db ,13,10,'$'
   cpt dw 0  ;counter to keep track of the number of the contacts
   
   msg_view db "-----------------------contacts------------------------------$"
   msg_contact db "contact $",0,"$"
   msg_delimitor db "*$" 
   nom db "-Nom: $"
   phone db "-Numero Telephone: $"
   cpt2 dw 0
   cpt3 dw 1  
cpt4 dw -1 ; for the sort process using it to track which contact we are comparing to exmp (first contact>>cpt4=0)  
   msg_notfound db 13,10,13,10,"  NO CORESPONDING NAME IN THE LISTE $",13,10
   msg_found db 13,10,"-Le numero est :$"
   bx_save dw 0   ; to avoid using the stack especially when theris int 21h calls that affects the stack
   cx_save dw 0   ; to avoid using the stack especially when theris int 21h calls that affects the stack
   message_full db "YOU CANT ADD MORE CONTACTS THE LIMIT IS 16 CONTACT",13,10,"$"

   zero_contact db 13,10,"Pas de contact a afficher (^-^)",13,10,"$"
   ;zero_contact_aff 13,10,"Pas de contact a rechercher (^-^)",13,10,"$"

menu    db 13,10,'=========== MENU ===========',13,10
               db "1. Ajouter un contact",13,10
               db "2. Afficher tous les contacts",13,10
               db "3. Rechercher un contact",13,10
               db "4. Modifier un contact",13,10
               db "5. Supprimer un contact",13,10
               db "6. display prefix name",13,10
               db "7. display prefix phone number",13,10 
               db "8. Quitter",13,10
               
               db "============================",13,10,13,10
               db "Choisissez une option (1-6): $"
   
   choix DB ? 
   entermsg db 13,10,"Appuyez sur une touche pour continuer...$"
ends
      
     entre_nom db 13,10,"Entrer le nom que vous voullez voir son numero : $" 
     entre_suprimer db 13,10,"Entrer le nom que vous voullez suprimer son contact : $" 
     entre_modif db 13,10,"Entrer le nom que vous voullez modifier son numero : $" 
     
     modif_termine db 13,10,13,10,"* Modification termine avec succes $",13,10,"$" 
     supp_termine db 13,10,13,10,"* Suppression termine avec succes $",13,10,"$"  
     
     ligne db "-----------------------------------------------------------------------------$"  
     
     cpt_prefix dw 0 ; for number sequence search in phones
     bx_save2 dw 0
     
     
     msg_pref_name db "ecrie le prefix que vous voulez chercher les noms qui commencent avec :$"
      msg_pref_phone db "ecrie le prefix de numero telephones :$"
      
      save_bx3 dw 0 
      cpt_phone_pref dw 0
      
      flag dw 0
            
stack segment
    dw   128  dup(0)
ends



 
 
 
 
 
 
 
 
 
 
; the start of the code segment;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
code segment


    
start:
    mov ax, data
    mov ds, ax
    mov es, ax
    

        
    
main_loop: 
    call clear_screen
    call new_line1
    
    mov cx,0  
    mov ah, 9
    lea dx, menu
    int 21h

    mov ah, 1
    int 21h
    mov choix, al

    call new_line1
    call new_line1

    cmp choix, '1'
    jne check2
    
    cmp cpt,16            ; cheking if we reched the limite of contacts 
    jl continuee
    
    full:
     mov ah,9
     lea dx,message_full
    
     int 21h
     jmp pause
    
     
    continuee:
     call clear_screen 
     call ADD_CONTACT          ; adding a contact
     jmp pause

check2:
    cmp choix, '2'
    jne check3
    call clear_screen
    call VIEW_ALL_CONTACTS     ; view all contacts
    jmp pause

check3:
    cmp choix, '3'
    jne check4 
    call clear_screen
    call search                ; searching for an account
    jmp pause

check4:
    cmp choix, '4'
    jne check5 
    call clear_screen
    call modify_contact        ; modify a contact
    jmp pause

check5:
    cmp choix, '5'
    jne check6  
    call clear_screen          
    call delete                ; deleting a contact
    jmp pause

check6:
    cmp choix, '6'
    jne check7
    call clear_screen
    call display_prefix_name
    
    jmp pause

check7:
    cmp choix, '7'
    jne check8
    call clear_screen
    call display_prefix_phone
    
    jmp pause


check8:
    cmp choix, '8'
    je exit_program
    jmp main_loop

pause:
    mov ah, 9
    lea dx, entermsg
    int 21h
    mov ah, 1
    int 21h
    jmp main_loop

exit_program:
    mov ax, 4c00h
    int 21h

ends


 
 
proc ADD_CONTACT near ;=======================================================================================
   
   
  ;--------------------------------------READING THE NAME FROM THE USER TO THE BUFFER------------------------------------

    call display_msg_name
   
    mov ah, 0Ah ; Code to read string
    lea dx, buffer
    int 21h    
   
    call new_line1
   
    mov si, 2  ; setting si for the next process  

     ;we are going to search for the coresponding ascii code of enter and replacing that byte with $
    fix1:
        cmp buffer[si], 0Dh ; 0Dh is the ASCII code of ENTER
        je replace1         ; found
        inc si
        jmp fix1

    replace1:
        mov buffer[si], '$'
        
    call upper_case
  ;--------------------------------------------------------------------------------------------------------

  ;---------------------------------COPYING NAME TO THE ARRAY----------------------------------------------
    
    
    
    call sort_insert
    
    
    
    

  ;-----------------------------------READING THE PHONE NUMBER FROM THE USER--------------------------------

    call display_msg_phone
    
    
   ;hna nebda ncopii 3la hsab l bx t3 sort
    mov ah, 0Ah
    lea dx, buffer
    int 21h

    call new_line1

    mov si, 2

    fix2:
        cmp buffer[si], 0Dh
        je replace2
        inc si
        jmp fix2

    replace2:
        mov buffer[si], '$'

  ;---------------------------------COPYING PHONE TO THE ARRAY----------------------------------------------
    
                   
    add bx, 11  ; phone number starts 11 bytes after name and bx is already set from the sort_insert proc
   

    lea di, contact[bx]   ; destination for phone number
    lea si, buffer[2]     ; source of phone number
    mov cx, 11

    cld
    repe movsb

    call reset_buffer

    inc cpt ; incrementing the counter which indicates the number of contacts

    ret
endp
;=============================================================================================================






proc VIEW_ALL_CONTACTS near 
;==============================================================================

    mov cx,cpt              ;loop counter
    xor bx,bx              
    mov si,1                ; contact number to display
    cmp cpt,0
    jne display 
    
    mov ah,09
    lea dx,zero_contact
    int 21h
    jmp no_contacts 
    
     mov ah,9
    lea dx,msg_view         ; display header
    int 21h
    
display:
    call new_line1          ; new line before each contact

    ;------------------------------------ displaying contact header -------------------------------------
    mov ah,9
    lea dx,msg_delimitor
    int 21h

    mov ah,9
    lea dx,msg_contact      ; printing "contact"
    int 21h
    
   
    ; display contact number
     mov dx,  si     
     cmp dx,10 ; if we reached 10 we display dh then dl
     mov ah, 2
     jge greater_10
   
    add dx, 30h             ; convert to ASCII 
    
    
    
    int 21h
    jmp end_greater
                  
    
    
 greater_10:
    
    mov dx,1
    add dx,30h    ; convert to ASCII
    int 21h ;displaying the msb 
    
     mov dx,  si ; reseting back the value of bx from si
     sub dx,10
    
    add dx,30h    ; convert to ASCII
    int 21h ;displaying the lower byte
    
    
 end_greater:   
    mov dl,':'              
    mov ah, 2
    int 21h

    call new_line1   
    call new_line1
    ;------------------------------------ displaying name -------------------------------------
    mov ah,9
    lea dx,nom
    int 21h

    lea dx,contact[bx]      ; name starts each 22 bytes
    mov ah,9
    int 21h

    call new_line1          ; line break after name

    ;------------------------------------ displaying phone number -----------------------------
    mov ah,9
    lea dx,phone
    int 21h

    lea dx,contact[bx+11]   ; phone starts each 22 bytes + 11 offset
    mov ah,9
    int 21h

    call new_line1          ; line break after phone number
    call new_line1          ; additional line break for spacing
    
    mov ah,09
    lea dx,ligne;
    int 21h
    ;------------------------------------ increments and loop ------------------------------
    add bx,22               ; next contact
    inc si                  ; increment contact number
    loop display
  no_contacts:
    ret
endp

;============================================================================================================




proc display_msg_name ;=======================================================================================
    mov ah,9
    lea dx,msg_nom
    int 21h
ret  

endp
;=============================================================================================================



proc display_msg_phone ;=======================================================================================
    mov ah,9
    lea dx,msg_phone
    int 21h
ret

endp
;=============================================================================================================



proc new_line1 ;===============================================================================================
    mov ah,9
    lea dx,new_line
    int 21h
ret

endp
;=============================================================================================================                        
                           
proc reset_buffer ;===========================================================================================

mov cx,11 ; 11 is the number of elements of the buffer
mov si,2
bcl2:
mov buffer[si],'$'
inc si
loop bcl2


ret
endp
;=============================================================================================================
                           


proc sort_insert near ;===========================================================================================

; case of the first contact to insert
cmp cpt,0
jne preloop


mov ax, cpt           ; current contact number
    mov bx, 22            ; each contact occupies 22 bytes
    mul bx                ; ax = cpt * 22
    mov bx, ax            ; store offset in BX

    lea di, contact[bx]   ; destination for name
    lea si, buffer[2]     ; source of name (skip count/length byte)
    mov cx, 11            ; number of characters to copy

    cld
    repe movsb

    call reset_buffer     ; reset shared buffer

jmp exitfinally


    
preloop:
inc cpt4  ;using it to track which contact we are comparing to exmp (first contact>>cpt4=0)
mov ax,cpt4
mov bx,22
mul bx
mov bx,ax     ; knowing from where to start the comparison the next time also saving where starting inserting 

lea si,buffer[2]    
lea di,contact[bx]

mov ax, cpt4 
cmp ax,cpt ; if we reached the end of the contacts or not  
    
je replacing
jg exitfinally   
    
mov cx,10 ; to compare 10 chars and stop

  mov cx, 10    ; limit comparison to first 10 chars
repe cmpsb    ; compare bytes
jne process   ; stop if different

  
  
   process: 
    jg preloop     ; its not were should be inserted
    jle replacing   ; found were should be inserted
    
    replacing:
      
     push bx ; saving the preivious bx because it contains from were to start inserting
     mov ax,cpt ; number of contacts
     mov bx,22
     mul bx
     mov bx,ax
     dec bx
     
     lea si, contact[bx] 
     add bx,22
     lea di,contact[bx]  ;start after si with 22 bytes (one contact)
     
     std ; copying in the opposite direction
     
     mov ax,cpt
     sub ax,cpt4 ;finding how much byte to shift
     mov bx,22
     mul bx
     
     
     mov cx,ax ; shifting 22 chars (counter for the movsb)
     rep movsb
     cld 
     

     
      
      ;inserting the ame to its proper place after i did the sort
    pop bx
    lea di, contact[bx]   ; destination for name
    lea si, buffer[2]     ; source of name (skip count/length byte)
    mov cx, 11            ; number of characters to copy

    cld
    repe movsb

    call reset_buffer     ; reset buffer
     
    mov cpt4,-1 ; resetting cpt4 
     

exitfinally:



ret
endp    

    
proc search near ;============================================================================================    


mov ah,09
lea dx,entre_nom;
int 21h



mov ah,0Ah
lea dx,buffer       ; read the string
int 21h

CALL upper_case       ; upper casing the name

mov bl,buffer[1]; 
mov bh,0
mov buffer[bx+2],'$'    ; replacing the enter ascii code stored in the buffer by $

mov bx,0

 
 bcll:
  
 
 mov cx,11
 lea si,buffer[2] ;traversing buffer with si
 lea di,contact[bx]  ;travversing the contact array with di ; bx is the current name we compare 
  
 mov bx_save,bx ;saving the value of bx
 
 add bx,22        ; moving to the next contact
 repe cmpsb           
 jl notfound 
 
 
 
 cmp cx,0
 je foundit
 
 cmp contact[di-1],'$' ; because the list is ordered so first time u find a letter less means no need to search the rest of the array
                    ; case of finding mismatch but its '$' means also not found but cant be included with the
                                ;previous condition because all the letters are greater then dollar
 je notfound
 
 jmp bcll 
 
 notfound:
 mov ah,09
 lea dx,msg_notfound        ; dispaly message not found
 int 21h
 jmp endsrch

 foundit:
 mov ah,09
 lea dx,msg_found              ; dispaly message found
 int 21h
 
 
 
 mov ah,09
 mov bx,bx_save ; returning previously saved value of bx
 add bX,11    ; to go to the phone number field
 lea dx,contact[BX]            ; dispaly the contact number
 int 21h
 
 call new_line1
endsrch:
  
ret
endp
;============================================================================================================


proc modify_contact near ;===================================================================================
    
mov ah,09
lea dx,entre_modif;
int 21h    


mov ah,0Ah
lea dx,buffer       ; read the string
int 21h

CALL upper_case       ; upper casing the name

mov bl,buffer[1]; 
mov bh,0
mov buffer[bx+2],'$'    ; replacing the enter ascii code stored in the buffer by $

mov bx,0

 
 bcllmod:
  
 
 mov cx,11
 lea si,buffer[2] ;traversing buffer with si
 lea di,contact[bx]  ;travversing the contact array with di ; bx is the current name we compare 
  
 mov bx_save,bx ;saving the value of bx
 
 add bx,22        ; moving to the next contact
 repe cmpsb           
 jl notfoundmod 
 
 
 
 cmp cx,0
 je founditmod
 
 cmp contact[di-1],'$' ; because the list is ordered so first time u find a letter less means no need to search the rest of the array
                    ; case of finding mismatch but its '$' means also not found but cant be included with the
                                ;previous condition because all the letters are greater then dollar
 je notfoundmod
 
 jmp bcllmod 
 
 notfoundmod:
 mov ah,09
 lea dx,msg_notfound        ; dispaly message not found
 int 21h
 jmp endsrchmod

 founditmod:
 mov ah,09
 lea dx,msg_found              ; dispaly message found
 int 21h
 
 ;dispaly whats the phone number u wanan inter
 
 mov ah,0Ah    ; reading the phone number
 lea dx,buffer
 int 21h
 
 cld
 mov cx_save,cx  ; saving cx 
 
 mov cx,10 ;movsb 10 times
 
 mov bx,bx_save ; returning previously saved value of bx
 add bx,11      ; to go to the phone number field
 lea di,contact[bx] 
 lea si,buffer[2]           
 rep movsb
 
 mov cx,cx_save ; reseting cx to the saved value
 
call reset_buffer
 
 mov ah,09
lea dx,modif_termine;
int 21h 
  
endsrchmod:
  
ret
endp
;=============================================================================================================


proc delete  ;================================================================================================
    
mov ah,09
lea dx,entre_suprimer;
int 21h

   
 mov ah,0Ah
lea dx,buffer       ; read the string
int 21h

CALL upper_case       ; upper casing the name

mov bl,buffer[1]; 
mov bh,0
mov buffer[bx+2],'$'    ; replacing the enter ascii code stored in the buffer by $

mov bx,0

 
 bcll_delete:
  
 
 mov cx,11
 lea si,buffer[2] ;traversing buffer with si
 lea di,contact[bx]  ;travversing the contact array with di ; bx is the current name we compare 
  
 mov bx_save,bx ;saving the value of bx
 
 add bx,22        ; moving to the next contact for next iteration
 repe cmpsb           
 jl notfound_delete 
 
 
       
 cmp cx,0
 je foundit_delete
 
 cmp contact[di-1],'$' ; because the list is ordered so first time u find a letter less means no need to search the rest of the array
                    ; case of finding mismatch but its '$' means also not found but cant be included with the
                                ;previous condition because all the letters are greater then dollar
 je notfound_delete
 
 jmp bcll_delete 
 
 notfound_delete:
 mov ah,09
 lea dx,msg_notfound        ; dispaly message not found
 int 21h
 jmp endsrch_delete

 foundit_delete:
 
 mov dx,cpt
 mov ax,22
 mul dx
 mov dx,ax ; last byte number in the array is in dx
 
 mov bx, bx_save ; first byte from were starting deleting 
 
 
   ;case of last contact
 mov cx,22
 add cx,bx
 cmp cx,dx 
 
 je directly_delete
 
 sub dx,bx
 sub dx,22  ; we got the exact number of bytes o shift
 
 
 mov cx,dx
 
 lea di,contact[bx]
 lea si,contact[bx+22]; starts 22 bytes after
 
 repe movsb
 cld
 

 directly_delete: ; we decrement cpt hence we dont need to really delete the contact cause later it willbe overwritten
 
 dec cpt ; number of contacts
 
  mov ah,09
  lea dx,supp_termine;
  int 21h

endsrch_delete:
     
    
call reset_buffer    


       
ret
endp    
;=============================================================================================================



proc upper_case near ;============================================================================================                           


mov si,1

upp_casing: 
inc si
cmp buffer[si],'$' 
je end    ;end of the string

cmp buffer[si],'a'  ; ascii code of 'a'
jl upp_casing   ; its alredy in upper case

sub buffer[si],32   ; trensforming the letter to upper case
jmp upp_casing

end:

ret
endp
;============================================================================================================



clear_screen proc ;==========================================================================================
  ; clearing the screen
    mov ah, 06h        ; Scroll up function
    mov al, 00h        ; Scroll 0 lines (clear)
    mov bh, 07h        ; Attribute (light gray on black)
    mov cx, 0000h      ; Upper-left corner (row 0, col 0)
    mov dx, 184Fh      ; Lower-right corner (row 24, col 79)
    int 10h            ; Call BIOS video service

    ; Moving cursor to the start of the page 
    mov ah, 02h        ; Set cursor position function
    mov bh, 00h        ; Page number
    mov dh, 00h        ; Row (0)
    mov dl, 00h        ; Column (0)
    int 10h            ; Call BIOS video service

    ret
endp

;===========================================================================================================







;==========================================================================================================
;==========================================================================================================
;============================================================================================================
;============================================================================================================
;==========================================================================================================
;==========================================================================================================
;============================================================================================================
;============================================================================================================
;==========================================================================================================
;==========================================================================================================
;============================================================================================================
;============================================================================================================


proc display_prefix_name near ;============================================================================================    


mov ah,09
lea dx,msg_pref_name 
int 21h



mov ah,0Ah
lea dx,buffer       ; read the string
int 21h

CALL upper_case       ; upper casing the name

mov bl,buffer[1]; 
mov bh,0
mov buffer[bx+2],'$'    ; replacing the enter ascii code stored in the buffer by $

mov bx,0

 
 bcll_prefix:
  
 
 mov cl,buffer[1]
 mov ch,0
 lea si,buffer[2] ;traversing buffer with si
 lea di,contact[bx]  ;travversing the contact array with di ; bx is the current name we compare 
  
 mov bx_save,bx ;saving the value of bx
 
 add bx,22        ; moving to the next contact
 repe cmpsb           
 jl notfound_prefix 
 
 
 
 cmp cx,0
 je foundit_prefix
 
 cmp contact[di-1],'$' ; because the list is ordered so first time u find a letter less means no need to search the rest of the array
                    ; case of finding mismatch but its '$' means also not found but cant be included with the
                                ;previous condition because all the letters are greater then dollar
 je notfound_prefix
 
 jmp bcll_prefix 
 
 notfound_prefix:
 mov ah,09
 lea dx,msg_notfound        ; dispaly message not found
 int 21h
 jmp endsrch_prefix

 foundit_prefix:
 mov ah,09
 lea dx,msg_found              ; dispaly message found
 int 21h
 
 
 
 mov ah,09
 mov bx,bx_save ; returning previously saved value of bx
 add bX,11    ; to go to the phone number field
 lea dx,contact[BX]            ; dispaly the contact number
 int 21h
 
 call new_line1
endsrch_prefix:
  
ret
endp
;============================================================================================================
















 ; khsara f tp 3reft ndir diplay prefix name besah hadi hselt whya ga3 khaterch kiderthoum derthoum binzoudj 
 ; a partir mn delete ikhdemtha mn 9bel fla partie home work tsema hselt , m3a lfenction lewla sed9etli w
 ; m3a tanya lala w kan il falais nekhdemha mlewel djdida lmouhim rani dertha dok wahdi bl chrono khaterch 
 ; rak ta3ref leklab kifach yedjriw tsema habit nchouf rouhi lmouhim dertha fi 55min-1h wzedt 10 d9aye9 berk
 ; l ta3dilat akhira w hadi hya , ya rabi tweli 3ndi sour3a

 proc display_prefix_phone near ;============================================================================================    



mov ah,0ah
lea dx,buffer
int 21h

call new_line1

mov bl,[1]; 
mov bh,0
mov buffer[bx+2],'$'    ; replacing the enter ascii code stored in the buffer by $

mov bx,0
mov bx,-11
push bx

starting:

pop bx

add bx,22
push bx   ; saving bx for next
mov save_bx3,bx

inc cpt_phone_pref



bcl_main:
mov cx,cpt

cmp cpt_phone_pref,cx ; if we saerched all the array
jg ended

cmp contact[bx],'$'
je starting



lea si,contact[bx]
lea di,buffer[2]


mov cl, buffer[1]
mov ch,0
add bx,1

repe cmpsb

jne bcl_main
cmp cx,0
 

jne bcl_main




foundIphone:

mov ah,09 
mov si,save_bx3
lea dx,contact[si]
int 21h
call new_line1
mov flag,1    ; if we displayed at least one number 
jmp starting









ended:
pop bx ; just poping it to not corrupt the stack
mov cpt_phone_pref,0
cmp flag,0 
 mov flag,0 ; for next time
jne houhou
lea dx,msg_notfound
int 21h

houhou:
ret
endp
;============================================================================================================











































;==========================================================================================================
;==========================================================================================================
;============================================================================================================
;============================================================================================================
;==========================================================================================================
;==========================================================================================================
;============================================================================================================
;============================================================================================================
;==========================================================================================================
;==========================================================================================================
;============================================================================================================
;===========================================================================================================
  


end start ; set entry point and stop the assembler