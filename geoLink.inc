; -----------------------------------------------------------
; geoLink.inc: constants for geoLink
; -----------------------------------------------------------
DEBUG	=	1
IP65	=	$3300	;ip65 load address and vector
PKTSIZE	=	260	;token, T/S, 256 bytes,cksum
MAXINPUT	=	80	;maximum input length for IRC
NUM_PRCS	=	3	;number of processes
PRC_POLL	=	0	;network card poll process
PRC_PING	=	1	;ping send process
PRC_AUTO	=	2	;IRC auto NICK/USER
; -----------------------------------------------------------
; Constants for IRC module
; -----------------------------------------------------------
TXT_LEDG	=	3	;left edge of text input area
TXT_REDG	=	272	;right edge of text input area
NICKLEN	=	15	;max. length of nick
; -----------------------------------------------------------
; Kipper constants (made unique for geoAssembler).
; See geos_dispatcher.s in cross-assembled source for details.
; -----------------------------------------------------------
K_FINIT	=	$01	;full-blown initialization
K_GETCFG	=	$02	;get configuration pointer
K_SETDFT	=	$03	;set defaults
K_CINIT	=	$04	;initialize card
K_SINIT	=	$05	;initialize network stack variables
K_SETIRQ	=	$06	;install IRQ handler
K_KILIRQ	=	$07	;remove IRQ handler
K_DINIT	=	$08	;initialize DHCP (get address)
K_POLL	=	$09	;network card poll routine
K_START	=	$0e	;initialize card polling
K_STOP	=	$0f	;stop polling
K_UDLIST	=	$10	;add UDP listener
K_PACKET	=	$11	;get UDP/TCP packet info
K_UDSEND	=	$12	;send UDP packet
K_UDULIS	=	$13	;remove UDP listener
K_TCCONN	=	$14	;TCP connect
K_TCSEND	=	$15	;TCP send
K_TCCLS	=	$16	;TCP close
K_DNRES	=	$30	;DNS resolve
K_DLOAD	=	$31	;download resource
K_PING	=	$32	;ping remote host
K_ICLIST	=	$33	;add ICMP listener
K_ICULIS	=	$34	;remove ICMP listener
K_ICECHO	=	$35	;send ICMP echo request
K_GETERR	=	$ff	;get last error code
; -----------------------------------------------------------
; offsets in UDP structure used to call into ip65
; -----------------------------------------------------------
UD_ADDR	=	0
UD_RPORT	=	4
UD_LPORT	=	6
UD_LEN	=	8
UD_DATA	=	10

