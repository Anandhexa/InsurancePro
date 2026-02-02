      Ctl-Opt DftActGrp(*No) ActGrp(*Caller);

      // Display file for screen (replaces BMS QUOTECOMP/COMPMAP)
      Dcl-F QUOTECOMPD Workstn InfDs(DspInfDs);

      // Copybook
      /Copy QUOTE

      // File information data structure for function key detection
      Dcl-Ds DspInfDs;
        FuncKey Char(1) Pos(369);
      End-Ds;

      // Function key constants (AID bytes)
      Dcl-C FK_F3     X'33';
      Dcl-C FK_F12    X'3C';

      // Working storage
      Dcl-S wsResponse        Int(10) Inz(0);
      Dcl-S wsCompareCount    Packed(2:0) Inz(0);
      Dcl-S wsBestPremium     Packed(14:2) Inz(999999999999.99);
      Dcl-S wsBestCarrier     Char(30);
      Dcl-S wsHighestCapacity Packed(5:2) Inz(0);
      Dcl-S wsCapacityCarrier Char(30);
      Dcl-S wsLowestAttach    Packed(14:2) Inz(999999999999.99);
      Dcl-S wsAttachCarrier   Char(30);
      Dcl-S dfhcommarea       Char(100);
      Dcl-S exitProgram       Ind Inz(*Off);
      Dcl-S idx               Int(5);

      // Comparison table entry structure
      Dcl-Ds CompEntry Qualified Dim(3);
        QuoteId    Char(10);
        Carrier    Char(30);
        Limit      Packed(17:2);
        Attach     Packed(14:2);
        Premium    Packed(14:2);
        Capacity   Packed(5:2);
        Selected   Char(1);
      End-Ds;

      // Screen field variables (from display file)
      // Output fields - Quote 1
      Dcl-S CARR1O     Char(12);
      Dcl-S LIMIT1O    Packed(17:2);
      Dcl-S ATTACH1O   Packed(14:2);
      Dcl-S PREM1O     Packed(14:2);
      Dcl-S CAPAC1O    Char(10);
      // Output fields - Quote 2
      Dcl-S CARR2O     Char(12);
      Dcl-S LIMIT2O    Packed(17:2);
      Dcl-S ATTACH2O   Packed(14:2);
      Dcl-S PREM2O     Packed(14:2);
      Dcl-S CAPAC2O    Char(10);
      // Output fields - Quote 3
      Dcl-S CARR3O     Char(12);
      Dcl-S LIMIT3O    Packed(17:2);
      Dcl-S ATTACH3O   Packed(14:2);
      Dcl-S PREM3O     Packed(14:2);
      Dcl-S CAPAC3O    Char(10);
      // Analysis results
      Dcl-S BESTREMO   Char(20);
      Dcl-S BESTCAPO   Char(20);
      Dcl-S LOWATTACHO Char(20);
      Dcl-S COMPSTSO   Char(50);

      // Entry point with commarea parameter
      Dcl-Pi *N ExtPgm('QUOTECOMP');
        commarea Char(100);
      End-Pi;

      dfhcommarea = commarea;

      LoadSelectedQuotes();
      CalculateComparisonAnalysis();

      // Main processing loop
      DoW Not exitProgram;
        SendMap();
        Exfmt COMPMAP;
        ProcessFunctionKey();
      EndDo;

      commarea = dfhcommarea;
      *InLR = *On;
      Return;

      // ****************************************************************
      // LOAD-SELECTED-QUOTES - Load demo quotes for comparison
      // ****************************************************************
      Dcl-Proc LoadSelectedQuotes;
        Dcl-Pi *N End-Pi;

        wsCompareCount = 3;

        // Quote 1 - LLOYDS OF LONDON
        CompEntry(1).QuoteId = 'QTE001';
        CompEntry(1).Carrier = 'LLOYDS OF LONDON';
        CompEntry(1).Limit = 1000000.00;
        CompEntry(1).Attach = 50000.00;
        CompEntry(1).Premium = 125000.00;
        CompEntry(1).Capacity = 100.00;
        CompEntry(1).Selected = 'Y';

        // Quote 2 - ZURICH INSURANCE
        CompEntry(2).QuoteId = 'QTE002';
        CompEntry(2).Carrier = 'ZURICH INSURANCE';
        CompEntry(2).Limit = 1500000.00;
        CompEntry(2).Attach = 75000.00;
        CompEntry(2).Premium = 135000.00;
        CompEntry(2).Capacity = 80.00;
        CompEntry(2).Selected = 'Y';

        // Quote 3 - ALLIANZ GROUP
        CompEntry(3).QuoteId = 'QTE003';
        CompEntry(3).Carrier = 'ALLIANZ GROUP';
        CompEntry(3).Limit = 2000000.00;
        CompEntry(3).Attach = 25000.00;
        CompEntry(3).Premium = 118000.00;
        CompEntry(3).Capacity = 90.00;
        CompEntry(3).Selected = 'Y';
      End-Proc LoadSelectedQuotes;

      // ****************************************************************
      // CALCULATE-COMPARISON-ANALYSIS - Find best options
      // ****************************************************************
      Dcl-Proc CalculateComparisonAnalysis;
        Dcl-Pi *N End-Pi;

        For idx = 1 To wsCompareCount;
          If CompEntry(idx).Selected = 'Y';

            // Find lowest (best) premium
            If CompEntry(idx).Premium < wsBestPremium;
              wsBestPremium = CompEntry(idx).Premium;
              wsBestCarrier = CompEntry(idx).Carrier;
            EndIf;

            // Find highest capacity
            If CompEntry(idx).Capacity > wsHighestCapacity;
              wsHighestCapacity = CompEntry(idx).Capacity;
              wsCapacityCarrier = CompEntry(idx).Carrier;
            EndIf;

            // Find lowest attachment point
            If CompEntry(idx).Attach < wsLowestAttach;
              wsLowestAttach = CompEntry(idx).Attach;
              wsAttachCarrier = CompEntry(idx).Carrier;
            EndIf;

          EndIf;
        EndFor;
      End-Proc CalculateComparisonAnalysis;

      // ****************************************************************
      // PROCESS-FUNCTION-KEY - Handle function key input
      // ****************************************************************
      Dcl-Proc ProcessFunctionKey;
        Dcl-Pi *N End-Pi;

        Select;
          When FuncKey = FK_F3;
            ReturnDashboard();
          When FuncKey = FK_F12;
            // Refresh - loop will re-send map
        EndSl;
      End-Proc ProcessFunctionKey;

      // ****************************************************************
      // RETURN-DASHBOARD - Return to full quote dashboard (F3)
      // ****************************************************************
      Dcl-Proc ReturnDashboard;
        Dcl-Pi *N End-Pi;

        CallP QUOTEFULL(dfhcommarea);
        exitProgram = *On;
      End-Proc ReturnDashboard;

      // ****************************************************************
      // SEND-MAP - Populate and display comparison screen
      // ****************************************************************
      Dcl-Proc SendMap;
        Dcl-Pi *N End-Pi;

        // Quote 1
        CARR1O = %Subst(CompEntry(1).Carrier:1:12);
        LIMIT1O = CompEntry(1).Limit;
        ATTACH1O = CompEntry(1).Attach;
        PREM1O = CompEntry(1).Premium;
        CAPAC1O = %Char(CompEntry(1).Capacity) + '%';

        // Quote 2
        CARR2O = %Subst(CompEntry(2).Carrier:1:12);
        LIMIT2O = CompEntry(2).Limit;
        ATTACH2O = CompEntry(2).Attach;
        PREM2O = CompEntry(2).Premium;
        CAPAC2O = %Char(CompEntry(2).Capacity) + '%';

        // Quote 3
        CARR3O = %Subst(CompEntry(3).Carrier:1:12);
        LIMIT3O = CompEntry(3).Limit;
        ATTACH3O = CompEntry(3).Attach;
        PREM3O = CompEntry(3).Premium;
        CAPAC3O = %Char(CompEntry(3).Capacity) + '%';

        // Analysis results
        BESTREMO = %Subst(wsBestCarrier:1:20);
        BESTCAPO = %Subst(wsCapacityCarrier:1:20);
        LOWATTACHO = %Subst(wsAttachCarrier:1:20);

        // Status message
        COMPSTSO = 'COMPARING ' + %Char(wsCompareCount) +
                   ' QUOTES - ANALYSIS COMPLETE';
      End-Proc SendMap;

