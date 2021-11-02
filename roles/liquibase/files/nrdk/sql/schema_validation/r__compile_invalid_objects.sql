--liquibase formatted sql
--changeset qed:compile_invalid_objects splitStatements:false
declare
    e_uncompiled_objects EXCEPTION;
    PRAGMA exception_init(e_uncompiled_objects, -20001);
    cursor invalid_objects is
        select * from user_objects where status = 'INVALID';
    invalid_objects_cnt number;
    retries number;
begin
    select count(*) into invalid_objects_cnt from user_objects where status = 'INVALID';
    retries := 1;
    while invalid_objects_cnt > 0 AND retries < 5 loop
        for invalid_object in invalid_objects loop
                if (invalid_object.object_type = 'PACKAGE BODY') then
                    begin
                       execute immediate 'alter package '||invalid_object.object_name||' compile body';
                    EXCEPTION when others then
                        dbms_output.put_line('Unable to compile PACKAGE BODY '||invalid_object.object_name);
                    end;
                else
                    begin
                        execute immediate 'alter '||invalid_object.object_type||' '||invalid_object.object_name||' compile';
                    EXCEPTION when others then
                        dbms_output.put_line('Unable to compile '||invalid_object.object_type||' '|| invalid_object.object_name);
                    end;
                end if;
        end loop;
        select count(*) into invalid_objects_cnt from user_objects where status = 'INVALID';
        retries := retries + 1;
    end loop;
    if invalid_objects_cnt > 0 then
        raise_application_error(-20001, 'Could not compile '||invalid_objects_cnt||' objects.');
    end if;
end;