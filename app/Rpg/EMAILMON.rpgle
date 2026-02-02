H*****************************************************************
H* Program : EMAILMON
H* Purpose : Monitor Email Queue and Trigger Quote Extraction
H* Source  : Mainframe COBOL Migration
H*****************************************************************

I*****************************************************************
I* COPYBOOKS
I*****************************************************************
I/COPY EMAILQUOTE

I*****************************************************************
I* WORKING STORAGE
I*****************************************************************
I             WSRESPONSE     S 9 0
I             WSEXTCNT       S 2 0 INZ(0)

I*****************************************************************
I* EMAIL STATUS TABLE (OCCURS 3)
I*****************************************************************
I             WSEMAILTAB     DS
I                                      1 120
I             WSEMAILFROM                1  15 OCCURS 3
I             WSRFQID                   16  25 OCCURS 3
I             WSCARRIER                 26  40 OCCURS 3
I             WSSTATUS                  41  55 OCCURS 3

I*****************************************************************
I* DFHCOMMAREA
I*****************************************************************
I             DFHCOMMAREA    DS
I                                      1 100

C*****************************************************************
C* MAIN LOGIC
C*****************************************************************
C                   EXSR      LOADEMAIL
C                   EXSR      SENDMAP
C                   RETRN

C*****************************************************************
C* LOAD EMAIL STATUS
C*****************************************************************
C     LOADEMAIL     BEGSR
C                   MOVEL     'uwb@axa.com'        WSEMAILFROM(1)
C                   MOVEL     'RFQ001'             WSRFQID(1)
C                   MOVEL     'LLOYDS'             WSCARRIER(1)
C                   MOVEL     'PENDING'            WSSTATUS(1)
C
C                   MOVEL     'quotes@zurich'      WSEMAILFROM(2)
C                   MOVEL     'RFQ002'             WSRFQID(2)
C                   MOVEL     'ZURICH'             WSCARRIER(2)
C                   MOVEL     'PENDING'            WSSTATUS(2)
C
C                   MOVEL     'uw@allianz'         WSEMAILFROM(3)
C                   MOVEL     'RFQ003'             WSRFQID(3)
C                   MOVEL     'ALLIANZ'            WSCARRIER(3)
C                   MOVEL     'PENDING'            WSSTATUS(3)
C                   ENDSR

C*****************************************************************
C* EXTRACT EMAILS (PF2)
C*****************************************************************
C     EXTRACT       BEGSR
C                   CALL      'EMAILEXT'
C                   PARM                    DFHCOMMAREA
C
C                   MOVEL     'EXTRACTED'          WSSTATUS(1)
C                   MOVEL     'EXTRACTED'          WSSTATUS(2)
C                   MOVEL     'EXTRACTED'          WSSTATUS(3)
C                   ADD       3                   WSEXTCNT
C
C                   EXSR      SENDMAP
C                   ENDSR

C*****************************************************************
C* SEND MAP
C*****************************************************************
C     SENDMAP       BEGSR
C                   MOVEL     WSEMAILFROM(1)       EMAILFROM1O
C                   MOVEL     WSRFQID(1)           RFQID1O
C                   MOVEL     WSCARRIER(1)         CARRIER1O
C                   MOVEL     WSSTATUS(1)          STATUS1O
C
C                   MOVEL     WSEMAILFROM(2)       EMAILFROM2O
C                   MOVEL     WSRFQID(2)           RFQID2O
C                   MOVEL     WSCARRIER(2)         CARRIER2O
C                   MOVEL     WSSTATUS(2)          STATUS2O
C
C                   MOVEL     WSEMAILFROM(3)       EMAILFROM3O
C                   MOVEL     WSRFQID(3)           RFQID3O
C                   MOVEL     WSCARRIER(3)         CARRIER3O
C                   MOVEL     WSSTATUS(3)          STATUS3O
C
C                   MOVEL     'EMAILS PROCESSED: ' MONSTSO
C                   CAT       WSEXTCNT             MONSTSO
C                   CAT       ' QUOTES EXTRACTED AND STORED'
C                             MONSTSO
C
C                   DSPLY     MONSTSO
C                   ENDSR

C*****************************************************************
C* RETURN TO DASHBOARD (PF3)
C*****************************************************************
C     RETDASH       BEGSR
C                   CALL      'QUOTEDASH'
C                   PARM                    DFHCOMMAREA
C                   ENDSR

C*****************************************************************
C* EMAIL PROCESSING (PF4)
C*****************************************************************
C     EMAILPROC     BEGSR
C                   CALL      'EMAILPROC'
C                   PARM                    DFHCOMMAREA
C
C                   EXSR      LOADEMAIL
C                   EXSR      SENDMAP
C                   ENDSR

C*****************************************************************
C* EMAIL ANALYTICS (PF5)
C*****************************************************************
C     EMAILANAL     BEGSR
C                   CALL      'EMAILANAL'
C                   PARM                    DFHCOMMAREA
C
C                   EXSR      SENDMAP
C                   ENDSR
