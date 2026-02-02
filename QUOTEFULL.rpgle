      // ****************************************************************
      // QUOTEFULL - Comprehensive Quote View (RPGLE equivalent)
      // Converts CICS BMS program to native RPG with display file
      // ****************************************************************
      Ctl-Opt DftActGrp(*No) ActGrp(*Caller);

      // Display file for screen (replaces BMS QUOTEFULL/FULLMAP)
      Dcl-F QUOTEFULLD Workstn InfDs(DspInfDs);

      // Submission file (replaces CICS DATASET 'AXASUBM')
      Dcl-F AXASUBM Disk(*Ext) Keyed Usage(*Input);

      // Copybooks
      /Copy QUOTE
      /Copy SUBMISSN

      // File information data structure for function key detection
      Dcl-Ds DspInfDs;
        FuncKey Char(1) Pos(369);
      End-Ds;

      // Function key constants (AID bytes)
      Dcl-C FK_ENTER  X'F1';
      Dcl-C FK_F2     X'32';
      Dcl-C FK_F3     X'33';
      Dcl-C FK_F4     X'34';
      Dcl-C FK_F12    X'3C';

      // Working storage
      Dcl-S wsResponse       Int(10) Inz(0);
      Dcl-S wsSubmissionKey  Char(10);
      Dcl-S wsQuoteCount     Packed(2:0) Inz(0);
      Dcl-S wsApiCount       Packed(2:0) Inz(0);
      Dcl-S wsEmailCount     Packed(2:0) Inz(0);
      Dcl-S wsWsCount        Packed(2:0) Inz(0);
      Dcl-S wsCompareCount   Packed(2:0) Inz(0);
      Dcl-S dfhcommarea      Char(100);
      Dcl-S exitProgram      Ind Inz(*Off);
      Dcl-S idx              Int(5);

      // Quote table entry structure
      Dcl-Ds QuoteEntry Qualified Dim(3);
        QuoteId          Char(10);
        RfqId            Char(10);
        CarrierName      Char(30);
        Description      Char(50);
        AttachPoint      Packed(14:2);
        Limit            Packed(17:2);
        TotalPremium     Packed(14:2);
        QuotedCapacity   Packed(5:2);
        Premium          Packed(14:2);
        QuoteExpiry      Char(10);
        UwSubmission     Char(15);
        Distribution     Char(15);
        CompareFlag      Char(1);
      End-Ds;

      // Submission record instance
      Dcl-Ds subRec LikeDs(SubmissionRecord);

      // Screen field variables (from display file)
      // Output fields - Quote 1
      Dcl-S RFQID1O      Char(10);
      Dcl-S CARRIER1O    Char(8);
      Dcl-S DESC1O       Char(11);
      Dcl-S ATTACH1O     Packed(14:2);
      Dcl-S LIMIT1O      Packed(17:2);
      Dcl-S PREM1O       Packed(14:2);
      Dcl-S CAPAC1O      Packed(5:2);
      Dcl-S EXPIRY1O     Char(5);
      Dcl-S UWREF1O      Char(8);
      // Output fields - Quote 2
      Dcl-S RFQID2O      Char(10);
      Dcl-S CARRIER2O    Char(8);
      Dcl-S DESC2O       Char(11);
      Dcl-S ATTACH2O     Packed(14:2);
      Dcl-S LIMIT2O      Packed(17:2);
      Dcl-S PREM2O       Packed(14:2);
      Dcl-S CAPAC2O      Packed(5:2);
      Dcl-S EXPIRY2O     Char(5);
      Dcl-S UWREF2O      Char(8);
      // Output fields - Quote 3
      Dcl-S RFQID3O      Char(10);
      Dcl-S CARRIER3O    Char(8);
      Dcl-S DESC3O       Char(11);
      Dcl-S ATTACH3O     Packed(14:2);
      Dcl-S LIMIT3O      Packed(17:2);
      Dcl-S PREM3O       Packed(14:2);
      Dcl-S CAPAC3O      Packed(5:2);
      Dcl-S EXPIRY3O     Char(5);
      Dcl-S UWREF3O      Char(8);
      // Distribution counts and status
      Dcl-S APICOUNTI    Packed(2:0);
      Dcl-S EMAILCNTI    Packed(2:0);
      Dcl-S WSCNTI       Packed(2:0);
      Dcl-S DASHSTS2O    Char(80);
      // Input fields - comparison flags
      Dcl-S CMP1I        Char(1);
      Dcl-S CMP2I        Char(1);
      Dcl-S CMP3I        Char(1);

      // Entry point with commarea parameter
      Dcl-Pi *N ExtPgm('QUOTEFULL');
        commarea Char(100);
      End-Pi;

      dfhcommarea = commarea;
      wsSubmissionKey = %Subst(dfhcommarea:1:10);

      ReadSubmissionData();
      LoadComprehensiveQuotes();
      CountDistributionTypes();

      // Main processing loop
      DoW Not exitProgram;
        SendMap();
        Exfmt FULLMAP;
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
        // If not found, subRec will be empty - handle in SendMap
      End-Proc ReadSubmissionData;

      // ****************************************************************
      // LOAD-COMPREHENSIVE-QUOTES - Load demo quote data
      // ****************************************************************
      Dcl-Proc LoadComprehensiveQuotes;
        Dcl-Pi *N End-Pi;

        wsQuoteCount = 3;

        // Quote 1 - LLOYDS via API
        QuoteEntry(1).QuoteId = 'QTE001';
        QuoteEntry(1).RfqId = 'RFQ001';
        QuoteEntry(1).CarrierName = 'LLOYDS';
        QuoteEntry(1).Description = 'PROPERTY INSURANCE';
        QuoteEntry(1).AttachPoint = 50000.00;
        QuoteEntry(1).Limit = 1000000.00;
        QuoteEntry(1).TotalPremium = 125000.00;
        QuoteEntry(1).QuotedCapacity = 100.00;
        QuoteEntry(1).Premium = 125000.00;
        QuoteEntry(1).QuoteExpiry = '2024-02-15';
        QuoteEntry(1).UwSubmission = 'UW2024001';
        QuoteEntry(1).Distribution = 'API';
        QuoteEntry(1).CompareFlag = *Blanks;

        // Quote 2 - ZURICH via WHITESPACE
        QuoteEntry(2).QuoteId = 'QTE002';
        QuoteEntry(2).RfqId = 'RFQ002';
        QuoteEntry(2).CarrierName = 'ZURICH';
        QuoteEntry(2).Description = 'LIABILITY COVER';
        QuoteEntry(2).AttachPoint = 75000.00;
        QuoteEntry(2).Limit = 1500000.00;
        QuoteEntry(2).TotalPremium = 135000.00;
        QuoteEntry(2).QuotedCapacity = 80.00;
        QuoteEntry(2).Premium = 135000.00;
        QuoteEntry(2).QuoteExpiry = '2024-02-16';
        QuoteEntry(2).UwSubmission = 'WS2024002';
        QuoteEntry(2).Distribution = 'WHITESPACE';
        QuoteEntry(2).CompareFlag = *Blanks;

        // Quote 3 - ALLIANZ via EMAIL
        QuoteEntry(3).QuoteId = 'QTE003';
        QuoteEntry(3).RfqId = 'RFQ003';
        QuoteEntry(3).CarrierName = 'ALLIANZ';
        QuoteEntry(3).Description = 'MARINE INSURANCE';
        QuoteEntry(3).AttachPoint = 25000.00;
        QuoteEntry(3).Limit = 2000000.00;
        QuoteEntry(3).TotalPremium = 118000.00;
        QuoteEntry(3).QuotedCapacity = 90.00;
        QuoteEntry(3).Premium = 118000.00;
        QuoteEntry(3).QuoteExpiry = '2024-02-17';
        QuoteEntry(3).UwSubmission = *Blanks;
        QuoteEntry(3).Distribution = 'EMAIL';
        QuoteEntry(3).CompareFlag = *Blanks;
      End-Proc LoadComprehensiveQuotes;

      // ****************************************************************
      // COUNT-DISTRIBUTION-TYPES - Count quotes by distribution method
      // ****************************************************************
      Dcl-Proc CountDistributionTypes;
        Dcl-Pi *N End-Pi;

        wsApiCount = 0;
        wsEmailCount = 0;
        wsWsCount = 0;

        For idx = 1 To wsQuoteCount;
          Select;
            When QuoteEntry(idx).Distribution = 'API';
              wsApiCount += 1;
            When QuoteEntry(idx).Distribution = 'EMAIL';
              wsEmailCount += 1;
            When QuoteEntry(idx).Distribution = 'WHITESPACE';
              wsWsCount += 1;
          EndSl;
        EndFor;
      End-Proc CountDistributionTypes;

      // ****************************************************************
      // PROCESS-FUNCTION-KEY - Handle function key input
      // ****************************************************************
      Dcl-Proc ProcessFunctionKey;
        Dcl-Pi *N End-Pi;

        Select;
          When FuncKey = FK_ENTER;
            CompareQuotes();
          When FuncKey = FK_F2;
            SimpleView();
          When FuncKey = FK_F3;
            ReturnSubmission();
          When FuncKey = FK_F4;
            BindRequest();
          When FuncKey = FK_F12;
            // Refresh - loop will re-send map
        EndSl;
      End-Proc ProcessFunctionKey;

      // ****************************************************************
      // COMPARE-QUOTES - Process comparison flags and transfer
      // ****************************************************************
      Dcl-Proc CompareQuotes;
        Dcl-Pi *N End-Pi;

        ProcessCompareFlags();

        If wsCompareCount > 1;
          %Subst(dfhcommarea:1:10) = subRec.SubmissionId;
          CallP QUOTECOMP(dfhcommarea);
          exitProgram = *On;
        EndIf;
        // Else stays in loop, re-sends map
      End-Proc CompareQuotes;

      // ****************************************************************
      // PROCESS-COMPARE-FLAGS - Count selected quotes for comparison
      // ****************************************************************
      Dcl-Proc ProcessCompareFlags;
        Dcl-Pi *N End-Pi;

        wsCompareCount = 0;

        If CMP1I = 'X';
          QuoteEntry(1).CompareFlag = 'X';
          wsCompareCount += 1;
        EndIf;

        If CMP2I = 'X';
          QuoteEntry(2).CompareFlag = 'X';
          wsCompareCount += 1;
        EndIf;

        If CMP3I = 'X';
          QuoteEntry(3).CompareFlag = 'X';
          wsCompareCount += 1;
        EndIf;
      End-Proc ProcessCompareFlags;

      // ****************************************************************
      // BIND-REQUEST - Transfer to bind request (F4)
      // ****************************************************************
      Dcl-Proc BindRequest;
        Dcl-Pi *N End-Pi;

        %Subst(dfhcommarea:1:10) = subRec.SubmissionId;
        CallP BINDREQ(dfhcommarea);
        exitProgram = *On;
      End-Proc BindRequest;

      // ****************************************************************
      // SIMPLE-VIEW - Transfer to simple quote dashboard (F2)
      // ****************************************************************
      Dcl-Proc SimpleView;
        Dcl-Pi *N End-Pi;

        %Subst(dfhcommarea:1:10) = subRec.SubmissionId;
        CallP QUOTEDASH(dfhcommarea);
        exitProgram = *On;
      End-Proc SimpleView;

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
      // SEND-MAP - Populate and display screen
      // ****************************************************************
      Dcl-Proc SendMap;
        Dcl-Pi *N End-Pi;

        Dcl-S statusMsg Char(80);

        // Quote 1
        RFQID1O = QuoteEntry(1).RfqId;
        CARRIER1O = %Subst(QuoteEntry(1).CarrierName:1:8);
        DESC1O = %Subst(QuoteEntry(1).Description:1:11);
        ATTACH1O = QuoteEntry(1).AttachPoint;
        LIMIT1O = QuoteEntry(1).Limit;
        PREM1O = QuoteEntry(1).Premium;
        CAPAC1O = QuoteEntry(1).QuotedCapacity;
        EXPIRY1O = %Subst(QuoteEntry(1).QuoteExpiry:6:5);
        UWREF1O = %Subst(QuoteEntry(1).UwSubmission:1:8);

        // Quote 2
        RFQID2O = QuoteEntry(2).RfqId;
        CARRIER2O = %Subst(QuoteEntry(2).CarrierName:1:8);
        DESC2O = %Subst(QuoteEntry(2).Description:1:11);
        ATTACH2O = QuoteEntry(2).AttachPoint;
        LIMIT2O = QuoteEntry(2).Limit;
        PREM2O = QuoteEntry(2).Premium;
        CAPAC2O = QuoteEntry(2).QuotedCapacity;
        EXPIRY2O = %Subst(QuoteEntry(2).QuoteExpiry:6:5);
        UWREF2O = %Subst(QuoteEntry(2).UwSubmission:1:8);

        // Quote 3
        RFQID3O = QuoteEntry(3).RfqId;
        CARRIER3O = %Subst(QuoteEntry(3).CarrierName:1:8);
        DESC3O = %Subst(QuoteEntry(3).Description:1:11);
        ATTACH3O = QuoteEntry(3).AttachPoint;
        LIMIT3O = QuoteEntry(3).Limit;
        PREM3O = QuoteEntry(3).Premium;
        CAPAC3O = QuoteEntry(3).QuotedCapacity;
        EXPIRY3O = %Subst(QuoteEntry(3).QuoteExpiry:6:5);
        UWREF3O = %Subst(QuoteEntry(3).UwSubmission:1:8);

        // Distribution counts
        APICOUNTI = wsApiCount;
        EMAILCNTI = wsEmailCount;
        WSCNTI = wsWsCount;

        // Status message
        statusMsg = 'QUOTES LOADED: ' + %Char(wsQuoteCount) +
                    ' SELECTED FOR COMPARISON: ' + %Char(wsCompareCount);
        DASHSTS2O = statusMsg;
      End-Proc SendMap;
