from django.contrib import admin
from django.contrib.auth.models import User
from django.urls import include, path
from rest_framework import serializers
from rest_framework.routers import DefaultRouter
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from vehicles.models import UserProfile
from vehicles.views import VehicleViewSet, MaintenanceRecordViewSet, ExpenseViewSet, health
import re

router = DefaultRouter()
router.register("vehicles", VehicleViewSet, basename="vehicle")
router.register("maintenance", MaintenanceRecordViewSet, basename="maintenance")
router.register("expenses", ExpenseViewSet, basename="expense")

class RegisterSerializer(serializers.ModelSerializer):
    phone = serializers.CharField(write_only=True, required=True, min_length=11, max_length=11)
    password = serializers.CharField(write_only=True, required=True, min_length=8)
    first_name = serializers.CharField(required=True)
    last_name = serializers.CharField(required=True)

    class Meta:
        model = User
        fields = ("username", "phone", "first_name", "last_name", "password")

    def validate_username(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("نام کاربری الزامی است.")
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("این نام کاربری قبلاً ثبت شده است.")
        return value

    def validate_phone(self, value):
        value = value.strip().replace(" ", "")
        if not re.fullmatch(r"09\d{9}", value):
            raise serializers.ValidationError("شماره موبایل باید به صورت 09xxxxxxxxx وارد شود.")
        if UserProfile.objects.filter(phone=value).exists():
            raise serializers.ValidationError("این شماره موبایل قبلاً ثبت شده است.")
        return value

    def create(self, validated_data):
        phone = validated_data.pop("phone")
        user = User.objects.create_user(**validated_data)
        UserProfile.objects.create(user=user, phone=phone)
        return user

class RegisterView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response({"id": user.id, "username": user.username, "phone": user.profile.phone, "first_name": user.first_name, "last_name": user.last_name}, status=201)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/health/", health, name="health"),
    path("api/v1/auth/register/", RegisterView.as_view(), name="register"),
    path("api/v1/auth/token/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/v1/auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/v1/", include(router.urls)),
]
