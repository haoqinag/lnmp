from django.shortcuts import render,redirect
import os,hashlib,configparser,subprocess,json
from django.http import HttpResponse
from webapp.models import softinfo,siteinfo,sitetag,domaininfo
# Create your views here.
shellroot="bash /www/panel/lnmp/shell"
def auth_login(request):
    try:
        user = request.session['username']
        return user
    except Exception:
        return 404

def login(request):
    user = auth_login(request)
    if user != 404: return redirect("/index")
    return render(request,'webapp/login.html',{'title':"登录页面","content":"Hello world!!"})

#判断域名是否已经存在
def uniquedomain(request):
    user = auth_login(request)
    if user == 404: return redirect("/")
    if request.method == "GET":
        domain = request.GET.get("domain")
        res = domaininfo.objects.filter(domain=domain)
        if res:
            return HttpResponse(domain)
        else:
            return HttpResponse(True)
    else:
        return HttpResponse(403)


def check(request):
    if request.method == "POST":
        user = request.POST.get("username")
        pwd = request.POST.get("password")
        p = os.path.join(os.path.dirname(os.path.abspath(__file__)),"data/admindb.txt")
        with open(p,"r") as f:
            while f:
                txt = f.readline()
                if not txt:break
                info = txt.split(":")
                if user == info[0] and hashlib.md5(pwd.encode("utf8")).hexdigest() == info[1].strip():
                    request.session['username'] = user
                    request.session.set_expiry(0)
                    return redirect('/index')
            return HttpResponse("用户名或者密码不正确")

def index(request):
    user = auth_login(request)
    if user == 404: return redirect("/")
    user = request.session['username']
    #处理页面地图
    tag = 0
    return render(request,'webapp/index.html',locals())

def loginout(request):
    auth_login(request)
    del request.session["username"]
    # request.session.clear()
    return redirect('/')

def site(request):
    user = auth_login(request)
    if user == 404: return redirect("/")
    user = request.session['username']
    tag = 1
    model = "网站管理"
    sites=siteinfo.objects.all()
    return render(request, 'webapp/site.html', locals())

#软件安装页面
def softinstall(request):
    user = auth_login(request)
    print(request.session.get("username"))
    if user == 404:return redirect("/")
    tag = 1
    model = "软件安装"
    #0-未安装 1-运行中 2-安装未运行 3-安装中
    softs = softinfo.objects.all()
    return render(request,'webapp/softinstall.html',locals())

def addsite(request):
    user = auth_login(request)
    if user == 404: return redirect("/")
    user = request.session['username']
    phps = softinfo.objects.filter(status=1,softname__contains="php").values_list("softname")
    phps = sorted(phps)
    if not phps:
        phps="null"
    #根据sitetag字段查询分类返回列表
    siteclass = sitetag.objects.values_list("sitetag")
    return render(request,'webapp/addsite.html',locals())

def installsoft(request):
    user = auth_login(request)
    if user == 404: return redirect("/")
    if request.method == "POST":
        softname = request.POST.get("softname")
        flag = request.POST.get("flag")
        q = softinfo.objects.filter(softname=softname).values('status')
        status = q[0]["status"]
        alias_soft = softname
        if softname[0:3]=="php":
            softname = "php"
        print(softname)
        if status == 0:
            devNull=open(os.devnull,"w")
            try:
                subprocess.Popen(shellroot+"/%s.sh %s" % (softname.lower(), flag),shell=True,stdout=devNull,stderr=devNull)
                softinfo.objects.filter(softname=alias_soft).update(status=3)
                return HttpResponse("ok")
            except Exception as e:
                #result={"status":"False","err":e}
                #print(result)
                return HttpResponse("False")

#添加站点数据
def sitedata(request):
    user = auth_login(request)
    if user == 404: return redirect("/")
    if request.method == "POST":
        #接收到的是字典,但是值是列表
        site_data = request.POST
        dic={}
        #遍历字典中的值，转换为字符串
        for k,v in site_data.items():
            dic[k] = str(v)
        #插入到表中
        domain = dic.get("domain")
        list_domain = domain.split(",")
        #批量创建对象插入
        list_obj=[]
        for d in list_domain:
            list_obj.append(domaininfo(domain=d,note=dic.get('note')))
        domaininfo.objects.bulk_create(list_obj)
        siteroot = dic.get("siteroot")
        sitephpver = dic.get('sitephpver')
        subprocess.Popen(shellroot+"/site.sh %s %s %s" % (domain,siteroot,sitephpver),shell=True)
        res = siteinfo.objects.create(**dic);
        if res.id:
            return HttpResponse("ok")

#查询网站分类
def tag(request):
    user = auth_login(request)
    if user == 404: return redirect("/")
    sitetags = sitetag.objects.values_list('id', 'sitetag')
    return render(request,'webapp/tag.html',locals())
#添加网站分类
def addtag(request):
    user = auth_login(request)
    if user == 404: return redirect("/")
    if request.method == "POST":
        act=request.POST['method']
        if act == 'add':
            tags=request.POST['tags']
            siteclass = sitetag.objects.values_list("sitetag")
            if (tags,) not in siteclass:
                res = sitetag.objects.create(sitetag=tags)
                return HttpResponse(res.id)
            else:
                return HttpResponse(0)
        elif act == 'del':
            id=request.POST['id']
            sitetag.objects.filter(id=id).delete()
            return HttpResponse("ok")

#站点操作
def op_site(request):
    user = auth_login(request)
    if user == 404: return redirect("/")
    if request.method == "POST":
        act = request.POST['method']
        if act == "del":
            id = request.POST['id']
            res = siteinfo.objects.filter(id=id).values('note','domain')
            note = res[0].get("note")
            domaininfo.objects.filter(note=note).delete()
            siteinfo.objects.filter(id=id).delete()
            subprocess.Popen(shellroot + "/delsite.sh %s" % (res[0].get("domain")), shell=True)
            return HttpResponse(200)

def success_install(request):
    softname=request.GET['softname']
    dir =request.GET['dir']
    res=softinfo.objects.filter(softname=softname).values('status','dir')
    if res[0].get('status') == 3 or res[0].get('dir') == '0':
        softinfo.objects.filter(softname=softname).update(status=1,dir=dir)
        return HttpResponse(softname+" install success")
    return HttpResponse(403)