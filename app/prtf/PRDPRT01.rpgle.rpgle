ctl-opt dftactgrp(*no) actgrp('INSURANCE');

dcl-f PRODUCT  usage(*input);
dcl-f PRDPRTF  printer;

dcl-s PrintDate   char(8);
dcl-s PrintTime   char(6);
dcl-s EndOfFile   ind inz(*off);

exsr Initialize;
exsr PrintHeader;
exsr ReadAndPrintProducts;
exsr PrintFooter;

*inlr = *on;
return;

begsr Initialize;

   PrintDate = %char(%date():*iso0);
   PrintTime = %char(%time():*hms0);

endsr;

begsr PrintHeader;

   RPTDATE = PrintDate;
   RPTTIME = PrintTime;
   write RPTHEADER;
   write COLHEADER;

endsr;

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

begsr PrintFooter;

   write FOOTER;

endsr;
