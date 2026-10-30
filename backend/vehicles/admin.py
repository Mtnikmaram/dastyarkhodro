from django.contrib import admin
from django.contrib.auth.models import User
from .models import UserProfile, Vehicle, MaintenanceRecord, Expense


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "phone", "user_active", "date_joined")
    search_fields = ("user__username", "user__first_name", "user__last_name", "phone")
    list_filter = ("user__is_active", "user__is_staff")

    @admin.display(boolean=True, description="فعال")
    def user_active(self, obj):
        return obj.user.is_active

    @admin.display(description="تاریخ ثبت")
    def date_joined(self, obj):
        return obj.user.date_joined


admin.site.unregister(User)


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ("username", "first_name", "last_name", "phone", "is_active", "is_staff", "date_joined")
    search_fields = ("username", "first_name", "last_name", "profile__phone")
    list_filter = ("is_active", "is_staff", "is_superuser")
    ordering = ("-date_joined",)
    readonly_fields = ("date_joined", "last_login")
    fieldsets = (
        ("اطلاعات ورود", {"fields": ("username", "password")}),
        ("اطلاعات شخصی", {"fields": ("first_name", "last_name", "email")}),
        ("دسترسی", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("تاریخچه", {"fields": ("last_login", "date_joined")}),
    )

    @admin.display(description="موبایل")
    def phone(self, obj):
        try:
            return obj.profile.phone
        except UserProfile.DoesNotExist:
            return "-"


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ("__str__", "owner", "year", "current_odometer_km", "fuel_type", "transmission", "created_at")
    search_fields = ("make", "model", "nickname", "owner__username")
    list_filter = ("fuel_type", "transmission", "year")
    autocomplete_fields = ("owner",)


@admin.register(MaintenanceRecord)
class MaintenanceRecordAdmin(admin.ModelAdmin):
    list_display = ("title", "vehicle", "category", "service_date", "odometer_km", "cost", "currency")
    search_fields = ("title", "vehicle__make", "vehicle__model", "vehicle__owner__username")
    list_filter = ("category", "currency", "service_date")
    autocomplete_fields = ("vehicle",)


@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    list_display = ("title", "vehicle", "category", "expense_date", "amount", "currency")
    search_fields = ("title", "vehicle__make", "vehicle__model", "vehicle__owner__username")
    list_filter = ("category", "currency", "expense_date")
    autocomplete_fields = ("vehicle",)
