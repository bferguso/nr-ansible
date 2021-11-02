--liquibase formatted sql
--changeset qed:v02__clear_baseline splitStatements:true endDelimiter:;
delete from nrdk_tmp_validation where stage='${stage}';
--rollback delete from nrdk_tmp_validation where stage='${stage}';