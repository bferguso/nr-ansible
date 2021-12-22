--liquibase formatted sql
--changeset qed:iitd_support_pkg splitStatements:true endDelimiter:/
create or replace package iitd_lb_support_pkg as
    e_uncompiled_objects EXCEPTION;
    PRAGMA exception_init (e_uncompiled_objects, -20001);

    e_unexpected_change EXCEPTION;
    PRAGMA exception_init (e_unexpected_change, -20002);

    TYPE VARCHAR2_RECORD is RECORD
                            (
                                EXCLUDE_VALUE VARCHAR2(4000)
                            );
    TYPE VARCHAR2_TABLE IS TABLE OF VARCHAR2_RECORD;
    FUNCTION csv_to_table(str varchar2) return VARCHAR2_TABLE PIPELINED;
    procedure compile_objects(csv_exclude_list varchar2);

    procedure backup_source(source_type varchar2, source_name varchar2, version_number varchar2);
    procedure clear_backup(p_source_type varchar2, p_source_name varchar2, p_version_number varchar2);
    procedure restore_source(p_source_type varchar2, p_source_name varchar2, p_version_number varchar2);

    procedure log_schema_state(p_stage varchar2);
    procedure clear_schema_state(p_stage varchar2);
    procedure validate_schema_changes(p_pre_stage varchar2, p_post_stage varchar2, p_pre_delta number, p_post_delta number);

end iitd_lb_support_pkg;
/