DGPFLMT1 ;ALB/RBS - PRF TRANSMISSION ERRORS BUILD LIST AREA ; 6/10/05 11:38am
 ;;5.3;Registration;**650,960**;Aug 13, 1993;Build 22
 ;     Last Edited: SHRPE/SGM - Jun 7, 2018 13:50
 ;
 ;  DG*5.3*960 - filter for only active and locally owned assignments
 ;     GET modified for filters   BLD modified for additional columns
 ;
 ;no direct entry
 QUIT
 ;
 ;
EN(DGARY,DGSRTBY,DGCNT) ;Entry point to build list area
 ;
 ;The following input variables are 'system wide variables' in the
 ;DGPF TRANSMISSION ERRORS List Manager screen:
 ;
 ;   Input:
 ;       DGARY - subscript name for temp global
 ;     DGSRTBY - list sort by criteria
 ;               "N" = Patient Name
 ;               "D" = Date/Time Error Received
 ;  Output:
 ;       DGCNT - number of lines in the list
 ;       DGARY - ^TMP(DGARY,$J)      - display list
 ;             - ^TMP("DGPFSORT",$J) - used to create final DGARY list
 ;
 ;display wait msg
 D WAIT^DICD
 ;
 ;retrieve and sort
 D GET(DGSRTBY)
 ;
 ;build list
 D BLD(DGARY,DGSRTBY,.DGCNT)
 ;
 ;if no entries in list, display message
 I 'DGCNT D
 . D SET(DGARY,1,"",1,,,.DGCNT)
 . D SET(DGARY,2,"There are no transmission error messages on file.",3,$G(IOINHI),$G(IOINORM),.DGCNT)
 ;
 Q
 ;
 ;
GET(DGSRTBY) ;Get "RJ" status entries.
 ;
 ;  Input:
 ;      DGSRTBY - list sort by value
 ;
 ; Output:
 ; ^TMP("DGPFSORT",$J,0,<assignment ien>,<site ien>,<HL7 log ien>)=""
 ;
 ;The 0 node is created to group each patient's PRF Assignment record
 ;with each Site Transmitted To that is rejecting the update with all
 ;of the pointed to HL7 transmission log records.
 ;Only the most recent transmission log entry will be displayed.
 ;
 N DGAIEN   ;assignment ien
 N DGDAT    ;original transmission date
 N DGLIEN   ;HL7 log record ien
 N DGPFA    ;assignment array
 N DGPFAH   ;assignment history data array
 N DGPFL    ;HL7 transmission log data array
 N DGPFPAT  ;patient data array
 N DGSITE   ;site transmitted to ien
 N DGSSN    ;patient ssn
 ;
 ;loop through ASTAT index of transmission date/times
 S DGDAT=0
 F  S DGDAT=$O(^DGPF(26.17,"ASTAT",DGDAT)) Q:'DGDAT  D
 . Q:'$D(^DGPF(26.17,"ASTAT",DGDAT,"RJ"))
 . S DGLIEN=0
 . F  S DGLIEN=$O(^DGPF(26.17,"ASTAT",DGDAT,"RJ",DGLIEN)) Q:'DGLIEN  D
 . . K DGPFL,DGPFAH
 . . ;- retrieve HL7 log data
 . . Q:'$$GETLOG^DGPFHLL(DGLIEN,.DGPFL)
 . . Q:'+DGPFL("ASGNHIST")
 . . S DGSITE=$P($G(DGPFL("SITE")),U,1)
 . . Q:DGSITE']""
 . . ;- retrieve assignment history data to get PRF Assignment ien
 . . Q:'$$GETHIST^DGPFAAH(+DGPFL("ASGNHIST"),.DGPFAH)
 . . S DGAIEN=$P($G(DGPFAH("ASSIGN")),U,1)
 . . Q:'DGAIEN
 . . ;
 . . ;- create 0 node by patient assignment, site ien and log ien
 . . S ^TMP("DGPFSORT",$J,0,DGAIEN,DGSITE,DGLIEN)=""
 ;
 Q:'$O(^TMP("DGPFSORT",$J,0,""))  ;quit if nothing setup
 ;
 ;- now loop the sorted 0 node and only use the most recent HL7 error
 ;  record to create the List Manager display temp file.
 ;
 S DGAIEN=0
 F  S DGAIEN=$O(^TMP("DGPFSORT",$J,0,DGAIEN)) Q:DGAIEN=""  D
 . S DGSITE=0
 . F  S DGSITE=$O(^TMP("DGPFSORT",$J,0,DGAIEN,DGSITE)) Q:DGSITE=""  D
 . . N X,Y
 . . K DGPFL,DGPFAH,DGPFA,DGPFPAT
 . . S DGLIEN=0  ;- get most recent record ien
 . . S DGLIEN=$O(^TMP("DGPFSORT",$J,0,DGAIEN,DGSITE,""),-1)
 . . Q:DGLIEN=""
 . . ;- retrieve HL7 log data
 . . Q:'$$GETLOG^DGPFHLL(DGLIEN,.DGPFL)
 . . ;- retrieve assignment file data to get Owner Site
 . . Q:'$$GETASGN^DGPFAA(DGAIEN,.DGPFA)
 . . ;- retrieve patient data to get ssn
 . . Q:'$$GETPAT^DGPFUT2(+DGPFA("DFN"),.DGPFPAT)
 . . S DGSSN=$G(DGPFPAT("SSN")) S:'DGSSN DGSSN="UNKNOWN"
 . . ;- add ssn to existing array
 . . S DGPFA("SSN")=DGSSN
 . . ;- retrieve assignment history data
 . . Q:'$$GETHIST^DGPFAAH(+DGPFL("ASGNHIST"),.DGPFAH)
 . . ;
 . . ;- DG*5.3*960 - FILTER check
 . . ;               STAT: 1:active; 0:inactive
 . . ;                OWN: 1:Owner local facility; 0:Owner not local
 . . ;               FLAG: "A" or flag variable pointer
 . . S X=$G(DGSORT("STAT")) I X?1N,+DGPFA("STATUS")'=X Q
 . . S X=$G(DGSORT("OWN")) I X?1N D  Q:'Y
 . . . S Y=+DGPFA("OWNER"),Y=$S(Y<1:0,1:$$ISDIV^DGPFUT(Y))
 . . . I X=1,Y>0 Q
 . . . I X=0 S Y=$S(Y>0:0,1:1)
 . . . Q
 . . S X=$G(DGSORT("FLAG")) I +X,$P(X,U)'=$P(DGPFA("FLAG"),U) Q
 . . ;
 . . ;- setup output array
 . . D SORT(DGLIEN,DGSRTBY,.DGPFA,.DGPFAH,.DGPFL)
 . . Q
 . Q
 ;
 Q
 ;
 ;
SORT(DGLIEN,DGSRTBY,DGPFA,DGPFAH,DGPFL) ;Setup output global
 ;
 ;  Input:
 ;      DGLIEN - ien of HL7 log record
 ;     DGSRTBY - list sort value
 ;       DGPFA - assignment array
 ;      DGPFAH - assignment history array
 ;       DGPFL - HL7 log array
 ;
 ; Output:
 ;   ^TMP("DGPFSORT",$J,1,S4,S5,S6,S7) = data string values
 ;   Subscript's are as follows for each sort by:
 ;
 ;       List by patient name     List by HL7 received d/t
 ;       Sort="N"                 Sort="D"
 ;       --------------------     ------------------------
 ;   S4  patient_name             ack_received_d/t
 ;   S5  assignment_ien           assignment_ien
 ;   S6  site_ien                 site_transmitted_to
 ;   S7  HL7_log_ien              HL7_log_ien
 ;
 ;   The data string value consists of 5 "^"-pieces
 ;   DFN ^ Patient_name ^ SSN ^ Ack_received_dt ^ Site_transmitted_to
 ;
 N DGACKDT   ;d/t error msg received
 N DGAIEN    ;assignment ien
 N DGPNAME   ;patient name
 N DGSITE    ;site transmitted to ien
 N DGSTRING  ;detail line
 N DGSUB     ;subscript var
 ;
 ;- subscript setup
 S DGACKDT=$P($G(DGPFL("ACKDT")),U) S:DGACKDT="" DGACKDT="UNKNOWN"
 S DGAIEN=$P($G(DGPFAH("ASSIGN")),U) S:DGAIEN="" DGAIEN="UNKNOWN"
 S DGPNAME=$P($G(DGPFA("DFN")),U,2) S:DGPNAME="" DGPNAME="UNKNOWN"
 S DGSITE=$P($G(DGPFL("SITE")),U)
 ;
 ;- data string setup -
 S DGSTRING=$P($G(DGPFA("DFN")),U)
 S $P(DGSTRING,U,2)=DGPNAME
 S $P(DGSTRING,U,3)=$P($G(DGPFA("SSN")),U)
 S $P(DGSTRING,U,4)=DGACKDT
 S $P(DGSTRING,U,5)=$P($G(DGPFL("SITE")),U,2)
 ;
 ;- patient name sort
 I DGSRTBY="N" S DGSUB=DGPNAME
 ;- date/time error received type sort
 I DGSRTBY="D" S DGSUB=DGACKDT
 ;
 S ^TMP("DGPFSORT",$J,1,DGSUB,DGAIEN,DGSITE,DGLIEN)=DGSTRING
 Q
 ;
 ;
BLD(DGARY,DGSRTBY,DGCNT) ;Build list area
 ;
 ;  Input:
 ;      DGARY - subscript name for temp global
 ;    DGSRTBY - list sort by value
 ;
 ; Output:
 ;      DGCNT - number of lines in the list
 ;      DGARY - display list - ^TMP(DGARY,$J)
 ;
 N DGACKDT   ;d/t error msg received
 N DGAIEN    ;assignment ien
 N DGLAST    ;date of last activation action
 N DGLIEN    ;log record ien
 N DGLINE    ;line counter
 N DGORIG    ;original assignment date
 N DGOWNER   ;owner of assignment
 N DGPNAME   ;patient name
 N DGSIEN    ;site ien
 N DGSITE    ;site transmitted to name
 N DGSSN     ;patient ssn
 N DGSTRING  ;detail line
 N DGSUB     ;loop var
 N DGTEMP    ;sort array root
 ;
 S DGTEMP=$NA(^TMP("DGPFSORT",$J,1))
 S DGSUB="",DGLINE=0
 ;
 F  S DGSUB=$O(@DGTEMP@(DGSUB)) Q:DGSUB=""  D
 . S DGAIEN=0
 . F  S DGAIEN=$O(@DGTEMP@(DGSUB,DGAIEN)) Q:'DGAIEN  D
 . . S DGORIG=$$GETADT^DGPFAAH(DGAIEN)
 . . S DGSIEN=0
 . . F  S DGSIEN=$O(@DGTEMP@(DGSUB,DGAIEN,DGSIEN)) Q:'DGSIEN  D
 . . . S DGLIEN=0
 . . . F  S DGLIEN=$O(@DGTEMP@(DGSUB,DGAIEN,DGSIEN,DGLIEN)) Q:'DGLIEN  D
 . . . . N X
 . . . . ;- get data fields
 . . . . S DGSTRING=$G(@DGTEMP@(DGSUB,DGAIEN,DGSIEN,DGLIEN))
 . . . . S DGPNAME=$P(DGSTRING,U,2)
 . . . . S DGSSN=$E($P(DGSTRING,U,3),6,9)
 . . . . S DGACKDT=$$FMTE^XLFDT($P(DGSTRING,U,4)\1,"2Z")
 . . . . S DGSITE=$E($P(DGSTRING,U,5),1,27)
 . . . . ;- increment line counter
 . . . . S DGLINE=DGLINE+1
 . . . . ;- set line into list area
 . . . . ;- format of display line, 2 spaces between columns
 . . . . ;  1-3    6-35    38-41      44-51         54-80
 . . . . ;  line# patient   ssn    Reject_date   Transmit_to
 . . . . D SET(DGARY,DGLINE,DGLINE,1,,,.DGCNT)
 . . . . D SET(DGARY,DGLINE,DGPNAME,6,,,.DGCNT)
 . . . . D SET(DGARY,DGLINE,DGSSN,38,,,.DGCNT)
 . . . . D SET(DGARY,DGLINE,DGACKDT,44,,,.DGCNT)
 . . . . D SET(DGARY,DGLINE,DGSITE,54,,,.DGCNT)
 . . . . ;
 . . . . ;- associate "IDX" list item entry with the pointer's
 . . . . ;  back to ^TMP("DGPFSORT",$J,0,DGAIEN,DGSITE,DGLIEN) global:
 . . . . ;  <assignment ien>^<site ien>^<HL7 log ien>^<patient dfn>^pat name^site name
 . . . . S ^TMP(DGARY,$J,"IDX",DGLINE,DGLINE)=DGAIEN_U_DGSIEN_U_DGLIEN_U_$P(DGSTRING,U,1)_U_DGPNAME_U_$P(DGSTRING,U,5)
 ;
 ;cleanup temp sort global
 K @DGTEMP
 Q
 ;
 ;
SET(DGARY,DGLINE,DGTEXT,DGCOL,DGON,DGOFF,DGCNT) ;Setup display detail lines
 ;
 ;  Input:
 ;      DGARY - subscript name for temp global
 ;     DGLINE - line number
 ;     DGTEXT - text
 ;      DGCOL - starting column
 ;       DGON - highlighting on
 ;      DGOFF - highlighting off
 ;
 ; Output:
 ;      DGARY - temp global array of LM detail lines
 ;      DGCNT - number of lines in the list
 ;
 N DGX  ;string to insert new text into
 ;
 S DGX=$S($D(^TMP(DGARY,$J,DGLINE,0)):^(0),1:"")
 S DGCNT=DGLINE
 ;
 S ^TMP(DGARY,$J,DGLINE,0)=$$SETSTR^VALM1(DGTEXT,DGX,DGCOL,$L(DGTEXT))
 ;
 D:$G(DGON)]""!($G(DGOFF)]"") CNTRL^VALM10(DGLINE,DGCOL,$L(DGTEXT),$G(DGON),$G(DGOFF))
 ;
 Q
