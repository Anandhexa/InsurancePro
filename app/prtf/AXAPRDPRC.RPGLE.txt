**FREE
ctl-opt dftactgrp(*no)
        actgrp(*new)
        option(*srcstmt);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXAPROD     usage(*input) keyed;
dcl-f AXAPRICING  usage(*input) keyed;
dcl-f AXAPRDPRC   printer;

/*----------------------------------------------------------------*/
/* Constants                                                      */
/*----------------------------------------------------------------*/
TITLE     = 'AXA PRODUCT AND PRICING DETAIL REPORT';
PRCHDRTXT = 'PRICING ID  RISK CATEGORY    BASE  MULT  COMM  MIN PREM   MAX PREM';
ENDMSG    = '*** END OF REPORT ***';

/*----------------------------------------------------------------*/
/* Main Program                                                   */
/*----------------------------------------------------------------*/
read AXAPROD;
dow not %eof(AXAPROD);

   /* Labels */
   PIDLBL   = 'Product ID:';
   PNAMELBL = 'Product Name:';
   PTYPLBL  = 'Product Type:';
   LIMLBL   = 'Coverage Limit:';
   DEDLBL   = 'Deductible:';
   PREMLBL  = 'Premium:';
   PSTSLBL  = 'Status:';

   write RPTHEADER;
   write PRODUCTR;

   /* Read Pricing by Product Type */
   setll PRODUCT_TYPE AXAPRICING;
   reade PRODUCT_TYPE AXAPRICING;

   if %found(AXAPRICING);
      write PRCHDR;

      dow %found(AXAPRICING);
         write PRICINGR;
         reade PRODUCT_TYPE AXAPRICING;
      enddo;
   endif;

   read AXAPROD;
enddo;

write RPTFOOTER;

*inlr = *on;
return;
