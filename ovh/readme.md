refreshes DynHost entry for OVH hosted domain.

- create domain & credentials for managing
- add entry to config.py 


add to cron
*/7 * * * * cd /home/kosci/services/ovh && /usr/bin/python3 main.py >> /home/kosci/services/ovh/log.txt 2>&1