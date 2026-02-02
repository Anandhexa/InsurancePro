H*****************************************************************
H* Program : CLAIMS
H* Purpose : Claim Creation / Update / Inquiry
H* Source  : Mainframe COBOL Migration
H*****************************************************************

F*****************************************************************
F* Files (CICS-managed VSAM equivalents)
F*****************************************************************
FAXACLAIMS IF   E           K DISK
FAXAPOLICY IF   E           K DISK

I*****************************************************************
I* COPYBOOKS
I*****************************************************************
I/COPY CLAIMS
I/COPY POLICY

I*****************************************************************
I* WORKING STORAGE
I*****************************************************************
I             WSRESPONSE     S 9 0
I             WSCLAIMKEY     S 15
I             WSCLMCNT       S 8 0 INZ(20000001)
I             WSUPDFLG       S 1   INZ('N')

I*****************************************************************
I* DFHCOMMAREA
I*****************************************************************
I             DFHCOMMAREA    DS
I                                      1 100

C*****************************************************************
C* MAIN LOGIC
C*****************************************************************
C                   MOVEL     DFHCOMMAREA WSCLAIMKEY

C                   IF        WSCLAIMKEY <> *BLANKS
C                   EXSR      READCLM
C                   ENDIF

C                   EXSR      SENDMAP
C                   RETRN

C*****************************************************************
C* READ CLAIM
C*****************************************************************
C     READCLM       BEGSR
C     WSCLAIMKEY    CHAIN     AXACLAIMS                90
C                   IF        *IN90 = *OFF
C                   MOVEL     'Y'         WSUPDFLG
C                   ELSE
C                   EXSR      NEWCLM
C                   ENDIF
C                   ENDSR

C*****************************************************************
C* NEW CLAIM
C*****************************************************************
C     NEWCLM        BEGSR
C                   CLEAR     CLAIMSRECORD
C                   MOVEL     DFHCOMMAREA POLICYID
C                   EXSR      READPOL
C                   EXSR      BUILDNEW
C                   ENDSR

C*****************************************************************
C* READ POLICY
C*****************************************************************
C     READPOL       BEGSR
C     POLICYID      CHAIN     AXAPOLICY                91
C                   ENDSR

C*****************************************************************
C* BUILD NEW CLAIM
C*****************************************************************
C     BUILDNEW      BEGSR
C                   MOVEL     'CLM'        CLAIMID
C                   MOVEL     WSCLMCNT     CLAIMID+3
C                   ADD       1            WSCLMCNT

C                   MOVEL     'CLAIM-'     CLAIMNUMBER
C                   TIME                    LASTMODIFIED
C                   MOVEL     POLICYID     POLICYID
C                   MOVEL     INSUREDNAME  INSUREDNAME
C                   MOVEL     CARRIERNAME  CARRIERNAME
C                   MOVEL     'REPORTED'   CLAIMSTATUS
C                   DATE                    REPORTEDDATE
C                   DATE                    CREATEDDATE
C                   ENDSR

C*****************************************************************
C* SAVE CLAIM
C*****************************************************************
C     SAVECLM       BEGSR
C                   EXSR      BUILDREC

C                   IF        WSUPDFLG = 'Y'
C                   UPDATE    AXACLAIMS
C                   ELSE
C                   WRITE     AXACLAIMS
C                   ENDIF

C                   EXSR      SENDMAP
C                   ENDSR

C*****************************************************************
C* BUILD CLAIM RECORD FROM MAP
C*****************************************************************
C     BUILDREC      BEGSR
C                   MOVEL     CLMTYPEI    CLAIMTYPE
C                   MOVEL     LOSSDTI     LOSSDATE
C                   MOVEL     LOSSDESI    LOSSDESC
C                   MOVEL     CLMAMTI     CLAIMAMOUNT
C                   MOVEL     RESERVEI    RESERVEAMT
C                   MOVEL     ADJNAMEI    ADJUSTERNAME
C                   SUB       PAIDAMOUNT CLAIMAMOUNT OUTSTANDAMT
C                   ENDSR

C*****************************************************************
C* SEND MAP
C*****************************************************************
C     SENDMAP       BEGSR
C                   MOVEL     CLAIMID     CLAIMIDO
C                   MOVEL     CLAIMNUMBER CLMNUMO
C                   MOVEL     INSUREDNAME INSNAMEO
C                   MOVEL     CLAIMTYPE   CLMTYPEO
C                   MOVEL     LOSSDATE    LOSSDTO
C                   MOVEL     CLAIMAMOUNT CLMAMTO
C                   MOVEL     RESERVEAMT  RESERVEO
C                   MOVEL     PAIDAMOUNT  PAIDO
C                   MOVEL     OUTSTANDAMT OUTSTO
C                   MOVEL     CLAIMSTATUS CLMSTSO
C                   ENDSR

C*****************************************************************
C* CLAIM INVESTIGATION
C*****************************************************************
C     CLMINV        BEGSR
C                   MOVEL     CLAIMID     DFHCOMMAREA
C                   CALL      'CLMINVEST'
C                   ENDSR

C*****************************************************************
C* CLAIM SETTLEMENT
C*****************************************************************
C     CLMSET        BEGSR
C                   MOVEL     CLAIMID     DFHCOMMAREA
C                   CALL      'CLMSETTLE'
C                   ENDSR

C*****************************************************************
C* RETURN TO POLICY
C*****************************************************************
C     RETPOL        BEGSR
C                   MOVEL     POLICYID    DFHCOMMAREA
C                   CALL      'POLICY'
C                   ENDSR
