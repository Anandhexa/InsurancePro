H*****************************************************************
H* Program : DOCGEN
H* Purpose : Generate and print submission document
H* Source  : Mainframe COBOL Migration
H*****************************************************************

F*****************************************************************
F* Files (CICS / VSAM Equivalents)
F*****************************************************************
FDOCGEN    CF   E             WORKSTN
FAXASUBM   IF   E           K DISK
FAXAPROD   IF   E           K DISK
FAXAPLCMT  IF   E           K DISK

I*****************************************************************
I* COPYBOOKS
I*****************************************************************
I/COPY SUBMISSN
I/COPY PRODUCT
I/COPY PLACEMENT
I/COPY CLIENT

I*****************************************************************
I* WORKING STORAGE
I*****************************************************************
I             WSRESPONSE     S 9 0
I             WSSUBMKEY      S 10
I             WSBROKMAIL     S 30 INZ('RGARCIA@AXAINSURANCE.COM')

I*****************************************************************
I* DFHCOMMAREA
I*****************************************************************
I             DFHCOMMAREA    DS
I                                      1 100

C*****************************************************************
C* MAIN LOGIC
C*****************************************************************
C                   MOVEL     DFHCOMMAREA WSSUBMKEY
C                   EXSR      READSUB
C                   EXSR      SENDMAP
C                   RETRN

C*****************************************************************
C*****************************************************************
C     READSUB       BEGSR
C     WSSUBMKEY     CHAIN     AXASUBM                 90
C                   IF        *IN90 = *OFF
C     PRODUCTID     CHAIN     AXAPROD                 91
C     PLACEMENTID   CHAIN     AXAPLCMT                92
C                   ENDIF
C                   ENDSR

C*****************************************************************
C* SEND MAP
C*****************************************************************
C     SENDMAP       BEGSR
C                   MOVEL     PLACEMENTNAME INSNAMEO
C                   MOVEL     WSBROKMAIL   BRKEMAILO
C                   MOVEL     PRODUCTNAME PRODNMO
C                   MOVEL     'NEW BUSINESS' BIZTYPEO
C                   MOVEL     SUBMISSIONDATE INCEPDTO
C                   MOVEL     VALIDUNTILDATE EXPIRDTO
C                   MOVEL     COVERAGELIMIT PROGLMTO
C                   ENDSR

C*****************************************************************
C*****************************************************************
C     PRINTDOC      BEGSR
C                   MOVEL     DOCMAP       WSRESPONSE
C                   ENDSR

C*****************************************************************
C*****************************************************************
C     RETSUB        BEGSR
C                   MOVEL     SUBMISSIONID DFHCOMMAREA
C                   CALL      'SUBMISSN'
C                   ENDSR
