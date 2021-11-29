--liquibase formatted sql
--changeset qed:iitd_support_pkg splitStatements:false
drop package iitd_lb_support_pkg
--rollback
