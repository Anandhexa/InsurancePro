H*****************************************************************
H* Program : EMAILEXT
H* Purpose : Extract Quotes from Incoming Emails
H* Source  : Mainframe COBOL Migration
H*****************************************************************

F*****************************************************************
F* Files
F*****************************************************************
FAXAQUOTE  UF   E           K DISK

I*****************************************************************
I* COPYBOOKS
I*****************************************************************
I/COPY EMAILQUOTE
I/COPY QUOTE

I*****************************************************************
I* WORKING STORAGE
I*****************************************************************
I             WSRESPONSE     S 9 0
I             WSEMAILCNT    S 3 0 INZ(0)
I             WSPROCCNT     S 3 0 INZ(0)
I             WSQTECNT      S 6 0 INZ(100001)

I*****************************************************************
I* DFHCOMMAREA
I*****************************************************************
I             DFHCOMMAREA    DS
I                                      1 100

C*****************************************************************
C* MAIN LOGIC
C*****************************************************************
C                   EXSR      PROCEMAIL
C                   EXSR      DISPRES
C                   RETRN

C*****************************************************************
C* PROCESS EMAIL QUEUE
C*****************************************************************
C     PROCEMAIL     BEGSR
C                   Z-ADD     1           WSEMAILCNT
C     EMLOOP       DOU       WSEMAILCNT > 3
C                   EXSR      READEMAIL
C                   EXSR      EXTRACTQT
C                   EXSR      STOREQT
C                   ADD       1           WSEMAILCNT
C                   ENDDO
C                   ENDSR

C*****************************************************************
C* READ EMAIL DATA (SIMULATED)
C*****************************************************************
C     READEMAIL     BEGSR
C                   SELECT
C                   WHEN      WSEMAILCNT = 1
C                   MOVEL     'uwb@axainsurance.com' EMAILFROM
C                   MOVEL     'Quote Response - RFQ001' EMAILSUBJ
C                   MOVEL     'Quote attached for RFQ001 from Lloyds'
C                             EMAILBODY
C                   MOVEL     'Quote_RFQ001_Lloyds.pdf' ATTACHNAME
C
C                   WHEN      WSEMAILCNT = 2
C                   MOVEL     'quotes@zurich.com' EMAILFROM
C                   MOVEL     'RE: Quote Request RFQ002' EMAILSUBJ
C                   MOVEL     'Please find quote for submission RFQ002'
C                             EMAILBODY
C                   MOVEL     'Zurich_Quote_RFQ002.xlsx' ATTACHNAME
C
C                   WHEN      WSEMAILCNT = 3
C                   MOVEL     'underwriting@allianz.com' EMAILFROM
C                   MOVEL     'Quote RFQ003 - Allianz Response' EMAILSUBJ
C                   MOVEL     'Attached quote for your consideration'
C                             EMAILBODY
C                   MOVEL     'Allianz_RFQ003_Quote.pdf' ATTACHNAME
C                   ENDSL
C                   ENDSR

C*****************************************************************
C* EXTRACT QUOTE ATTRIBUTES
C*****************************************************************
C     EXTRACTQT     BEGSR
C                   EXSR      PARSESUB
C                   EXSR      EXTRACTAT
C                   EXSR      BUILDQTE
C                   ENDSR

C*****************************************************************
C* PARSE EMAIL SUBJECT
C*****************************************************************
C     PARSESUB      BEGSR
C                   IF        %SUBST(EMAILSUBJ:15:6) = 'RFQ001'
C                   MOVEL     'RFQ001' EXTRFQID
C                   MOVEL     'SUB001' EXTSUBID
C                   MOVEL     'LLOYDS OF LONDON' EXTCARRIER
C                   ELSE
C                   IF        %SUBST(EMAILSUBJ:19:6) = 'RFQ002'
C                   MOVEL     'RFQ002' EXTRFQID
C                   MOVEL     'SUB001' EXTSUBID
C                   MOVEL     'ZURICH INSURANCE' EXTCARRIER
C                   ELSE
C                   IF        %SUBST(EMAILSUBJ:7:6) = 'RFQ003'
C                   MOVEL     'RFQ003' EXTRFQID
C                   MOVEL     'SUB001' EXTSUBID
C                   MOVEL     'ALLIANZ GROUP' EXTCARRIER
C                   ENDIF
C                   ENDIF
C                   ENDIF
C                   ENDSR

C*****************************************************************
C* EXTRACT DATA FROM ATTACHMENT (SIMULATED)
C*****************************************************************
C     EXTRACTAT     BEGSR
C                   SELECT
C                   WHEN      EXTCARRIER = 'LLOYDS OF LONDON'
C                   Z-ADD     125000.00  EXTQTEAMT
C                   Z-ADD     15000.00   EXTPREMIUM
C                   Z-ADD     5000.00    EXTDEDUCT
C                   Z-ADD     1000000.00 EXTCOVER
C                   MOVEL     '2024-01-15' EXTQTEDT
C                   MOVEL     '2024-02-15' EXTVALID
C                   MOVEL     'Standard terms and conditions apply'
C                             EXTTERMS
C
C                   WHEN      EXTCARRIER = 'ZURICH INSURANCE'
C                   Z-ADD     135000.00  EXTQTEAMT
C                   Z-ADD     16500.00   EXTPREMIUM
C                   Z-ADD     7500.00    EXTDEDUCT
C                   Z-ADD     1500000.00 EXTCOVER
C                   MOVEL     '2024-01-16' EXTQTEDT
C                   MOVEL     '2024-02-16' EXTVALID
C                   MOVEL     'Enhanced coverage with additional benefits'
C                             EXTTERMS
C
C                   WHEN      EXTCARRIER = 'ALLIANZ GROUP'
C                   Z-ADD     118000.00  EXTQTEAMT
C                   Z-ADD     14200.00   EXTPREMIUM
C                   Z-ADD     4500.00    EXTDEDUCT
C                   Z-ADD     2000000.00 EXTCOVER
C                   MOVEL     '2024-01-17' EXTQTEDT
C                   MOVEL     '2024-02-17' EXTVALID
C                   MOVEL     'Competitive rates with flexible terms'
C                             EXTTERMS
C                   ENDSL
C                   ENDSR

C*****************************************************************
C* BUILD QUOTE RECORD
C*****************************************************************
C     BUILDQTE      BEGSR
C                   MOVEL     'QTE'       EXTQUOTEID
C                   Z-ADD     WSQTECNT   EXTQUOTEID
C                   ADD       1           WSQTECNT
C                   ENDSR

C*****************************************************************
C* STORE QUOTE IN BWB (AXAQUOTE)
C*****************************************************************
C     STOREQT       BEGSR
C                   MOVEL     EXTQUOTEID  QUOTEID
C                   MOVEL     EXTRFQID    RFQID
C                   MOVEL     EXTSUBID    SUBMISSIONID
C                   MOVEL     EXTCARRIER CARRIERNAME
C                   MOVEL     'QUOTED'    RESPONSESTATUS
C                   MOVEL     *BLANKS     ACTION
C                   MOVEL     EXTQTEDT    QUOTEDATE
C                   Z-ADD     EXTQTEAMT  QUOTEAMOUNT
C                   MOVEL     'RECEIVED'  QUOTESTATUS
C
C     QUOTEID       WRITE     AXAQUOTE
C                   ADD       1           WSPROCCNT
C                   MOVEL     'EXTRACTED' EXTRACTIONSTATUS
C                   ENDSR

C*****************************************************************
C* DISPLAY RESULTS
C*****************************************************************
C     DISPRES       BEGSR
C                   DSPLY     'EMAIL QUOTE EXTRACTION COMPLETED'
C                   ENDSR

C*****************************************************************
C* ERROR HANDLER
C*****************************************************************
C     ERRORHDL      BEGSR
C                   DSPLY     'EMAIL EXTRACTION ERROR'
C                   ENDSR
