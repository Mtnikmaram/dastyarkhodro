from django.contrib import admin
from django.contrib.auth.models import User
from django.urls import include, path
from rest_framework import serializers
from rest_framework.routers import DefaultRouter
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from vehicles.views import VehicleViewSet, MaintenanceRecordViewSet, ExpenseViewSet, health

router = DefaultRouter()
router.register("vehicles", VehicleViewSet, basename="vehicle")
router.register("maintenance", MaintenanceRecordViewSet, basename="maintenance")
router.register("expenses", ExpenseViewSet, basename="expense")

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    class Meta:
        model = User
        fields = ("username", "email", "password")
    def create(self, validated_data):
        return User.objects.create_user(**validated_data)

class RegisterView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response({"id": user.id, "username": user.username, "email": user.email}, status=201)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/health/", health, name="health"),
    path("api/v1/auth/register/", RegisterView.as_view(), name="register"),
    path("api/v1/auth/token/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/v1/auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/v1/", include(router.urls)),
]
