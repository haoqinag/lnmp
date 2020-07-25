from django.db import models

# Create your models here.
#软件信息
class softinfo(models.Model):
    softname = models.CharField(max_length=128)
    version = models.CharField(max_length=32)
    dir = models.CharField(max_length=256)
    introduce = models.CharField(max_length=1024)
    image = models.CharField(max_length=256)
    status = models.IntegerField()
#站点信息
class siteinfo(models.Model):
    domain = models.CharField(max_length=1024)
    note = models.CharField(max_length=128)
    siteroot = models.CharField(max_length=128)
    ftp = models.CharField(max_length=128)
    ftppass = models.CharField(max_length=128)
    mysql = models.CharField(max_length=64)
    mysqlpass = models.CharField(max_length=64)
    sitephpver = models.CharField(max_length=16)
    sitetag = models.CharField(max_length=16)
#站点分类
class sitetag(models.Model):
    sitetag=models.CharField(max_length=32)
class domaininfo(models.Model):
    domain = models.CharField(max_length=256)
    note = models.CharField(max_length=128)