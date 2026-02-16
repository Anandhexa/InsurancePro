H*****************************************************************
H* Program : DOCMETA
H* Purpose : Upload document metadata and persist document record
H* Source  : Mainframe COBOL Migration
H*****************************************************************

F*****************************************************************
F*****************************************************************
FDOCMETA   CF   E             WORKSTN
FAXASUBM   IF   E           K DISK
FAXADOC    UF   E           K DISK

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
I             WSDOCCNTR      S 6 0 INZ(200001)
I             WSUPLDCNT      S 2 0 INZ(0)
I             WSHTTPSTS     S 3 0
I             WSJSON        S 1500
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
C                   EXSR      SENDMAP
C                   RETRN

C*****************************************************************
C*****************************************************************
C     READSUB       BEGSR
C     WSSUBMKEY     CHAIN     AXASUBM                 90
C                   ENDSR

C*****************************************************************
C* UPLOAD WITH METADATA (ENTER)
C*****************************************************************
C     UPLOADMD      BEGSR
C                   EXSR      BUILDMD
C                   EXSR      CALLAPI
C                   EXSR      SAVEDOC
C                   EXSR      SENDMAP
C                   ENDSR

C*****************************************************************
C* BUILD METADATA RECORD
C*****************************************************************
C     BUILDMD       BEGSR
C                   MOVEL     'DOC'       DOCUMENTID
C                   Z-ADD     WSDOCCNTR   DOCUMENTID
C                   ADD       1           WSDOCCNTR
C                   MOVEL     CLIENTID    CLIENTID
C                   MOVEL     SUBMIDI     SUBMISSIONID
C                   MOVEL     DOCTYPEI    DOCUMENTTYPE
C                   MOVEL     DOCNAMEI    DOCUMENTNAME
C                   MOVEL     FILEPATHI   FILEPATH
C                   Z-ADD     3500000     FILESIZE
C                   MOVEL     *DATE       UPLOADDATE
C                   MOVEL     'ROSALIA GARCIA' UPLOADEDBY
C                   MOVEL     'UPLOADING' DOCUMENTSTATUS
C                   MOVEL     'application/pdf' MIMETYPE
C                   MOVEL     CLIENTI     CLIENTNAME
C                   MOVEL     POLIYEARI   POLICYYEAR
C                   MOVEL     CARRIERI   CARRIERNAME
C                   MOVEL     DATERECVI  DATERECEIVED
C                   MOVEL     DOCUMENTTYPE METADATATAGS
C                   CAT       '|'         METADATATAGS
C                   CAT       CLIENTNAME  METADATATAGS
C                   CAT       '|'         METADATATAGS
C                   CAT       POLICYYEAR  METADATATAGS
C                   CAT       '|'         METADATATAGS
C                   CAT       CARRIERNAME METADATATAGS
C                   CAT       '|'         METADATATAGS
C                   CAT       DATERECEIVED METADATATAGS
C                   ENDSR

C*****************************************************************
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
C*****************************************************************
C     SAVEDOC       BEGSR
C     DOCUMENTID    WRITE     AXADOC
C                   ENDSR

C*****************************************************************
C*****************************************************************
C     SENDMAP       BEGSR
C                   MOVEL     SUBMISSIONID SUBMIDO
C                   MOVEL     'METADATA UPLOAD STATUS:' METASTSO
C                   CAT       DOCUMENTSTATUS METASTSO
C                   CAT       ' COUNT:' METASTSO
C                   CAT       WSUPLDCNT METASTSO
C                   ENDSR

C*****************************************************************
C*****************************************************************
C     RETUPL        BEGSR
C                   MOVEL     SUBMISSIONID DFHCOMMAREA
C                   CALL      'DOCUPLOAD'
C                   ENDSR
