import json
import os
import time
import urllib.request
import socket
import subprocess
from config import *
import base64


IP_SERVICES = [
    "https://api.ipify.org", "https://ipv4.lafibre.info/ip.php", "https://v4.ident.me"
]

DNS_TTL = 3660  # time for rechecking cached dns
CFG_FILE = "ovh_dns.json"
cfg = {
    "domains": {},
    "ip_counter": 0,
}


def save_cfg():
    with open(CFG_FILE, "w") as f:
        json.dump(cfg, f)


def check_my_ip(cfg):
    idx = cfg['ip_counter']
    if idx >= len(IP_SERVICES):
        idx = 0

    response = urllib.request.urlopen(IP_SERVICES[idx])
    ip = response.read().decode('utf-8')
    idx += 1
    cfg['ip_counter'] = idx

    return ip


def check_domain_ip(domain):
    command = f"dig "+DNS_SERVER+" +short " + domain + " A"
    try:
        result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print("An error occurred while executing the command: {e.stderr}")

    return None


if not os.path.exists(CFG_FILE):
    save_cfg()


with open(CFG_FILE) as f:
    cfg = json.load(f)

# check what is our current IP
my_ip = check_my_ip(cfg)
entries = DOMAINS.copy()
dirty = []

#  check and refresh current domain data if necessary
for entry in filter(lambda domain: domain.get("depends") is None, entries):
    print("* Checking IP for ", entry['domain'])
    if (entry['domain'] not in cfg["domains"]  # if we have no entry
            or time.time() > cfg["domains"][entry['domain']][1] + DNS_TTL # or entry is old
            or cfg["domains"][entry['domain']][0] is None #  we have no IP
        ):
        print("- force cache refreshing (IP)")
        domain_ip = check_domain_ip(entry['domain'])
        cfg["domains"][entry['domain']] = [domain_ip, time.time()]

    if cfg["domains"][entry['domain']][0] != my_ip:
        dirty.append(entry['domain'])
        print("- IP missmatch")


for domain in dirty:
    print("Checking: ", domain)
    for item in entries:
        if item['domain'] == domain: # or item['depends'] == domain:
            print("Refreshing: ", item['domain'])
            credentials = base64.b64encode((item['login'] + ":" + item['password']).encode('utf-8')).decode('utf-8')
            url = "https://www.ovh.com/nic/update?system=dyndns&hostname=" + item['domain'] + "&myip=" + my_ip
            headers = {
                'Authorization': f'Basic {credentials}'
            }
            request = urllib.request.Request(url, headers=headers)
            try:
                response = urllib.request.urlopen(request)
                data = response.read().decode('utf-8')
                cfg["domains"][domain][0] = my_ip
                print("OK")
            except urllib.error.HTTPError as e:
                print(e)
                print(" !!!! FAILED")

save_cfg()
