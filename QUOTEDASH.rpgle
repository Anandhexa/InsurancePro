      // ****************************************************************
      // QUOTEDASH - Quote Dashboard (RPGLE equivalent of QUOTEDASH.cbl)
      // Converts CICS BMS program to native RPG with display file
      // ****************************************************************
      Ctl-Opt DftActGrp(*No) ActGrp(*Caller);

      // Display file for screen (replaces BMS QUOTEDASH/QUOTEMP)
      Dcl-F QUOTEDASHD Workstn InfDs(DspInfDs);

      // Submission file (replaces CICS DATASET 'AXASUBM')
      Dcl-F AXASUBM Disk(*Ext) Keyed Usage(*Input);

      // Quote file (replaces CICS DATASET 'AXAQUOTE')
      Dcl-F AXAQUOTE Disk(*Ext) Keyed Usage(*Input);

      // Copybooks
      /Copy QUOTE
      /Copy SUBMISSN

      // File information data structure for function key detection
      Dcl-Ds DspInfDs;
        FuncKey Char(1) Pos(369);
      End-Ds;

      // Function key constants (AID bytes)
      Dcl-C FK_ENTER  X'F1';
      Dcl-C FK_F1     X'31';
      Dcl-C FK_F2     X'32';
      Dcl-C FK_F3     X'33';
      Dcl-C FK_F4     X'34';
      Dcl-C FK_F5     X'35';
      Dcl-C FK_F6     X'36';
      Dcl-C FK_F7     X'37';
      Dcl-C FK_F12    X'3C';

      // Working storage
      Dcl-S wsResponse       Int(10) Inz(0);
      Dcl-S wsSubmissionKey  Char(10);
      Dcl-S wsQuoteCount     Packed(2:0) Inz(0);
      Dcl-S wsProcessedCount Packed(2:0) Inz(0);
      Dcl-S dfhcommarea      Char(100);
      Dcl-S exitProgram      Ind Inz(*Off);
      Dcl-S idx              Int(5);

      // Quote table entry structure
      Dcl-Ds QuoteEntry Qualified Dim(3);
        QuoteId          Char(10);
        RfqId            Char(10);
        CarrierName      Char(30);
        ResponseStatus   Char(20);
        Action           Char(20);
        QuoteDate        Char(10);
      End-Ds;

      // Submission record instance
      Dcl-Ds subRec LikeDs(SubmissionRecord);

      // Quote record instance
      Dcl-Ds qteRec LikeDs(QuoteRecord);

      // Screen field variables (from display file)
      // Output fields - Quote 1
      Dcl-S QUOTEID1O    Char(10);
      Dcl-S RFQID1O      Char(10);
      Dcl-S CARRIER1O    Char(30);
      Dcl-S RESPSTS1O    Char(20);
      Dcl-S QDATE1O      Char(10);
      // Output fields - Quote 2
      Dcl-S QUOTEID2O    Char(10);
      Dcl-S RFQID2O      Char(10);
      Dcl-S CARRIER2O    Char(30);
      Dcl-S RESPSTS2O    Char(20);
      Dcl-S QDATE2O      Char(10);
      // Output fields - Quote 3
      Dcl-S QUOTEID3O    Char(10);
      Dcl-S RFQID3O      Char(10);
      Dcl-S CARRIER3O    Char(30);
      Dcl-S RESPSTS3O    Char(20);
      Dcl-S QDATE3O      Char(10);
      // Status field
      Dcl-S DASHSTSO     Char(80);
      // Input fields - action codes
      Dcl-S ACTION1I     Char(1);
      Dcl-S ACTION2I     Char(1);
      Dcl-S ACTION3I     Char(1);

      // Entry point with commarea parameter
      Dcl-Pi *N ExtPgm('QUOTEDASH');
        commarea Char(100);
      End-Pi;

      dfhcommarea = commarea;
      wsSubmissionKey = %Subst(dfhcommarea:1:10);

      ReadSubmissionData();
      LoadSampleQuotes();

      // Main processing loop
      DoW Not exitProgram;
        SendMap();
        Exfmt QUOTEMP;
        ProcessFunctionKey();
      EndDo;

      commarea = dfhcommarea;
      *InLR = *On;
      Return;

      // ****************************************************************
      // READ-SUBMISSION-DATA - Read submission record
      // ****************************************************************
      Dcl-Proc ReadSubmissionData;
        Dcl-Pi *N End-Pi;

        Chain wsSubmissionKey AXASUBM subRec;
        // If not found, subRec will be empty
      End-Proc ReadSubmissionData;

      // ****************************************************************
      // LOAD-SAMPLE-QUOTES - Load quotes from file or defaults
      // ****************************************************************
      Dcl-Proc LoadSampleQuotes;
        Dcl-Pi *N End-Pi;

        ReadExtractedQuotes();

        If wsQuoteCount = 0;
          LoadDefaultQuotes();
        EndIf;
      End-Proc LoadSampleQuotes;

      // ****************************************************************
      // READ-EXTRACTED-QUOTES - Read quotes from AXAQUOTE file
      // Replaces CICS STARTBR/READNEXT/ENDBR browse logic
      // ****************************************************************
      Dcl-Proc ReadExtractedQuotes;
        Dcl-Pi *N End-Pi;

        wsQuoteCount = 0;

        // Position to first quote for this submission
        SetLL subRec.SubmissionId AXAQUOTE;

        // Read up to 3 quotes
        DoW wsQuoteCount < 3;
          Read AXAQUOTE qteRec;
          If %Eof(AXAQUOTE);
            Leave;
          EndIf;

          // Check if quote belongs to this submission
          If qteRec.SubmissionId = subRec.SubmissionId;
            wsQuoteCount += 1;
            QuoteEntry(wsQuoteCount).QuoteId = qteRec.QuoteId;
            QuoteEntry(wsQuoteCount).RfqId = qteRec.RfqId;
            QuoteEntry(wsQuoteCount).CarrierName = qteRec.CarrierName;
            QuoteEntry(wsQuoteCount).ResponseStatus = qteRec.ResponseStatus;
            QuoteEntry(wsQuoteCount).Action = qteRec.Action;
            QuoteEntry(wsQuoteCount).QuoteDate = qteRec.QuoteDate;
          Else;
            // Past our submission's quotes
            Leave;
          EndIf;
        EndDo;
      End-Proc ReadExtractedQuotes;

      // ****************************************************************
      // LOAD-DEFAULT-QUOTES - Load demo quote data
      // ****************************************************************
      Dcl-Proc LoadDefaultQuotes;
        Dcl-Pi *N End-Pi;

        wsQuoteCount = 3;

        // Quote 1 - LLOYDS
        QuoteEntry(1).QuoteId = 'QTE001';
        QuoteEntry(1).RfqId = 'RFQ001';
        QuoteEntry(1).CarrierName = 'LLOYDS';
        QuoteEntry(1).ResponseStatus = 'QUOTED';
        QuoteEntry(1).Action = *Blanks;
        QuoteEntry(1).QuoteDate = '2024-01-15';

        // Quote 2 - ZURICH
        QuoteEntry(2).QuoteId = 'QTE002';
        QuoteEntry(2).RfqId = 'RFQ002';
        QuoteEntry(2).CarrierName = 'ZURICH';
        QuoteEntry(2).ResponseStatus = 'PENDING FOR REVIEW';
        QuoteEntry(2).Action = *Blanks;
        QuoteEntry(2).QuoteDate = '2024-01-14';

        // Quote 3 - ALLIANZ
        QuoteEntry(3).QuoteId = 'QTE003';
        QuoteEntry(3).RfqId = 'RFQ003';
        QuoteEntry(3).CarrierName = 'ALLIANZ';
        QuoteEntry(3).ResponseStatus = 'SUBMISSION-SENT';
        QuoteEntry(3).Action = *Blanks;
        QuoteEntry(3).QuoteDate = '2024-01-13';
      End-Proc LoadDefaultQuotes;

      // ****************************************************************
      // PROCESS-FUNCTION-KEY - Handle function key input
      // ****************************************************************
      Dcl-Proc ProcessFunctionKey;
        Dcl-Pi *N End-Pi;

        Select;
          When FuncKey = FK_ENTER;
            ProcessActions();
          When FuncKey = FK_F1;
            FullDashboard();
          When FuncKey = FK_F2;
            EmailMonitor();
          When FuncKey = FK_F3;
            ReturnSubmission();
          When FuncKey = FK_F4;
            PricingEngine();
          When FuncKey = FK_F5;
            QuoteValidation();
          When FuncKey = FK_F6;
            PolicyAdmin();
          When FuncKey = FK_F7;
            AnalyticsDashboard();
          When FuncKey = FK_F12;
            // Refresh - loop will re-send map
        EndSl;
      End-Proc ProcessFunctionKey;

      // ****************************************************************
      // PROCESS-ACTIONS - Process user action entries
      // ****************************************************************
      Dcl-Proc ProcessActions;
        Dcl-Pi *N End-Pi;

        ProcessActionEntries();
        // SendMap will be called by main loop
      End-Proc ProcessActions;

      // ****************************************************************
      // PROCESS-ACTION-ENTRIES - Handle D=Decline, U=Upload actions
      // ****************************************************************
      Dcl-Proc ProcessActionEntries;
        Dcl-Pi *N End-Pi;

        // Process action for Quote 1
        If ACTION1I = 'D' Or ACTION1I = 'U';
          wsProcessedCount += 1;
          If ACTION1I = 'D';
            QuoteEntry(1).Action = 'DECLINED';
          Else;
            QuoteEntry(1).Action = 'UPLOAD QUOTE';
          EndIf;
        EndIf;

        // Process action for Quote 2
        If ACTION2I = 'D' Or ACTION2I = 'U';
          wsProcessedCount += 1;
          If ACTION2I = 'D';
            QuoteEntry(2).Action = 'DECLINED';
          Else;
            QuoteEntry(2).Action = 'UPLOAD QUOTE';
          EndIf;
        EndIf;

        // Process action for Quote 3
        If ACTION3I = 'D' Or ACTION3I = 'U';
          wsProcessedCount += 1;
          If ACTION3I = 'D';
            QuoteEntry(3).Action = 'DECLINED';
          Else;
            QuoteEntry(3).Action = 'UPLOAD QUOTE';
          EndIf;
        EndIf;
      End-Proc ProcessActionEntries;

      // ****************************************************************
      // FULL-DASHBOARD - Transfer to full quote view (F1)
      // ****************************************************************
      Dcl-Proc FullDashboard;
        Dcl-Pi *N End-Pi;

        %Subst(dfhcommarea:1:10) = subRec.SubmissionId;
        CallP QUOTEFULL(dfhcommarea);
        exitProgram = *On;
      End-Proc FullDashboard;

      // ****************************************************************
      // EMAIL-MONITOR - Transfer to email monitor (F2)
      // ****************************************************************
      Dcl-Proc EmailMonitor;
        Dcl-Pi *N End-Pi;

        CallP EMAILMON(dfhcommarea);
        exitProgram = *On;
      End-Proc EmailMonitor;

      // ****************************************************************
      // RETURN-SUBMISSION - Return to submission screen (F3)
      // ****************************************************************
      Dcl-Proc ReturnSubmission;
        Dcl-Pi *N End-Pi;

        %Subst(dfhcommarea:1:10) = subRec.SubmissionId;
        CallP SUBMISSN(dfhcommarea);
        exitProgram = *On;
      End-Proc ReturnSubmission;

      // ****************************************************************
      // PRICING-ENGINE - Call pricing engine (F4) - LINK equivalent
      // ****************************************************************
      Dcl-Proc PricingEngine;
        Dcl-Pi *N End-Pi;

        %Subst(dfhcommarea:1:10) = QuoteEntry(1).QuoteId;
        CallP PRICEENG(dfhcommarea);
        // Returns here - reload and refresh
        LoadSampleQuotes();
      End-Proc PricingEngine;

      // ****************************************************************
      // QUOTE-VALIDATION - Call quote validation (F5) - LINK equivalent
      // ****************************************************************
      Dcl-Proc QuoteValidation;
        Dcl-Pi *N End-Pi;

        %Subst(dfhcommarea:1:10) = QuoteEntry(1).QuoteId;
        CallP QUOTEVALID(dfhcommarea);
        // Returns here - reload and refresh
        LoadSampleQuotes();
      End-Proc QuoteValidation;

      // ****************************************************************
      // POLICY-ADMIN - Transfer to policy admin (F6)
      // ****************************************************************
      Dcl-Proc PolicyAdmin;
        Dcl-Pi *N End-Pi;

        %Subst(dfhcommarea:1:10) = QuoteEntry(1).QuoteId;
        CallP POLICY(dfhcommarea);
        exitProgram = *On;
      End-Proc PolicyAdmin;

      // ****************************************************************
      // ANALYTICS-DASHBOARD - Transfer to analytics (F7)
      // ****************************************************************
      Dcl-Proc AnalyticsDashboard;
        Dcl-Pi *N End-Pi;

        CallP ANALYTICS(dfhcommarea);
        exitProgram = *On;
      End-Proc AnalyticsDashboard;

      // ****************************************************************
      // SEND-MAP - Populate and display screen
      // ****************************************************************
      Dcl-Proc SendMap;
        Dcl-Pi *N End-Pi;

        Dcl-S statusMsg Char(80);

        // Quote 1
        QUOTEID1O = QuoteEntry(1).QuoteId;
        RFQID1O = QuoteEntry(1).RfqId;
        CARRIER1O = QuoteEntry(1).CarrierName;
        RESPSTS1O = QuoteEntry(1).ResponseStatus;
        QDATE1O = QuoteEntry(1).QuoteDate;

        // Quote 2
        QUOTEID2O = QuoteEntry(2).QuoteId;
        RFQID2O = QuoteEntry(2).RfqId;
        CARRIER2O = QuoteEntry(2).CarrierName;
        RESPSTS2O = QuoteEntry(2).ResponseStatus;
        QDATE2O = QuoteEntry(2).QuoteDate;

        // Quote 3
        QUOTEID3O = QuoteEntry(3).QuoteId;
        RFQID3O = QuoteEntry(3).RfqId;
        CARRIER3O = QuoteEntry(3).CarrierName;
        RESPSTS3O = QuoteEntry(3).ResponseStatus;
        QDATE3O = QuoteEntry(3).QuoteDate;

        // Status message
        statusMsg = 'QUOTES LOADED: ' + %Char(wsQuoteCount) +
                    ' ACTIONS PROCESSED: ' + %Char(wsProcessedCount);
        DASHSTSO = statusMsg;
      End-Proc SendMap;
