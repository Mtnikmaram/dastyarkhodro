from django.contrib import admin
from django.urls import include, path
from rest_framework.routers import DefaultRouter
from vehicles.views import VehicleViewSet, MaintenanceRecordViewSet, ExpenseViewSet, health

router = DefaultRouter()
router.register("vehicles", VehicleViewSet, basename="vehicle")
router.register("maintenance", MaintenanceRecordViewSet, basename="maintenance")
router.register("expenses", ExpenseViewSet, basename="expense")

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/health/", health, name="health"),
    path("api/v1/", include(router.urls)),
]
