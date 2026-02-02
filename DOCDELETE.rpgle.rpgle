H*****************************************************************
H* Program : DOCDELETE
H* Purpose : Delete selected documents via API and local storage
H* Source  : Mainframe COBOL Migration
H*****************************************************************

F*****************************************************************
F* Files (CICS / VSAM Equivalents)
F*****************************************************************
FAXASUBM   IF   E           K DISK
FAXADOC    IF   E           K DISK

I*****************************************************************
I* COPYBOOKS
I*****************************************************************
I/COPY DOCUMENT
I/COPY SUBMISSN

I*****************************************************************
I* WORKING STORAGE
I*****************************************************************
I             WSRESPONSE     S 9 0
I             WSSUBMKEY      S 10
I             WSDELCNT       S 2 0 INZ(0)
I             WSSUCCNT       S 2 0 INZ(0)
I             WSHTTPSTS      S 3 0
I             WSJSON         S 1000
I             WSAPIRESP      S 500

I*****************************************************************
I* DOCUMENT TABLE
I*****************************************************************
I             WSDOCTBL       DS
I             WSDOCID        S 10 DIM(3)
I             WSDOCNAME      S 50 DIM(3)
I             WSDOCTYPE      S 20 DIM(3)
I             WSDOCSTAT      S 15 DIM(3)
I             WSDOCDATE      S 10 DIM(3)
I             WSDOCSIZE      S 8  DIM(3)
I             WSDOCSEL       S 1  DIM(3)

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
C                   EXSR      LOADDOC
C                   EXSR      SENDMAP
C                   RETRN

C*****************************************************************
C* READ SUBMISSION
C*****************************************************************
C     READSUB       BEGSR
C     WSSUBMKEY     CHAIN     AXASUBM                 90
C                   ENDSR

C*****************************************************************
C* LOAD EXISTING DOCUMENTS
C*****************************************************************
C     LOADDOC       BEGSR
C                   MOVEL     'DOC100001' WSDOCID(1)
C                   MOVEL     'Policy_Document.pdf' WSDOCNAME(1)
C                   MOVEL     'POLICY'    WSDOCTYPE(1)
C                   MOVEL     'UPLOADED'  WSDOCSTAT(1)
C                   MOVEL     '2024-01-15' WSDOCDATE(1)
C                   MOVEL     '2.5MB'     WSDOCSIZE(1)

C                   MOVEL     'DOC100002' WSDOCID(2)
C                   MOVEL     'Quote_Response.pdf' WSDOCNAME(2)
C                   MOVEL     'QUOTE'     WSDOCTYPE(2)
C                   MOVEL     'UPLOADED'  WSDOCSTAT(2)
C                   MOVEL     '2024-01-14' WSDOCDATE(2)
C                   MOVEL     '1.8MB'     WSDOCSIZE(2)

C                   MOVEL     'DOC100003' WSDOCID(3)
C                   MOVEL     'Binding_Authority.pdf' WSDOCNAME(3)
C                   MOVEL     'BINDER'    WSDOCTYPE(3)
C                   MOVEL     'UPLOADED'  WSDOCSTAT(3)
C                   MOVEL     '2024-01-13' WSDOCDATE(3)
C                   MOVEL     '1.2MB'     WSDOCSIZE(3)
C                   ENDSR

C*****************************************************************
C* DELETE SELECTED DOCUMENTS
C*****************************************************************
C     DELSEL        BEGSR
C                   Z-ADD     0            WSDELCNT
C                   Z-ADD     0            WSSUCCNT

C                   IF        DEL1I = 'X'
C                   ADD       1            WSDELCNT
C                   Z-ADD     1            WSRESPONSE
C                   EXSR      DELDOC
C                   ENDIF

C                   IF        DEL2I = 'X'
C                   ADD       1            WSDELCNT
C                   Z-ADD     2            WSRESPONSE
C                   EXSR      DELDOC
C                   ENDIF

C                   IF        DEL3I = 'X'
C                   ADD       1            WSDELCNT
C                   Z-ADD     3            WSRESPONSE
C                   EXSR      DELDOC
C                   ENDIF
C                   ENDSR

C*****************************************************************
C* DELETE DOCUMENT
C*****************************************************************
C     DELDOC        BEGSR
C                   EXSR      CALLAPI
C                   EXSR      DELLOCAL
C                   ENDSR

C*****************************************************************
C* CALL DELETE API
C*****************************************************************
C     CALLAPI       BEGSR
C                   MOVEL     '{ "documentId":"' WSJSON
C                   MOVEL     WSDOCID(WSRESPONSE) WSJSON+15
C                   MOVEL     '" }'         WSJSON+50

C* Simulated WEB API call result
C                   Z-ADD     200           WSHTTPSTS

C                   IF        WSHTTPSTS = 200
C                   MOVEL     'DELETED'     WSDOCSTAT(WSRESPONSE)
C                   ADD       1             WSSUCCNT
C                   ELSE
C                   MOVEL     'DELETE FAILED' WSDOCSTAT(WSRESPONSE)
C                   ENDIF
C                   ENDSR

C*****************************************************************
C* DELETE FROM LOCAL STORAGE
C*****************************************************************
C     DELLOCAL      BEGSR
C                   IF        WSHTTPSTS = 200
C     WSDOCID(WSRESPONSE)
C                   DELETE    AXADOC
C                   ENDIF
C                   ENDSR

C*****************************************************************
C* SEND MAP
C*****************************************************************
C     SENDMAP       BEGSR
C                   MOVEL     CLIENTID     CLIENTIDO
C                   MOVEL     SUBMISSIONID SUBMIDO

C                   MOVEL     WSDOCNAME(1) DOC1O
C                   MOVEL     WSDOCTYPE(1) TYPE1O
C                   MOVEL     WSDOCSTAT(1) STAT1O

C                   MOVEL     WSDOCNAME(2) DOC2O
C                   MOVEL     WSDOCTYPE(2) TYPE2O
C                   MOVEL     WSDOCSTAT(2) STAT2O

C                   MOVEL     WSDOCNAME(3) DOC3O
C                   MOVEL     WSDOCTYPE(3) TYPE3O
C                   MOVEL     WSDOCSTAT(3) STAT3O
C                   ENDSR

C*****************************************************************
C* RETURN TO UPLOAD
C*****************************************************************
C     RETUPL        BEGSR
C                   MOVEL     SUBMISSIONID DFHCOMMAREA
C                   CALL      'DOCUPLOAD'
C                   ENDSR
