from django.http import HttpResponse
from .models import Item

def index(request):
    items = Item.objects.all()
    return HttpResponse(', '.join([item.name for item in items]))
