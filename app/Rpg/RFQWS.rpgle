      **free
       // ============================================================
       // Program: RFQWS
       // Description: RFQ Web Service - Send RFQ to UWB API
       //              Converted from COBOL/CICS program
       // ============================================================

       // Control options
       ctl-opt dftactgrp(*no) actgrp(*caller)
               option(*srcstmt:*nodebugio)
               main(Main);

       // External files
       // Display file for screen I/O (equivalent to BMS map RFQMAP/RFQWS)
       dcl-f RFQWSD workstn indds(wsIndicators)
                    usropn;

       // Database files (equivalent to VSAM datasets)
       dcl-f AXASUBMPF disk(*ext) usage(*input) keyed usropn;
       dcl-f AXAPRODPF disk(*ext) usage(*input) keyed usropn;
       dcl-f AXAPLCMTPF disk(*ext) usage(*input) keyed usropn;

       // ============================================================
       // Copy in data structures (copybooks)
       // ============================================================
       /copy qcpysrc,RFQAPI
       /copy qcpysrc,SUBMISSN
       /copy qcpysrc,PRODUCT
       /copy qcpysrc,PLACEMENT
       /copy qcpysrc,CLIENT

       // ============================================================
       // Working Storage Variables
       // ============================================================
       dcl-ds wsIndicators;
         wsExit        ind pos(3);    // F3 = Exit
         wsSendMap     ind pos(12);   // F12 = Send Map
         wsEnter       ind pos(21);   // Enter key
       end-ds;

       dcl-s wsResponse      int(10);
       dcl-s wsSubmissionKey char(10);
       dcl-s wsUwbApiUrl     char(100) inz('https://uwb.axainsurance.com/api/v1/rfq');
       dcl-s wsAuthToken     char(100) inz('Bearer UWB_RFQ_TOKEN_XYZ789');
       dcl-s wsHttpStatus    packed(3:0);
       dcl-s wsApiResponse   char(500);
       dcl-s wsJsonPayload   varchar(1500);
       dcl-s wsCurrentDate   char(10);
       dcl-s wsCommArea      char(100);
       dcl-s wsError         ind inz(*off);

       // HTTP API variables
       dcl-s httpHandle      int(10);
       dcl-s httpResponse    varchar(32767);
       dcl-s httpStatusCode  int(10);

       // ============================================================
       // Screen fields (equivalent to BMS map fields)
       // ============================================================
       dcl-s RFQIDO          char(10);   // RFQ ID output
       dcl-s CLIENTNMO       char(30);   // Client name output
       dcl-s BROKERNMO       char(30);   // Broker name output
       dcl-s CARRIERNMO      char(30);   // Carrier name output
       dcl-s BIZTYPEO        char(15);   // Business type output
       dcl-s INCEPDTO        char(10);   // Inception date output
       dcl-s EXPDTO          char(10);   // Expiry date output
       dcl-s LIMITAMTO       packed(15:2); // Limit amount output
       dcl-s DEDUCTAMTO      packed(12:2); // Deductible amount output
       dcl-s APISTATUSO      char(50);   // API status output
       dcl-s PRIORITYI       char(10);   // Priority input
       dcl-s DUEDATEI        char(10);   // Due date input

       // ============================================================
       // Prototype for HTTP API service program
       // ============================================================
       dcl-pr QSYS2_HTTP_POST varchar(32767) extproc('QSYS2.HTTP_POST');
         url       varchar(2048) const;
         message   varchar(32767) const;
         options   varchar(32767) const options(*nopass);
       end-pr;

       dcl-pr QSYS2_HTTP_POST_VERBOSE varchar(32767)
                                      extproc('QSYS2.HTTP_POST_VERBOSE');
         url       varchar(2048) const;
         message   varchar(32767) const;
         options   varchar(32767) const options(*nopass);
       end-pr;

       // ============================================================
       // Main Procedure
       // ============================================================
       dcl-proc Main;

         // Open files
         open RFQWSD;
         open AXASUBMPF;
         open AXAPRODPF;
         open AXAPLCMTPF;

         // Get submission key from parameter (like DFHCOMMAREA)
         wsSubmissionKey = %subst(wsCommArea:1:10);

         // Read submission data
         ReadSubmissionData();

         // Send initial map
         if not wsError;
           SendMap();
         endif;

         // Process screen interaction loop
         dow not wsExit and not wsSendMap;
           read RFQWSD;

           select;
             when wsEnter;
               // Enter pressed - Send RFQ to API
               SendRfqApi();

             when wsExit;
               // F3 pressed - Return to Submission
               ReturnSubmission();

             when wsSendMap;
               // F12 pressed - Refresh/Send Map
               SendMap();
           endsl;
         enddo;

         // Close files
         close RFQWSD;
         close AXASUBMPF;
         close AXAPRODPF;
         close AXAPLCMTPF;

         return;

       end-proc;

       // ============================================================
       // ReadSubmissionData - Read data from database files
       // (Equivalent to CICS READ DATASET operations)
       // ============================================================
       dcl-proc ReadSubmissionData;

         // Read submission record
         chain wsSubmissionKey AXASUBMPF submissionRecord;
         if not %found(AXASUBMPF);
           wsError = *on;
           APISTATUSO = 'SUBMISSION NOT FOUND';
           SendMap();
           return;
         endif;

         // Read product record using product ID from submission
         chain productId AXAPRODPF productRecord;
         if not %found(AXAPRODPF);
           wsError = *on;
           APISTATUSO = 'PRODUCT NOT FOUND';
           SendMap();
           return;
         endif;

         // Read placement record using placement ID from product
         chain placementId AXAPLCMTPF placementRecord;
         if not %found(AXAPLCMTPF);
           wsError = *on;
           APISTATUSO = 'PLACEMENT NOT FOUND';
           SendMap();
           return;
         endif;

       end-proc;

       // ============================================================
       // SendRfqApi - Handle Enter key - Send RFQ to UWB API
       // (Equivalent to CICS RECEIVE MAP and API call)
       // ============================================================
       dcl-proc SendRfqApi;

         BuildRfqRequest();
         BuildJsonPayload();
         CallUwbRfqApi();
         SendMap();

       end-proc;

       // ============================================================
       // BuildRfqRequest - Populate RFQ API request structure
       // ============================================================
       dcl-proc BuildRfqRequest;

         dcl-s currentTimestamp timestamp;
         dcl-s currentDateNum   packed(8:0);

         // Get current timestamp
         currentTimestamp = %timestamp();
         currentDateNum = %dec(%date():*iso);

         // Generate RFQ ID from timestamp
         rfqId = %char(%subst(%char(currentTimestamp):12:8));

         // Populate from submission record
         rfqSubmissionId = submissionId;
         rfqInceptionDate = submissionDate;
         rfqExpiryDate = validUntilDate;
         rfqSubmissionDate = %char(%date():*iso);

         // Populate from product record
         rfqProductId = productId;
         rfqLimitAmount = coverageLimit;
         rfqDeductibleAmount = deductible;
         rfqPremiumEstimate = premium;

         // Populate from placement record
         rfqPlacementId = placementId;
         rfqClientName = placementName;

         // Set static values
         rfqBrokerName = 'ROSALIA GARCIA';
         rfqCarrierName = 'LLOYD''S OF LONDON';
         rfqBusinessType = 'NEW BUSINESS';
         rfqCurrencyCode = 'USD';
         rfqCommissionRate = 5.00;
         rfqStatus = 'PENDING';

         // Get values from screen input
         rfqPriorityLevel = PRIORITYI;
         rfqResponseDueDate = DUEDATEI;

       end-proc;

       // ============================================================
       // CallUwbRfqApi - Call external HTTP REST API
       // (Equivalent to CICS WEB OPEN/SEND/RECEIVE/CLOSE)
       // Using SQL HTTP functions (DB2 for i)
       // ============================================================
       dcl-proc CallUwbRfqApi;

         dcl-s sqlResponse   varchar(32767);
         dcl-s httpOptions   varchar(500);

         // Build HTTP options with headers
         httpOptions = '{' +
           '"header":"Content-Type,application/json",' +
           '"header":"Authorization,' + %trim(wsAuthToken) + '"' +
           '}';

         // Check SQL status
         if sqlCode = 0;
           wsApiResponse = sqlResponse;
           APISTATUSO = 'RFQ SENT TO UWB VIA API - SUCCESS';
         else;
           APISTATUSO = 'RFQ API CALL FAILED - CHECK LOGS';
         endif;

         // Alternative: Check for specific HTTP status codes
         // In production, parse the response to get actual status

       end-proc;

       // ============================================================
       // SendMap - Display screen with current data
       // (Equivalent to CICS SEND MAP)
       // ============================================================
       dcl-proc SendMap;

         RFQIDO = rfqId;
         CLIENTNMO = rfqClientName;
         BROKERNMO = rfqBrokerName;
         CARRIERNMO = rfqCarrierName;
         BIZTYPEO = rfqBusinessType;
         INCEPDTO = rfqInceptionDate;
         EXPDTO = rfqExpiryDate;
         LIMITAMTO = rfqLimitAmount;
         DEDUCTAMTO = rfqDeductibleAmount;

         write RFQWSR;   // Write record format to display file

       end-proc;

       // ============================================================
       // ReturnSubmission - Transfer to SUBMISSN program
       // (Equivalent to CICS XCTL)
       // ============================================================
       dcl-proc ReturnSubmission;

         dcl-pr SUBMISSN extpgm('SUBMISSN');
           pCommArea char(100);
         end-pr;

         %subst(wsCommArea:1:10) = rfqSubmissionId;

         // Close files before calling another program
         if %open(RFQWSD);
           close RFQWSD;
         endif;
         if %open(AXASUBMPF);
           close AXASUBMPF;
         endif;
         if %open(AXAPRODPF);
           close AXAPRODPF;
         endif;
         if %open(AXAPLCMTPF);
           close AXAPLCMTPF;
         endif;

         // Call SUBMISSN program (like XCTL)
         SUBMISSN(wsCommArea);

       end-proc;

       // ============================================================
       // ErrorHandler - Handle errors
       // (Equivalent to CICS HANDLE CONDITION ERROR)
       // ============================================================
       dcl-proc ErrorHandler;

         APISTATUSO = 'RFQ API ERROR - CONTACT SUPPORT';
         SendMap();

       end-proc;
