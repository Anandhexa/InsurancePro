**FREE
ctl-opt dftactgrp(*no)
        actgrp(*new)
        option(*srcstmt);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXASUBM     usage(*input) keyed;
dcl-f AXAPROD     usage(*input) keyed;
dcl-f AXAPRICING  usage(*input) keyed;
dcl-f AXASPRPRC   printer;

/*----------------------------------------------------------------*/
/* Constants                                                      */
/*----------------------------------------------------------------*/
TITLE     = 'AXA SUBMISSION / PRODUCT / PRICING DETAIL REPORT';
PRCHDRTXT = 'PRICING ID  RISK CATEGORY     BASE  MULT  COMM  MIN PREM   MAX PREM';
ENDMSG    = '*** END OF REPORT ***';

/*----------------------------------------------------------------*/
/* Main Processing                                                */
/*----------------------------------------------------------------*/
read AXASUBM;
dow not %eof(AXASUBM);

   /* Submission Labels */
   SUBMIDL = 'Submission ID:';
   SUBDTL  = 'Submitted On:';
   VALLBL  = 'Valid Until:';
   BROKLBL = 'Broker Ref:';
   SUBSTL  = 'Status:';
   WFLBL   = 'Workflow:';
   ASGLBL  = 'Assigned To:';
   PRILBL  = 'Priority:';
   VALLBL2 = 'Validation:';
   BUSLBL  = 'Business Rule:';
   SLALBL  = 'SLA Due:';
   ESCLBL  = 'Escalated:';
   CRTLBL  = 'Created By:';

   write RPTHEADER;
   write SUBMR;

   /* Read Product */
   chain PRODUCT_ID AXAPROD;
   if %found(AXAPROD);

      PIDLBL  = 'Product ID:';
      PNAMLBL = 'Product Name:';
      PTYPLBL = 'Product Type:';
      LIMLBL  = 'Coverage Limit:';
      DEDLBL  = 'Deductible:';
      PREMLBL = 'Premium:';
      PSTSLBL = 'Status:';

      write PRODR;

      /* Pricing by Product Type */
      setll PRODUCT_TYPE AXAPRICING;
      reade PRODUCT_TYPE AXAPRICING;

      if %found(AXAPRICING);
         write PRCHDR;

         dow %found(AXAPRICING);
            write PRICER;
            reade PRODUCT_TYPE AXAPRICING;
         enddo;
      endif;
   endif;

   read AXASUBM;
enddo;

write RPTFOOT;

*inlr = *on;
return;
