**FREE
ctl-opt dftactgrp(*no)
        actgrp(*new)
        option(*srcstmt);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXAPOLICY usage(*input) keyed;
dcl-f AXACLAIM  usage(*input) keyed;
dcl-f AXAPCLMRPT printer;

/*----------------------------------------------------------------*/
/* Headings                                                       */
/*----------------------------------------------------------------*/
RPTTITLE  = 'AXA POLICY AND CLAIM DETAIL REPORT';
CLMHDR    = 'CLAIM NO          TYPE                 LOSS DATE   AMOUNT';
ENDMESSAGE= '*** END OF REPORT ***';

/*----------------------------------------------------------------*/
/* Main Processing                                                */
/*----------------------------------------------------------------*/
read AXAPOLICY;
dow not %eof(AXAPOLICY);

   /* Policy Labels */
   PLBL   = 'Policy ID:';
   PNBL   = 'Policy No:';
   INSBL  = 'Insured:';
   PTBL   = 'Policy Type:';
   DATEBL = 'Inception:';
   EXPBL  = 'Expiry:';
   LIMBL  = 'Limit:';
   PREMBL = 'Premium:';

   write RPTHEADER;
   write POLICYR;

   /* Read Claims for this Policy */
   setll POLICY_ID AXACLAIM;
   reade POLICY_ID AXACLAIM;

   if %found(AXACLAIM);
      write CLAIMHDR;

      dow %found(AXACLAIM);
         write CLAIMR;
         reade POLICY_ID AXACLAIM;
      enddo;
   endif;

   read AXAPOLICY;
enddo;

write RPTFOOTER;

*inlr = *on;
return;
