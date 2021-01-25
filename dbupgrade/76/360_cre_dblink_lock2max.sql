

drop database link lock2max;

create database link lock2max connect to lockadm identified by lock$12345 using 'resprd';
