create table nrdk_tmp_source(source_name varchar2(255), source_type varchar2(80), source_version varchar2(80), text clob)
/

create unique index nrdk_tmp_source_uk on nrdk_tmp_source(source_name, source_type, source_version)
/

create or replace procedure nrdk_backup_source(source_type varchar2, source_name varchar2, version_number varchar2) is
    cursor source_lines(source_type varchar2, source_lines varchar2) is
        select * from user_source where name = source_name
                                    and type = source_type
        order by line;
    existing_source clob;
begin
    dbms_lob.CREATETEMPORARY(existing_source, true);
    for source_line in source_lines(source_type, source_name) loop
            dbms_lob.APPEND(existing_source, source_line.text);
        end loop;
    insert into nrdk_tmp_source(source_name, source_type, source_version, text)
    values(source_name, source_type, version_number, existing_source);
end;
/

create or replace procedure nrdk_clear_backup(p_source_type varchar2, p_source_name varchar2, p_version_number varchar2) is
begin
    delete from nrdk_tmp_source
        where source_name = p_source_name
          and source_type = p_source_type
          and source_version = p_version_number;
end;
/

create or replace procedure nrdk_restore_source(p_source_type varchar2, p_source_name varchar2, p_version_number varchar2) is
    source_to_restore nrdk_tmp_source%rowtype;
begin
    select * into source_to_restore from nrdk_tmp_source
    where source_type = p_source_type
      and source_name = p_source_name
      and source_version = p_version_number;
    execute immediate 'create or replace '||source_to_restore.text;
    /*
    if (p_clear_backup) then
        nrdk_clear_backup(p_source_type, p_source_name, p_version_number);
    end if;
     */
end;
/