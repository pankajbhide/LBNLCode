


Delete From invoicetrans Where Not Exists (Select * From invoice where invoicenum=invoicetrans.invoicenum And siteid=invoicetrans.siteid);

commit;
