#!/usr/bin/env python


# http://ranman.com/jira-plugin-api/
import base64
import os
import os.path
import time
import json
import httplib # because fetch_url doesn't support posting files

from ansible.module_utils.urls import *
from ansible.module_utils.basic import AnsibleModule

class JiraPlugin(object):
    # pylint: disable=too-many-instance-attributes
    def __init__(self, module):
        self.changed = False
        self.is_installed = False
        self.is_enabled = False
        self.plugin_descriptor = dict()
        self.module = module
        self.src = module.params['src']
        self.jira_url = module.params['jira_url']
        self.key = module.params['plugin_key']
        self.version = module.params['plugin_version']
        self.force = module.params['force']

    def get_token(self):
        print('Fetching token')
        token_url = self.jira_url + '/rest/plugins/1.0/?os_authType=basic'
        rsp, info = fetch_url(self.module, token_url, method="GET")
        token = rsp.headers['upm-token']
        print("Token: %s" % token)
        return token
    
    
    def fetch_current_state(self):
        plugin_url = self.jira_url + '/rest/plugins/1.0/' + self.key + '-key'     
        rsp, info = fetch_url(self.module, plugin_url, method="GET")  #fetch_url() https://github.com/ansible/ansible/blob/devel/lib/ansible/module_utils/urls.py#L985

        status_code = info['status']
        if status_code == -1:
            self.module.fail_json(msg=info['msg'], url=plugin_url)
        elif status_code == 404:
            # plugin doesn't exist
            pass
        elif status_code == 200:
            # plugin exists
            self.is_installed = True
            json_encoded = rsp.read()
            decoded_data = json.loads(json_encoded)
            self.plugin_descriptor = decoded_data
            self.is_enabled = decoded_data['enabled']
        else:
            print("Failed request")
            self.module.fail_json(msg="%s: %s" % (status_code, info['body']), url=plugin_url)

    def remove(self):
        if self.is_installed:
            plugin_url = self.jira_url + '/rest/plugins/1.0/' + self.key + '-key'
            rsp, info = fetch_url(self.module, plugin_url, method="DELETE")

            status_code = info['status']
            if status_code == -1:
                self.module.fail_json(msg=info['msg'], url=plugin_url)
            elif status_code == 404:
                return # cool, but this shouldn't have happened; maybe an exceptional case?
            elif status_code == 204:
                self.changed = True # success
            else:
                self.module.fail_json(msg=info['body'])
        else:
            # cool, no-op
            return

    def install(self):
        if self.is_installed and (self.version <= self.plugin_descriptor['version'] and not self.force):
            print('Skipping install')
            return
        else:
            print("Installing")
            token = self.get_token()
            url = self.jira_url + '/rest/plugins/1.0/?token=' + token
            headers = {'X-Atlassian-Token': 'nocheck', 'Content-Type': 'application/x-www-form-urlencoded'} 
            plugin_file = open(self.src, 'rb')
            data = {'plugin': plugin_file }
            
            conn = httplib.HTTPConnection('http://localhost:2990')
            conn.request("POST", '/jira/rest/plugins/1.0/?token=' + token , data, headers)
            response = conn.getresponse()
            print response.status, response.reason
            data = response.read()
            conn.close()

            self.module.json_fail(msg="exit")


            # rsp, info = fetch_url(self.module, url, method="POST", headers=headers, data=data)
            
            print ("after request")
            # {
            #     "type": "INSTALL",
            #     "pingAfter": 100,
            #     "status": {
            #         "done": false,
            #         "statusCode": 200,
            #         "contentType": "application/vnd.atl.plugins.install.installing+json",
            #         "source": "infra-jira-calendar-plugin-jar-1.0.0-SNAPSHOT.jar",
            #         "name": "infra-jira-calendar-plugin-jar-1.0.0-SNAPSHOT.jar"
            #     },
            #     "links": {
            #         "self": "/jira/rest/plugins/1.0/pending/f1b81c91-aa52-4803-bf02-1a843d3dc665",
            #         "alternate": "/jira/rest/plugins/1.0/tasks/f1b81c91-aa52-4803-bf02-1a843d3dc665"
            #     },
            #     "timestamp": 1505018507149,
            #     "userKey": "admin",
            #     "id": "f1b81c91-aa52-4803-bf02-1a843d3dc665"
            # }

            status_code = info['status']
            if status_code == -1:
                for k, v in info.iteritems():
                    print("%s: %s" % (k,v))

                self.module.fail_json(msg=info['msg'], url=url)
                
            elif status_code == 202:
                self.changed = True
                json_encoded = rsp.read()
                decoded_data = json.loads(json_encoded)
                done = decoded_data['status']['done']
                status_url = self.jira_url + decoded_data['links']['self']
                timeout = 4
                while not done:
                    time.sleep(1)
                    self.__wait_for_install(status_url)
                    timeout -= 1
                    if (timeout <= 0):
                        module.fail_json(msg="Timeout")
            else:
                self.module.fail_json(msg=info['body'])

    def __wait_for_install(self, url):
        rsp, info = fetch_url(self.module, url, method="GET")

        status_code = info['status']
        
        if status_code == -1:
            self.module.fail_json(msg=info['msg'], url=plugin_url)
        elif status_code == 200:
            rsp.headers['content-type']
        else:
            self.module.fail_json(msg="404", url=url)
        
        


    def disable(self):
        self.install()
        self.__set_state(False)

    def enable(self):
        self.install()
        self.__set_state(True)

    def __set_state(self, is_enabled):
        if is_enabled == self.is_enabled:
            return
        else:
            plugin_url = self.jira_url + '/rest/plugins/1.0/' + self.key + '-key'
            headers = {
                'Content-Type': 'application/vnd.atl.plugins.plugin+json',
                'X-Atlassian-Token': 'nocheck'
            }

            self.plugin_descriptor['enabled'] = is_enabled
            data = self.module.jsonify(self.plugin_descriptor)

            rsp, info = fetch_url(self.module, plugin_url, method="PUT", headers=headers, data=data)  #fetch_url() https://github.com/ansible/ansible/blob/devel/lib/ansible/module_utils/urls.py#L985

            status_code = info['status']
            print("Status code: %s" % status_code)
            if status_code == -1:
                self.module.fail_json(msg=info['msg'], url=plugin_url)
            elif status_code == 404:
                self.module.fail_json(msg="No plugin with key " + self.key + " was found")
            elif status_code == 200:
                self.changed = True
            else:
                self.module.fail_json(msg=info['body'])

def main():
    module = AnsibleModule(
        argument_spec=dict(
            src=dict(required=True),
            plugin_key=dict(required=True),
            plugin_version=dict(required=True),
            jira_url=dict(required=True),
            url_username=dict(required=True),
            url_password=dict(required=True),
            state=dict(choices=['enabled', 'disabled', 'absent']),
            force=dict(required=False, default=False),
            force_basic_auth=dict(required=False, default=True)
        ),
        supports_check_mode=False
    )
    jpi = JiraPlugin(module)
    jpi.fetch_current_state()
    if jpi.is_installed:
        print(jpi.plugin_descriptor['version'])

    desired_state = module.params['state']
    force = module.params['force']

    result = {}

    if desired_state == 'enabled':
        jpi.enable()
        result['state'] = 'enabled'
    elif desired_state == 'disabled':
        print("Disabling")
        jpi.disable()
        result['state'] = 'disabled'
    elif desired_state == 'absent':
        print("Removing")
        jpi.remove()
        result['state'] == 'absent'
    else:
        print("Doing none of the above")
    
    print("Stuff was checked")
    result['changed'] = jpi.changed

    if jpi.is_installed:
        result['plugin_name'] = jpi.plugin_descriptor['name']
        result['plugin_version'] = jpi.plugin_descriptor['version']
        result['plugin_vendor'] = jpi.plugin_descriptor['vendor']['name']

    module.exit_json(**result)


if __name__ == '__main__':
    main()