      **free
       // ============================================================
       // Program: QUOTERESP
       // Description: Quote Response Display Program
       //              Displays submission and placement status
       //              Converted from COBOL/CICS program
       // ============================================================

       // Control options
       ctl-opt dftactgrp(*no) actgrp(*caller)
               option(*srcstmt:*nodebugio)
               main(Main);

       // External files
       // Display file for screen I/O (equivalent to BMS map QUOTEMAP/QUOTERESP)
       dcl-f QUOTERESPD workstn indds(wsIndicators)
                        usropn;

       // Database files (equivalent to VSAM datasets)
       dcl-f AXASUBMPF disk(*ext) usage(*input) keyed usropn;
       dcl-f AXAPLCMTPF disk(*ext) usage(*input) keyed usropn;

       // ============================================================
       // Copy in data structures (copybooks)
       // ============================================================
       /copy qcpysrc,SUBMISSN
       /copy qcpysrc,PLACEMENT

       // ============================================================
       // Working Storage Variables
       // ============================================================
       dcl-ds wsIndicators;
         wsExit        ind pos(3);    // F3 = Return to Submission
         wsRefresh     ind pos(12);   // F12 = Refresh
       end-ds;

       dcl-s wsResponse      int(10);
       dcl-s wsSubmissionKey char(10);
       dcl-s wsCurrentDate   char(10);
       dcl-s wsCommArea      char(100);
       dcl-s wsError         ind inz(*off);

       // ============================================================
       // Screen fields (equivalent to BMS map fields)
       // ============================================================
       dcl-s SUBMIDO         char(10);   // Submission ID output
       dcl-s SUBMSTSO        char(10);   // Submission status output
       dcl-s PLCMTSTSO       char(15);   // Placement status output
       dcl-s SENTDATEO       char(8);    // Sent date output
       dcl-s MSGLINEO        char(78);   // Message line output

       // ============================================================
       // Program Entry Parameter (equivalent to DFHCOMMAREA)
       // ============================================================
       dcl-pi Main;
         piCommArea char(100);
       end-pi;

       // ============================================================
       // Main Procedure
       // ============================================================

         // Initialize working storage from parameter
         wsCommArea = piCommArea;

         // Open files
         open QUOTERESPD;
         open AXASUBMPF;
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
         dow not wsExit;
           read QUOTERESPD;

           select;
             when wsExit;
               // F3 pressed - Return to Submission
               ReturnSubmission();

             when wsRefresh;
               // F12 pressed - Refresh display
               ReadSubmissionData();
               SendMap();

             other;
               SendMap();
           endsl;
         enddo;

         // Close files
         close QUOTERESPD;
         close AXASUBMPF;
         close AXAPLCMTPF;

         // Return parameter
         piCommArea = wsCommArea;

         return;

       // ============================================================
       // ReadSubmissionData - Read submission and placement records
       // (Equivalent to CICS READ DATASET operations)
       // ============================================================
       dcl-proc ReadSubmissionData;

         // Read submission record
         chain wsSubmissionKey AXASUBMPF submissionRecord;

         if not %found(AXASUBMPF);
           wsError = *on;
           MSGLINEO = 'SUBMISSION NOT FOUND';
           return;
         endif;

         // Read placement record using placement ID
         // Note: Need to get placement ID from a related record
         // For now, using a lookup approach
         chain submissionId AXAPLCMTPF placementRecord;

         if not %found(AXAPLCMTPF);
           // Placement not found - not necessarily an error
           clear placementRecord;
           placementStatus = 'NOT FOUND';
         endif;

         wsError = *off;

       end-proc;

       // ============================================================
       // SendMap - Display screen with current data
       // (Equivalent to CICS SEND MAP)
       // ============================================================
       dcl-proc SendMap;

         // Populate screen fields from record data
         SUBMIDO = submissionId;
         SUBMSTSO = submissionStatus;
         PLCMTSTSO = placementStatus;

         // Get current date (equivalent to FUNCTION CURRENT-DATE)
         SENTDATEO = %char(%date():*iso0);

         // Write record format to display file
         write QUOTERESPR;

       end-proc;

       // ============================================================
       // ReturnSubmission - Transfer to SUBMISSN program
       // (Equivalent to CICS XCTL)
       // ============================================================
       dcl-proc ReturnSubmission;

         dcl-pr SUBMISSN extpgm('SUBMISSN');
           pCommArea char(100);
         end-pr;

         // Set submission ID in comm area for return
         %subst(wsCommArea:1:10) = submissionId;

         // Close files before calling another program
         if %open(QUOTERESPD);
           close QUOTERESPD;
         endif;
         if %open(AXASUBMPF);
           close AXASUBMPF;
         endif;
         if %open(AXAPLCMTPF);
           close AXAPLCMTPF;
         endif;

         // Call SUBMISSN program (like XCTL)
         SUBMISSN(wsCommArea);

       end-proc;
