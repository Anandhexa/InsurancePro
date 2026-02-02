      **free
       // ============================================================
       // Program: QUOTEVALID
       // Description: Quote Validation Program
       //              Validates quote fields and business rules,
       //              calculates validation score
       //              Converted from COBOL/CICS program
       // ============================================================

       // Control options
       ctl-opt dftactgrp(*no) actgrp(*caller)
               option(*srcstmt:*nodebugio)
               main(Main);

       // Database file for quotes (equivalent to VSAM AXAQUOTE)
       dcl-f AXAQUOTPF disk(*ext)
                       usage(*update)
                       keyed
                       usropn;

       // ============================================================
       // Copy in data structures (copybooks)
       // ============================================================
       /copy qcpysrc,VALIDATION
       /copy qcpysrc,QUOTE

       // ============================================================
       // Working Storage Variables
       // ============================================================
       dcl-s wsResponse        int(10);
       dcl-s wsValidationCount packed(2:0) inz(0);
       dcl-s wsErrorCount      packed(2:0) inz(0);
       dcl-s wsWarningCount    packed(2:0) inz(0);
       dcl-s wsScore           packed(3:0) inz(100);
       dcl-s wsCommArea        char(100);
       dcl-s wsCurrentDate     char(8);
       dcl-s wsFound           ind;

       // ============================================================
       // Program Entry Parameter (equivalent to DFHCOMMAREA)
       // ============================================================
       dcl-pi Main;
         piCommArea char(100);
       end-pi;

       // ============================================================
       // Main Procedure
       // ============================================================

         // Open file
         open AXAQUOTPF;

         // Get quote ID from parameter (like DFHCOMMAREA)
         quoteId = %subst(piCommArea:1:10);

         // Perform validation steps
         ReadQuoteData();

         if wsFound;
           ValidateQuoteFields();
           ValidateBusinessRules();
           CalculateQuoteScore();
           UpdateValidationStatus();
         endif;

         // Close file
         close AXAQUOTPF;

         // Return (equivalent to EXEC CICS RETURN)
         return;

       // ============================================================
       // ReadQuoteData - Read quote record from database
       // (Equivalent to CICS READ DATASET)
       // ============================================================
       dcl-proc ReadQuoteData;

         chain quoteId AXAQUOTPF quoteRecord;

         if %found(AXAQUOTPF);
           wsFound = *on;
         else;
           wsFound = *off;
         endif;

       end-proc;

       // ============================================================
       // ValidateQuoteFields - Validate individual quote fields
       // ============================================================
       dcl-proc ValidateQuoteFields;

         // Get current date in YYYYMMDD format
         wsCurrentDate = %char(%date():*iso0);

         // Validate quote amount is not zero
         if quoteAmount = 0;
           wsErrorCount += 1;
           wsScore -= 20;
         endif;

         // Validate quote expiry date is not in the past
         if quoteExpiryDate < wsCurrentDate;
           wsErrorCount += 1;
           wsScore -= 30;
         endif;

         // Validate carrier name is not blank
         if carrierName = *blanks;
           wsErrorCount += 1;
           wsScore -= 15;
         endif;

         // Validate limit is not zero
         if limit = 0;
           wsErrorCount += 1;
           wsScore -= 25;
         endif;

       end-proc;

       // ============================================================
       // ValidateBusinessRules - Validate business rules
       // ============================================================
       dcl-proc ValidateBusinessRules;

         // Rule 1: Total premium should not exceed 15% of limit
         if totalPremium > (limit * 0.15);
           wsWarningCount += 1;
           wsScore -= 10;
         endif;

         // Rule 2: Quoted capacity should not exceed 100%
         if quotedCapacity > 100;
           wsErrorCount += 1;
           wsScore -= 20;
         endif;

         // Rule 3: Attach point should not exceed 50% of limit
         if attachPoint > (limit * 0.50);
           wsWarningCount += 1;
           wsScore -= 5;
         endif;

       end-proc;

       // ============================================================
       // CalculateQuoteScore - Calculate final validation score
       // ============================================================
       dcl-proc CalculateQuoteScore;

         // Ensure score doesn't go negative
         if wsScore < 0;
           wsScore = 0;
         endif;

         // Update quote record with calculated score
         quoteScore = wsScore;

       end-proc;

       // ============================================================
       // UpdateValidationStatus - Update validation status and save
       // (Equivalent to CICS REWRITE)
       // ============================================================
       dcl-proc UpdateValidationStatus;

         // Set error and warning counts in record
         errorCount = wsErrorCount;
         warningCount = wsWarningCount;

         // Determine validation status based on error/warning counts
         select;
           when wsErrorCount = 0 and wsWarningCount = 0;
             validationStatus = 'VALID';

           when wsErrorCount = 0 and wsWarningCount > 0;
             validationStatus = 'VALID-WARNINGS';

           other;
             validationStatus = 'INVALID';
         endsl;

         // Update the record in the database (equivalent to CICS REWRITE)
         update AXAQUOTPF quoteRecord;

       end-proc;
