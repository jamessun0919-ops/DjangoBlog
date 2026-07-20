from django.contrib.auth.decorators import login_required
from django.shortcuts import redirect, render
from django.http import HttpResponse
from article.forms import PostForm
from article.models import Post
from datetime import datetime
# Create your views here.

def index(request):
    # posts = Post.objects.all()
    # post_list = list()
   
    # for count, post in enumerate(posts):
    #     post_list.append("#{}: {}<br><hr>".format(str(count), str(post)))
    #     post_list.append("<small>{}</small><br><hr>".format(post.content))
    #     post_list.append("<h6><i>{}</i></h6></br>".format(str(post.slug)))
    #     post_list.append("<h6>{}</h6>".format(str(post.pub_date)))

    # return HttpResponse(post_list)

    posts = Post.objects.all()
    now = datetime.now()

    return render(request, "index.html", {'posts': posts, 'now': now})


@login_required
def post_create(request):
    if request.method == 'POST':
        form = PostForm(request.POST)
        if form.is_valid():
            post = form.save(commit=False)
            post.author = request.user
            post.save()
            return redirect('index')
    else:
        form = PostForm()

    return render(request, "post_form.html", {'form': form})
