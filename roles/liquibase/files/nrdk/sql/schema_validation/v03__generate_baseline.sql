--liquibase formatted sql
--changeset qed:v03__generate_baseline splitStatements:true endDelimiter:;
insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
    select rownum, 'user_objects', '${stage}', object_name||' '||object_type||' '||status
    from user_objects
    where object_name not like 'NRDK%'
    order by object_name;

insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
    select rownum, 'user_tab_columns', '${stage}', table_name||' '|| column_name||' '|| data_type||' '|| data_type_mod||' '|| data_type_owner||' '|| data_length||' '|| data_precision||' '|| data_scale||' '|| nullable||' '|| default_length||' '|| /*data_default||' '||*/ character_set_name||' '|| char_col_decl_length||' '|| global_stats||' '|| user_stats||' '|| char_length
        from user_tab_columns
        where table_name not like 'NRDK%'
        order by table_name, column_name;

insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
    select rownum, 'user_ind_columns', '${stage}', index_name||' '|| table_name||' '|| column_name||' '|| column_position||' '|| column_length||' '|| char_length||' '|| descend||' '|| collated_column_id
        from user_ind_columns
        where table_name not like 'NRDK%'
        order by index_name, table_name, column_name;

insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
    select rownum, 'user_source', '${stage}', name||' '|| type||' '|| line||' '|| text||' '|| origin_con_id
    from user_source
    where name not like 'NRDK%'
    order by name, type, line;

insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
    select rownum, 'user_policies', '${stage}', OBJECT_NAME||' '|| POLICY_GROUP||' '|| POLICY_NAME||' '|| PF_OWNER||' '|| PACKAGE||' '|| FUNCTION||' '|| SEL||' '|| INS||' '|| UPD||' '|| DEL||' '|| IDX||' '|| CHK_OPTION||' '|| ENABLE||' '|| STATIC_POLICY||' '|| POLICY_TYPE||' '|| LONG_PREDICATE||' '|| COMMON||' '|| INHERITED
    from user_policies
    order by object_name, policy_group, policy_name, pf_owner, package, function;

insert into nrdk_tmp_validation (seq_id, validation_type, stage, validation_data)
    select rownum, 'user_sys_privs', '${stage}', USERNAME||' '|| PRIVILEGE||' '|| ADMIN_OPTION||' '|| COMMON||' '|| INHERITED
    from user_sys_privs
    order by username, privilege;
--rollback delete from nrdk_tmp_validation where stage='${stage}';