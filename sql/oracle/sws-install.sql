/* -------------------
***************** NEW installation ***********************

1. Login in as ctxsys and run the intermedia-setup.sql - If you have already 
    run this for another ACS installation using the same Oracle
    instance, do not run this again.

2. Run the sws-package-all.sql under the same schema as the ACS instance.

3. Run content-revision-sws.sql to add SWS for content-revision object type.  

4. (if file-storage installed) file-storage-sws.sql to setup SWS for file storage

5. (if news-sws installed) news-sws.sql to setup SWS for news

6. (if bboard installed) bboard-sws.sql to setup SWS for bboard. 
   Copy site-wide-search/www/search-redirect.tcl to bboard/www/

7. sws-reindex.sql 
---------------------*/


/* ------------------
***************** UPGRADE 4.0.13b to 4.0.1 instructions ***********************************
/* 
1. (if file-storage installed) file-storage-sws.sql to setup SWS for file storage

2. (if news-sws installed) news-sws.sql to setup SWS for news

3. (if bboard installed) bboard-sws.sql to setup SWS for bboard
   Copy site-wide-search/www/search-redirect.tcl to bboard/www/

4. sws-reindex.sql
*/


/* -------------------
Instructions for removing the site wide search:

1. (if installed) Run file-storage-sws-drop.sql to remove SWS support files

2. (if installed) Run news-sws-drop.sql to remove SWS support for news

3. (if installed) Run bboard-sws-drop.sql to remove SWS support for bboard

4. (if installed) Run content-revision-sws-drop.sql to drop SWS for content-revison object

5. Run the sws-package-all-drop.sql under the same schema as the ACS instance.

6. If there are no other ACS instances, on the same Oracle instance, have SWS installed, then you can run intermedia-setup-remove.sql under the ctxsys schema.


---------------------*/
 



