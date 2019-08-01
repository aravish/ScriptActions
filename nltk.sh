#! /bin/bash
sudo su spark
mkdir /home/nltk_data
chown spark:root /home/nltk_data
/usr/bin/anaconda/bin/python -m nltk.downloader all -d /home/nltk_data