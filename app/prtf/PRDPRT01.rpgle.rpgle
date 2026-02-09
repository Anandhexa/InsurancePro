**--------------------------------------------------------------
** Program : PRDPRT01
** Purpose : Product Master List Printing
** Type    : Printer Program
**--------------------------------------------------------------

ctl-opt dftactgrp(*no) actgrp('INSURANCE');

**--------------------------------------------------------------
** Files
**--------------------------------------------------------------
dcl-f PRODUCT  usage(*input);
dcl-f PRDPRTF  printer;

**--------------------------------------------------------------
** Working Variables
**--------------------------------------------------------------
dcl-s PrintDate   char(8);
dcl-s PrintTime   char(6);
dcl-s EndOfFile   ind inz(*off);

**--------------------------------------------------------------
** Main Program
**--------------------------------------------------------------
exsr Initialize;
exsr PrintHeader;
exsr ReadAndPrintProducts;
exsr PrintFooter;

*inlr = *on;
return;

**==============================================================
** Initialize
**==============================================================
begsr Initialize;

   PrintDate = %char(%date():*iso0);
   PrintTime = %char(%time():*hms0);

endsr;

**==============================================================
** Print Report Header
**==============================================================
begsr PrintHeader;

   RPTDATE = PrintDate;
   RPTTIME = PrintTime;
   write RPTHEADER;
   write COLHEADER;

endsr;

**==============================================================
** Read Product File and Print Details
**==============================================================
begsr ReadAndPrintProducts;

   setll *loval PRODUCT;

   dow EndOfFile = *off;

      read PRODUCT;
      if %eof(PRODUCT);
         EndOfFile = *on;
      else;

         PRODID     = PRODUCT.PRODUCT_ID;
         PRODNAME   = PRODUCT.PRODUCT_NAME;
         PRODTYPE   = PRODUCT.PRODUCT_TYPE;
         PRODSTATUS = PRODUCT.PRODUCT_STATUS;

         write DETAIL;

      endif;

   enddo;

endsr;

**==============================================================
** Print Footer
**==============================================================
begsr PrintFooter;

   write FOOTER;

endsr;
