from rest_framework import serializers
from .models import Vehicle, MaintenanceRecord, Expense


class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ["id", "nickname", "make", "model", "year", "current_odometer_km", "fuel_type", "created_at", "updated_at"]
        read_only_fields = ["id", "created_at", "updated_at"]

    def validate_year(self, value):
        if value is not None and not 1885 <= value <= 2200:
            raise serializers.ValidationError("سال ساخت معتبر نیست.")
        return value


class MaintenanceRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = MaintenanceRecord
        fields = ["id", "vehicle", "category", "title", "service_date", "odometer_km", "cost", "currency", "notes", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate(self, attrs):
        vehicle = attrs.get("vehicle", getattr(self.instance, "vehicle", None))
        odo = attrs.get("odometer_km")
        if vehicle and odo is not None and odo > max(vehicle.current_odometer_km, odo):
            raise serializers.ValidationError({"odometer_km": "کیلومتر نامعتبر است."})
        return attrs


class ExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Expense
        fields = ["id", "vehicle", "category", "title", "amount", "currency", "expense_date", "odometer_km", "notes", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate_amount(self, value):
        if value < 0:
            raise serializers.ValidationError("مبلغ نمی‌تواند منفی باشد.")
        return value
