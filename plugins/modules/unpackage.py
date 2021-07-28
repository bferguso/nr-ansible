#!/usr/bin/env python


ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}
DOCUMENTATION = '''
---

module: unpackage.py
short_description: A Custom Version of unarchive
description:
    - Untars/Unzips if no valid checksum file is found 
    - After succesful unpack creates checksum file
version_added: "2.3"
author: "Dryden Linden-Bremner"
Status : preview
options:
    src:
        description:
            - The location of the file to attempt to unpack.
        required: true
    dest:
        description:
            - The location to unpack to 
        required: true

    safe_mode:
        description: 
            Used to prevent deletion  
        required: False 
        default: False
        

    checksum:
        description: the checksum to match aganst 
        required: False
    exclude: 
        Description: files to not be included in the unzip 
        required: False
        type: 'list'
    directory_permissions:  
        description: The permssions of the dest directory if it does not exist 
        required:False
        default=0775    
    extra_opts: 
        description: In order to allow for more options in unzip/tar these will be included in the command that gets run  
        required: False
    top_dir:
        description: 
            if using unzip the name of the top_directory that would be created by unzipping the archive 
        required: for .zip if you want to make the dest the top folder
    archive_name: 
        description:
            The name of the program to unarchived used for makeing the checksum_archivename and the tmp dir in zip 
        required=True



This module is designed to provide similer functionality to the native unarchive with some key differences
1) The dest specified wil be created if it does not exist
2) the dest will be the location all files are placed in 
3) the top_dir of the archive will be cut ie apache-tomcat2.6.8 will not exist and all file will be placed in dest 
4) if a .checksum_archive_name is present and contains the current checksum of the archive to unpack no action will happen returns unchanged 

Expected behavior 

This is the main decision tree for the program
                             
(Start) -> [Requriments exist]
                              (no)  -> (fail)  
                              (yes) -> [src archive exists?]
                                                            (no)  -> (fail)
                                                            (yes) -> [dest exists?] 
                                                                                    (no)  -> (make_dir) -> [success?]
                                                                                                                     (yes) -> (find_handler) -> [success?] 
                                                                                                                                                          (yes) -> (update .checksum) -> (end_with_change)
                                                                                                                                                          (no)  -> (fail)
                                                                                                                     (no)  -> (fail)
                                                                                    (yes) -> [.checksum file exists?] 
                                                                                                                    (yes) -> [.checksum matchs checksum]
                                                                                                                                                            (yes) -> (end_no_change)
                                                                                                                                                            (no)  -> [safe_mode?]
                                                                                                                                                                                 (no)  -> (find_handler)
                                                                                                                                                                                                        (yes) -> (update .checksum) -> (end_with_change)
                                                                                                                                                                                                        (no)  -> (fail)
                                                                                                                                                                                 (yes) -> (end_no_change) 
                                                                                                                    (no) -> [safe_mode?] 
                                                                                                                                        (no)  -> (find_handler) -> [success?] 
                                                                                                                                                                            (yes) -> (end_with_change)
                                                                                                                                                                            (no)  -> (fail)
                                                                                                                                        (yes) -> (end_no_change) 

'''

import re
import os
import stat
import pwd
import grp
import datetime
import time
import binascii
import codecs
import os.path
from distutils.dir_util import copy_tree
from zipfile import ZipFile, BadZipfile
from ansible.module_utils._text import to_text
from ansible.module_utils.basic import AnsibleModule

class unpackage(object):
    def __init__(self, module):
        self.module = module
        self.changed = False
        self.state = ''
        self.tgz_zip_flag =''
        self.file_args = self.module.load_file_common_arguments(self.module.params)
        self.extra_opts = module.params['extra_opts']
        self.dest = module.params['dest']
        self.src = module.params['src']
        self.safe_mode = module.params['safe_mode']
        self.exclude = module.params['exclude']
        self.checksum = module.params['checksum']
        self.directory_permissions= module.params['directory_permissions']
        self.top_dir = module.params['top_dir']
        self.name = ''
    
    def strip_archive_name(self): 
        self.name = self.src.rsplit('/',1)[1]
        self.name = self.name.split('.', 1)[0]
        
    def make_dir(self):
        
        try:
            os.makedirs(self.dest)
        except:
            self.module.fail_json(msg="failed to unpack make dir")
    
    def ZipArchive(self): 
    
        if self.top_dir:
            path = self.dest + "/tmp_" + self.name
            print path
            if not os.path.isdir(path):
                try:
                    os.makedirs(path)
                except:
                    self.module.fail_json(msg='failed to make temp dir for unzip')
            else :
                try:
                        self.module.run_command("rm -rf " +  path)
                        print ("rm -rf" + path)
                        os.makedirs(path ,0755)
                except:
                        self.module.fail_json(msg='failed to make temp dir for unzip, dest/temp_archive_name already exists')
            directory_structure= os.listdir(path)
            command= 'unzip ' + '-o ' + self.src 
            if self.extra_opts:
                command+= self.extra_opts
            if self.exclude:
                for x in self.exclude:
                    command += ' -x ' + x
            command += ' -d ' + self.dest + "/tmp_" + self.name
            print command
            rc, out, err = self.module.run_command(command, cwd=self.dest)        
            if rc != 0:
                self.module.run_command("rm -rf " + self.dest + "/tmp_" + self.name)
                return False 
            new_dir = os.listdir(path)
            top_dir = [y for y in new_dir if y not in directory_structure]
            fullpath = path + '/' + ''.join(top_dir)
            copy_tree(fullpath , self.dest)
            
            self.module.run_command("rm -rf " + self.dest + "/tmp_" + self.name)
            return True
        else:
            command= 'unzip ' + '-o ' + self.src
            if self.extra_opts:
                command+= self.extra_opts
            if self.exclude:
                for x in self.exclude:
                    command += ' -x ' + x
            command += ' -d ' + self.dest
            print command
            rc, out, err = self.module.run_command(command, cwd=self.dest)
            if rc != 0 :
                return False 
            return True
        
    def TgzArchive(self): 
        command = 'tar ' + '--extract ' + '-C ' + self.dest + " --strip-components=1 "
        if self.extra_opts:
            command+= self.extra_opts
        if self.file_args['owner']:
            command+= ' --owner=' + self.file_args['owner']
        if self.file_args['group']:
            command +=' --group=' + self.file_args['group']   
        if self.exclude:
            for f in self.exclude:
                command+= ' --exclude=' + f 
        if self.tgz_zip_flag:
            command+= self.tgz_zip_flag
        command += ' -f ' + self.src
        print command
        rc, out, err = self.module.run_command(command, cwd=self.dest)
        if rc != 0 :
            return False 
        return True
    
    def TarArchive(self):
        self.tgz_zip_flag = ''
        error = self.TgzArchive()
        return error
        
        
    def TarBzipArchive(self):
        print ("Trying TarBZip ")
        self.tgz_zip_flag = '-j'
        error = self.TgzArchive()
        self.tgz_zip_flag = ''
        return error
        
    def TarXzArchive(self):
        print ("Trying TarXz ")
        self.tgz_zip_flag = '-J'
        print ("Trying tarxzArchive")
        error = self.TgzArchive()
        self.tgz_zip_flag = ''
        
        return error
        
    def find_handler(self):
        handlers = [self.ZipArchive,  self.TgzArchive ,   self.TarArchive ,  self.TarBzipArchive, self.TarXzArchive]
        for handler in handlers:
            obj = handler()
            
            if obj:
                return
        print ("Fail: Failed to find an appropriate handler, check that archive type is supported")
        self.module.fail_json(msg='Failed to find handler for "%s". Make sure the required command to extract the file is installed.' % (self.src ))
        
def main():
    
    module = AnsibleModule(
        argument_spec=dict(
            safe_mode=dict(required=False, default=False),
            src=dict(required=True),
            dest=dict(required=True),
            checksum=dict(required=False),
            exclude=dict(required=False, type='list'),
            directory_permissions=dict(required=False, default=0775),
            extra_opts=dict(required=False),
            top_dir=dict(required=False, default= True),
            archive_name=dict(required=False),
            check_mode=dict(required=False, default= False)
        ),
        supports_check_mode=False
    )
    
        
    archive = unpackage(module) 
    if not module.params['archive_name']:
        archive.strip_archive_name()
    if module.params['check_mode'] == "True": 
        if not os.path.exists(module.params['src']):
            print ("Fail: source file not found, checkmode") 
            module.fail_json(msg='Src does not exist, checkmode')
                    
        if not os.path.isdir(module.params['dest']):
            archive.changed= True
            print ("It would have tryed to make a dir and find handlers, but in check mode and skips these tasks")        
        elif os.path.exists(module.params['dest'] +"/.checksum_" + archive.name):             
            checksum_old = open((module.params['dest'] + "/.checksum_" + archive.name), "r")
            file_checksum= checksum_old.read()
            
            if module.params['checksum'] in file_checksum:
                print ("No Changes: checksum exists and is the same as supplied checksum, checkmode was enabled so no changes")
                archive.changed = False
                checksum_old.close()
            else:
                print ("Not Finding Handler... Checkmode does not support checking handlers as doing so causes changes")
                checksum_old.close()
                archive.changed= True
                
        elif archive.safe_mode == "False":
            print ("Not Finding Handler... checkmode does not support finding handler")
            archive.changed= True
        else:
            print ("No changes: Because Directory exists, checksum does not exist, and safe_mode is enabled, checkmode was enabled")
            archive.changed = False     
        result = {}
        result['name'] = archive.dest
        result['changed'] = archive.changed
        result['state'] =  ""
        module.exit_json(**result) 
         
    if not os.path.exists(module.params['src']):
        print ("Fail: source file not found") 
        module.fail_json(msg='Src does not exist')
        
        
    if not os.path.isdir(module.params['dest']):
        archive.make_dir()
        archive.find_handler()
        archive.changed= True
        
    elif os.path.exists(module.params['dest'] +"/.checksum_" + archive.name):
        
        checksum_old = open((module.params['dest'] + "/.checksum_" + archive.name), "r")
        file_checksum= checksum_old.read()
        
        if module.params['checksum'] in file_checksum:
            print ("No Changes: checksum exists and is the same as supplied checksum")
            archive.changed = False
            checksum_old.close()
        else:
            print ("Finding Handler...")
            checksum_old.close()
            archive.find_handler()
            archive.changed= True
            
    elif archive.safe_mode == "False":
        print ("Finding Handler...")
        archive.find_handler()
        archive.changed= True
    else:
        print ("No changes: Because Directory exists, checksum does not exist, and safe_mode is enabled")
        archive.changed = False
    
    if archive.changed:
        if os.path.exists(module.params['dest'] +"/.checksum_" + archive.name):
            os.remove(module.params['dest']+ "/.checksum_"+ archive.name)
            checksum_new = open(module.params['dest']+ "/.checksum_"+ archive.name , "w+")
            checksum_new.write(module.params['checksum'])
            checksum_new.close()
        else:
            checksum_new = open(module.params['dest']+ "/.checksum_" + archive.name , "w+")
            checksum_new.write(module.params['checksum'])
            checksum_new.close()
        
    
    
    result = {}
    result['name'] = archive.dest
    result['changed'] = archive.changed
    result['state'] =  ""
    module.exit_json(**result)
    
    
        
if __name__ == '__main__':
    main()
