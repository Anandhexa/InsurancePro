**--------------------------------------------------------------
** Program : QTFPRDPRT
** Purpose : Quoted Product List Print
** Source  : QUOTEFULL logic
**--------------------------------------------------------------

ctl-opt dftactgrp(*no) actgrp('INSURANCE');

**--------------------------------------------------------------
** Files
**--------------------------------------------------------------
dcl-f QUOTE     usage(*input);
dcl-f PRODUCT   usage(*input);
dcl-f QTFPRTF   printer;

**--------------------------------------------------------------
** Working Variables
**--------------------------------------------------------------
dcl-s PrintDate     char(8);
dcl-s PrintTime     char(6);
dcl-s EndQuoteFile  ind inz(*off);
dcl-s EndProdFile   ind inz(*off);

dcl-s CurrProdId    char(10);
dcl-s QuoteCount    packed(5:0);

**--------------------------------------------------------------
** Main Program
**--------------------------------------------------------------
exsr Initialize;
exsr PrintHeader;
exsr ProcessQuotedProducts;
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
** Print Header
**==============================================================
begsr PrintHeader;

   RPTDATE = PrintDate;
   RPTTIME = PrintTime;
   write RPTHEADER;
   write COLHEADER;

endsr;

**==============================================================
** Process Quoted Products
**==============================================================
begsr ProcessQuotedProducts;

   setll *loval PRODUCT;

   dow EndProdFile = *off;

      read PRODUCT;
      if %eof(PRODUCT);
         EndProdFile = *on;
      else;

         CurrProdId = PRODUCT.PRODUCT_ID;
         QuoteCount = 0;

         exsr CountQuotesForProduct;

         if QuoteCount > 0;

            PRODID     = PRODUCT.PRODUCT_ID;
            PRODNAME   = PRODUCT.PRODUCT_NAME;
            QUOTECNT   = QuoteCount;
            PRODSTATUS = PRODUCT.PRODUCT_STATUS;

            write DETAIL;

         endif;

      endif;

   enddo;

endsr;

**==============================================================
** Count Quotes For Current Product
**==============================================================
begsr CountQuotesForProduct;

   EndQuoteFile = *off;
   setll CurrProdId QUOTE;

   dow EndQuoteFile = *off;

      reade CurrProdId QUOTE;
      if %eof(QUOTE);
         EndQuoteFile = *on;
      else;

         QuoteCount += 1;

      endif;

   enddo;

endsr;

**==============================================================
** Print Footer
**==============================================================
begsr PrintFooter;

   write FOOTER;

endsr;
