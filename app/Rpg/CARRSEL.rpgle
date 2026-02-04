H*****************************************************************
H* Program : CARRSEL
H* Purpose : Carrier Selection RFQ Submission
H* Source  : Mainframe COBOL Migration
H*****************************************************************

FAXASUBM   IF   E           K DISK
FAXAPROD   IF   E           K DISK
FAXAPLCMT  IF   E           K DISK

E*****************************************************************
E* Compile time arrays Carrier Table
E*****************************************************************
E CARRNAME     25  3
E CARRURL     100  3
E CARRAUTH     50  3

I*****************************************************************
I* COPYBOOKS
I*****************************************************************
I/COPY APISUBM
I/COPY SUBMISSN
I/COPY PRODUCT
I/COPY PLACEMENT
I/COPY CARRIER

I*****************************************************************
I* WORKING STORAGE
I*****************************************************************
I             WSRESPONSE      S 9 0
I             WSSUBKEY        S 10
I             WSSELCOUNT      S 2 0 INZ(0)
I             WSSUCCOUNT      S 2 0 INZ(0)
I             WSHTTPSTS       S 3 0
I             WSAPIRESP       S 200

I*****************************************************************
I* LINKAGE (DFHCOMMAREA)
I*****************************************************************
I             DFHCOMMAREA     DS
I                                      1 100

C*****************************************************************
C* MAIN LOGIC
C*****************************************************************
C                   MOVEL     DFHCOMMAREA WSSUBKEY

C                   EXSR      LOADCARR
C                   EXSR      READSUBM
C                   EXSR      SENDMAP
C                   RETRN

C*****************************************************************
C* LOAD CARRIERS
C*****************************************************************
C     LOADCARR      BEGSR
C                   MOVEL     'LLOYDS OF LONDON' CARRNAME(1)
C                   MOVEL     'https://api.lloyds.com/v1/submissions'
C                             CARRURL(1)
C                   MOVEL     'Bearer LLOYDS_API_TOKEN_123'
C                             CARRAUTH(1)

C                   MOVEL     'ZURICH INSURANCE' CARRNAME(2)
C                   MOVEL     'https://api.zurich.com/v2/rfq'
C                             CARRURL(2)
C                   MOVEL     'Bearer ZURICH_API_TOKEN_456'
C                             CARRAUTH(2)

C                   MOVEL     'ALLIANZ GROUP' CARRNAME(3)
C                   MOVEL     'https://api.allianz.com/submissions'
C                             CARRURL(3)
C                   MOVEL     'Bearer ALLIANZ_API_TOKEN_789'
C                             CARRAUTH(3)
C                   ENDSR

C*****************************************************************
C*****************************************************************
C     READSUBM      BEGSR
C     WSSUBKEY      CHAIN     AXASUBM                  90
C                   IF        *IN90 = *OFF
C                   MOVEL     PRODUCTID  PRODUCTID
C                   CHAIN     PRODUCTID  AXAPROD
C                   MOVEL     PLACEMENTID PLACEMENTID
C                   CHAIN     PLACEMENTID AXAPLCMT
C                   ENDIF
C                   ENDSR

C*****************************************************************
C* SEND RFQ REQUEST
C*****************************************************************
C     SENDRFQ       BEGSR
C                   ADD       1           WSSELCOUNT
C                   IF        WSHTTPSTS = 200
C                   ADD       1           WSSUCCOUNT
C                   ENDIF
C                   ENDSR

C*****************************************************************
C* SEND MAP
C*****************************************************************
C     SENDMAP       BEGSR
C                   EVAL      RFQSTATUSO = 'RFQ SENT TO ' +
C                             %CHAR(WSSELCOUNT) +
C                             ' CARRIERS, ' +
C                             %CHAR(WSSUCCOUNT) +
C                             ' SUCCESSFUL'
C                   ENDSR
