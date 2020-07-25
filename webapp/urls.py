from django.urls import path
from . import views

urlpatterns = [
    path('', views.login,),
    path('check', views.check,),
    path('index', views.index,),
    path('loginout', views.loginout,),
    path('softinstall', views.softinstall,),
    path(r'site',views.site),
    path(r'addsite',views.addsite),
    path('installsoft',views.installsoft),
    path('sitedata',views.sitedata),
    path('tag',views.tag),
    path('addtag', views.addtag),
    path('op_site', views.op_site),
    path('success_install', views.success_install),
    path('uniquedomain', views.uniquedomain),
]