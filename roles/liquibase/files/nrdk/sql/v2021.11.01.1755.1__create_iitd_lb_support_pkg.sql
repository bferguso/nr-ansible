--liquibase formatted sql
--changeset qed:iitd_support_pkg splitStatements:true endDelimiter:/
create or replace package iitd_lb_support_pkg as
    e_uncompiled_objects EXCEPTION;
    PRAGMA exception_init (e_uncompiled_objects, -20001);
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

    procedure generate_baseline(stage varchar2);
    procedure clear_baseline(stage varchar2);

end iitd_lb_support_pkg;
/

create or replace package body iitd_lb_support_pkg as
    FUNCTION CSV_TO_TABLE(str varchar2) return VARCHAR2_TABLE PIPELINED is
        cursor c1 is
            with rws as (select str from dual)
            select trim(upper(regexp_substr(
                    str,
                    '[^,]+',
                    1,
                    level
                ))) value
            from rws
            connect by level <= length(str) - length(replace(str, ',')) + 1;
    BEGIN
        for r1 in c1
            loop
                pipe row (r1);
            end loop;
    END;

    procedure compile_objects(csv_exclude_list varchar2) is
        cursor invalid_objects(p_exclude_list VARCHAR2) is
            select *
            from user_objects
            where status = 'INVALID'
              and object_type || '.' || object_name not in
                  (select a.exclude_value from table (csv_to_table(p_exclude_list)) a where exclude_value is not null);
        invalid_objects_cnt number;
        retries             number;
        exclude_count       binary_integer;
        uncompiled_list     VARCHAR2(4000);

        function get_invalid_count(p_exclude_list VARCHAR2) return number is
            l_invalid_objects_cnt number;
        begin
            select count(*)
            into l_invalid_objects_cnt
            from user_objects
            where status = 'INVALID'
              and object_type || '.' || object_name not in
                  (select a.exclude_value from table (csv_to_table(p_exclude_list)) a where exclude_value is not null);
            return l_invalid_objects_cnt;
        end;
    begin
        invalid_objects_cnt := get_invalid_count(csv_exclude_list);
        select count(*) into exclude_count from table (csv_to_table(csv_exclude_list));
        dbms_output.put_line('Invalid count ' || 'Could not compile ' || invalid_objects_cnt || ' objects.');
        retries := 1;
        while invalid_objects_cnt > 0 AND retries < 5
            loop
                dbms_output.put_line('Attempt ' || retries);
                for invalid_object in invalid_objects(csv_exclude_list)
                    loop
                        dbms_output.put_line('Trying to compile ' || invalid_object.object_type || '.' ||
                                             invalid_object.object_name);
                        if (invalid_object.object_type = 'PACKAGE BODY') then
                            begin
                                execute immediate 'alter package ' || invalid_object.object_name || ' compile body';
                            EXCEPTION
                                when others then
                                    dbms_output.put_line('Unable to compile PACKAGE BODY ' || invalid_object.object_name);
                            end;
                        else
                            begin
                                execute immediate 'alter ' || invalid_object.object_type || ' ' ||
                                                  invalid_object.object_name || ' compile';
                            EXCEPTION
                                when others then
                                    dbms_output.put_line('Unable to compile ' || invalid_object.object_type || ' ' ||
                                                         invalid_object.object_name);
                            end;
                        end if;
                    end loop;
                invalid_objects_cnt := get_invalid_count(csv_exclude_list);
                retries := retries + 1;
            end loop;
        if invalid_objects_cnt > 0 then
            uncompiled_list := '[';
            for invalid_object in invalid_objects(csv_exclude_list) loop
                uncompiled_list := uncompiled_list||invalid_object.object_type||'.'||invalid_object.object_name||', ';
            end loop;
            uncompiled_list := uncompiled_list || ']';
            raise_application_error(-20001, 'Could not compile ' || invalid_objects_cnt || ' objects. '||uncompiled_list);
        end if;
    end;

    procedure BACKUP_SOURCE(source_type varchar2, source_name varchar2, version_number varchar2) is
        cursor source_lines(source_type varchar2, source_lines varchar2) is
            select *
            from user_source
            where name = source_name
              and type = source_type
            order by line;
        existing_source clob;
    begin
        dbms_lob.CREATETEMPORARY(existing_source, true);
        for source_line in source_lines(source_type, source_name)
            loop
                dbms_lob.APPEND(existing_source, source_line.text);
            end loop;
        insert into nrdk_tmp_source(source_name, source_type, source_version, text)
        values (source_name, source_type, version_number, existing_source);
    end backup_source;

    procedure CLEAR_BACKUP(p_source_type varchar2, p_source_name varchar2, p_version_number varchar2) is
    begin
        delete
        from nrdk_tmp_source
        where source_name = p_source_name
          and source_type = p_source_type
          and source_version = p_version_number;
    end;

    procedure RESTORE_SOURCE(p_source_type varchar2, p_source_name varchar2, p_version_number varchar2) is
        source_to_restore nrdk_tmp_source%rowtype;
    begin
        select *
        into source_to_restore
        from nrdk_tmp_source
        where source_type = p_source_type
          and source_name = p_source_name
          and source_version = p_version_number;
        execute immediate 'create or replace ' || source_to_restore.text;
        --if (p_clear_backup) then
        --    nrdk_clear_backup(p_source_type, p_source_name, p_version_number);
        --end if;
    end;

    -- Functions to generate and clear baseline data
    procedure GENERATE_BASELINE(p_stage varchar2) is
    begin
        insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
        select rownum, 'user_objects', p_stage, object_name || ' ' || object_type || ' ' || status
        from user_objects
        where object_name not like 'NRDK%'
        order by object_name;

        insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
        select rownum,
               'user_tab_columns',
               p_stage,
               table_name || ' ' || column_name || ' ' || data_type || ' ' || data_type_mod || ' ' || data_type_owner ||
               ' ' || data_length || ' ' || data_precision || ' ' || data_scale || ' ' || nullable || ' ' ||
               default_length || ' ' || /*data_default||' '||*/ character_set_name || ' ' || char_col_decl_length ||
               ' ' || global_stats || ' ' || user_stats || ' ' || char_length
        from user_tab_columns
        where table_name not like 'NRDK%'
        order by table_name, column_name;

        insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
        select rownum,
               'user_ind_columns',
               p_stage,
               index_name || ' ' || table_name || ' ' || column_name || ' ' || column_position || ' ' ||
               column_length || ' ' || char_length || ' ' || descend || ' ' || collated_column_id
        from user_ind_columns
        where table_name not like 'NRDK%'
        order by index_name, table_name, column_name;

        insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
        select rownum,
               'user_source',
               p_stage,
               name || ' ' || type || ' ' || line || ' ' || text || ' ' || origin_con_id
        from user_source
        where name not like 'NRDK%'
        order by name, type, line;

        insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
        select rownum,
               'user_policies',
               p_stage,
               OBJECT_NAME || ' ' || POLICY_GROUP || ' ' || POLICY_NAME || ' ' || PF_OWNER || ' ' || PACKAGE || ' ' ||
               FUNCTION || ' ' || SEL || ' ' || INS || ' ' || UPD || ' ' || DEL || ' ' || IDX || ' ' || CHK_OPTION ||
               ' ' || ENABLE || ' ' || STATIC_POLICY || ' ' || POLICY_TYPE || ' ' || LONG_PREDICATE || ' ' || COMMON ||
               ' ' || INHERITED
        from user_policies
        order by object_name, policy_group, policy_name, pf_owner, package, function;

        insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
        select rownum,
               'user_sys_privs',
               p_stage,
               USERNAME || ' ' || PRIVILEGE || ' ' || ADMIN_OPTION || ' ' || COMMON || ' ' || INHERITED
        from user_sys_privs
        order by username, privilege;
    end;

    procedure CLEAR_BASELINE(p_stage varchar2) is
    begin
        delete from nrdk_tmp_validation where stage=p_stage;
    end;


end iitd_lb_support_pkg;
/
--rollback drop package iitd_lb_support_pkg
--rollback /
