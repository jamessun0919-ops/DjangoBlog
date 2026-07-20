from django.urls import path
from article import views

urlpatterns = [
    path('', views.index, name='index'),
    path('post/new/', views.post_create, name='post_create'),
]
