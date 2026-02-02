**FREE
ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXAEMAILCFG usage(*input)  keyed;
dcl-f AXAQUOTE    usage(*output) keyed;

/*----------------------------------------------------------------*/
/* Copy books (externally described DS)                            */
/*----------------------------------------------------------------*/
 /copy EMAIL-CONFIG
 /copy EMAILQUOTE
 /copy QUOTE

/*----------------------------------------------------------------*/
/* Program parameter (DFHCOMMAREA equivalent)                      */
/*----------------------------------------------------------------*/
dcl-pi *n;
   pCommArea char(100);
end-pi;

/*----------------------------------------------------------------*/
/* Working storage                                                */
/*----------------------------------------------------------------*/
dcl-s wsEmailCount     int(5) inz(0);
dcl-s wsProcessedCnt  int(5) inz(0);
dcl-s wsErrorCount    int(5) inz(0);
dcl-s wsQuoteExtract  int(5) inz(0);

/*----------------------------------------------------------------*/
/* Main processing                                                */
/*----------------------------------------------------------------*/
readEmailConfig();
connectEmailServer();
processIncomingEmails();
updateEmailMetrics();

return;

/*----------------------------------------------------------------*/
/* Read email configuration                                      */
/*----------------------------------------------------------------*/
dcl-proc readEmailConfig;

   Config_Id = 'EMAIL001';
   chain Config_Id AXAEMAILCFG;

end-proc;

/*----------------------------------------------------------------*/
/* Connect to email server (status only)                          */
/*----------------------------------------------------------------*/
dcl-proc connectEmailServer;

   Processing_Status =
      'CONNECTING TO ' + Email_Server + ':' + %char(Server_Port);

end-proc;

/*----------------------------------------------------------------*/
/* Process incoming emails                                       */
/*----------------------------------------------------------------*/
dcl-proc processIncomingEmails;

   retrieveEmails();
   parseEmailContent();
   extractQuoteData();
   storeExtractedQuotes();

end-proc;

/*----------------------------------------------------------------*/
/* Retrieve emails (simulated)                                    */
/*----------------------------------------------------------------*/
dcl-proc retrieveEmails;

   Email_Id        = 'EMAIL001';
   From_Address    = 'quotes@lloyds.com';
   To_Address      = 'broker@axa.com';
   Email_Subject   = 'Quote Response - RFQ001';
   Email_Date      = %subst(%char(%date()):1:8);
   Email_Time      = %subst(%char(%time()):1:6);
   Attachment_Count= 1;

   Processing_Status = 'RETRIEVED';
   wsEmailCount += 1;

end-proc;

/*----------------------------------------------------------------*/
/* Parse email content                                            */
/*----------------------------------------------------------------*/
dcl-proc parseEmailContent;

   if %scan('QUOTE': Email_Subject) > 0
      or %scan('RFQ': Email_Subject) > 0;

      Processing_Status = 'QUOTE-EMAIL';
      extractRfqReference();

   else;

      Processing_Status = 'NON-QUOTE-EMAIL';

   endif;

end-proc;

/*----------------------------------------------------------------*/
/* Extract RFQ reference                                         */
/*----------------------------------------------------------------*/
dcl-proc extractRfqReference;

   if %scan('RFQ001': Email_Subject) > 0;
      %subst(Extracted_Data:1:6) = 'RFQ001';
   endif;

   if %scan('RFQ002': Email_Subject) > 0;
      %subst(Extracted_Data:1:6) = 'RFQ002';
   endif;

   if %scan('RFQ003': Email_Subject) > 0;
      %subst(Extracted_Data:1:6) = 'RFQ003';
   endif;

end-proc;

/*----------------------------------------------------------------*/
/* Extract quote data                                             */
/*----------------------------------------------------------------*/
dcl-proc extractQuoteData;

   Extracted_Data =
      'QUOTE:125000|CARRIER:LLOYDS|STATUS:QUOTED';

   wsQuoteExtract += 1;

end-proc;

/*----------------------------------------------------------------*/
/* Store extracted quotes                                        */
/*----------------------------------------------------------------*/
dcl-proc storeExtractedQuotes;

   Quote_Id        = 'QTE001';
   Rfq_Id          = %subst(Extracted_Data:1:6);
   Carrier_Name    = 'LLOYDS OF LONDON';
   Response_Status = 'QUOTED';
   Quote_Amount    = 125000.00;
   Quote_Status    = 'EMAIL-EXTRACTED';
   Quote_Date      = %subst(%char(%date()):1:8);

   write AXAQUOTE;

   wsProcessedCnt += 1;

end-proc;

/*----------------------------------------------------------------*/
/* Update email metrics                                          */
/*----------------------------------------------------------------*/
dcl-proc updateEmailMetrics;

   Email_Count         = wsEmailCount;
   Response_Count      = wsProcessedCnt;
   Quote_Extracted     = wsQuoteExtract;
   Processing_Errors   = wsErrorCount;
   Metric_Date         = %subst(%char(%date()):1:8);
   Metric_Status       = 'COMPLETED';

end-proc;
