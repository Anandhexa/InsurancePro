 H*****************************************************************
H* Program : DOCUPLOAD
H* Purpose : Upload document and persist document record
H* Source  : Mainframe COBOL Migration
H*****************************************************************

F*****************************************************************
F* Files
F*****************************************************************
FAXASUBM   IF   E           K DISK
FAXACLIENT IF   E           K DISK
FAXADOC    UF   E           K DISK

I*****************************************************************
I* COPYBOOKS
I*****************************************************************
I/COPY DOCUMENT
I/COPY SUBMISSN
I/COPY CLIENT

I*****************************************************************
I* WORKING STORAGE
I*****************************************************************
I             WSRESPONSE     S 9 0
I             WSSUBMKEY      S 10
I             WSDOCCNTR      S 6 0 INZ(100001)
I             WSUPLDCNT      S 2 0 INZ(0)
I             WSHTTPSTS     S 3 0
I             WSJSON        S 1000
I             WSAPIRESP     S 500

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
C* READ SUBMISSION CLIENT DATA
C*****************************************************************
C     READSUB       BEGSR
C     WSSUBMKEY     CHAIN     AXASUBM                 90
C                   CHAIN     CLIENTID  AXACLIENT
C                   ENDSR

C*****************************************************************
C* LOAD EXISTING DOCUMENTS (DISPLAY ONLY)
C*****************************************************************
C     LOADDOC       BEGSR
C                   MOVEL     'Policy_Document.pdf' DOC1O
C                   MOVEL     'POLICY'              TYPE1O
C                   MOVEL     'UPLOADED'            STAT1O
C                   MOVEL     '2024-01-15'           DATE1O
C                   MOVEL     '2.5MB'               SIZE1O
C                   ENDSR

C*****************************************************************
C* UPLOAD DOCUMENT (ENTER)
C*****************************************************************
C     UPLOADDOC     BEGSR
C                   EXSR      BUILDDOC
C                   EXSR      CALLAPI
C                   EXSR      SAVEDOC
C                   EXSR      SENDMAP
C                   ENDSR

C*****************************************************************
C* BUILD DOCUMENT RECORD
C*****************************************************************
C     BUILDDOC      BEGSR
C                   MOVEL     'DOC'       DOCUMENTID
C                   Z-ADD     WSDOCCNTR   DOCUMENTID
C                   ADD       1           WSDOCCNTR
C                   MOVEL     CLIENTID    CLIENTID
C                   MOVEL     SUBMISSIONID SUBMISSIONID
C                   MOVEL     DOCTYPEI    DOCUMENTTYPE
C                   MOVEL     DOCNAMEI    DOCUMENTNAME
C                   MOVEL     FILEPATHI   FILEPATH
C                   Z-ADD     2500000     FILESIZE
C                   MOVEL     *DATE       UPLOADDATE
C                   MOVEL     'ROSALIA GARCIA' UPLOADEDBY
C                   MOVEL     'UPLOADING' DOCUMENTSTATUS
C                   MOVEL     'application/pdf' MIMETYPE
C                   ENDSR

C*****************************************************************
C* CALL UPLOAD API (LOGICAL REPRESENTATION)
C*****************************************************************
C     CALLAPI       BEGSR
C                   MOVEL     '{JSON PAYLOAD}' WSJSON
C                   Z-ADD     200          WSHTTPSTS
C                   IF        WSHTTPSTS = 200
C                   MOVEL     'UPLOADED'  DOCUMENTSTATUS
C                   ADD       1           WSUPLDCNT
C                   ELSE
C                   MOVEL     'FAILED'    DOCUMENTSTATUS
C                   ENDIF
C                   ENDSR

C*****************************************************************
C* SAVE DOCUMENT RECORD
C*****************************************************************
C     SAVEDOC       BEGSR
C     DOCUMENTID    WRITE     AXADOC
C                   ENDSR

C*****************************************************************
C* SEND MAP
C*****************************************************************
C     SENDMAP       BEGSR
C                   MOVEL     CLIENTID     CLIENTIDO
C                   MOVEL     SUBMISSIONID SUBMIDO
C                   MOVEL     'DOCUMENTS UPLOADED:' UPLOADSTSO
C                   CAT       WSUPLDCNT    UPLOADSTSO
C                   CAT       ' STATUS:'   UPLOADSTSO
C                   CAT       DOCUMENTSTATUS UPLOADSTSO
C                   ENDSR

C*****************************************************************
C* DELETE DOCUMENTS
C*****************************************************************
C     DELDOC        BEGSR
C                   MOVEL     SUBMISSIONID DFHCOMMAREA
C                   CALL      'DOCDELETE'
C                   ENDSR

C*****************************************************************
C* METADATA UPLOAD
C*****************************************************************
C     METADATA      BEGSR
C                   MOVEL     SUBMISSIONID DFHCOMMAREA
C                   CALL      'DOCMETA'
C                   ENDSR

C*****************************************************************
C* RETURN TO SUBMISSION
C*****************************************************************
C     RETSUB        BEGSR
C                   MOVEL     SUBMISSIONID DFHCOMMAREA
C                   CALL      'SUBMISSN'
C                   ENDSR
