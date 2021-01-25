
update maxattributecfg set classname=null  where objectname='LBL_SP_CHARGE_DIST' and attributename in ('CHARGED_TO_PERCENT','PROJ_ACT_ID');
update maxattribute    set classname=null  where objectname='LBL_SP_CHARGE_DIST' and attributename in ('CHARGED_TO_PERCENT','PROJ_ACT_ID');


update maxobjectcfg set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_SP_CHARGE_DIST';
update maxobject    set classname='psdi.mbo.custapp.CustomMboSet' where objectname='LBL_SP_CHARGE_DIST'; 


commit;


-- FOR SPACE_PACKAGE 

GRANT SELECT ON LOCATIONSSEQ TO  PUBLIC;

GRANT SELECT  ON LOCANCESTORSEQ TO PUBLIC;

GRANT SELECT ON lochierarchySEQ TO PUBLIC;

GRANT SELECT  ON LONGDESCRIPTIONSEQ TO PUBLIC;

GRANT SELECT ON LOCOPERSEQ TO PUBLIC;

