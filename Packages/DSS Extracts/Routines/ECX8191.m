ECX8191 ; COMPILED XREF FOR FILE #727.819 ; 11/26/19
 ; 
 S DIKZK=2
 S DIKZ(0)=$G(^ECX(727.819,DA,0))
 S X=$P($G(DIKZ(0)),U,3)
 I X'="" K ^ECX(727.819,"AC",$E(X,1,30),DA)
END Q
