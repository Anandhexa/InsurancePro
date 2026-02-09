**FREE
ctl-opt dftactgrp(*no)
        actgrp(*new)
        option(*srcstmt);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXAPOLICY usage(*input) keyed;
dcl-f AXAQUOTE  usage(*input) keyed;
dcl-f AXACLAIM  usage(*input) keyed;
dcl-f AXAPOLRPT printer;

/*----------------------------------------------------------------*/
/* Working storage                                                */
/*----------------------------------------------------------------*/
dcl-s eofPolicy ind inz(*off);

/*----------------------------------------------------------------*/
/* Headings                                                       */
/*----------------------------------------------------------------*/
H1TITLE = 'AXA POLICY / QUOTE / CLAIM DETAIL REPORT';
QTITLE  = 'QUOTE DETAILS';
CLTITLE = 'CLAIM DETAILS';
F1MSG   = '*** END OF REPORT ***';

/*----------------------------------------------------------------*/
/* Main processing                                                */
/*----------------------------------------------------------------*/
read AXAPOLICY;
dow not %eof(AXAPOLICY);

   /* Print Policy Section */
   PLBL = 'Policy ID:';
   PNBL = 'Policy No:';
   INSBL= 'Insured:';
   PTBL = 'Policy Type:';
   DATEBL = 'Inception:';
   EXPBL  = 'Expiry:';
   LIMBL  = 'Limit:';
   PREMBL = 'Premium:';

   write RPTHEADER;
   write POLICYR;

   /* Read Quote */
   chain POLICY.QUOTE_ID AXAQUOTE;
   if %found(AXAQUOTE);
      QIDLBL   = 'Quote ID:';
      CARRLBL  = 'Carrier:';
      QAMTLBL  = 'Quote Amt:';
      QSTATLBL = 'Status:';
      write QUOTER;
   endif;

   /* Claims for Policy */
   setll POLICY.POLICY_ID AXACLAIM;

   read AXAPOLICY;
enddo;

write RPTFOOTER;

*inlr = *on;
return;
