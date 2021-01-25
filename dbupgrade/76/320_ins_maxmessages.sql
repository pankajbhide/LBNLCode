-- connect maximo@mmoxxx



insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('lbl_canotsaveemptyrecord', 'lbl_wkthru', 'Can not save record. Fill in empty values.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('lbl_fieldnotnull', 'workorder', 'The value in the field {0} should be blank.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('lbl_invalidrtpervault', 'lbl_wrhsfeed', 'Rate per vault should be > 0.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

--insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
--values ('lbl_invalidmindaysrecharge', 'lbl_wrhsfeed', 'Minimum days recharge should be > 0.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('lbl_invaliduom', 'lbl_wrhsfeed', 'Invalid unit of measure.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('lbl_InvalidPerson', 'workorder', 'Invalid Person id.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('lbl_field<=0', 'workorder', 'Value in {0} should be > 0.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('lbl_badminmaxpoints', 'workorder', 'Inconsistent values in minimum and maximum points.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('lbl_wcdcondexists', 'lbl_wcdcondition', 'Condition already exists.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('lblsubcondnotallowed', 'workorder', 'Add/modify to sub condition not allowed.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('lbl_requestedbynull', 'pr', 'Requested by should not be null.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);

insert into maxmessages (msgkey, msggroup, value, title, displaymethod, options, maxmessagesid)
values ('LblFldAssetUserCustPersonID', 'ASSETUSERCUST', 'Can’t add person with the same personid.', 'MAXIMO Error', 'MSGBOX',2,maxmessagesseq.nextval);


rollback;
