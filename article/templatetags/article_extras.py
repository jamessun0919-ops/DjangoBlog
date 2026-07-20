import markdown
from django import template
from django.template.defaultfilters import striptags

register = template.Library()


@register.filter
def strip_markdown(value):
    html = markdown.markdown(value)
    return striptags(html)
