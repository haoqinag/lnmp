# Generated by Django 2.1 on 2020-05-23 14:30

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('webapp', '0004_domaininfo'),
    ]

    operations = [
        migrations.AddField(
            model_name='domaininfo',
            name='note',
            field=models.CharField(default=1, max_length=128),
            preserve_default=False,
        ),
    ]
