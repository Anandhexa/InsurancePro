**FREE
/*********************************************************************/
/* Program : ANALYTICS                                                */
/* Purpose : Analytics / KPI Reporting                                */
/* Source  : Mainframe CICS COBOL migration                            */
/*********************************************************************/

ctl-opt dftactgrp(*no)
        actgrp('INSURANCE')
        option(*nodebugio : *srcstmt);

/*-------------------------------------------------------------------*/
/* Files                                                             */
/*-------------------------------------------------------------------*/
dcl-f AXASUBM      usage(*input)  keyed;
dcl-f AXAQUOTE     usage(*input)  keyed;
dcl-f AXABIND      usage(*input)  keyed;
dcl-f AXAANALYTICS usage(*output) keyed;
dcl-f ANALDSPF    workstn;

/*-------------------------------------------------------------------*/
/* Copybooks                                                         */
/*-------------------------------------------------------------------*/
 /copy QRPGLESRC,ANALYTICS
 /copy QRPGLESRC,QUOTE
 /copy QRPGLESRC,SUBMISSN
 /copy QRPGLESRC,BIND

/*-------------------------------------------------------------------*/
/* Working Storage                                                   */
/*-------------------------------------------------------------------*/
dcl-s wsResponse          int(10) inz(0);
dcl-s wsReportPeriod     char(8);

dcl-s wsSubmissionCount  packed(6:0) inz(0);
dcl-s wsQuoteCount       packed(6:0) inz(0);
dcl-s wsBindingCount     packed(5:0) inz(0);
dcl-s wsTotalPremium     packed(15:2) inz(0);
dcl-s wsTotalCommission  packed(12:2) inz(0);

/*-------------------------------------------------------------------*/
/* Main Processing                                                   */
/*-------------------------------------------------------------------*/
dou *inlr;

   exfmt ANALMAP;

   select;
      when *in03;
           monthlyReport();

      when *in02;
           weeklyReport();

      when *in01;
           dailyReport();

      when *in12;
           exfmt ANALMAP;

      other;
           exfmt ANALMAP;
   endsl;

enddo;

*inlr = *on;
return;

/*-------------------------------------------------------------------*/
/* Procedures                                                        */
/*-------------------------------------------------------------------*/
dcl-proc generateReport;

   resetCounters();

   countSubmissions();
   countQuotes();
   countBindings();
   calculateTotals();
   calculateKPIs();
   storeAnalytics();
   sendMap();

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc resetCounters;

   wsSubmissionCount = 0;
   wsQuoteCount      = 0;
   wsBindingCount    = 0;
   wsTotalPremium    = 0;
   wsTotalCommission = 0;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc countSubmissions;

   setll wsReportPeriod AXASUBM;
   read AXASUBM;

   dow not %eof(AXASUBM);

      if Submission_Date >= wsReportPeriod;
         wsSubmissionCount += 1;
      endif;

      read AXASUBM;
   enddo;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc countQuotes;

   setll wsReportPeriod AXAQUOTE;
   read AXAQUOTE;

   dow not %eof(AXAQUOTE);

      if Quote_Date >= wsReportPeriod;
         wsQuoteCount += 1;
         wsTotalPremium    += Total_Premium;
         wsTotalCommission += Commission_Amount;
      endif;

      read AXAQUOTE;
   enddo;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc countBindings;

   setll wsReportPeriod AXABIND;
   read AXABIND;

   dow not %eof(AXABIND);

      if Bind_Date >= wsReportPeriod
         and Bind_Status = 'BOUND';

         wsBindingCount += 1;
      endif;

      read AXABIND;
   enddo;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc calculateTotals;

   Total_Submissions  = wsSubmissionCount;
   Total_Quotes       = wsQuoteCount;
   Total_Bindings     = wsBindingCount;
   Total_Premium      = wsTotalPremium;
   Total_Commission   = wsTotalCommission;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc calculateKPIs;

   if wsQuoteCount > 0;
      Quote_To_Bind_Ratio =
         (wsBindingCount / wsQuoteCount) * 100;
   endif;

   if wsBindingCount > 0;
      Avg_Premium_Size =
         wsTotalPremium / wsBindingCount;
   endif;

   if wsSubmissionCount > 0;
      Conversion_Rate =
         (wsBindingCount / wsSubmissionCount) * 100;
   endif;

   Top_Carrier   = 'LLOYDS OF LONDON';
   Top_Product   = 'PROPERTY';
   Avg_Quote_Time = 24;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc storeAnalytics;

   Analytics_Id =
      'RPT' + %subst(%char(%timestamp()):9:6);

   Report_Type     = 'PERFORMANCE';
   Report_Period   = wsReportPeriod;
   Generated_Date  = %subst(%char(%date()):1:8);
   Generated_Time  = %subst(%char(%time()):1:6);

   write AXAANALYTICS;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc sendMap;

   TotSubMO  = Total_Submissions;
   TotQuoTO  = Total_Quotes;
   TotBindO  = Total_Bindings;
   TotPremO  = Total_Premium;
   ConvRatO  = Conversion_Rate;
   TopCarrO  = Top_Carrier;
   AvgQTimeO = Avg_Quote_Time;

   exfmt ANALMAP;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc dailyReport;

   wsReportPeriod = %char(%date());
   generateReport();

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc weeklyReport;

   wsReportPeriod =
      %char(%date() - %days(7));
   generateReport();

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc monthlyReport;

   wsReportPeriod =
      %char(%date() - %days(30));
   generateReport();

end-proc;
