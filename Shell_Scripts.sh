
--------------------------------------------------------------
--Hard and Soft Links
--------------------------------------------------------------

-- Soft link example

Syntax:
ln -s targetFile srcFile

-s : Option for softlink



mkdir LinkTest;

touch softlink_test.txt;

ls -li softlink_test.txt;

ln -s softlink_test.txt myShortcut;

ls -li;

cat softlink_test.txt;
cat myShortcut;


mv softlink_test.txt renamedSoftlink_test.txt
ls -li
cat myShortcut;

--Create link for terminal
cd ~/Desktop;
ln -s /usr/bin/gnome-ternimal terminal;
ls -li;



-- Hard link example

touch hardlink_test.txt;
ln harklink_test.txt hardlink1;

ls -la hardlink_test.txt hardlink1;
