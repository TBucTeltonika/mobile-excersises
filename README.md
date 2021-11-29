# mobile-excersises

**1. Patikrinti ar SIM kortelė užrakinta su PIN**
patikrinti ar prisijunges irenginys prie modemo - "dmesg | grep -A 1 -B 12 ttyUSB"

prisijungimas prie irenginio - "socat - /dev/ttyUSB2,crnl"

Jeigu yra atinout programa - "atinout - /dev/ttyUSB3 -

AT+CPIN?

+CPIN: READY
//     READY –  This means  SIM PIN is already unlocked or lock has been disabled

**2. Atrakinti SIM kortelę su PIN kodu**

AT+CLCK="SC",0,"1234" 

**3. Pakeisti SIM PIN kodą**

AT+CPIN="94235816","1234"

**4. Patikrinti kokiam operatoriui priklauso SIM kortelė**

AT+COPS=3,0

AT+COPS?


**5. Patikrinti prie kokio opeartoriaus prisijungęs**

AT+QSPN

**6. Nustatyti rankiniu būdu prie kokio operatoriaus jungtis**

Tik prie savo leidzia panasu kad.

AT+COPS=1,1,"BITE",2

**7. Patikrinti prie kokio tinklo prisiregistravęs (namų ar roaming).**

AT+CREG?
+CREG: 2,1,	"2905","068304B",2
       n,act,	LAC,    CI,      ACT

act:
1 - home.
5 - roaming.

**8. Patikrinti prie kokio band prisijungęs, nustatyti band prioritetą**

AT+QCFG="band" parodo dabartini

AT+QCFG="band"    Band Configuration

AT+QCFG="band",0,800134,0,1 visi bandai pvz. Reikia sudet values.

pvz: 0x4 + 0x10 + 0x40 + 0x80 + 0x800000 = 0x800134



**9. Atlikti skambutį iš modemo į telefoną (be garso žinoma :D)**

ATD#;
; - reikalingas.

ATH atmesti.

**10. Atsiliepti į skambutį/padėti ragelį modeme.**

ATA

**11. SMS žinučių gavimas(indikacija)/skaitymas/siuntimas.**

AT+CMGL isvardinti visas "UNREAD MESSAGES"

Sending:

AT+CMGF=1 -text mode.

AT+CSCS="GSM" - GSM Char formatas

AT+CMGS="869213067"

Ateiti turi > simbolis ir "CTRL+V CTRL+Z" indikuoti pabaiga. Normaliai ctrl+Z jeigu klientas neperima C+Z.




**12. Patikrinti PDP context'ą**

AT+CGDCONT=?

AT+CGDCONT?

**13. Nustatyti APN'ą**

Write Command 

AT+CGDCONT=<cid>[,<PDP_type>[,<APN>[,<PDP_addr>[,<data_comp>[,<head_comp>]]]]] 

**14. Pakeisti IP adresą**

AT+CGDCONT=<cid>[,<PDP_type>[,<APN>[,<PDP_addr>[,<data_comp>[,<head_comp>]]]]]

PDP adresas. tai yra atliekama pakeiciant PDP contexta. su AT+CGACT=<state>,<cid>.
