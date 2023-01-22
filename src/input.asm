; OUT -  B - pressed key
; OUT - AF - garbage
; OUT -  C - garbage
input_read:
.kempston:
    ld a, #ff                ; read kempston
    in a, (#1f)              ; ...
    and #3f                  ; mask useless bits
    jp z, .keyboard          ; ret if key pressed
    ld b, a                  ; ...
    ret                      ; ...
.keyboard:
    xor a                    ; return if no keys pressed
    in a, (#fe)              ; ...
    or #e0                   ; ...
    xor #ff                  ; ...
    ld b, INPUT_KEY_NONE     ; ...
    ret z                    ; ...
.enter_lkjh:
    ld a, #bf                ; read keys
    in a, (#fe)              ; ...
    bit 0, a                 ; handle Enter (ACTION) key
    jp nz, .qwert            ; ...
    ld b, INPUT_KEY_ACT      ; ...
    ret                      ;
.qwert:
    ld a, #fb                ; read keys
    in a, (#fe)              ; ...
    bit 0, a                 ; handle Q (UP) key
    jp nz, .asdfg            ; ...
    ld b, INPUT_KEY_UP       ; ...
    ret                      ;
.asdfg:
    ld a, #fd                ; read keys
    in a, (#fe)              ; ...
    bit 0, a                 ; handle A (DOWN) key
    jp nz, .poiuy            ; ...
    ld b, INPUT_KEY_DOWN     ; ...
    ret                      ;
.poiuy:
    ld a, #df                ; read keys
    in a, (#fe)              ; ...
    bit 0, a                 ; handle P (RIGHT) key
    jp nz, .poiuy1           ; ...
    ld b, INPUT_KEY_RIGHT    ; ...
    ret                      ;
.poiuy1:
    bit 1, a                 ; handle O (LEFT) key
    jp nz, .cs_zxcv          ; ...
    ld b, INPUT_KEY_LEFT     ; ...
    ret                      ;
.cs_zxcv:
    ld a, #fe                ; read keys
    in a, (#fe)              ; ...
    bit 0, a                 ; handle CS key. if pressed - assume cursor key. else - assume sinclair joystick
    jp z, .space_break       ; ...
.space_ss_mnb:
    ld a, #7f                ; read keys
    in a, (#fe)              ; ...
    bit 0, a                 ; handle Space (ACTION) key
    jp nz, .sinclair_09876   ; ...
    ld b, INPUT_KEY_ACT      ; ...
    ret                      ;
.sinclair_09876:
    ld a, #ef                ; read keys
    in a, (#fe)              ; ...
    bit 0, a                 ; handle 0 (ACTION) key
    jp nz, .sinclair_09876_9 ; ...
    ld b, INPUT_KEY_ACT      ; ...
    ret                      ;
.sinclair_09876_9:
    bit 1, a                 ; handle 9 (UP) key
    jp nz, .sinclair_09876_8 ; ...
    ld b, INPUT_KEY_UP       ; ...
    ret                      ;
.sinclair_09876_8:
    bit 2, a                 ; handle 8 (DOWN) key
    jp nz, .sinclair_09876_7 ; ...
    ld b, INPUT_KEY_DOWN     ; ...
    ret                      ;
.sinclair_09876_7:
    bit 3, a                 ; handle 7 (RIGHT) key
    jp nz, .sinclair_09876_6 ; ...
    ld b, INPUT_KEY_RIGHT    ; ...
    ret                      ;
.sinclair_09876_6:
    bit 4, a                 ; handle 6 (LEFT) key
    jp nz, .sinclair_ssmnb   ; ...
    ld b, INPUT_KEY_LEFT     ; ...
    ret                      ;
.sinclair_ssmnb:
    ld a, #7f                ; read keys
    in a, (#fe)              ; ...
    bit 2, a                 ; handle M (BACK) key
    jp nz, .return           ; ...
    ld b, INPUT_KEY_BACK     ; ...
    ret                      ;
.space_break:
    ld a, #7f                ; read keys
    in a, (#fe)              ; ...
    bit 0, a                 ; handle CS+Space (BACK) key
    jp nz, .cursor_09876_7   ; ...
    ld b, INPUT_KEY_BACK     ; ...
    ret                      ;
.cursor_09876_7:
    ld a, #ef                ; read keys
    in a, (#fe)              ; ...
    bit 3, a                 ; handle 7 (UP) key
    jp nz, .cursor_09876_6   ; ...
    ld b, INPUT_KEY_UP       ; ...
    ret                      ;
.cursor_09876_6:
    bit 4, a                 ; handle 6 (DOWN) key
    jp nz, .cursor_09876_8   ; ...
    ld b, INPUT_KEY_DOWN     ; ...
    ret                      ;
.cursor_09876_8:
    bit 2, a                 ; handle 8 (RIGHT) key
    jp nz, .cursor_12345_5   ; ...
    ld b, INPUT_KEY_RIGHT    ; ...
    ret                      ;
.cursor_12345_5:
    ld a, #f7                ; read keys
    in a, (#fe)              ; ...
    bit 4, a                 ; handle 5 (LEFT) key
    jp nz, .return           ; ...
    ld b, INPUT_KEY_LEFT     ; ...
    ret                      ;
.return:
    ret                      ;


; OUT - AF - garbage
input_beep:
    ld a, #10              ;
    out (#fe), a           ;
    ld a, INPUT_BEEP_DELAY ;
.loop:
    dec a                  ;
    jr nz, .loop           ;
    out (#fe), a           ;
    ret                    ;


; OUT -  B - current pressed key mask
; OUT - AF - garbage
; OUT -  C - garbage
input_process:
.A: call input_read                   ; read keys. Self modifying code! see input_detect_kempston
    ld a, (var_input_key_last)        ;
    cp b                              ; if (current_pressed_key == last_pressed_key) {input_key = current_pressed_key; timer = X}
    jr nz, .new_key_event             ; ...
    or a                              ; exit if no key pressed
    ret z                             ; ...
.repeat:
    ld a, (var_input_key_hold_timer)  ; ...
    dec a                             ; timer--
    jp nz, .repeat_wait               ; if (timer == 0) input_key = current_pressed_key
    ld a, (var_input_key_last)        ; ...
    ld (var_input_key), a             ; ...
    call input_beep                   ;
    ld a, INPUT_REPEAT                ; timer = INPUT_REPEAT
    ld (var_input_key_hold_timer), a  ; ...
    ret                               ;
.repeat_wait:
    ld (var_input_key_hold_timer), a  ; timer--
    xor a                             ; input_key = none
    ld (var_input_key), a             ; ...
    ret                               ;
.new_key_event:
    ld a, b                           ;
    ld (var_input_key), a             ; input_key = current_pressed_key
    ld (var_input_key_last), a        ; last_pressed_ley = current_pressed_key
    or a                              ;
    ret z                             ;
    call input_beep                   ;
    ld a, INPUT_REPEAT_FIRST          ; timer = INPUT_REPEAT_FIRST
    ld (var_input_key_hold_timer), a  ; ...
    ret                               ;


; OUT - AF - garbage
input_detect_kempston:
    ei : halt                       ; avoid collision with attribute port
    ld a, #ff                       ; read kempston
    in a, (#1f)                     ; ...
    bit 7, a                        ; detect presence by 7th bit
    jp nz, .no                      ;
.yes:
    ld a, low  input_read           ; call input_read
    ld (input_process.A+1), a       ; ...
    ld a, high input_read           ; ...
    ld (input_process.A+2), a       ; ...
    ret                             ;
.no:
    ld a, low  input_read.keyboard  ; call input_read.keyboard
    ld (input_process.A+1), a       ; ...
    ld a, high input_read.keyboard  ; ...
    ld (input_process.A+2), a       ; ...
    ret                             ;


; input_debug:
;     ld hl, LAYOUT_DEBUG
;     call get_char_address
;     ld a, (var_input_key)
;     call print_hex
;     ld a, (var_input_key_last)
;     call print_hex
;     ld a, (var_input_key_hold_timer)
;     call print_hex
;     ret
