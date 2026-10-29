from django.contrib import admin
from .models import Vehicle, MaintenanceRecord, Expense

admin.site.register(Vehicle)
admin.site.register(MaintenanceRecord)
admin.site.register(Expense)
