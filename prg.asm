; =============================================================================
; Team Leave Gift gadget (wave player) with 9S08DZ60 board.
; =============================================================================

; ===================== INCLUDE FILES ==========================================
#include "dz60.inc"
#include "cop.sub"
#include "iic.sub"
#include "ssd1780.sub"          ; 0.96" 128x64 OLED display
#include "lib.sub"
#include "wave.sub"
#include "teamlogo.inc"
; ====================  EQUATES ===============================================

; ====================  VARIABLES  ============================================

#RAM
strcnt          ds      1
random          ds      1


; ====================  PROGRAM START  ========================================
#ROM

start:
        sei                     ; disable interrupts

        ldhx    #XRAM_END       ; H:X points to SP
        txs                     ; init SP

        jsr     COP_Init
        jsr     WAV_Init
        jsr     IIC_Init

        ; ADC module initialization (for random number support)
        ; ADLPC = 0 (High speed config)
        ; ADIV = 11b (input clock / 8)
        ; ADLSMP = 1 (Long sample time) maybe filter out noise pulses
        ; MODE = 00b (8 bit mode)
        ; ADICLK = 01b (Bus clock divided by 2)
        mov     #ADIV0_|ADIV1_|ADLSMP_|ADICLK0_,ADCCFG

        cli

        ; Init debug LED
        mov     #PIN6_,PTA      ; Switch LED On on PTA6
        mov     #PIN6_,DDRA     ; PTA6 output

        ; Print display
        jsr     IIC_wfe         ; Wait for end of action list
        jsr     DISP_init       ; Initialize display

        ldhx    #teamlogo
        jsr     DISP_image	; Show logo

        lda     #1
        jsr     sleep

        ; Random number generation
        mov     #26,ADCSC1      ; Read internal temperature sensor
ADC_read_loop
        jsr     KickCop
        brclr   COCO.,ADCSC1,ADC_read_loop      ; When ready, value is on ADCRL
        lda     ADCRL
randomloop                      ; loop ADCRL times
        jsr     KickCop         ; Update watchdog
        dbnza   randomloop
        lda     TPM1CNTH        ; PWM free running counter
        add     TPM1CNTL
        add     RTCCNT          ; RTC free running counter
        clrh
        ldx     #71             ; Number of messages
        div                     ; HA/X -> A, Reminder -> H
        pshh
        pula                    ; Now A = random % 71
        sta     random
        ldhx    #messages       ; Get address of string
        tsta
        beq     messprint
messloop
        aix     #64
        aix     #64             ; += 128
        dbnza   messloop
messprint
        clra                    ; Left top corner of display
        jsr     DISP_print      ; Print string

        lda     #3
        bsr     sleep

        ldhx    #members
        clra                    ; Left top corner of display 
        jsr     DISP_print      ; Print string

        lda     #1
        bsr     sleep

        lda     #128
        ldhx    #members
        jsr     addhxanda
        clra                    ; Left top corner of display 
        jsr     DISP_print      ; Print string

        lda     #1
        bsr     sleep

        ldhx    #members
        pshh
        pula
        inca
        psha
        pulh                    ; this is actually an inch, same as HX+=256
        clra                    ; Left top corner of display 
        jsr     DISP_print      ; Print string

        lda     #1
        bsr     sleep
startscr
        clra                    ; Left top corner of display 
        ldhx    #startscreen    ; Get address of string
        jsr     DISP_print      ; Print string

        clr     strcnt
main
        jsr     KickCop         ; Update watchdog

        lda     PTA             ; Toggle debug LED
        eor     #PIN6_
        sta     PTA

        clrh
        lda     chimecnt
        ldx     #8
        div
        sta     strcnt
        pshh
        pula
        tsta
        beq     savebatt	; When chimecnt%8 == 0, show (chimecnt/8)-th text instead of chimecnt 

        lda     #$60            ; Set position to top-left
        ldhx    #chimecount     ; Get address of string
        jsr     DISP_print      ; Print string

        lda     chimecnt
        clrh
        clrx                    ; No fractional part
        mov     #3,str_bufidx   ; Set length of string
        jsr     str_val         ; Convert value to string
        lda     #$6D            ; Screen position
        jsr     DISP_print      ; Print string

        bra     strend
savebatt
        lda     strcnt
        deca
        and     #7
        tax
        lda     #17
        mul
        ldhx    #savebattstr    ; Get address of string
        jsr     addhxanda
        lda     #$60            ; Set position to top-left
        jsr     DISP_print      ; Print string
strend

	bra	main            ; jump back to main loop

; ===================== ROUTINES ================================================
sleep
        add     chimecnt
        psha
sleeploop
        jsr     KickCop         ; Update watchdog
        lda     chimecnt
        cmp     1,sp
        blo     sleeploop
        ;ais     #1
        pula
        rts

; ===================== STRINGS ================================================

messages
        ;   0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF
        ;   0               0               0               0               0               0               0               0
        db "Valakinek a csu-nya lanyokat is meg kell...                                                                                     "
        db "Kabatzseb?      Hagyma csipos?                                                                                                  "
        db "Nem lehetek     kiszaradt fa!                                                                                                   "
        db "Ez az uzenet    elolvasasa utan 5 masodperccel  megsemmisul!    BUMM!                                                           "
        db "Ne olyan        gornyedten ulj!                                                                                                 "
        db "Toltsd ki a     timereportot!                                                                                                   "
        db "Meg mindig nem  toltotted ki a  timereportot?                                                                                   "
        db "Hoch die Hande, Wochenende!                                                                                                     "
        db "Hoznal nekem is banant?                                                                                                         "
        ;   0               0               0               0               0               0               0               0
        db "Borda?                                                                                                                          "
        db "En vagyok az    sci2can box                                                                                                     "
        db "Kezmosaskor     csakket         papirtorlot     hasznalj!                                                                       "
        db "Mennyit         futottalma?                                                                                                     "
        db "Major?                                                                                                                          "
        db "Chilis bab elkeszitese: A karikara vagott voroshagymat olajon megpiritjuk, majd a zuzott fokhagymat is hozzapiritjuk 10 masod..."
        db "Szasz! Osztok!                                                                                                                  "
        db "Ebed? Na? Na?   Ebed? Na?                                                                                                       "
        db "Kedvesss...     Peter                                                                                                           "
        db "Mivan kalacskepu?!                                                                                                              "
        db "KUTYAAAK!                                                                                                                       "
        db "Csoves munkas   auto                                                                                                            "
        ;   0               0               0               0               0               0               0               0
        db "Szia Lajos!                                                                                                                     "
        db "Mer', nem vagyokrendessen?                                                                                                      "
        db "Kutyadat itt    setaltatod?                                                                                                     "
        db "Ilyen           szerelesben?                                                                                                    "
        db "Hat bazmeg!                                                                                                                     "
        db "Ne legyel       gengszter!                                                                                                      "
        db "Bocsi, csak egy kerdes                                                                                                          "
        db "Eppen ezaz hogy                                                                                                                 "
        ;   0               0               0               0               0               0               0               0
        db "Gyorsan                                                                                                                         "
        db "Meg 5 perc                                                                                                                      "
        db "Csocsok es segg                                                                                                                 "
        db "BLAZS                                                                                                                           "
        db "Berti says:     MIIIIVVVAAAANNNN???                                                                                             "
        db "Ez faszsag                                                                                                                      "
        db "Kave? Kave? Kave?                                                                                                               "
        db "Onkoltseges a   buli?                                                                                                           "
        db "Spongyabob      BARBAR                                                                                                          "
        db "Ki lakik        odalentkit rejt a viz? Tunyacsaptestver!                                                                        "
        ;   0               0               0               0               0               0               0               0
        db "Kurvanagy a baj                                                                                                                 "
        db "Bezzeg a        Zsuzsikanal     milyen jo volt!                                                                                 "
        db "Kicsengettek!                                                                                                                   "
        db "De Belam!                                                                                                                       "
        db "NULLAAA                                                                                                                         "
        db "Van ra request?                                                                                                                 "
        db "Ebedre kinai?                                                                                                                   "
        ;   0               0               0               0               0               0               0               0
        db "Bikas gyros?                                                                                                                    "
        db "Ez nem barna,   ez oarany                                                                                                       "
        db "A korforgalombolhajts ki a 4.   kijaraton                                                                                       "
        db "Ez a nap mar a  kutyake                                                                                                         "
        db "Csak a sor-vodka                                                                                                                "
        db "SZIA!           PETI VAGYOK!                                                                                                    "
        db "kolbaszos bufi  intensifies                                                                                                     "
        db "Kikapcsolashoz  nyomja meg a    nyomogombot     33-szor                                                                         "
        ;   0               0               0               0               0               0               0               0
        db "A keszulek      elofizetese     lejart.                                                                                         "

members
        ;   0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF
        db "Team members:   Xxxxxx Xxxxxx   Xxx Xxxxxxxxx   Xxxx Xxxxxxxxxx Xxxxx Xxxxxxx   Xxxxxx Xxxxxx   Xxx Xxxxxxxxx   Xxxx Xxxxxxxxxx "
        db "Xxxxxx Xxxxxx   Xxx Xxxxxxxxx   Xxxxx Xxxxxxx   Xxxx Xxxxxxxxxx Xxxxx Xxxxxxx   Xxxx Xxxxxxxxxx Xxxxxx Xxxxxx   Xxx Xxxxxxxxx   "
        db "Xxxxx Xxxxxxx   Xxxxxx Xxxxxx   Xxx Xxxxxxxxx   ...                                                                             "

hexakars
        db '0123456789ABCDEF'
startscreen
        db "Remember Box for"
        db "P",30,"ter  Xxxxxxxxx"
        db "                "
        db "Enjoy FORD warn-"
        db "ing chime to re-"
        db "member Xxxx Team"
        db "Chime count:    "
        db "1v0 (c)2022 Aug."
chimecount
        db "Chime count: ",0
savebattstr
        db " Think battery! ",0
        db " Save battery ! ",0
        db "  Release me !  ",0
        db "Are you serious?",0

        db "Don't U bore me?",0
        db " Switch me OFF! ",0
        db "Play with other!",0
        db " Unbeliveable ! ",0

; ===================== IT VECTORS ==========================================
#VECTORS
        org     Vreset
        dw      start           ; Program Start




