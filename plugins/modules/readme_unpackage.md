Unpackage.py
============
A Custom Version of unarchive

Requirements
-------------------------------

This module is designed to provide similar functionality to the native unarchive with some key differences
1) The dest specified will be created if it does not exist
2) the dest will be the location all files are placed in 
3) the top_dir of the archive will be cut ie apache-tomcat2.6.8 will not exist and all file will be placed in dest 
4) if a .checksum_archive_name is present and contains the current checksum of the archive to unpack no action will happen returns unchanged 

Module Options
---------------

| Option | Required | type | Description | 
|--------|----------|------|-------------|
| src | y | String | The source archive path |  
| dest | y | String | The path to the destination directory | 
| archive_name | y | String | Used for naming .checksum and the temp dir in unzip |
| safe_mode | n | Bool | prevents deletion unless the checksum is different | 
| checksum | n | String |the checksum of the new archive |
| exclude | n | String | names of files to ignore during unpack  |
| directory_ permissions | n| int (octal)|Set dir permissions for the dest folder if it doesn’t exist | 
| extra opts | n | String | An argument to give yourself the ability to add extra opts | 
| top_dir | n | Bool | If you want the top dir trimmed off when zip | 
|check_mode | n | Bool | Runs program in check mode which will not try to find_handler | 

Example
-------
~~~~
- name: Test zip archive
  unpackage:
    src: /test/src/test.zip
    dest: /test/dest/zip
    checksum: 1
    archive_name: zip
    top_dir: /apache-tomcat-8.5.23
~~~~
This is the main decision tree for the program

~~~~                     
(Start) -> [Requriments exist]
    ├(no)  -> (fail)  
    └(yes) -> [src archive exists?]
        ├(no)  -> (fail)
        └(yes) -> [dest exists?] 
            ├(no)  -> (make_dir) -> [success?]
            |   ├(yes) -> (find_handler) -> [success?] 
            |   |   |yes) -> (update .checksum) -> (end_with_change)
            |   |   └(no)  -> (fail)
            |   └(no)  -> (fail)
            └(yes) -> [.checksum file exists?] 
                ├(yes) -> [.checksum matchs {{checksum}}?]
                |   ├(yes) -> (end_no_change)
                |   └(no)  -> [safe_mode?]
                |       ├(no)  -> (find_handler)
                |       |   ├(yes) -> (update .checksum) -> (end_with_change)
                |       |    └(no)  -> (fail)
                |       └(yes) -> (end_no_change) 
                └(no) -> [safe_mode?] 
                    ├(no)  -> (find_handler) -> [success?] 
                    |   ├(yes) -> (end_with_change)
                    |   └(no)  -> (fail)
                    └(yes) -> (end_no_change) 
~~~~